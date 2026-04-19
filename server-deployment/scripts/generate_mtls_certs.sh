#!/bin/bash
set -e

# Directory to store certificates
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/../nginx/certs"
mkdir -p "$CERTS_DIR"

echo "============================================="
echo " Generating MTLS Certificates for Thamani  "
echo "============================================="

# 1. Generate Root CA Private Key
echo "[1/4] Generating Root CA Private Key..."
openssl genrsa -out "$CERTS_DIR/ca.key" 4096

# 2. Generate Root CA Certificate (valid for 10 years)
echo "[2/4] Generating Root CA Certificate..."
openssl req -x509 -new -nodes -key "$CERTS_DIR/ca.key" -sha256 -days 3650 -out "$CERTS_DIR/ca.crt" -subj "/C=US/ST=State/L=City/O=Thamani/OU=IoT/CN=Thamani Root CA"

# 3. Generate ESP32 Client Private Key
echo "[3/4] Generating ESP32 Client Private Key..."
openssl genrsa -out "$CERTS_DIR/esp32_client.key" 2048

# 4. Generate ESP32 Client Certificate Signing Request (CSR)
echo "[4/4] Generating ESP32 Client CSR and Certificate..."
openssl req -new -key "$CERTS_DIR/esp32_client.key" -out "$CERTS_DIR/esp32_client.csr" -subj "/C=US/ST=State/L=City/O=Thamani/OU=IoT/CN=ESP32-Device-001"

# 5. Sign the ESP32 Client Certificate with the Root CA (valid for 5 years)
openssl x509 -req -in "$CERTS_DIR/esp32_client.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial -out "$CERTS_DIR/esp32_client.crt" -days 1825 -sha256

echo "============================================="
echo " Success! MTLS Certificates Generated.       "
echo " Certificates are stored in $CERTS_DIR       "
echo "============================================="
