"""
Main Orchestrator – Flask API Server
=====================================
Receives raw sensor data from medical devices, triggers MATLAB processing
asynchronously, and returns the processed risk score.

Job lifecycle
─────────────
POST /api/process  → 202 { job_id, status: "processing" }
GET  /api/jobs/<id>  → { status: "processing" | "completed" | "failed", ... }
GET  /api/jobs/<id>/model  → binary .tflite model file (when available)
GET  /api/model/latest     → metadata for the most recent model file
"""

import os
import json
import uuid
import logging
import threading
from datetime import datetime, timezone

from flask import Flask, request, jsonify, send_file
from orchestrator import MatlabOrchestrator

# ── Configuration ────────────────────────────────────────────────────────
app = Flask(__name__, static_folder="static", static_url_path="/static")
app.config["DATA_PATH"] = os.environ.get("DATA_MOUNT_PATH", "/data")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

orchestrator = MatlabOrchestrator(
    worker_image=os.environ.get("WORKER_IMAGE", "thamani-tinyml-matlab-worker"),
    shared_volume=os.environ.get("SHARED_VOLUME", "thamani-tinyml_shared-data"),
    data_path=app.config["DATA_PATH"],
)

# ── In-memory job state store ────────────────────────────────────────────
# Keyed by job_id. Survives the request but NOT a server restart — completed
# jobs are also on disk via output.json so the GET endpoint falls back there.
_jobs: dict = {}
_jobs_lock = threading.Lock()


def _set_job(job_id: str, data: dict):
    with _jobs_lock:
        _jobs[job_id] = data


def _get_job(job_id: str) -> dict | None:
    with _jobs_lock:
        return _jobs.get(job_id)


# ── Background worker ────────────────────────────────────────────────────

def _run_worker(job_id: str):
    """Runs in a daemon thread. Calls the MATLAB worker and updates job state."""
    logger.info("Job %s: worker thread started", job_id)
    try:
        exit_code = orchestrator.run_worker(job_id)

        if exit_code == 0:
            result = orchestrator.read_output(job_id)
            _set_job(job_id, {
                **_get_job(job_id),
                "status": "completed",
                "result": result,
                "completed_at": datetime.now(timezone.utc).isoformat(),
            })
            logger.info("Job %s: completed (risk: %s)", job_id,
                        result.get("result", {}).get("risk_category", "?"))
        else:
            _set_job(job_id, {
                **_get_job(job_id),
                "status": "failed",
                "error": f"Worker exited with code {exit_code}",
                "failed_at": datetime.now(timezone.utc).isoformat(),
            })
            logger.error("Job %s: worker exited %d", job_id, exit_code)

    except Exception as exc:
        _set_job(job_id, {
            **_get_job(job_id),
            "status": "failed",
            "error": str(exc),
            "failed_at": datetime.now(timezone.utc).isoformat(),
        })
        logger.exception("Job %s: unexpected error in worker thread", job_id)


# ── Routes ───────────────────────────────────────────────────────────────

@app.route("/", methods=["GET"])
def index():
    """Serve the demo dashboard."""
    return app.send_static_file("index.html")


