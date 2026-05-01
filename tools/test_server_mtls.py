import requests
import zlib
import os
import sys

# --- CONFIGURATION ---
BASE_URL = "https://edge.thamanihc.com/api"
CERT_DIR = "/Users/andhan/Desktop/Sami/Thamani/Thamani-TinyML/server-deployment/nginx/certs"
CLIENT_CERT = os.path.join(CERT_DIR, "esp32_client.crt")
CLIENT_KEY = os.path.join(CERT_DIR, "esp32_client.key")
CA_CERT = os.path.join(CERT_DIR, "ca.crt")

FILE_PATH = "/Users/andhan/Desktop/Sami/Thamani/Thamani-TinyML/Sample data/rec_0133_20260420_160015.bin"
DEVICE_ID = "PYTHON-TEST-CLIENT"
CHUNK_SIZE = 4096 # 4KB chunks like the ESP32

def test_upload_workflow():
    if not os.path.exists(FILE_PATH):
        print(f"Error: File not found at {FILE_PATH}")
        return

    print(f"--- Starting mTLS Upload Test ---")
    print(f"Target: {BASE_URL}")
    print(f"File: {os.path.basename(FILE_PATH)}")

    # 1. Initialize Transfer
    print("\n[1/3] Initializing transfer...")
    try:
        response = requests.post(
            f"{BASE_URL}/upload/init",
            json={"device_id": DEVICE_ID},
            cert=(CLIENT_CERT, CLIENT_KEY),
            verify=CA_CERT,
            timeout=10
        )
        response.raise_for_status()
        transfer_id = response.json().get("transfer_id")
        print(f"Success! Transfer ID: {transfer_id}")
    except Exception as e:
        print(f"Failed at init: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response: {e.response.text}")
        return

    # 2. Upload Chunks
    print(f"\n[2/3] Uploading chunks...")
    total_crc = 0
    file_size = os.path.getsize(FILE_PATH)
    bytes_sent = 0

    with open(FILE_PATH, "rb") as f:
        while True:
            chunk = f.read(CHUNK_SIZE)
            if not chunk:
                break
            
            chunk_crc = zlib.crc32(chunk) & 0xFFFFFFFF
            total_crc = zlib.crc32(chunk, total_crc) & 0xFFFFFFFF
            
            files = {'file': ('chunk.bin', chunk, 'application/octet-stream')}
            data = {
                'transfer_id': transfer_id,
                'crc32': str(chunk_crc)
            }
            
            try:
                res = requests.post(
                    f"{BASE_URL}/upload/chunk",
                    files=files,
                    data=data,
                    cert=(CLIENT_CERT, CLIENT_KEY),
                    verify=CA_CERT,
                    timeout=10
                )
                res.raise_for_status()
                bytes_sent += len(chunk)
                print(f" Sent {bytes_sent}/{file_size} bytes...", end="\r")
            except Exception as e:
                print(f"\nFailed at chunk upload: {e}")
                return

    print(f"\nUpload complete. Total CRC32: {total_crc}")

    # 3. Finalize and Get Result
    print("\n[3/3] Finalizing and processing...")
    try:
        response = requests.post(
            f"{BASE_URL}/upload/finish",
            json={
                "transfer_id": transfer_id,
                "total_crc32": str(total_crc)
            },
            cert=(CLIENT_CERT, CLIENT_KEY),
            verify=CA_CERT,
            timeout=120 # Give MATLAB time to process
        )
        response.raise_for_status()
        result = response.json()
        print("\n--- WORKFLOW SUCCESSFUL ---")
        print("Server Response:")
        import json
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Failed at finish: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response: {e.response.text}")

if __name__ == "__main__":
    test_upload_workflow()
