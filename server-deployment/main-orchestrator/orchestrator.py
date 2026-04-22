"""
MATLAB Worker Orchestrator
===========================
Manages the lifecycle of ephemeral MATLAB processing containers using
the Docker SDK. Handles:
  - Saving raw input to the shared volume
  - Spinning up a worker container
  - Waiting for completion
  - Reading processed output
  - Cleaning up finished containers
"""

import os
import json
import logging
import docker

logger = logging.getLogger(__name__)


class MatlabOrchestrator:
    """Orchestrates ephemeral MATLAB worker containers."""

    def __init__(self, worker_image: str, shared_volume: str, data_path: str):
        """
        Args:
            worker_image:   Docker image name for the MATLAB worker.
            shared_volume:  Name of the Docker volume shared between containers.
            data_path:      Mount path inside containers for the shared volume.
        """
        self.worker_image = worker_image
        self.shared_volume = shared_volume
        self.data_path = data_path
        self.client = docker.from_env()

    # ── File I/O ────────────────────────────────────────────────────────
    def _job_dir(self, job_id: str) -> str:
        """Return the directory path for a specific job."""
        return os.path.join(self.data_path, "jobs", job_id)

    def save_input(self, job_id: str, data: dict) -> str:
        """Save raw input data to the shared volume."""
        job_dir = self._job_dir(job_id)
        os.makedirs(job_dir, exist_ok=True)

        input_path = os.path.join(job_dir, "input.json")
        with open(input_path, "w") as f:
            json.dump(data, f, indent=2)

        return input_path

    def save_binary_input(self, job_id: str, file_data: bytes) -> str:
        """Save binary input data to the shared volume."""
        job_dir = self._job_dir(job_id)
        os.makedirs(job_dir, exist_ok=True)

        # The worker expects input.bin based on the prompt commentary
        input_path = os.path.join(job_dir, "input.bin")
        with open(input_path, "wb") as f:
            f.write(file_data)

        # We can also write a small info.json if the worker needs metadata,
        # but storing the .bin is the primary requirement.
        return input_path

    def init_binary_upload(self, job_id: str) -> str:
        """Initialize an empty binary file for chunked upload."""
        job_dir = self._job_dir(job_id)
        os.makedirs(job_dir, exist_ok=True)
        input_path = os.path.join(job_dir, "input.bin")
        with open(input_path, "wb") as f:
            pass # Create empty file
        return input_path

    def append_binary_chunk(self, job_id: str, chunk_data: bytes) -> str:
        """Append a chunk of binary data to the job's input.bin."""
        job_dir = self._job_dir(job_id)
        input_path = os.path.join(job_dir, "input.bin")
        if not os.path.exists(input_path):
            raise FileNotFoundError(f"Transfer {job_id} not initialized.")
        with open(input_path, "ab") as f:
            f.write(chunk_data)
        return input_path

    def get_binary_path(self, job_id: str) -> str:
        """Return path to the input.bin file."""
        return os.path.join(self._job_dir(job_id), "input.bin")

    def read_output(self, job_id: str) -> dict:
        """Read processed output from the shared volume."""
        output_path = os.path.join(self._job_dir(job_id), "output.json")

        if not os.path.exists(output_path):
            raise FileNotFoundError(f"No output found for job {job_id}")

        with open(output_path, "r") as f:
            return json.load(f)

    # ── Container Management ────────────────────────────────────────────
    def run_worker(self, job_id: str, timeout: int = 120) -> int:
        """
        Spin up a MATLAB worker container, wait for it to finish,
        and clean up.

        Args:
            job_id:   Unique identifier for this processing job.
            timeout:  Max seconds to wait for the worker to finish.

        Returns:
            Container exit code (0 = success).
        """
        container_name = f"matlab-worker-{job_id[:8]}"

        logger.info("Starting worker container: %s", container_name)

        container = self.client.containers.run(
            image=self.worker_image,
            name=container_name,
            environment={
                "JOB_ID": job_id,
                "DATA_PATH": self.data_path,
            },
            volumes={
                self.shared_volume: {
                    "bind": self.data_path,
                    "mode": "rw",
                },
            },
            detach=True,
            remove=False,  # Keep container for log inspection
        )

        try:
            # Wait for the container to finish
            result = container.wait(timeout=timeout)
            exit_code = result.get("StatusCode", -1)

            # Capture logs for debugging
            logs = container.logs().decode("utf-8", errors="replace")
            if exit_code == 0:
                logger.info("Worker %s completed successfully", container_name)
                logger.debug("Worker logs:\n%s", logs)
            else:
                logger.error(
                    "Worker %s failed (exit code %d). Logs:\n%s",
                    container_name, exit_code, logs,
                )

            return exit_code

        finally:
            # Clean up the stopped container
            try:
                container.remove(force=True)
                logger.debug("Removed container %s", container_name)
            except Exception:
                logger.warning("Could not remove container %s", container_name)

    def get_model_path(self, job_id: str) -> str:
        """
        Return the path to the TFLite model file produced for a job.

        Raises FileNotFoundError if the worker has not written a model file yet.
        """
        model_path = os.path.join(self._job_dir(job_id), "model.tflite")
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"No model file for job {job_id}")
        return model_path

    def get_latest_model(self) -> dict:
        """
        Scan all job directories and return metadata for the most recently
        produced model.tflite file.

        Returns a dict with: job_id, model_url, size_bytes, created_at.
        Raises FileNotFoundError if no model files exist yet.
        """
        from datetime import datetime, timezone

        jobs_dir = os.path.join(self.data_path, "jobs")
        if not os.path.exists(jobs_dir):
            raise FileNotFoundError("No jobs directory")

        latest_job_id = None
        latest_mtime = 0.0

        for entry in os.listdir(jobs_dir):
            model_path = os.path.join(jobs_dir, entry, "model.tflite")
            if os.path.exists(model_path):
                mtime = os.path.getmtime(model_path)
                if mtime > latest_mtime:
                    latest_mtime = mtime
                    latest_job_id = entry

        if latest_job_id is None:
            raise FileNotFoundError("No model files found")

        model_path = os.path.join(jobs_dir, latest_job_id, "model.tflite")
        return {
            "job_id": latest_job_id,
            "model_url": f"/api/jobs/{latest_job_id}/model",
            "size_bytes": os.path.getsize(model_path),
            "created_at": datetime.fromtimestamp(
                latest_mtime, tz=timezone.utc
            ).isoformat(),
        }

    def cleanup_old_jobs(self, max_age_hours: int = 24):
        """
        Remove job data older than max_age_hours from the shared volume.
        Call this periodically to prevent disk usage buildup.
        """
        import time

        jobs_dir = os.path.join(self.data_path, "jobs")
        if not os.path.exists(jobs_dir):
            return

        cutoff = time.time() - (max_age_hours * 3600)
        removed = 0

        for job_id in os.listdir(jobs_dir):
            job_path = os.path.join(jobs_dir, job_id)
            if os.path.isdir(job_path):
                mtime = os.path.getmtime(job_path)
                if mtime < cutoff:
                    import shutil
                    shutil.rmtree(job_path, ignore_errors=True)
                    removed += 1

        if removed:
            logger.info("Cleaned up %d old job(s)", removed)
