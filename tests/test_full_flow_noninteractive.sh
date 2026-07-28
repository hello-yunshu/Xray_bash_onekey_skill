#!/bin/bash
#
# Xray_bash_onekey_skill — Full-Flow Non-Interactive Test (P0-A)
#
# This test verifies that the Skill templates (setup-reality.sh and
# setup-tls.sh) can drive the REAL install_xray_reality and
# install_xray_ws_tls call chains to completion without ANY interactive
# input, with stdin closed, under a timeout.
#
# Key guarantees verified:
#   1. No read/read_optimize call hangs on stdin
#   2. All system-modifying functions are mocked (no real changes)
#   3. Required variables are assigned after the flow
#   4. No fake secret values appear in stdout/stderr
#   5. The flow reaches the final success marker
#
# Usage: bash tests/test_full_flow_noninteractive.sh
# Exits 0 if all checks pass, 1 otherwise.
#

set -uo pipefail

SKILL_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_REPO_ROOT="${SKILL_REPO_ROOT}/../Xray_bash_onekey"
INSTALL_SH="${MAIN_REPO_ROOT}/install.sh"

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); echo "  ✅ PASS: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ❌ FAIL: $1"; }

echo "============================================================"
echo "  Full-Flow Non-Interactive Test (P0-A)"
echo "============================================================"
echo ""

# ----------------------------------------------------------------
# Section 1: Verify install.sh exists
# ----------------------------------------------------------------
echo "--- Section 1: Prerequisites ---"
if [[ ! -f "${INSTALL_SH}" ]]; then
    echo "  ❌ install.sh not found at ${INSTALL_SH}. Aborting."
    exit 1
fi
ok "install.sh exists locally"

# Portable timeout: use timeout/gtimeout if available, else bash-based fallback
TIMEOUT_CMD=""
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout"
fi

# run_with_timeout <seconds> <command...>
# Captures stdout+stderr into RUN_OUTPUT, sets RUN_EXIT.
# Exit code 124 = timed out.
RUN_OUTPUT=""
RUN_EXIT=0
run_with_timeout() {
    local secs="$1"
    shift
    local tmp_out
    tmp_out=$(mktemp /tmp/xray_timeout_out_XXXXXX)
    if [[ -n "${TIMEOUT_CMD}" ]]; then
        RUN_OUTPUT=$("${TIMEOUT_CMD}" "${secs}" "$@" </dev/null 2>&1)
        RUN_EXIT=$?
    else
        # Bash-based fallback: background + sleep loop
        "$@" </dev/null >"${tmp_out}" 2>&1 &
        local pid=$!
        local count=0
        while [[ ${count} -lt ${secs} ]]; do
            if ! kill -0 "${pid}" 2>/dev/null; then
                break
            fi
            sleep 1
            count=$((count + 1))
        done
        if kill -0 "${pid}" 2>/dev/null; then
            kill "${pid}" 2>/dev/null
            wait "${pid}" 2>/dev/null
            RUN_EXIT=124
        else
            wait "${pid}"
            RUN_EXIT=$?
        fi
        RUN_OUTPUT=$(cat "${tmp_out}")
    fi
    rm -f "${tmp_out}"
}

ok "timeout mechanism available"

# ----------------------------------------------------------------
# Section 2: Build the Reality full-flow wrapper
# ----------------------------------------------------------------
echo ""
echo "--- Section 2: Reality full-flow with stdin closed ---"

REALITY_WRAPPER=$(mktemp /tmp/xray_skill_reality_flow_XXXXXX.sh)

cat > "${REALITY_WRAPPER}" << 'WRAPPER_EOF'
#!/bin/bash
set -uo pipefail
export _TEST_MODE=1

# --- Source install.sh (loads all function definitions, no execution) ---
INSTALL_SH="__INSTALL_SH_PLACEHOLDER__"
# shellcheck source=/dev/null
source "${INSTALL_SH}" 2>/dev/null || true

