#!/bin/bash
#
# Xray Reality Mode — Non-Interactive Setup Script Template
#
# This is a TEMPLATE. The AI must:
#   1. Read install.sh source to verify function signatures and variable names
#   2. Replace all <PLACEHOLDER> values with actual user preferences
#   3. Adjust override functions if the source has changed
#
# Contract-verified against install.sh v2.12.10+:
#   - install_config.json path: /etc/idleleo/conf/install_config.json (NOT /etc/idleleo/info/)
#   - Nginx binary path: /usr/local/nginx/sbin/nginx
#   - UUIDv5_tranc requires an argument (random UUIDv5 char string)
#   - Reality key variables: privateKey, password (NOT private_key/public_key)
#   - xray x25519 output format: "PrivateKey: xxx\nPassword: yyy" or "PublicKey: yyy"
#   - ip_check sets: local_ip, ip_version (NOT IP)
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
# shellcheck source=/dev/null
source "${INSTALL_SH}"

# ============================================================
# Override interactive functions
# ============================================================

old_config_exist_check() {
    old_config_status="off"
}

ip_check() {
    # Contract: real ip_check sets local_ip + ip_version (NOT IP).
    # Default to IPv4; override here if IPv6 is required.
    ip_version="IPv4"
    local_ip="$(get_public_ip "${ip_version}")"
    if [[ -z "${local_ip}" ]]; then
        echo "  ❌ Failed to get public IP"
        return 1
    fi
    echo "  Server IP (${ip_version}): ${local_ip}"
}

port_set() {
    port="${PORT}"
}

email_set() {
    email="${EMAIL}"
}

UUID_set() {
    # Contract: UUIDv5_tranc requires an argument (random char string).
    # An empty call returns immediately with no output, producing an invalid UUID.
    if [[ -z "${UUID}" ]]; then
        local uuid5_char
        uuid5_char="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
        UUID="$(UUIDv5_tranc "${uuid5_char}")"
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
    # Contract: xray x25519 output is "PrivateKey: <key>\nPassword: <key>"
    # (or "PublicKey:" in some versions). Variable names in install.sh are
    # `privateKey` (camelCase) and `password` (NOT public_key).
    # Use the project-provided parse_reality_public_key helper for compatibility.
    local keys
    keys="$(${xray_bin_dir}/xray x25519)"
    privateKey="$(printf '%s\n' "${keys}" | awk -F"PrivateKey: " '{print $2}' | awk '{print $1}')"
    password="$(parse_reality_public_key "${keys}")"
    if [[ -z "${privateKey}" || -z "${password}" ]]; then
        echo "  ❌ Failed to generate Reality keys"
        return 1
    fi
    echo "  privateKey: ${privateKey}"
    echo "  publicKey (password): ${password}"
}

shortIds_set() {
    # Contract: install.sh uses generate_reality_short_id helper when available,
    # fallback to openssl rand -hex 8. shortIds must be 16 hex chars.
    if command -v generate_reality_short_id >/dev/null 2>&1; then
        shortIds="$(generate_reality_short_id)"
    else
        shortIds="$(openssl rand -hex 8)"
    fi
    echo "  shortIds: ${shortIds}"
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
# Contract: install_config.json is at /etc/idleleo/conf/ (NOT /etc/idleleo/info/).
if [[ -f /etc/idleleo/conf/install_config.json ]]; then
    cat /etc/idleleo/conf/install_config.json
else
    echo "  ❌ install_config.json not found at /etc/idleleo/conf/"
fi

# Cleanup
rm -f "${INSTALL_SH}"
