"""
Main Orchestrator – Flask API Server
=====================================
Receives raw sensor data from medical devices, triggers MATLAB processing,
and returns the processed risk score.
"""

import os
import json
import uuid
import logging
from datetime import datetime, timezone

from flask import Flask, request, jsonify
from orchestrator import MatlabOrchestrator

# ── Configuration ───────────────────────────────────────────────────────
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


# ── Routes ──────────────────────────────────────────────────────────────
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
    Accept raw sensor data, trigger MATLAB processing, return results.

    Expected JSON payload:
    {
        "device_id": "DEV-001",
        "sensor_data": {
            "heart_rate": 72,
            "spo2": 98,
            "temperature": 36.6,
            ...
        }
    }
    """
    # ── Validate request ────────────────────────────────────────────────
    if not request.is_json:
        return jsonify({"error": "Content-Type must be application/json"}), 400

    payload = request.get_json()

    if "device_id" not in payload:
        return jsonify({"error": "Missing required field: device_id"}), 400
    if "sensor_data" not in payload:
        return jsonify({"error": "Missing required field: sensor_data"}), 400

    # ── Create job ──────────────────────────────────────────────────────
    job_id = str(uuid.uuid4())
    logger.info("Job %s: Received data from device %s", job_id, payload["device_id"])

    job_record = {
        "job_id": job_id,
        "device_id": payload["device_id"],
        "received_at": datetime.now(timezone.utc).isoformat(),
        "sensor_data": payload["sensor_data"],
    }

    try:
        # Save raw data to shared volume
        orchestrator.save_input(job_id, job_record)
        logger.info("Job %s: Raw data saved", job_id)

        # Spin up MATLAB worker and wait for completion
        logger.info("Job %s: Spinning up MATLAB worker...", job_id)
        exit_code = orchestrator.run_worker(job_id)

        if exit_code != 0:
            logger.error("Job %s: Worker exited with code %d", job_id, exit_code)
            return jsonify({
                "error": "Processing failed",
                "job_id": job_id,
                "worker_exit_code": exit_code,
            }), 500

        # Read processed results
        result = orchestrator.read_output(job_id)
        logger.info("Job %s: Processing complete", job_id)

        return jsonify({
            "job_id": job_id,
            "device_id": payload["device_id"],
            "status": "completed",
            "result": result,
        }), 200

    except Exception as e:
        logger.exception("Job %s: Unexpected error", job_id)
        return jsonify({
            "error": str(e),
            "job_id": job_id,
        }), 500


@app.route("/api/jobs/<job_id>", methods=["GET"])
def get_job(job_id):
    """Retrieve results for a previously processed job."""
    try:
        result = orchestrator.read_output(job_id)
        return jsonify({
            "job_id": job_id,
            "status": "completed",
            "result": result,
        }), 200
    except FileNotFoundError:
        return jsonify({"error": "Job not found", "job_id": job_id}), 404


# ── Entry Point ─────────────────────────────────────────────────────────
if __name__ == "__main__":
    logger.info("🏥 Medical Data Orchestrator starting on port 5000")
    app.run(host="0.0.0.0", port=5000, debug=False)