# --- Mock all system-modifying functions BEFORE overrides ---
# These functions must NOT do anything real; they just succeed silently.
is_root() { :; }
check_and_create_user_group() { :; }
check_system() { :; }
dependency_install() { :; }
basic_optimization() { :; }
create_directory() { :; }
xray_install() {
    xray_version="${xray_online_version:-25.12.8}"
    return 0
}
stop_service_all() { :; }
port_exist_check() { :; }
xray_conf_add() { :; }
install_config_reality() { :; }
install_config_tls_ws() { :; }
install_config_ws_only() { :; }
install_config_xtls_only() { :; }
update_json_config() { :; }
harden_config_permissions() { :; }
basic_information() { :; }
enable_process_systemd() { :; }
service_restart() { :; }
setup_auto_clean_logs() { :; }
show_information() { :; }
nginx_exist_check() { :; }
nginx_systemd() { :; }
nginx_ssl_conf_add() { :; }
nginx_conf_add() { :; }
nginx_servers_conf_add() { :; }
ssl_judge_and_install() { :; }
tls_type() { :; }
acme_cron_update() { :; }
judge() { :; }
log_echo() { :; }
download_script_file() { :; }

# Mock network/IP helpers
get_public_ip() { echo "203.0.113.1"; }
generate_spiderx() { echo "/spiderx"; }
generate_random_port() { echo "$((RANDOM % 999 + 10000))"; }
generate_reality_short_id() { echo "0123456789abcdef"; }
UUIDv5_tranc() { echo "uuid-v5-generated"; }

# Mock xray binary for keys_set
xray_bin_dir="/tmp/mock_xray_bin_flow_$$"
mkdir -p "${xray_bin_dir}"
cat > "${xray_bin_dir}/xray" << 'XRAYEOF'
#!/bin/bash
echo "PrivateKey: MOCK_PRIVATE_KEY_DO_NOT_LEAK"
echo "Password: MOCK_PASSWORD_DO_NOT_LEAK"
XRAYEOF
chmod +x "${xray_bin_dir}/xray"

# Mock systemctl
systemctl() { :; }

# Mock info_extraction (returns placeholder values for config queries)
info_extraction() {
    case "$1" in
        xray_version) echo "25.12.8" ;;
        host) echo "203.0.113.1" ;;
        ip_version) echo "IPv4" ;;
        *) echo "" ;;
    esac
}

# Mock dig for TLS template
dig() { echo "203.0.113.1"; }

# Mock crontab for auto_update (though auto_update is overridden)
crontab() { :; }

# --- Source template overrides ---
# We inline the override functions from setup-reality.sh
__REALITY_TEMPLATE__="__REALITY_TEMPLATE_PLACEHOLDER__"

# Extract and evaluate just the override section
eval "$(awk '/^# Override interactive functions/{copy=1} /^# Execute installation/{copy=0} copy' "${__REALITY_TEMPLATE__}")"

# --- Set required config variables ---
PORT="443"
TARGET="www.microsoft.com"
SERVERNAMES="www.microsoft.com"
EMAIL="auto@reality-setup"
UUID=""
random_num="${random_num:-8}"
xray_online_version="25.12.8"
old_config_status="off"
shell_mode="Reality"
tls_mode="reality"

# --- Call the REAL install_xray_reality ---
install_xray_reality

# --- Verify required variables are assigned ---
REQUIRED_OK=1
[[ -z "${port:-}" ]] && echo "VAR_FAIL: port empty" && REQUIRED_OK=0
[[ -z "${custom_email:-}" ]] && echo "VAR_FAIL: custom_email empty" && REQUIRED_OK=0
[[ -z "${UUID:-}" ]] && echo "VAR_FAIL: UUID empty" && REQUIRED_OK=0
[[ -z "${target:-}" ]] && echo "VAR_FAIL: target empty" && REQUIRED_OK=0
[[ -z "${serverNames:-}" ]] && echo "VAR_FAIL: serverNames empty" && REQUIRED_OK=0
[[ -z "${privateKey:-}" ]] && echo "VAR_FAIL: privateKey empty" && REQUIRED_OK=0
[[ -z "${password:-}" ]] && echo "VAR_FAIL: password empty" && REQUIRED_OK=0
[[ -z "${shortIds:-}" ]] && echo "VAR_FAIL: shortIds empty" && REQUIRED_OK=0
[[ -z "${reality_add_more:-}" ]] && echo "VAR_FAIL: reality_add_more empty" && REQUIRED_OK=0
[[ -z "${transport_mode:-}" ]] && echo "VAR_FAIL: transport_mode empty" && REQUIRED_OK=0
[[ -z "${reality_add_balance:-}" ]] && echo "VAR_FAIL: reality_add_balance empty" && REQUIRED_OK=0
[[ -z "${reality_add_nginx:-}" ]] && echo "VAR_FAIL: reality_add_nginx empty" && REQUIRED_OK=0
[[ -z "${spiderx_path:-}" ]] && echo "VAR_FAIL: spiderx_path empty" && REQUIRED_OK=0

