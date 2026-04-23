"""
MATLAB Worker – Data Processor (Placeholder)
==============================================
Processes data received from the STM32 edge device.

Input priority:
  1. /data/jobs/{JOB_ID}/input.bin  — raw binary (chunked upload from ESP32)
  2. /data/jobs/{JOB_ID}/input.json — JSON sensor data (legacy / single-shot upload)

Binary format (from STM32 firmware):
  Interleaved uint16 little-endian, 6 bytes per sample:
    [analog_LSB, analog_MSB, ppg1_LSB, ppg1_MSB, ppg2_LSB, ppg2_MSB, ...]
  Sampling rate: 500 Hz (simulated)

Outputs written:
  - /data/jobs/{JOB_ID}/output.json  — risk score result (always)
  - /data/jobs/{JOB_ID}/input.txt    — decoded sensor samples, one per line
                                        Format: "analog ppg1 ppg2"
                                        Ready for the real MATLAB algorithm.

Replace this file with your compiled MATLAB executable when ready.
  Exit with code 0 on success, non-zero on failure.
"""

import os
import sys
import json
import struct
import logging
from datetime import datetime, timezone

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [MATLAB-WORKER] %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Binary parser
# ---------------------------------------------------------------------------

def parse_binary_input(bin_path: str) -> tuple[list, list, list]:
    """
    Parse the STM32 binary format into three sample arrays.

    Returns:
        (analog_samples, ppg1_samples, ppg2_samples)
        Each is a list of uint16 integer values.

    Raises:
        ValueError if the file is empty or malformed.
    """
    with open(bin_path, "rb") as f:
        raw = f.read()

    if len(raw) == 0:
        raise ValueError("input.bin is empty")

    # Trim to nearest complete sample (6 bytes)
    remainder = len(raw) % 6
    if remainder:
        logger.warning("Trimming %d trailing bytes to align to 6-byte sample boundary", remainder)
        raw = raw[: len(raw) - remainder]

    n_samples = len(raw) // 6
    logger.info("Parsed %d samples from %d bytes", n_samples, len(raw))

    analog, ppg1, ppg2 = [], [], []

    for i in range(n_samples):
        offset = i * 6
        a, p1, p2 = struct.unpack_from("<HHH", raw, offset)
        analog.append(a)
        ppg1.append(p1)
        ppg2.append(p2)

    return analog, ppg1, ppg2


def write_text_output(job_dir: str, analog: list, ppg1: list, ppg2: list) -> str:
    """
    Write decoded samples to input.txt — one sample per line.

    Format: "analog ppg1 ppg2"
    This is the file the real MATLAB algorithm will read as input.

    Returns the path to the written file.
    """
    txt_path = os.path.join(job_dir, "input.txt")
    with open(txt_path, "w") as f:
        f.write("# analog ppg1 ppg2\n")
        for a, p1, p2 in zip(analog, ppg1, ppg2):
            f.write(f"{a} {p1} {p2}\n")
    logger.info("Wrote %d samples to input.txt", len(analog))
    return txt_path


# ---------------------------------------------------------------------------
# Placeholder signal analysis (derives vitals from raw samples)
# Replace with real MATLAB MCR call when available.
# ---------------------------------------------------------------------------

def analyse_binary_signals(analog: list, ppg1: list, ppg2: list) -> dict:
    """
    Derive basic vital-sign proxies from the raw ADC / PPG channels.

    This is a placeholder — it passes derived values into the threshold-based
    risk scorer so the full pipeline can be validated before MATLAB is integrated.
    """
    n = len(analog)
    if n == 0:
        return {}

    # -- Basic stats --
    analog_mean = sum(analog) / n
    ppg1_mean   = sum(ppg1) / n
    ppg2_mean   = sum(ppg2) / n

    # -- Simulated SpO2 from red/IR ratio (placeholder formula) --
    # In reality: SpO2 = A - B * (ppg_red_AC/ppg_red_DC) / (ppg_ir_AC/ppg_ir_DC)
    ratio = ppg1_mean / ppg2_mean if ppg2_mean > 0 else 1.0
    simulated_spo2 = round(max(85.0, min(100.0, 110.0 - 25.0 * ratio)), 1)

    # -- Simulated HR from peak density (placeholder) --
    # A real implementation would run a peak-detection algorithm on ppg1 at 500 Hz.
    # Here we use sample variance as a crude proxy for signal activity.
    variance_ppg1 = sum((x - ppg1_mean) ** 2 for x in ppg1) / n
    simulated_hr = round(60 + (variance_ppg1 ** 0.5) / 10, 1)
    simulated_hr = max(40.0, min(160.0, simulated_hr))

    logger.info(
        "Signal analysis — analog_mean=%.1f ppg1_mean=%.1f ppg2_mean=%.1f "
        "simulated_hr=%.1f simulated_spo2=%.1f",
        analog_mean, ppg1_mean, ppg2_mean, simulated_hr, simulated_spo2,
    )

    return {
        "heart_rate":  simulated_hr,
        "spo2":        simulated_spo2,
        "n_samples":   n,
        "analog_mean": round(analog_mean, 2),
        "ppg1_mean":   round(ppg1_mean, 2),
        "ppg2_mean":   round(ppg2_mean, 2),
    }


