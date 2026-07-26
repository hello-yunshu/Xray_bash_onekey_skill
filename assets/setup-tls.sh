#!/bin/bash
#
# Xray TLS Mode — Non-Interactive Setup Script Template
#
# This is a TEMPLATE. The AI must:
#   1. Read install.sh source to verify function signatures and variable names
#   2. Replace all <PLACEHOLDER> values with actual user preferences
#   3. Adjust override functions if the source has changed
#
# Contract-verified against install.sh v2.12.10+:
#   - install_config.json path: /etc/idleleo/conf/install_config.json (NOT /etc/idleleo/info/)
#   - Nginx binary path: /usr/local/nginx/sbin/nginx (NOT /etc/idleleo/nginx/sbin/nginx)
#   - UUIDv5_tranc requires an argument (random UUIDv5 char string)
#   - generate_random_port requires min/max arguments
#   - transport_mode valid values: onlyws | onlygRPC | onlyxhttp | wsxhttp | wsgRPCxhttp
#     (there is NO "all" value; use wsgRPCxhttp for ws+gRPC+xHTTP)
#   - Inbound port variables: xport (ws), gport (gRPC), xhttpport (xHTTP)
#     (NOT ws_port/grpc_port/xhttp_port)
#   - Path variables: path (ws), serviceName (gRPC), xhttppath (xHTTP)
#     (NOT ws_path/grpc_path/xhttp_path)
#   - ip_check sets: local_ip, ip_version (NOT IP)
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
# Valid values: onlyws | onlygRPC | onlyxhttp | wsxhttp | wsgRPCxhttp
# Use wsgRPCxhttp for the previous "all" behaviour (ws+gRPC+xHTTP).
TRANSPORT_MODE="wsgRPCxhttp"

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
    ip_version="IPv4"
    local_ip="$(get_public_ip "${ip_version}")"
    if [[ -z "${local_ip}" ]]; then
        echo "  ❌ Failed to get public IP"
        return 1
    fi
    echo "  Server IP (${ip_version}): ${local_ip}"
}

domain_check() {
    domain="${DOMAIN}"
    local resolved_ip
    resolved_ip="$(dig +short "${domain}" | tail -1)"
    if [[ "${resolved_ip}" != "${local_ip}" ]]; then
        echo "  ⚠️  DNS: ${domain} resolves to ${resolved_ip}, expected ${local_ip}"
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
    # Contract: UUIDv5_tranc requires an argument (random char string).
    if [[ -z "${UUID}" ]]; then
        local uuid5_char
        uuid5_char="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
        UUID="$(UUIDv5_tranc "${uuid5_char}")"
    fi
    echo "  UUID: ${UUID}"
}

transport_choose() {
    # Contract: transport_mode accepts onlyws | onlygRPC | onlyxhttp | wsxhttp | wsgRPCxhttp.
    # There is NO "all" value.
    transport_mode="${TRANSPORT_MODE}"
    _transport_set_shell_mode
}

ws_inbound_port_set() {
    # Contract: variable is `xport` (NOT ws_port). generate_random_port requires min/max.
    xport="$(generate_random_port 10000 10999)"
    echo "  ws inbound_port: ${xport}"
}

grpc_inbound_port_set() {
    # Contract: variable is `gport` (NOT grpc_port).
    gport="$(generate_random_port 10000 10999)"
    while [[ "${gport}" == "${xport:-}" ]]; do
        gport="$(generate_random_port 10000 10999)"
    done
    echo "  gRPC inbound_port: ${gport}"
}

xhttp_inbound_port_set() {
    # Contract: variable is `xhttpport` (NOT xhttp_port).
    xhttpport="$(generate_random_port 11000 11999)"
    while [[ "${xhttpport}" == "${xport:-}" || "${xhttpport}" == "${gport:-}" ]]; do
        xhttpport="$(generate_random_port 11000 11999)"
    done
    echo "  xHTTP inbound_port: ${xhttpport}"
}

ws_path_set() {
    # Contract: variable is `path` (NOT ws_path).
    path="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
    echo "  ws path: ${path}"
}

grpc_path_set() {
    # Contract: variable is `serviceName` (NOT grpc_path).
    serviceName="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
    echo "  gRPC serviceName: ${serviceName}"
}

xhttp_path_set() {
    # Contract: variable is `xhttppath` (NOT xhttp_path).
    xhttppath="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
    echo "  xHTTP path: ${xhttppath}"
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
    # Contract: Nginx binary is at /usr/local/nginx/sbin/nginx.
    /usr/local/nginx/sbin/nginx -t 2>&1 || true
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
