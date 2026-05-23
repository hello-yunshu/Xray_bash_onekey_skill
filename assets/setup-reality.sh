#!/bin/bash
#
# Xray Reality Mode — Non-Interactive Setup Script Template
#
# This is a TEMPLATE. The AI must:
#   1. Read install.sh source to verify function signatures and variable names
#   2. Replace all <PLACEHOLDER> values with actual user preferences
#   3. Adjust override functions if the source has changed
#
# Usage: bash setup-reality.sh
#

set -euo pipefail

# ============================================================
# User Configuration — Replace these with actual values
# ============================================================

PORT="443"
TARGET="www.microsoft.com"
SERVERNAMES="www.microsoft.com"
EMAIL="auto@reality-setup"
UUID=""  # Leave empty for auto-generation

# ============================================================
# Download and source install.sh
# ============================================================

INSTALL_SH_URL="https://raw.githubusercontent.com/hello-yunshu/Xray_bash_onekey/main/install.sh"
INSTALL_SH="/tmp/xray_install_$$.sh"

echo "[1/5] Downloading install.sh..."
curl -fsSL "${INSTALL_SH_URL}" -o "${INSTALL_SH}"

echo "[2/5] Sourcing install.sh with _TEST_MODE=1..."
export _TEST_MODE=1
source "${INSTALL_SH}"

# ============================================================
# Override interactive functions
# ============================================================

old_config_exist_check() {
    old_config_status="off"
}

ip_check() {
    IP="$(get_public_ip)"
    echo "  Server IP: ${IP}"
}

port_set() {
    port="${PORT}"
}

email_set() {
    email="${EMAIL}"
}

UUID_set() {
    if [[ -z "${UUID}" ]]; then
        UUID="$(UUIDv5_tranc)"
    fi
    echo "  UUID: ${UUID}"
}

target_set() {
    target="${TARGET}"
}

serverNames_set() {
    serverNames="${SERVERNAMES}"
}

keys_set() {
    local key_output
    key_output="$(${xray_bin_dir}/xray x25519)"
    private_key="$(echo "${key_output}" | grep "Private key" | awk '{print $3}')"
    public_key="$(echo "${key_output}" | grep "Public key" | awk '{print $3}')"
    echo "  Private Key: ${private_key}"
    echo "  Public Key: ${public_key}"
}

shortIds_set() {
    shortIds="$(openssl rand -hex 8)"
    echo "  Short ID: ${shortIds}"
}

xray_reality_add_more_choose() {
    add_more="off"
    ws_grpc_mode="None"
}

firewall_set() {
    :
}

# ============================================================
# Execute installation
# ============================================================

echo "[3/5] Running Reality mode installation..."
install_xray_reality

# ============================================================
# Verify and report
# ============================================================

echo "[4/5] Verifying installation..."
if systemctl is-active xray >/dev/null 2>&1; then
    echo "  ✅ Xray service is running"
else
    echo "  ❌ Xray service is NOT running"
    journalctl -u xray -e --no-pager
fi

echo "[5/5] Connection info:"
if [[ -f /etc/idleleo/info/install_config.json ]]; then
    cat /etc/idleleo/info/install_config.json
else
    echo "  ❌ install_config.json not found"
fi

# Cleanup
rm -f "${INSTALL_SH}"
