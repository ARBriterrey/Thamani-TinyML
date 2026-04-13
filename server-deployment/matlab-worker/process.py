"""
MATLAB Worker – Data Processor (Placeholder)
==============================================
This script simulates the MATLAB processing step.

Replace this file with your compiled MATLAB executable when ready.
The contract is:
  - Read raw data from:   /data/jobs/{JOB_ID}/input.json
  - Write results to:     /data/jobs/{JOB_ID}/output.json
  - Exit with code 0 on success, non-zero on failure.
"""

import os
import sys
import json
import math
import logging
from datetime import datetime, timezone

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [MATLAB-WORKER] %(message)s",
)
logger = logging.getLogger(__name__)


def compute_risk_score(sensor_data: dict) -> dict:
    """
    Placeholder risk scoring algorithm.

    In production, this is replaced by the compiled MATLAB executable
    which runs the actual clinical risk model.

    This placeholder uses simple thresholds to demonstrate the data flow.
    """
    score = 0.0
    flags = []

    # ── Heart Rate Analysis ─────────────────────────────────────────────
    hr = sensor_data.get("heart_rate")
    if hr is not None:
        if hr < 50:
            score += 30
            flags.append("bradycardia")
        elif hr > 100:
            score += 25
            flags.append("tachycardia")
        elif 60 <= hr <= 100:
            score += 0
        else:
            score += 10

    # ── SpO2 Analysis ───────────────────────────────────────────────────
    spo2 = sensor_data.get("spo2")
    if spo2 is not None:
        if spo2 < 90:
            score += 40
            flags.append("critical_hypoxemia")
        elif spo2 < 95:
            score += 20
            flags.append("mild_hypoxemia")

    # ── Temperature Analysis ────────────────────────────────────────────
    temp = sensor_data.get("temperature")
    if temp is not None:
        if temp > 38.5:
            score += 25
            flags.append("fever")
        elif temp < 35.0:
            score += 30
            flags.append("hypothermia")

    # ── Blood Pressure Analysis ─────────────────────────────────────────
    systolic = sensor_data.get("systolic_bp")
    diastolic = sensor_data.get("diastolic_bp")
    if systolic is not None:
        if systolic > 140:
            score += 20
            flags.append("hypertension")
        elif systolic < 90:
            score += 30
            flags.append("hypotension")
    if diastolic is not None:
        if diastolic > 90:
            score += 15
            flags.append("diastolic_elevated")

    # ── Normalize to 0–100 ──────────────────────────────────────────────
    normalized_score = min(100.0, score)

    # ── Risk category ───────────────────────────────────────────────────
    if normalized_score >= 60:
        category = "HIGH"
    elif normalized_score >= 30:
        category = "MODERATE"
    else:
        category = "LOW"

    return {
        "risk_score": round(normalized_score, 2),
        "risk_category": category,
        "clinical_flags": flags,
        "parameters_analyzed": len([v for v in [hr, spo2, temp, systolic, diastolic] if v is not None]),
    }


def main():
    """Main entry point – read input, process, write output."""
    job_id = os.environ.get("JOB_ID")
    data_path = os.environ.get("DATA_PATH", "/data")

    if not job_id:
        logger.error("JOB_ID environment variable is required")
        sys.exit(1)

    logger.info("Processing job: %s", job_id)

    # ── Read input ──────────────────────────────────────────────────────
    input_path = os.path.join(data_path, "jobs", job_id, "input.json")

    if not os.path.exists(input_path):
        logger.error("Input file not found: %s", input_path)
        sys.exit(1)

    with open(input_path, "r") as f:
        job_data = json.load(f)

    sensor_data = job_data.get("sensor_data", {})
    logger.info("Received sensor data with %d parameters", len(sensor_data))

    # ── Process (this is where MATLAB code runs in production) ──────────
    logger.info("Running risk scoring algorithm...")
    result = compute_risk_score(sensor_data)

    # ── Build output ────────────────────────────────────────────────────
    output = {
        "job_id": job_id,
        "device_id": job_data.get("device_id", "unknown"),
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "processing_engine": "placeholder-python",  # Change to "matlab-mcr" in prod
        "result": result,
    }

    # ── Write output ────────────────────────────────────────────────────
    output_path = os.path.join(data_path, "jobs", job_id, "output.json")

    with open(output_path, "w") as f:
        json.dump(output, f, indent=2)

    logger.info(
        "✅ Job %s complete – Risk: %s (score: %.1f)",
        job_id, result["risk_category"], result["risk_score"],
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
