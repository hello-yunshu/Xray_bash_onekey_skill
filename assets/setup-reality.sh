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
#   - email variable is `custom_email` (NOT `email`)
#   - Reality add-more variable is `reality_add_more` (NOT `add_more`)
#   - Transport mode variable is `transport_mode` (NOT `ws_grpc_mode`)
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

# Optional: pin to a specific install.sh ref/commit (default: main)
# Using a commit SHA provides immutability; using main always fetches the latest.
INSTALL_SH_REF="${INSTALL_SH_REF:-main}"

# ============================================================
# Guard against overwriting an existing installation
# ============================================================

CONFIG_FILE="/etc/idleleo/conf/install_config.json"
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"

if [[ -f "${CONFIG_FILE}" && "${FORCE_REINSTALL}" != "1" ]]; then
    echo "❌ Existing installation detected at ${CONFIG_FILE}"
    echo "Set FORCE_REINSTALL=1 only when replacement is intentional."
    exit 1
fi

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
    if [[ -f "${CONFIG_FILE}" && "${FORCE_REINSTALL}" != "1" ]]; then
        echo "❌ Existing installation detected; refusing to overwrite."
        return 1
    fi
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
    # Contract: install.sh uses `custom_email` (NOT `email`) as the variable name.
    # The value is used for acme.sh certificate registration and Xray user email.
    custom_email="${EMAIL}"
}

UUID_set() {
    # Contract: UUIDv5_tranc requires an argument (random char string).
    # An empty call returns immediately with no output, producing an invalid UUID.
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
    # Do NOT echo privateKey/password — they are secrets.
    # Only confirm that keys were generated successfully.
    echo "  Reality keys: generated (values suppressed for safety)"
}

shortIds_set() {
    # Contract: install.sh uses generate_reality_short_id helper when available,
    # fallback to openssl rand -hex 8. shortIds must be 16 hex chars.
    if command -v generate_reality_short_id >/dev/null 2>&1; then
        shortIds="$(generate_reality_short_id)"
    else
        shortIds="$(openssl rand -hex 8)"
    fi
    # Do NOT echo shortIds — it is a secret.
    echo "  shortIds: generated (value suppressed for safety)"
}

xray_reality_add_more_choose() {
    # Contract: install.sh uses `reality_add_more` (NOT `add_more`) and
    # `transport_mode` (NOT `ws_grpc_mode`) as the variable names.
    reality_add_more="off"
    transport_mode="None"
}

spiderx_set() {
    # Non-interactive: generate spiderx path silently (value is part of VLESS link).
    if [[ "${old_config_status}" != "on" ]]; then
        spiderx_path="$(generate_spiderx)"
    fi
}

reality_balance_add_fq() {
    # Non-interactive: skip load balancing setup.
    reality_add_balance="off"
    # Explicitly clear balance role so the standard Reality template never
    # inherits a stale primary/secondary value from a prior install state.
    reality_balance_role=""
}

reality_nginx_add_fq() {
    # Non-interactive: skip additional Nginx setup for Reality.
    reality_add_nginx="off"
}

firewall_set() {
    :
}

auto_update() {
    # Non-interactive: skip auto-update cron setup in template mode.
    :
}

vless_link_image_choice() {
    # Non-interactive: skip VLESS link/image generation (may print secrets).
    :
}

# ============================================================
# Execute installation
# ============================================================

echo "[4/6] Running Reality mode installation..."
if ! install_xray_reality; then
    echo "❌ Reality installation failed"
    rm -f "${INSTALL_SH}"
    exit 1
fi

# ============================================================
# Verify and report (safe — no secrets)
# ============================================================

echo "[5/6] Verifying installation..."
verification_failed=0

if ! systemctl is-active --quiet xray; then
    echo "  ❌ Xray service is NOT running"
    verification_failed=1
else
    echo "  ✅ Xray service is running"
fi

if [[ ! -s "${CONFIG_FILE}" ]] || ! jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
    echo "  ❌ Installation config is missing or invalid"
    verification_failed=1
fi

if [[ -s "${CONFIG_FILE}" ]] && jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
    if [[ "$(jq -r '.tls // empty' "${CONFIG_FILE}" 2>/dev/null)" != "Reality" ]]; then
        echo "  ❌ Installation config tls field is not Reality"
        verification_failed=1
    fi
    # Contract: install_config.json stores the Reality user id under the field
    # name "id" (NOT "UUID"). Accept "UUID" only as a legacy fallback so older
    # configs are not falsely flagged. A normal Reality install must NOT fail
    # merely because ".UUID" is absent when ".id" is present.
    user_id="$(jq -r '.id // .UUID // empty' "${CONFIG_FILE}" 2>/dev/null)"
    if [[ -z "${user_id}" ]]; then
        echo "  ❌ Required field missing or empty: id"
        verification_failed=1
    fi
    for _field in privateKey password shortIds host; do
        if [[ -z "$(jq -r --arg f "${_field}" '.[$f] // empty' "${CONFIG_FILE}" 2>/dev/null)" ]]; then
            echo "  ❌ Required field missing or empty: ${_field}"
            verification_failed=1
        fi
    done
fi

if (( verification_failed != 0 )); then
    rm -f "${INSTALL_SH}"
    exit 1
fi

echo "[6/6] Installation summary (secrets suppressed):"
# Contract: do NOT cat the full install_config.json — it contains UUID, privateKey,
# password, shortIds, host, and other secrets. Output a safe summary instead.
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
            "  config_file: \(. | " (present at /etc/idleleo/conf/install_config.json)")"
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
