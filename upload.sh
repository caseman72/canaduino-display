#!/bin/bash
# OTA upload script for display-monitor
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-display-monitor.local}"
CONFIG="${2:-display-monitor.yaml}"
SECRETS="${3:-secrets.h}"

if [[ ! -f "$SCRIPT_DIR/$SECRETS" ]]; then
    echo "Error: ${SECRETS} not found. Copy secrets.example.h to ${SECRETS} and fill in values."
    exit 1
fi

# Parse secrets.h and extract value
parse_secret() {
    grep "#define $1 " "$SCRIPT_DIR/$SECRETS" | sed 's/.*"\(.*\)"/\1/'
}

WIFI_SSID=$(parse_secret WIFI_SSID)
WIFI_PASSWORD=$(parse_secret WIFI_PASSWORD)
OTA_PASSWORD=$(parse_secret OTA_PASSWORD)

echo "Uploading to $DEVICE..."
cd "$SCRIPT_DIR"
esphome \
    -s wifi_ssid "$WIFI_SSID" \
    -s wifi_password "$WIFI_PASSWORD" \
    -s ota_password "$OTA_PASSWORD" \
    run "$CONFIG" --no-logs --device "$DEVICE"
