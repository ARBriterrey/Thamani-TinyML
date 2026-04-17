# PRD: MATLAB Worker Concurrency — Scale to 100 Parallel Jobs

**Status:** Pending senior review
**Author:** Thamani TinyML Team
**Date:** 2026-04-15

---

## Problem Statement

The current architecture spawns one ephemeral Docker container per processing job
using the Docker SDK (Docker-outside-of-Docker pattern on a single GCP VM). At low
concurrency this works correctly, but the system cannot safely handle 100 simultaneous
MATLAB worker jobs because:

1. **Memory ceiling on a single VM**: A real MATLAB MCR (MATLAB Compiler Runtime)
   container requires approximately 2–4 GB of RAM. 100 concurrent containers would
   require 200–400 GB on a single machine — exceeding the capacity of any single
   GCP instance.

2. **Docker daemon overload**: The Docker engine on the host has practical limits
   on simultaneous container lifecycle operations and concurrent I/O on the shared
   volume.

3. **No back-pressure mechanism**: The current async implementation spawns a new OS
   thread and Docker container for every accepted HTTP request with no cap. Under
   high load this exhausts both thread pool and system memory simultaneously.

---

## Goals

1. Allow up to 100 MATLAB worker jobs to run concurrently without crashing or
   degrading the orchestrator.
2. Keep the existing REST API contract unchanged (ESP32 and dashboard continue to
   work without modification).
3. Support horizontal scale-out without requiring the orchestrator to manage a larger
   VM.

## Non-Goals

- Real-time streaming of results (polling pattern is acceptable).
- Changes to the MATLAB algorithm or risk scoring logic.
- Modifications to the ESP32 firmware (covered separately).

---

## Proposed Solution

### Layer 1 — Concurrency Guard (Immediate, Low Risk)

Add a `threading.Semaphore` in the orchestrator to hard-cap the number of
simultaneously running Docker containers on the current VM.

- Cap value read from environment variable `MAX_CONCURRENT_WORKERS` (default: 5
  for real MATLAB MCR; can be raised for the Python placeholder).
- Jobs that arrive when all slots are occupied queue in their Python threads and
  execute as capacity frees.
- Zero infrastructure change — works with the existing Docker Compose deployment.

**Files affected:**
- `server-deployment/main-orchestrator/app.py` — add semaphore, wrap worker
  invocation with `with _worker_sem:`

**Risk:** Low. Fully backwards compatible.

---

### Layer 2 — Cloud Run Jobs (Proper Horizontal Scale)

Replace the Docker-SDK container spawn with Google Cloud Run Jobs API calls.
Each submitted job triggers an isolated Cloud Run Job execution managed entirely
by Google Cloud. This provides true horizontal concurrency — 100 jobs = 100
parallel Cloud Run executions on Google's managed infrastructure.

#### Why Cloud Run Jobs (not standard Cloud Run)

| Feature | Cloud Run (service) | Cloud Run Jobs |
|---------|-------------------|----------------|
| Trigger | HTTP request | API / schedule |
| Lifetime | Long-running | Runs to completion, exits |
| Billed | Per request-second | Per CPU-second of execution |
| Suitable for MATLAB | No (request timeout) | Yes (up to 24h timeout) |

#### Shared Data: Docker Volume → GCS Bucket

Docker named volumes cannot be shared with Cloud Run. The
`/data/jobs/{job_id}/input.json` and `output.json` file-based contract is
preserved, but the transport moves to a GCS bucket:

```
jobs/{job_id}/input.json    (orchestrator writes → worker reads)
jobs/{job_id}/output.json   (worker writes → orchestrator reads)
jobs/{job_id}/model.tflite  (worker writes → orchestrator serves via HTTP)
```

Both the orchestrator and the MATLAB worker use the `google-cloud-storage`
Python SDK. The file path strings and JSON schemas remain identical — only
the read/write calls change.

#### Execution Flow (Layer 2)