if [[ ${REQUIRED_OK} -eq 1 ]]; then
    echo "ALL_VARS_ASSIGNED"
fi

# --- Success marker ---
echo "REALITY_FLOW_COMPLETE"

# Cleanup
rm -rf "${xray_bin_dir}"
WRAPPER_EOF

# Replace placeholders
sed -i.bak "s|__INSTALL_SH_PLACEHOLDER__|${INSTALL_SH}|g" "${REALITY_WRAPPER}"
sed -i.bak2 "s|__REALITY_TEMPLATE_PLACEHOLDER__|${SKILL_REPO_ROOT}/assets/setup-reality.sh|g" "${REALITY_WRAPPER}"
rm -f "${REALITY_WRAPPER}.bak" "${REALITY_WRAPPER}.bak2"

# Run with stdin closed and timeout
run_with_timeout 10 bash "${REALITY_WRAPPER}"
REALITY_OUTPUT="${RUN_OUTPUT}"
REALITY_EXIT="${RUN_EXIT}"

if [[ ${REALITY_EXIT} -eq 124 ]]; then
    bad "Reality flow timed out (likely waiting for input)"
elif [[ ${REALITY_EXIT} -ne 0 ]]; then
    bad "Reality flow exited non-zero (${REALITY_EXIT})"
    printf '%s\n' "${REALITY_OUTPUT}" | sed 's/^/      output: /'
else
    ok "Reality flow exited 0 within timeout"
fi

# Check for success marker
if printf '%s\n' "${REALITY_OUTPUT}" | grep -q "REALITY_FLOW_COMPLETE"; then
    ok "Reality flow reached success marker"
else
    bad "Reality flow did NOT reach success marker"
fi

# Check all variables assigned
if printf '%s\n' "${REALITY_OUTPUT}" | grep -q "ALL_VARS_ASSIGNED"; then
    ok "Reality flow assigned all required variables"
else
    bad "Reality flow did NOT assign all required variables"
    # Print which variables failed
    printf '%s\n' "${REALITY_OUTPUT}" | grep "VAR_FAIL" | sed 's/^/      /'
fi

# Check no VAR_FAIL lines
VAR_FAIL_COUNT=$(printf '%s\n' "${REALITY_OUTPUT}" | grep -c "VAR_FAIL" || true)
if [[ ${VAR_FAIL_COUNT} -eq 0 ]]; then
    ok "Reality flow: no empty required variables"
else
    bad "Reality flow: ${VAR_FAIL_COUNT} required variable(s) empty"
fi

# Check no fake secrets leaked
SECRET_LEAK=0
if printf '%s\n' "${REALITY_OUTPUT}" | grep -qF "MOCK_PRIVATE_KEY_DO_NOT_LEAK"; then
    bad "Reality flow: privateKey value leaked in output"
    SECRET_LEAK=1
fi
if printf '%s\n' "${REALITY_OUTPUT}" | grep -qF "MOCK_PASSWORD_DO_NOT_LEAK"; then
    bad "Reality flow: password value leaked in output"
    SECRET_LEAK=1
fi
if [[ ${SECRET_LEAK} -eq 0 ]]; then
    ok "Reality flow: no fake secrets leaked in output"
fi

rm -f "${REALITY_WRAPPER}"

# ----------------------------------------------------------------
# Section 3: Build the TLS full-flow wrapper
# ----------------------------------------------------------------
echo ""
echo "--- Section 3: TLS full-flow with stdin closed ---"

TLS_WRAPPER=$(mktemp /tmp/xray_skill_tls_flow_XXXXXX.sh)

cat > "${TLS_WRAPPER}" << 'WRAPPER_EOF'
#!/bin/bash
set -uo pipefail
export _TEST_MODE=1

# --- Source install.sh ---
INSTALL_SH="__INSTALL_SH_PLACEHOLDER__"
# shellcheck source=/dev/null
source "${INSTALL_SH}" 2>/dev/null || true

