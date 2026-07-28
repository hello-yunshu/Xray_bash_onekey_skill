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
#   - email variable is `custom_email` (NOT `email`)
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

# Optional: pin to a specific install.sh ref/commit (default: main)
# Using a commit SHA provides immutability; using main always fetches the latest.
INSTALL_SH_REF="${INSTALL_SH_REF:-main}"

# ============================================================
# Download and source install.sh
# ============================================================

INSTALL_SH_URL="https://raw.githubusercontent.com/hello-yunshu/Xray_bash_onekey/${INSTALL_SH_REF}/install.sh"
INSTALL_SH="/tmp/xray_install_$$.sh"

echo "[1/6] Downloading install.sh (ref: ${INSTALL_SH_REF})..."
curl -fsSL "${INSTALL_SH_URL}" -o "${INSTALL_SH}"

echo "[2/6] Syntax-checking install.sh (bash -n)..."
if ! bash -n "${INSTALL_SH}"; then
    echo "  ❌ install.sh failed bash -n syntax check. Aborting."
    rm -f "${INSTALL_SH}"
    exit 1
fi

echo "[3/6] Sourcing install.sh with _TEST_MODE=1..."
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
    # Contract: install.sh uses `custom_email` (NOT `email`) as the variable name.
    # The value is used for acme.sh certificate registration and Xray user email.
    custom_email="${EMAIL}"
}

UUID_set() {
    # Contract: UUIDv5_tranc requires an argument (random char string).
    if [[ -z "${UUID}" ]]; then
        local uuid5_char
        uuid5_char="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
        UUID="$(UUIDv5_tranc "${uuid5_char}")"
    fi
    # Do NOT echo the full UUID — it is a secret. Only confirm it was generated.
    if [[ -n "${UUID}" ]]; then
        echo "  UUID: generated (value suppressed for safety)"
    else
        echo "  ❌ UUID generation failed"
        return 1
    fi
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
    echo "  ws path: generated (value suppressed for safety)"
}

grpc_path_set() {
    # Contract: variable is `serviceName` (NOT grpc_path).
    serviceName="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
    echo "  gRPC serviceName: generated (value suppressed for safety)"
}

xhttp_path_set() {
    # Contract: variable is `xhttppath` (NOT xhttp_path).
    xhttppath="$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})"
    echo "  xHTTP path: generated (value suppressed for safety)"
}

firewall_set() {
    :
}

# ============================================================
# Execute installation
# ============================================================

echo "[4/6] Running TLS mode installation..."
install_xray_ws_tls

# ============================================================
# Verify and report (safe — no secrets)
# ============================================================

echo "[5/6] Verifying installation..."
if systemctl is-active xray >/dev/null 2>&1; then
    echo "  ✅ Xray service is running"
else
    echo "  ❌ Xray service is NOT running"
    # Contract: do NOT output unredacted journalctl — it may contain secrets.
    # Suggest the user run the redacted diagnostic command manually.
    echo "  ℹ️  For safe diagnostics, run:"
    echo "      journalctl -u xray -e --no-pager | redact_text_for_diagnostics"
    echo "      (Source .github/test/redact.sh from the main repo first.)"
fi

if systemctl is-active nginx >/dev/null 2>&1; then
    echo "  ✅ Nginx service is running"
else
    echo "  ❌ Nginx service is NOT running"
    # Contract: Nginx binary is at /usr/local/nginx/sbin/nginx.
    /usr/local/nginx/sbin/nginx -t 2>&1 || true
fi

echo "[6/6] Installation summary (secrets suppressed):"
# Contract: do NOT cat the full install_config.json — it contains UUID, privateKey,
# password, shortIds, host, domain, and other secrets. Output a safe summary instead.
CONFIG_FILE="/etc/idleleo/conf/install_config.json"
if [[ -f "${CONFIG_FILE}" ]]; then
    # Try to print a safe summary using jq if available.
    if command -v jq >/dev/null 2>&1; then
        jq -r '
            "  mode: \(.shell_mode // .mode // "unknown")",
            "  transport_mode: \(.transport_mode // "unknown")",
            "  shell_version: \(.shell_version // "unknown")",
            "  xray_version: \(.xray_version // "unknown")",
            "  has_UUID: \(.UUID // .uuid | type == "string")",
            "  has_privateKey: \(.privateKey | type == "string")",
            "  has_publicKey: \(.publicKey // .password | type == "string")",
            "  has_shortIds: \(.shortIds | type == "string")",
            "  has_host: \(.host | type == "string")",
            "  has_email: \(.email | type == "string")"
        ' "${CONFIG_FILE}" 2>/dev/null || echo "  (config file exists but could not be parsed)"
    else
        echo "  ✅ Config file exists at ${CONFIG_FILE}"
        echo "  ℹ️  To view a safe summary, run:"
        echo "      source .github/test/redact.sh && safe_print_config_summary ${CONFIG_FILE}"
    fi
else
    echo "  ❌ install_config.json not found at /etc/idleleo/conf/"
fi

echo ""
echo "ℹ️  Full connection info (including VLESS link) is available on the server via:"
echo "    idleleo  (option 18 to view connection info)"
echo "    Only reveal it interactively in a trusted terminal."

# Cleanup
rm -f "${INSTALL_SH}"
