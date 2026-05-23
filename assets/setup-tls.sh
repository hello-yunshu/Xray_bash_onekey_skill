#!/bin/bash
#
# Xray TLS Mode — Non-Interactive Setup Script Template
#
# This is a TEMPLATE. The AI must:
#   1. Read install.sh source to verify function signatures and variable names
#   2. Replace all <PLACEHOLDER> values with actual user preferences
#   3. Adjust override functions if the source has changed
#
# Usage: bash setup-tls.sh
#

set -euo pipefail

# ============================================================
# User Configuration — Replace these with actual values
# ============================================================

DOMAIN="example.com"
PORT="443"
EMAIL="auto@tls-setup"
UUID=""  # Leave empty for auto-generation
TRANSPORT_MODE="all"

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

domain_check() {
    domain="${DOMAIN}"
    local resolved_ip
    resolved_ip="$(dig +short "${domain}" | tail -1)"
    if [[ "${resolved_ip}" != "${IP}" ]]; then
        echo "  ⚠️  DNS: ${domain} resolves to ${resolved_ip}, expected ${IP}"
        echo "  ⚠️  Certificate issuance may fail"
    else
        echo "  ✅ DNS: ${domain} correctly points to this server"
    fi
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

transport_choose() {
    transport_mode="${TRANSPORT_MODE}"
    _transport_set_shell_mode
}

ws_inbound_port_set() {
    ws_port="$(generate_random_port)"
}

grpc_inbound_port_set() {
    grpc_port="$(generate_random_port)"
}

xhttp_inbound_port_set() {
    xhttp_port="$(generate_random_port)"
}

ws_path_set() {
    ws_path="/$(openssl rand -hex 8)"
}

grpc_path_set() {
    grpc_path="$(openssl rand -hex 8)"
}

xhttp_path_set() {
    xhttp_path="/$(openssl rand -hex 8)"
}

firewall_set() {
    :
}

# ============================================================
# Execute installation
# ============================================================

echo "[3/5] Running TLS mode installation..."
install_xray_ws_tls

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

if systemctl is-active nginx >/dev/null 2>&1; then
    echo "  ✅ Nginx service is running"
else
    echo "  ❌ Nginx service is NOT running"
    /etc/idleleo/nginx/sbin/nginx -t 2>&1 || true
fi

echo "[5/5] Connection info:"
if [[ -f /etc/idleleo/info/install_config.json ]]; then
    cat /etc/idleleo/info/install_config.json
else
    echo "  ❌ install_config.json not found"
fi

# Cleanup
rm -f "${INSTALL_SH}"