```
POST /api/process
  │
  ├─ orchestrator writes input.json → GCS
  ├─ orchestrator calls Cloud Run Jobs API: jobs.run(job_id, gcs_bucket)
  │   └─ Cloud Run schedules execution on managed infrastructure
  ├─ orchestrator polls executions.get() every 5 s
  └─ on SUCCEEDED: reads output.json from GCS, updates job state → "completed"
     on FAILED:    updates job state → "failed" with error
```

#### One-Time Infrastructure Setup (manual, done once)

```bash
# Push MATLAB worker image to Artifact Registry
gcloud artifacts repositories create thamani --repository-format=docker --location=REGION
docker tag thamani-tinyml-matlab-worker gcr.io/PROJECT_ID/thamani-matlab-worker
docker push gcr.io/PROJECT_ID/thamani-matlab-worker

# Create the Cloud Run Job resource
gcloud run jobs create matlab-worker \
  --image gcr.io/PROJECT_ID/thamani-matlab-worker \
  --region REGION \
  --task-timeout 300 \
  --max-retries 1 \
  --service-account thamani-worker-sa@PROJECT_ID.iam.gserviceaccount.com
```

---

## Files Requiring Changes (Layer 2)

| File | Change |
|------|--------|
| `server-deployment/main-orchestrator/orchestrator.py` | Replace Docker SDK calls with Cloud Run Jobs API + GCS read/write |
| `server-deployment/main-orchestrator/requirements.txt` | Add `google-cloud-run`, `google-cloud-storage` |
| `server-deployment/matlab-worker/process.py` | Replace `open()` file I/O with GCS SDK calls |
| `server-deployment/matlab-worker/requirements.txt` | Add `google-cloud-storage` |
| `server-deployment/docker-compose.yml` | Add `GCS_BUCKET`, `GOOGLE_APPLICATION_CREDENTIALS` env vars; remove `shared-data` volume |
| `server-deployment/main-orchestrator/app.py` | Pass `gcs_bucket` to orchestrator constructor |

---

## Implementation Order

| Step | Task | Risk |
|------|------|------|
| 1 | Add semaphore guard to `app.py` | Low |
| 2 | Create GCS bucket, test access from VM | Low |
| 3 | Update `process.py` to read/write GCS | Medium |
| 4 | Update `orchestrator.py` to use GCS for I/O | Medium |
| 5 | Push MATLAB worker image to Artifact Registry | Low |
| 6 | Create Cloud Run Job resource | Low |
| 7 | Replace `docker.containers.run()` with Cloud Run Jobs API | High |
| 8 | Remove Docker volume from `docker-compose.yml` | Low |

---

## Acceptance Criteria

- [ ] 100 concurrent POST requests to `/api/process` all return `202` within 1 s.
- [ ] All 100 jobs complete and return `status: "completed"` when polled.
- [ ] No OOM errors on the orchestrator VM under 100 concurrent jobs.
- [ ] Cloud Run Jobs console shows 100 parallel executions for a 100-job burst.
- [ ] Existing API contract (`/api/process`, `/api/jobs/<id>`, `/api/model/latest`)
      unchanged — ESP32 firmware requires no modification.

---

## Open Questions for Senior Review

1. **GCS bucket region**: Should the bucket be co-located with the Cloud Run Job
   region (same region as GCP VM) to minimise latency and egress cost?

2. **Service account permissions**: Least-privilege — orchestrator SA needs
   `run.jobs.run` + `storage.objects.create`; worker SA needs
   `storage.objects.get` + `storage.objects.create`. Is this the right split?

3. **Layer 1 only?**: If max realistic concurrency is ≤ 20 and the VM is sized
   appropriately, is Layer 1 (semaphore) sufficient without Cloud Run migration?

4. **MATLAB MCR image size**: MCR r2024a is ~8 GB compressed. Cold-start latency
   on Cloud Run for first execution may be 2–3 minutes. Is this acceptable, or
   does the job need a warm pool?