# --- Mock all system-modifying functions ---
is_root() { :; }
check_and_create_user_group() { :; }
check_system() { :; }
dependency_install() { :; }
basic_optimization() { :; }
create_directory() { :; }
xray_install() {
    xray_version="${xray_online_version:-25.12.8}"
    return 0
}
stop_service_all() { :; }
port_exist_check() { :; }
xray_conf_add() { :; }
install_config_reality() { :; }
install_config_tls_ws() { :; }
install_config_ws_only() { :; }
install_config_xtls_only() { :; }
update_json_config() { :; }
harden_config_permissions() { :; }
basic_information() { :; }
enable_process_systemd() { :; }
service_restart() { :; }
setup_auto_clean_logs() { :; }
show_information() { :; }
nginx_exist_check() { :; }
nginx_systemd() { :; }
nginx_ssl_conf_add() { :; }
nginx_conf_add() { :; }
nginx_servers_conf_add() { :; }
ssl_judge_and_install() { :; }
tls_type() { :; }
acme_cron_update() { :; }
judge() { :; }
log_echo() { :; }
download_script_file() { :; }

# Mock network/IP helpers
get_public_ip() { echo "203.0.113.1"; }
generate_random_port() { echo "$((RANDOM % 999 + 10000))"; }
UUIDv5_tranc() { echo "uuid-v5-generated"; }

# Mock systemctl
systemctl() { :; }

# Mock info_extraction
info_extraction() {
    case "$1" in
        xray_version) echo "25.12.8" ;;
        host) echo "203.0.113.1" ;;
        ip_version) echo "IPv4" ;;
        *) echo "" ;;
    esac
}

# Mock dig for domain_check
dig() { echo "203.0.113.1"; }

# Mock crontab
crabtab() { :; }
crontab() { :; }

# --- Source template overrides ---
__TLS_TEMPLATE__="__TLS_TEMPLATE_PLACEHOLDER__"

eval "$(awk '/^# Override interactive functions/{copy=1} /^# Execute installation/{copy=0} copy' "${__TLS_TEMPLATE__}")"

# --- Set required config variables ---
DOMAIN="example.com"
PORT="443"
EMAIL="auto@tls-setup"
UUID=""
TRANSPORT_MODE="wsgRPCxhttp"
random_num="${random_num:-8}"
xray_online_version="25.12.8"
old_config_status="off"
shell_mode="TLS"
tls_mode="tls"
local_ip="203.0.113.1"

# --- Call the REAL install_xray_ws_tls ---
install_xray_ws_tls

# --- Verify required variables are assigned ---
REQUIRED_OK=1
[[ -z "${port:-}" ]] && echo "VAR_FAIL: port empty" && REQUIRED_OK=0
[[ -z "${custom_email:-}" ]] && echo "VAR_FAIL: custom_email empty" && REQUIRED_OK=0
[[ -z "${UUID:-}" ]] && echo "VAR_FAIL: UUID empty" && REQUIRED_OK=0
[[ -z "${domain:-}" ]] && echo "VAR_FAIL: domain empty" && REQUIRED_OK=0
[[ -z "${transport_mode:-}" ]] && echo "VAR_FAIL: transport_mode empty" && REQUIRED_OK=0
[[ -z "${xport:-}" ]] && echo "VAR_FAIL: xport empty" && REQUIRED_OK=0
[[ -z "${gport:-}" ]] && echo "VAR_FAIL: gport empty" && REQUIRED_OK=0
[[ -z "${xhttpport:-}" ]] && echo "VAR_FAIL: xhttpport empty" && REQUIRED_OK=0
[[ -z "${path:-}" ]] && echo "VAR_FAIL: path empty" && REQUIRED_OK=0
[[ -z "${serviceName:-}" ]] && echo "VAR_FAIL: serviceName empty" && REQUIRED_OK=0
[[ -z "${xhttppath:-}" ]] && echo "VAR_FAIL: xhttppath empty" && REQUIRED_OK=0

if [[ ${REQUIRED_OK} -eq 1 ]]; then
    echo "ALL_VARS_ASSIGNED"
fi

# --- Success marker ---
echo "TLS_FLOW_COMPLETE"
WRAPPER_EOF

# Replace placeholders
sed -i.bak "s|__INSTALL_SH_PLACEHOLDER__|${INSTALL_SH}|g" "${TLS_WRAPPER}"
sed -i.bak2 "s|__TLS_TEMPLATE_PLACEHOLDER__|${SKILL_REPO_ROOT}/assets/setup-tls.sh|g" "${TLS_WRAPPER}"
rm -f "${TLS_WRAPPER}.bak" "${TLS_WRAPPER}.bak2"