# ---------------------------------------------------------------------------
# Risk scorer (applied to derived or JSON-supplied vitals)
# ---------------------------------------------------------------------------

def compute_risk_score(sensor_data: dict) -> dict:
    """
    Placeholder risk scoring algorithm.

    In production, this is replaced by the compiled MATLAB executable
    which runs the actual clinical risk model.
    """
    score = 0.0
    flags = []

    hr = sensor_data.get("heart_rate")
    if hr is not None:
        if hr < 50:
            score += 30; flags.append("bradycardia")
        elif hr > 100:
            score += 25; flags.append("tachycardia")

    spo2 = sensor_data.get("spo2")
    if spo2 is not None:
        if spo2 < 90:
            score += 40; flags.append("critical_hypoxemia")
        elif spo2 < 95:
            score += 20; flags.append("mild_hypoxemia")

    temp = sensor_data.get("temperature")
    if temp is not None:
        if temp > 38.5:
            score += 25; flags.append("fever")
        elif temp < 35.0:
            score += 30; flags.append("hypothermia")

    systolic = sensor_data.get("systolic_bp")
    if systolic is not None:
        if systolic > 140:
            score += 20; flags.append("hypertension")
        elif systolic < 90:
            score += 30; flags.append("hypotension")

    diastolic = sensor_data.get("diastolic_bp")
    if diastolic is not None:
        if diastolic > 90:
            score += 15; flags.append("diastolic_elevated")

    normalized = min(100.0, score)
    category = "HIGH" if normalized >= 60 else "MODERATE" if normalized >= 30 else "LOW"

    return {
        "risk_score":           round(normalized, 2),
        "risk_category":        category,
        "clinical_flags":       flags,
        "parameters_analyzed":  len([v for v in [hr, spo2, temp, systolic, diastolic] if v is not None]),
    }


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    job_id    = os.environ.get("JOB_ID")
    data_path = os.environ.get("DATA_PATH", "/data")

    if not job_id:
        logger.error("JOB_ID environment variable is required")
        sys.exit(1)

    logger.info("Processing job: %s", job_id)

    job_dir   = os.path.join(data_path, "jobs", job_id)
    bin_path  = os.path.join(job_dir, "input.bin")
    json_path = os.path.join(job_dir, "input.json")

    sensor_data       = {}
    processing_engine = "placeholder-python"
    source            = "unknown"

    # ------------------------------------------------------------------
    # Path A — Binary input (chunked upload from STM32 via ESP32)
    # ------------------------------------------------------------------
    if os.path.exists(bin_path) and os.path.getsize(bin_path) > 0:
        logger.info("Binary input detected (%d bytes). Parsing...", os.path.getsize(bin_path))
        try:
            analog, ppg1, ppg2 = parse_binary_input(bin_path)

            # Write decoded samples to input.txt for the real MATLAB algorithm
            write_text_output(job_dir, analog, ppg1, ppg2)

            sensor_data = analyse_binary_signals(analog, ppg1, ppg2)
            source = "binary"
        except Exception as exc:
            logger.error("Failed to parse input.bin: %s", exc)
            sys.exit(1)

    # ------------------------------------------------------------------
    # Path B — JSON input (legacy single-shot upload)
    # ------------------------------------------------------------------
    elif os.path.exists(json_path):
        logger.info("JSON input detected. Reading...")
        try:
            with open(json_path, "r") as f:
                job_data = json.load(f)
            sensor_data = job_data.get("sensor_data", {})
            source = "json"
        except Exception as exc:
            logger.error("Failed to parse input.json: %s", exc)
            sys.exit(1)

    else:
        logger.error("No input found at %s or %s", bin_path, json_path)
        sys.exit(1)

    logger.info("Source: %s | Parameters: %d", source, len(sensor_data))

    # ------------------------------------------------------------------
    # Process — placeholder risk score (or call MATLAB here)
    # ------------------------------------------------------------------
    logger.info("Running risk scoring algorithm...")
    result = compute_risk_score(sensor_data)

    # ------------------------------------------------------------------
    # Write output.json
    # ------------------------------------------------------------------
    output = {
        "job_id":            job_id,
        "source":            source,
        "processed_at":      datetime.now(timezone.utc).isoformat(),
        "processing_engine": processing_engine,
        "sensor_summary":    sensor_data,
        "result":            result,
    }

    output_path = os.path.join(job_dir, "output.json")
    with open(output_path, "w") as f:
        json.dump(output, f, indent=2)

    logger.info(
        "✅ Job %s complete — Source: %s | Risk: %s (score: %.1f)",
        job_id, source, result["risk_category"], result["risk_score"],
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