@app.route("/api/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "medical-data-orchestrator",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }), 200


@app.route("/api/process", methods=["POST"])
def process_data():
    """
    Accept raw sensor data and kick off asynchronous MATLAB processing.

    Returns 202 immediately with a job_id. The client polls
    GET /api/jobs/<job_id> until status is "completed" or "failed".

    Expected JSON payload:
    {
        "device_id": "DEV-001",
        "sensor_data": {
            "heart_rate": 72,
            "spo2": 98,
            "temperature": 36.6,
            "systolic_bp": 120,
            "diastolic_bp": 80
        }
    }
    """
    job_id = str(uuid.uuid4())
    received_at = datetime.now(timezone.utc).isoformat()

    if request.is_json:
        payload = request.get_json()
        if "device_id" not in payload:
            return jsonify({"error": "Missing required field: device_id"}), 400
        if "sensor_data" not in payload:
            return jsonify({"error": "Missing required field: sensor_data"}), 400

        device_id = payload["device_id"]
        logger.info("Job %s: received JSON from device %s", job_id, device_id)

        job_record = {
            "job_id": job_id,
            "device_id": device_id,
            "received_at": received_at,
            "sensor_data": payload["sensor_data"],
        }
        try:
            orchestrator.save_input(job_id, job_record)
        except Exception as exc:
            logger.exception("Job %s: failed to save input", job_id)
            return jsonify({"error": str(exc), "job_id": job_id}), 500

    elif "file" in request.files:
        device_id = request.form.get("device_id", "UNKNOWN-DEV")
        logger.info("Job %s: received BINARY file from device %s", job_id, device_id)
        file_obj = request.files["file"]
        file_data = file_obj.read()
        
        try:
            # Save the binary data as .bin
            orchestrator.save_binary_input(job_id, file_data)
            # Also save input.json with metadata in case the worker needs it
            job_record = {
                "job_id": job_id,
                "device_id": device_id,
                "received_at": received_at,
                "sensor_data": "binary_payload"
            }
            orchestrator.save_input(job_id, job_record)
        except Exception as exc:
            logger.exception("Job %s: failed to save binary input", job_id)
            return jsonify({"error": str(exc), "job_id": job_id}), 500
            
    else:
        return jsonify({"error": "Request must be application/json or multipart/form-data with 'file'"}), 400

    # Register job as processing before spawning thread (avoids race)
    _set_job(job_id, {
        "status": "processing",
        "device_id": device_id,
        "received_at": received_at,
    })

    thread = threading.Thread(target=_run_worker, args=(job_id,), daemon=True)
    thread.start()

    return jsonify({
        "job_id": job_id,
        "status": "processing",
        "poll_url": f"/api/jobs/{job_id}",
    }), 202


@app.route("/api/jobs/<job_id>", methods=["GET"])
def get_job(job_id):
    """
    Return current job status. Poll this until status != "processing".

    Response when processing:  { job_id, status: "processing" }
    Response when completed:   { job_id, status: "completed", result: { ... } }
    Response when failed:      { job_id, status: "failed", error: "..." }
    """
    job = _get_job(job_id)

    if job:
        return jsonify({"job_id": job_id, **job}), 200

    # Fallback: job survived a server restart — check disk
    try:
        result = orchestrator.read_output(job_id)
        return jsonify({
            "job_id": job_id,
            "status": "completed",
            "result": result,
        }), 200
    except FileNotFoundError:
        return jsonify({"error": "Job not found", "job_id": job_id}), 404


@app.route("/api/jobs/<job_id>/model", methods=["GET"])
def get_job_model(job_id):
    """
    Download the TFLite model file produced by the MATLAB worker for this job.
    Returns the binary file as an attachment.
    Used by ESP32 to fetch a new model for on-device inference.
    """
    try:
        model_path = orchestrator.get_model_path(job_id)
        return send_file(
            model_path,
            as_attachment=True,
            download_name=f"model_{job_id[:8]}.tflite",
            mimetype="application/octet-stream",
        )
    except FileNotFoundError:
        return jsonify({"error": "No model file for this job", "job_id": job_id}), 404


@app.route("/api/model/latest", methods=["GET"])
def get_latest_model():
    """
    Return metadata about the most recently produced model file.
    ESP32 checks this endpoint to decide whether to download a new model.

    Response: { job_id, model_url, size_bytes, created_at }
    """
    try:
        meta = orchestrator.get_latest_model()
        return jsonify(meta), 200
    except FileNotFoundError:
        return jsonify({"error": "No model available yet"}), 404


@app.route("/api/jobs/recent", methods=["GET"])
def get_recent_jobs():
    """Retrieve the 5 most recently processed jobs to populate the live dashboard."""
    try:
        jobs = orchestrator.get_recent_jobs(limit=5)
        return jsonify({"recent_jobs": jobs}), 200
    except Exception:
        logger.exception("Failed to fetch recent jobs")
        return jsonify({"error": "Failed to fetch recent jobs"}), 500


# ── Entry Point ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    logger.info("Medical Data Orchestrator starting on port 5000")
    app.run(host="0.0.0.0", port=5000, debug=False)