# Run with stdin closed and timeout
run_with_timeout 10 bash "${TLS_WRAPPER}"
TLS_OUTPUT="${RUN_OUTPUT}"
TLS_EXIT="${RUN_EXIT}"

if [[ ${TLS_EXIT} -eq 124 ]]; then
    bad "TLS flow timed out (likely waiting for input)"
elif [[ ${TLS_EXIT} -ne 0 ]]; then
    bad "TLS flow exited non-zero (${TLS_EXIT})"
    printf '%s\n' "${TLS_OUTPUT}" | sed 's/^/      output: /'
else
    ok "TLS flow exited 0 within timeout"
fi

# Check for success marker
if printf '%s\n' "${TLS_OUTPUT}" | grep -q "TLS_FLOW_COMPLETE"; then
    ok "TLS flow reached success marker"
else
    bad "TLS flow did NOT reach success marker"
fi

# Check all variables assigned
if printf '%s\n' "${TLS_OUTPUT}" | grep -q "ALL_VARS_ASSIGNED"; then
    ok "TLS flow assigned all required variables"
else
    bad "TLS flow did NOT assign all required variables"
    printf '%s\n' "${TLS_OUTPUT}" | grep "VAR_FAIL" | sed 's/^/      /'
fi

# Check no VAR_FAIL lines
VAR_FAIL_COUNT=$(printf '%s\n' "${TLS_OUTPUT}" | grep -c "VAR_FAIL" || true)
if [[ ${VAR_FAIL_COUNT} -eq 0 ]]; then
    ok "TLS flow: no empty required variables"
else
    bad "TLS flow: ${VAR_FAIL_COUNT} required variable(s) empty"
fi

rm -f "${TLS_WRAPPER}"

# ----------------------------------------------------------------
# Section 4: Template syntax check
# ----------------------------------------------------------------
echo ""
echo "--- Section 4: Template syntax check ---"
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    if bash -n "$f" 2>/dev/null; then
        ok "bash -n $(basename "$f")"
    else
        bad "bash -n $(basename "$f") (syntax error)"
    fi
done

# ----------------------------------------------------------------
# Section 5: Verify all required overrides exist in templates
# ----------------------------------------------------------------
echo ""
echo "--- Section 5: Override coverage check ---"

# Reality template must override these
REALITY_REQUIRED_OVERRIDES=(
    "old_config_exist_check"
    "ip_check"
    "port_set"
    "email_set"
    "UUID_set"
    "target_set"
    "serverNames_set"
    "keys_set"
    "shortIds_set"
    "spiderx_set"
    "xray_reality_add_more_choose"
    "reality_balance_add_fq"
    "reality_nginx_add_fq"
    "firewall_set"
    "auto_update"
    "vless_link_image_choice"
)

for func in "${REALITY_REQUIRED_OVERRIDES[@]}"; do
    if grep -qE "^${func}\(\)" "${SKILL_REPO_ROOT}/assets/setup-reality.sh" 2>/dev/null; then
        ok "setup-reality.sh overrides ${func}"
    else
        bad "setup-reality.sh does NOT override ${func}"
    fi
done

# TLS template must override these
TLS_REQUIRED_OVERRIDES=(
    "old_config_exist_check"
    "ip_check"
    "domain_check"
    "transport_choose"
    "port_set"
    "email_set"
    "UUID_set"
    "ws_inbound_port_set"
    "grpc_inbound_port_set"
    "xhttp_inbound_port_set"
    "ws_path_set"
    "grpc_path_set"
    "xhttp_path_set"
    "firewall_set"
    "auto_update"
    "vless_link_image_choice"
)

for func in "${TLS_REQUIRED_OVERRIDES[@]}"; do
    if grep -qE "^${func}\(\)" "${SKILL_REPO_ROOT}/assets/setup-tls.sh" 2>/dev/null; then
        ok "setup-tls.sh overrides ${func}"
    else
        bad "setup-tls.sh does NOT override ${func}"
    fi
done

# ----------------------------------------------------------------
# Summary
# ----------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Full-Flow Non-Interactive Test Summary (P0-A)"
echo "============================================================"
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo "============================================================"

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
exit 0
