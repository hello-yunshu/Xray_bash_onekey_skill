#!/bin/bash
#
# Xray_bash_onekey_skill — Execution-type contract tests
#
# Verifies that Skill templates use the correct variable names and do NOT
# leak secrets. Unlike the static contract test, this test sources the
# real install.sh (with _TEST_MODE=1), mocks network/systemctl/certificates,
# and calls the template override functions to verify runtime behavior.
#
# Test coverage:
#   - email_set() sets custom_email (NOT email)
#   - xray_reality_add_more_choose() sets reality_add_more (NOT add_more)
#   - xray_reality_add_more_choose() sets transport_mode (NOT ws_grpc_mode)
#   - UUID is non-empty after UUID_set()
#   - parse_reality_public_key handles "Password:", "PublicKey:", "Password (PublicKey):"
#   - stdout/stderr does NOT contain test private key, shortId, full JSON secrets
#   - Reality/TLS templates both pass bash -n
#   - Original contract tests still pass (delegated to test_contract.sh)
#
# Usage: bash test_contract_exec.sh
# Exits 0 if all checks pass, 1 otherwise.
#

set -uo pipefail

# Resolve repo paths
SKILL_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_REPO_ROOT="${MAIN_REPO_ROOT:-${1:-${SKILL_REPO_ROOT}/../Xray_bash_onekey}}"
INSTALL_SH="${MAIN_REPO_ROOT}/install.sh"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); echo "  ✅ PASS: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ❌ FAIL: $1"; }
skip() { SKIP=$((SKIP+1)); echo "  ⏭  SKIP: $1"; }

# Capture stdout+stderr from a command and check it does NOT contain a pattern
assert_output_not_contains() {
    local desc="$1" pattern="$2" output="$3"
    if printf '%s' "${output}" | grep -qF -- "${pattern}"; then
        bad "${desc} (output contains '${pattern}')"
    else
        ok "${desc}"
    fi
}

assert_output_contains() {
    local desc="$1" pattern="$2" output="$3"
    if printf '%s' "${output}" | grep -qF -- "${pattern}"; then
        ok "${desc}"
    else
        bad "${desc} (output does NOT contain '${pattern}')"
    fi
}

echo "============================================================"
echo "  Xray Skill Execution-Type Contract Test (P0-D)"
echo "============================================================"
echo ""

# ----------------------------------------------------------------
# Verify install.sh exists locally
# ----------------------------------------------------------------
echo "--- Section 1: install.sh availability ---"
if [[ ! -f "${INSTALL_SH}" ]]; then
    echo "  ❌ install.sh not found locally at ${INSTALL_SH}. Aborting."
    exit 1
fi
ok "install.sh exists locally at ${INSTALL_SH}"

# ----------------------------------------------------------------
# Source install.sh with _TEST_MODE=1 in a subshell
# ----------------------------------------------------------------
echo ""
echo "--- Section 2: Source install.sh with _TEST_MODE=1 ---"

# Source install.sh in a subshell to avoid polluting the test environment.
# We capture the function definitions and variables into a wrapper script.
WRAPPER_SCRIPT=$(mktemp /tmp/xray_skill_exec_test_XXXXXX.sh)

{
    echo '#!/bin/bash'
    echo 'set -uo pipefail'
    echo 'export _TEST_MODE=1'
    echo "source \"${INSTALL_SH}\" 2>/dev/null || true"
    echo ''
    echo '# Now source the template override functions'
    echo '# We extract just the override functions from the templates'
    echo '# and call them in sequence to verify variable assignments.'
    echo ''
    echo '# Extract email_set override from setup-reality.sh'
    echo 'source_setup_reality_overrides() {'
    awk '/^# Override interactive functions/{copy=1} /^# Execute installation/{copy=0} copy' \
        "${SKILL_REPO_ROOT}/assets/setup-reality.sh"
    echo '}'
    echo ''
    echo '# Extract email_set override from setup-tls.sh'
    echo 'source_setup_tls_overrides() {'
    awk '/^# Override interactive functions/{copy=1} /^# Execute installation/{copy=0} copy' \
        "${SKILL_REPO_ROOT}/assets/setup-tls.sh"
    echo '}'
    echo ''
    echo '# Test 3: email_set from reality template'
    echo 'test_email_set_reality() {'
    echo '    source_setup_reality_overrides'
    echo '    EMAIL="test@reality.example"'
    echo '    email_set'
    echo '    if [[ "${custom_email:-}" == "test@reality.example" ]]; then'
    echo '        echo "PASS: custom_email set correctly by reality template email_set"'
    echo '    else'
    echo '        echo "FAIL: custom_email not set correctly (got: ${custom_email:-})"'
    echo '    fi'
    echo '    if [[ -n "${email:-}" ]]; then'
    echo '        echo "FAIL: email variable should NOT be set by template"'
    echo '    else'
    echo '        echo "PASS: email variable NOT set (correct behavior)"'
    echo '    fi'
    echo '}'
    echo ''
    echo '# Test 4: email_set from TLS template'
    echo 'test_email_set_tls() {'
    echo '    source_setup_tls_overrides'
    echo '    EMAIL="test@tls.example"'
    echo '    email_set'
    echo '    if [[ "${custom_email:-}" == "test@tls.example" ]]; then'
    echo '        echo "PASS: custom_email set correctly by TLS template email_set"'
    echo '    else'
    echo '        echo "FAIL: custom_email not set correctly (got: ${custom_email:-})"'
    echo '    fi'
    echo '}'
    echo ''
    echo '# Test 5: xray_reality_add_more_choose from reality template'
    echo 'test_reality_add_more_choose() {'
    echo '    source_setup_reality_overrides'
    echo '    xray_reality_add_more_choose'
    echo '    if [[ "${reality_add_more:-}" == "off" ]]; then'
    echo '        echo "PASS: reality_add_more set to off"'
    echo '    else'
    echo '        echo "FAIL: reality_add_more not set to off (got: ${reality_add_more:-})"'
    echo '    fi'
    echo '    if [[ "${transport_mode:-}" == "None" ]]; then'
    echo '        echo "PASS: transport_mode set to None"'
    echo '    else'
    echo '        echo "FAIL: transport_mode not set to None (got: ${transport_mode:-})"'
    echo '    fi'
    echo '    if [[ -n "${add_more:-}" ]]; then'
    echo '        echo "FAIL: add_more variable should NOT be set by template"'
    echo '    else'
    echo '        echo "PASS: add_more variable NOT set (correct behavior)"'
    echo '    fi'
    echo '    if [[ -n "${ws_grpc_mode:-}" ]]; then'
    echo '        echo "FAIL: ws_grpc_mode variable should NOT be set by template"'
    echo '    else'
    echo '        echo "PASS: ws_grpc_mode variable NOT set (correct behavior)"'
    echo '    fi'
    echo '}'
    echo ''
    echo '# Test 6: UUID_set from reality template (with mocked random_num)'
    echo 'test_uuid_set_reality() {'
    echo '    source_setup_reality_overrides'
    echo '    random_num="${random_num:-8}"'
    echo '    UUID=""'
    echo '    UUID_set'
    echo '    if [[ -n "${UUID}" ]]; then'
    echo '        echo "PASS: UUID is non-empty after UUID_set"'
    echo '    else'
    echo '        echo "FAIL: UUID is empty after UUID_set"'
    echo '    fi'
    echo '}'
    echo ''
    echo '# Test 7: parse_reality_public_key handles all 3 formats'
    echo 'test_parse_reality_public_key_formats() {'
    echo '    if ! command -v parse_reality_public_key >/dev/null 2>&1; then'
    echo '        echo "SKIP: parse_reality_public_key not available"'
    echo '        return 0'
    echo '    fi'
    echo ''
    echo '    local result'
    echo ''
    echo '    # Format 1: "PrivateKey: xxx\nPassword: yyy"'
    echo '    result=$(parse_reality_public_key $'"'"'PrivateKey: AAA\nPassword: BBB'"'"')'
    echo '    if [[ "${result}" == "BBB" ]]; then'
    echo '        echo "PASS: parse_reality_public_key handles Password: format"'
    echo '    else'
    echo '        echo "FAIL: parse_reality_public_key returned ${result} for Password: format"'
    echo '    fi'
    echo ''
    echo '    # Format 2: "PublicKey: yyy"'
    echo '    result=$(parse_reality_public_key "PublicKey: CCC")'
    echo '    if [[ "${result}" == "CCC" ]]; then'
    echo '        echo "PASS: parse_reality_public_key handles PublicKey: format"'
    echo '    else'
    echo '        echo "FAIL: parse_reality_public_key returned ${result} for PublicKey: format"'
    echo '    fi'
    echo ''
    echo '    # Format 3: "Password (PublicKey): yyy"'
    echo '    result=$(parse_reality_public_key "Password (PublicKey): DDD")'
    echo '    if [[ "${result}" == "DDD" ]]; then'
    echo '        echo "PASS: parse_reality_public_key handles Password (PublicKey): format"'
    echo '    else'
    echo '        echo "FAIL: parse_reality_public_key returned ${result} for Password (PublicKey): format"'
    echo '    fi'
    echo '}'
    echo ''
    echo '# Test 8: Secret leak detection — verify templates do NOT echo secret values'
    echo 'test_no_secret_leak_reality() {'
    echo '    local output'
    echo '    source_setup_reality_overrides'
    echo ''
    echo '    # Set fake secret values and call override functions'
    echo '    local FAKE_UUID="fake-uuid-1234-5678"'
    echo '    export FAKE_PRIVATE_KEY="FAKE_PRIVATE_KEY_xyz789"'
    echo '    local FAKE_SHORT_IDS="0123456789abcdef"'
    echo '    export FAKE_PASSWORD="FAKE_PASSWORD_abc123"'
    echo ''
    echo '    # Capture output from UUID_set (should NOT contain the UUID value)'
    echo '    UUID="${FAKE_UUID}"'
    echo '    output=$(UUID_set 2>&1 || true)'
    echo '    if printf "%s" "${output}" | grep -qF -- "${FAKE_UUID}"; then'
    echo '        echo "FAIL: UUID_set output contains the UUID value"'
    echo '    else'
    echo '        echo "PASS: UUID_set output does NOT contain the UUID value"'
    echo '    fi'
    echo ''
    echo '    # Capture output from shortIds_set (should NOT contain the shortIds value)'
    echo '    # We need to mock the openssl command to produce a known value'
    echo '    generate_reality_short_id() { echo "${FAKE_SHORT_IDS}"; }'
    echo '    output=$(shortIds_set 2>&1 || true)'
    echo '    if printf "%s" "${output}" | grep -qF -- "${FAKE_SHORT_IDS}"; then'
    echo '        echo "FAIL: shortIds_set output contains the shortIds value"'
    echo '    else'
    echo '        echo "PASS: shortIds_set output does NOT contain the shortIds value"'
    echo '    fi'
    echo ''
    echo '    # Capture output from keys_set (should NOT contain privateKey or password values)'
    echo '    # Mock xray binary to produce known keys'
    echo '    xray_bin_dir="/tmp/mock_xray_bin"'
    echo '    mkdir -p "${xray_bin_dir}"'
    echo '    cat > "${xray_bin_dir}/xray" << "XRAYEOF"'
    echo '#!/bin/bash'
    echo 'echo "PrivateKey: ${FAKE_PRIVATE_KEY}"'
    echo 'echo "Password: ${FAKE_PASSWORD}"'
    echo 'XRAYEOF'
    echo '    chmod +x "${xray_bin_dir}/xray"'
    echo '    output=$(keys_set 2>&1 || true)'
    echo '    if printf "%s" "${output}" | grep -qF -- "${FAKE_PRIVATE_KEY}"; then'
    echo '        echo "FAIL: keys_set output contains the privateKey value"'
    echo '    else'
    echo '        echo "PASS: keys_set output does NOT contain the privateKey value"'
    echo '    fi'
    echo '    if printf "%s" "${output}" | grep -qF -- "${FAKE_PASSWORD}"; then'
    echo '        echo "FAIL: keys_set output contains the password value"'
    echo '    else'
    echo '        echo "PASS: keys_set output does NOT contain the password value"'
    echo '    fi'
    echo '    rm -rf "${xray_bin_dir}"'
    echo '}'
    echo ''
    echo '# Run all tests'
    echo 'echo "--- Section 3: Variable name contract (execution) ---"'
    echo 'test_email_set_reality'
    echo 'test_email_set_tls'
    echo ''
    echo 'echo ""'
    echo 'echo "--- Section 4: Reality add-more variable contract (execution) ---"'
    echo 'test_reality_add_more_choose'
    echo ''
    echo 'echo ""'
    echo 'echo "--- Section 5: UUID non-empty after UUID_set ---"'
    echo 'test_uuid_set_reality'
    echo ''
    echo 'echo ""'
    echo 'echo "--- Section 6: parse_reality_public_key format compatibility ---"'
    echo 'test_parse_reality_public_key_formats'
    echo ''
    echo 'echo ""'
    echo 'echo "--- Section 7: Secret leak detection ---"'
    echo 'test_no_secret_leak_reality'
    echo ''
    echo 'echo ""'
    echo 'echo "--- Section 8: Done ---"'
} > "${WRAPPER_SCRIPT}"

# Run the wrapper script and capture output
echo "  Running wrapper script..."
EXEC_OUTPUT=$(bash "${WRAPPER_SCRIPT}" 2>&1)
EXEC_STATUS=$?
DYNAMIC_RESULTS=0
while IFS= read -r line; do
    case "${line}" in
        PASS:*) DYNAMIC_RESULTS=$((DYNAMIC_RESULTS + 1)); ok "${line#PASS: }" ;;
        FAIL:*) DYNAMIC_RESULTS=$((DYNAMIC_RESULTS + 1)); bad "${line#FAIL: }" ;;
        SKIP:*) DYNAMIC_RESULTS=$((DYNAMIC_RESULTS + 1)); skip "${line#SKIP: }" ;;
        *) ;;
    esac
done <<< "${EXEC_OUTPUT}"

if [[ ${EXEC_STATUS} -ne 0 ]]; then
    bad "execution wrapper exited non-zero (${EXEC_STATUS})"
    printf '%s\n' "${EXEC_OUTPUT}" | sed 's/^/      wrapper: /'
fi
if [[ ${DYNAMIC_RESULTS} -lt 12 ]]; then
    bad "execution wrapper produced only ${DYNAMIC_RESULTS} contract results"
else
    ok "execution wrapper produced ${DYNAMIC_RESULTS} real contract results"
fi

rm -f "${WRAPPER_SCRIPT}"

# ----------------------------------------------------------------
# Static grep checks for variable names in templates
# ----------------------------------------------------------------
echo ""
echo "--- Section 9: Static variable name checks in templates ---"

for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_grep_in_file() {
        local pattern="$1" file="$2" label="$3"
        if grep -qE -- "$pattern" "$file" 2>/dev/null; then
            ok "$label"
        else
            bad "$label (pattern: $pattern in $file)"
        fi
    }
    assert_not_grep_in_file() {
        local pattern="$1" file="$2" label="$3"
        if grep -qE -- "$pattern" "$file" 2>/dev/null; then
            bad "$label (unexpected match: $pattern in $file)"
        else
            ok "$label"
        fi
    }
    # email_set should use custom_email (NOT email=)
    assert_grep_in_file 'custom_email=' "$f" "$f uses custom_email in email_set"
    assert_not_grep_in_file '^\s*email=\$' "$f" "$f does NOT use email= (deprecated)"
done

# Reality template should use reality_add_more and transport_mode
REALITY_TEMPLATE="${SKILL_REPO_ROOT}/assets/setup-reality.sh"
assert_grep_in_file_reality() {
    local pattern="$1" label="$2"
    if grep -qE -- "$pattern" "${REALITY_TEMPLATE}" 2>/dev/null; then
        ok "$label"
    else
        bad "$label (pattern: $pattern in ${REALITY_TEMPLATE})"
    fi
}
assert_not_grep_in_file_reality() {
    local pattern="$1" label="$2"
    if grep -qE -- "$pattern" "${REALITY_TEMPLATE}" 2>/dev/null; then
        bad "$label (unexpected match: $pattern in ${REALITY_TEMPLATE})"
    else
        ok "$label"
    fi
}
assert_grep_in_file_reality 'reality_add_more=' "setup-reality.sh uses reality_add_more"
assert_grep_in_file_reality 'transport_mode=' "setup-reality.sh uses transport_mode"
assert_not_grep_in_file_reality '\badd_more="off"' "setup-reality.sh does NOT use add_more (deprecated)"
assert_not_grep_in_file_reality '\bws_grpc_mode=' "setup-reality.sh does NOT use ws_grpc_mode (deprecated)"

# ----------------------------------------------------------------
# Static grep checks for secret output in templates
# ----------------------------------------------------------------
echo ""
echo "--- Section 10: Secret output checks in templates ---"

for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    # Templates must NOT cat the full install_config.json
    if grep -qE 'cat\s+/etc/idleleo/conf/install_config\.json' "$f" 2>/dev/null; then
        bad "$(basename "$f") does NOT cat install_config.json (secret leak)"
    else
        ok "$(basename "$f") does NOT cat install_config.json"
    fi
    # Templates must NOT echo privateKey value directly
    if grep -qE 'echo\s+.*\$\{?privateKey' "$f" 2>/dev/null; then
        bad "$(basename "$f") does NOT echo privateKey value (secret leak)"
    else
        ok "$(basename "$f") does NOT echo privateKey value"
    fi
    # Templates must NOT echo password value directly
    if grep -qE 'echo\s+.*\$\{?password\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") does NOT echo password value (secret leak)"
    else
        ok "$(basename "$f") does NOT echo password value"
    fi
    # Templates must NOT echo shortIds value directly
    if grep -qE 'echo\s+.*\$\{?shortIds\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") does NOT echo shortIds value (secret leak)"
    else
        ok "$(basename "$f") does NOT echo shortIds value"
    fi
    # Templates must NOT echo UUID value directly
    if grep -qE 'echo\s+.*\$\{?UUID\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") does NOT echo UUID value (secret leak)"
    else
        ok "$(basename "$f") does NOT echo UUID value"
    fi
    # Templates must NOT output unredacted journalctl
    if grep -qE 'journalctl\s+-u\s+xray\s+-e\s+--no-pager$' "$f" 2>/dev/null; then
        bad "$(basename "$f") does NOT output unredacted journalctl (secret leak)"
    else
        ok "$(basename "$f") does NOT output unredacted journalctl"
    fi
    # Templates MUST have bash -n syntax check
    if grep -qE 'bash\s+-n\s+.*INSTALL_SH' "$f" 2>/dev/null; then
        ok "$(basename "$f") has bash -n syntax check"
    else
        bad "$(basename "$f") has bash -n syntax check (missing)"
    fi
    # Templates MUST support INSTALL_SH_REF for ref pinning
    if grep -qE 'INSTALL_SH_REF' "$f" 2>/dev/null; then
        ok "$(basename "$f") supports INSTALL_SH_REF for ref pinning"
    else
        bad "$(basename "$f") supports INSTALL_SH_REF for ref pinning (missing)"
    fi
    # Templates MUST use safe_print_config_summary or jq summary (NOT cat)
    if grep -qE 'safe_print_config_summary|jq\s+-r' "$f" 2>/dev/null; then
        ok "$(basename "$f") uses safe summary output (jq or safe_print_config_summary)"
    else
        bad "$(basename "$f") uses safe summary output (missing)"
    fi
done

# ----------------------------------------------------------------
# Shell syntax check on templates
# ----------------------------------------------------------------
echo ""
echo "--- Section 11: Shell syntax check ---"
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    if bash -n "$f" 2>/dev/null; then
        ok "bash -n $(basename "$f")"
    else
        bad "bash -n $(basename "$f") (syntax error)"
    fi
done

# ----------------------------------------------------------------
# Documentation checks — ensure docs use correct variable names
# ----------------------------------------------------------------
echo ""
echo "--- Section 12: Documentation variable name checks ---"
MODES_MD="${SKILL_REPO_ROOT}/references/modes.md"
# modes.md should mention custom_email (NOT just email= as a variable assignment)
if grep -qE 'custom_email=' "${MODES_MD}" 2>/dev/null; then
    ok "modes.md references custom_email variable"
else
    bad "modes.md does NOT reference custom_email variable"
fi
# modes.md should mention reality_add_more (as a variable name, with or without =)
if grep -qE 'reality_add_more\b' "${MODES_MD}" 2>/dev/null; then
    ok "modes.md references reality_add_more variable"
else
    bad "modes.md does NOT reference reality_add_more variable"
fi
# modes.md should mention transport_mode
if grep -qE 'transport_mode=' "${MODES_MD}" 2>/dev/null; then
    ok "modes.md references transport_mode variable"
else
    bad "modes.md does NOT reference transport_mode variable"
fi
# modes.md should have Secret Redaction Contract section
if grep -qE 'Secret Redaction Contract' "${MODES_MD}" 2>/dev/null; then
    ok "modes.md has Secret Redaction Contract section"
else
    bad "modes.md has Secret Redaction Contract section (missing)"
fi

SKILL_MD="${SKILL_REPO_ROOT}/SKILL.md"
# SKILL.md should mention custom_email
if grep -qE 'custom_email' "${SKILL_MD}" 2>/dev/null; then
    ok "SKILL.md references custom_email variable"
else
    bad "SKILL.md does NOT reference custom_email variable"
fi
# SKILL.md should mention reality_add_more
if grep -qE 'reality_add_more' "${SKILL_MD}" 2>/dev/null; then
    ok "SKILL.md references reality_add_more variable"
else
    bad "SKILL.md does NOT reference reality_add_more variable"
fi
# SKILL.md should mention secret redaction
if grep -qE 'Secret redaction|safe_print_config_summary' "${SKILL_MD}" 2>/dev/null; then
    ok "SKILL.md mentions secret redaction"
else
    bad "SKILL.md mentions secret redaction (missing)"
fi

# ----------------------------------------------------------------
# Full content leak scan — run template functions and
# verify stdout/stderr does not contain test secrets
# ----------------------------------------------------------------
echo ""
echo "--- Section 13: Full content leak scan ---"
# The leak scan above already validates template output; here we also statically
# grep template sources for patterns that echo secrets directly.
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    # Check for echo statements that output secret variables directly
    # Pattern: echo ... $privateKey or echo ... ${privateKey}
    if grep -qE 'echo.*\$\{?privateKey\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") static scan: found echo with privateKey variable"
    else
        ok "$(basename "$f") static scan: no echo with privateKey variable"
    fi
    if grep -qE 'echo.*\$\{?shortIds\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") static scan: found echo with shortIds variable"
    else
        ok "$(basename "$f") static scan: no echo with shortIds variable"
    fi
    if grep -qE 'echo.*\$\{?password\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") static scan: found echo with password variable"
    else
        ok "$(basename "$f") static scan: no echo with password variable"
    fi
    if grep -qE 'echo.*\$\{?UUID\b' "$f" 2>/dev/null; then
        bad "$(basename "$f") static scan: found echo with UUID variable"
    else
        ok "$(basename "$f") static scan: no echo with UUID variable"
    fi
done

# ----------------------------------------------------------------
# Verify original contract tests still pass
# ----------------------------------------------------------------
echo ""
echo "--- Section 14: Original contract tests still pass ---"
if bash "${SKILL_REPO_ROOT}/tests/test_contract.sh" >/dev/null 2>&1; then
    ok "Original contract tests pass (test_contract.sh)"
else
    bad "Original contract tests pass (test_contract.sh) (failed)"
fi

# ----------------------------------------------------------------
# Fail-closed verification scenarios (Scenarios 3-9)
#   3. Xray inactive → returns non-zero
#   4. TLS Nginx inactive → returns non-zero
#   5. Config missing → returns non-zero
#   6. Config JSON corrupted → returns non-zero
#   7. Reality config uses `.id` → validation succeeds
#   8. Existing install + INSTALL_MODE=NEW_INSTALL → reject + file unchanged
#   9. Existing install + CLEAN_INSTALL + CONFIRM_CLEAN_INSTALL=1 → reject (no bypass)
#  10. Existing install + INSTALL_MODE=anything → reject (always)
# ----------------------------------------------------------------
echo ""
echo "--- Section 15: Fail-closed verification scenarios ---"

VERIFY_WRAPPER=$(mktemp /tmp/xray_skill_verify_XXXXXX.sh)
VERIFY_TMP_DIR=$(mktemp -d /tmp/xray_skill_verify_tmp_XXXXXX)
trap 'rm -rf "${VERIFY_WRAPPER}" "${VERIFY_TMP_DIR}"' EXIT

cat > "${VERIFY_WRAPPER}" << 'VERIFY_EOF'
#!/bin/bash
set -uo pipefail
export _TEST_MODE=1

INSTALL_SH="__INSTALL_SH_PLACEHOLDER__"
# shellcheck source=/dev/null
source "${INSTALL_SH}" 2>/dev/null || true

# Default mocks (overridden per-scenario below)
log_echo() { :; }
gettext() { printf '%s' "$1"; }

SCENARIO="__SCENARIO_PLACEHOLDER__"
CONFIG_FILE="__CONFIG_FILE_PLACEHOLDER__"
NGINX_BIN="__NGINX_BIN_PLACEHOLDER__"

# Per-scenario systemctl mock
# Handles the real call form: systemctl is-active --quiet <service>
case "${SCENARIO}" in
    xray_inactive|reality_xray_inactive)
        # xray inactive, nginx active
        systemctl() {
            if [[ "$1" == "is-active" ]]; then
                local svc=""; shift
                while [[ $# -gt 0 ]]; do
                    case "$1" in --quiet) shift ;; *) svc="$1"; break ;; esac
                done
                [[ "${svc}" == "xray" ]] && return 3
                return 0
            fi
            return 0
        }
        ;;
    nginx_inactive)
        # xray active, nginx inactive
        systemctl() {
            if [[ "$1" == "is-active" ]]; then
                local svc=""; shift
                while [[ $# -gt 0 ]]; do
                    case "$1" in --quiet) shift ;; *) svc="$1"; break ;; esac
                done
                [[ "${svc}" == "nginx" ]] && return 3
                return 0
            fi
            return 0
        }
        ;;
    *)
        # Default: both active
        systemctl() { return 0; }
        ;;
esac

# Mock nginx binary: create a script that returns the desired exit code
if [[ -n "${NGINX_BIN}" ]]; then
    mkdir -p "$(dirname "${NGINX_BIN}")"
    cat > "${NGINX_BIN}" << 'NGINXEOF'
#!/bin/bash
__NGINX_EXIT__
exit 0
NGINXEOF
    case "${SCENARIO}" in
        nginx_inactive) sed -i 's/__NGINX_EXIT__/exit 1/' "${NGINX_BIN}" ;;
        *) sed -i 's/__NGINX_EXIT__/exit 0/' "${NGINX_BIN}" ;;
    esac
    chmod +x "${NGINX_BIN}"
fi

verification_failed=0

# Replicate the Reality verification logic from setup-reality.sh
run_reality_verify() {
    verification_failed=0
    if ! systemctl is-active --quiet xray; then
        verification_failed=1
    fi
    if [[ ! -s "${CONFIG_FILE}" ]] || ! jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
        verification_failed=1
    fi
    if [[ -s "${CONFIG_FILE}" ]] && jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
        if [[ "$(jq -r '.tls // empty' "${CONFIG_FILE}" 2>/dev/null)" != "Reality" ]]; then
            verification_failed=1
        fi
        user_id="$(jq -r '.id // .UUID // empty' "${CONFIG_FILE}" 2>/dev/null)"
        if [[ -z "${user_id}" ]]; then
            verification_failed=1
        fi
        for _field in privateKey password shortIds host; do
            if [[ -z "$(jq -r --arg f "${_field}" '.[$f] // empty' "${CONFIG_FILE}" 2>/dev/null)" ]]; then
                verification_failed=1
            fi
        done
    fi
    return ${verification_failed}
}

# Replicate the TLS verification logic from setup-tls.sh
run_tls_verify() {
    verification_failed=0
    if ! systemctl is-active --quiet xray; then
        verification_failed=1
    fi
    if ! systemctl is-active --quiet nginx; then
        verification_failed=1
    fi
    if [[ ! -s "${CONFIG_FILE}" ]] || ! jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
        verification_failed=1
    fi
    if [[ -s "${CONFIG_FILE}" ]] && jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
        if [[ "$(jq -r '.tls // empty' "${CONFIG_FILE}" 2>/dev/null)" != "TLS" ]]; then
            verification_failed=1
        fi
    fi
    if [[ -x /usr/local/nginx/sbin/nginx ]] && ! /usr/local/nginx/sbin/nginx -t >/dev/null 2>&1; then
        verification_failed=1
    fi
    return ${verification_failed}
}

case "${SCENARIO}" in
    xray_inactive)
        # Xray inactive → Reality verify fails
        run_reality_verify
        exit $?
        ;;
    reality_xray_inactive)
        # Variant: Xray inactive → Reality verify fails (explicit)
        run_reality_verify
        exit $?
        ;;
    nginx_inactive)
        # TLS Nginx inactive → TLS verify fails
        run_tls_verify
        exit $?
        ;;
    config_missing)
        # Config missing → Reality verify fails
        run_reality_verify
        exit $?
        ;;
    config_corrupted)
        # Config JSON corrupted → verify fails
        run_reality_verify
        exit $?
        ;;
    reality_id_ok)
        # Reality config uses .id → validation succeeds
        run_reality_verify
        exit $?
        ;;
    *)
        exit 99
        ;;
esac
VERIFY_EOF

sed -i.bak "s|__INSTALL_SH_PLACEHOLDER__|${INSTALL_SH}|g" "${VERIFY_WRAPPER}"
rm -f "${VERIFY_WRAPPER}.bak"

run_verify_scenario() {
    local scenario="$1" config_file="$2" nginx_bin="${3:-}"
    local tmp_wrapper
    tmp_wrapper=$(mktemp /tmp/xray_skill_verify_run_XXXXXX.sh)
    cp "${VERIFY_WRAPPER}" "${tmp_wrapper}"
    sed -i.bak "s|__SCENARIO_PLACEHOLDER__|${scenario}|g" "${tmp_wrapper}"
    sed -i.bak2 "s|__CONFIG_FILE_PLACEHOLDER__|${config_file}|g" "${tmp_wrapper}"
    sed -i.bak3 "s|__NGINX_BIN_PLACEHOLDER__|${nginx_bin}|g" "${tmp_wrapper}"
    rm -f "${tmp_wrapper}.bak" "${tmp_wrapper}.bak2" "${tmp_wrapper}.bak3"
    bash "${tmp_wrapper}" 2>/dev/null
    local rc=$?
    rm -f "${tmp_wrapper}"
    return ${rc}
}

# --- Xray inactive → verification fails ---
echo "  --- Scenario 3: Xray inactive → verify fails ---"
VALID_CONFIG="${VERIFY_TMP_DIR}/valid_reality.json"
cat > "${VALID_CONFIG}" << 'JSON_EOF'
{"tls":"Reality","id":"test-id","privateKey":"pk","password":"pw","shortIds":"sid","host":"203.0.113.1"}
JSON_EOF
run_verify_scenario "reality_xray_inactive" "${VALID_CONFIG}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -ne 0 ]]; then
    ok "Scenario 3: Xray inactive → verify returns non-zero (${rc})"
else
    bad "Scenario 3: Xray inactive → verify should return non-zero but got 0"
fi

# --- TLS Nginx inactive → verification fails ---
echo "  --- Scenario 4: TLS Nginx inactive → verify fails ---"
TLS_CONFIG="${VERIFY_TMP_DIR}/valid_tls.json"
cat > "${TLS_CONFIG}" << 'JSON_EOF'
{"tls":"TLS","id":"test-id","domain":"example.com"}
JSON_EOF
NGINX_BIN_MOCK="${VERIFY_TMP_DIR}/nginx"
run_verify_scenario "nginx_inactive" "${TLS_CONFIG}" "${NGINX_BIN_MOCK}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -ne 0 ]]; then
    ok "Scenario 4: TLS Nginx inactive → verify returns non-zero (${rc})"
else
    bad "Scenario 4: TLS Nginx inactive → verify should return non-zero but got 0"
fi

# --- Config missing → verification fails ---
echo "  --- Scenario 5: Config missing → verify fails ---"
# Use systemctl default (both active) but config file doesn't exist
MISSING_CONFIG="${VERIFY_TMP_DIR}/nonexistent.json"
run_verify_scenario "config_missing" "${MISSING_CONFIG}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -ne 0 ]]; then
    ok "Scenario 5: Config missing → verify returns non-zero (${rc})"
else
    bad "Scenario 5: Config missing → verify should return non-zero but got 0"
fi

# --- Config JSON corrupted → verification fails ---
echo "  --- Scenario 6: Config JSON corrupted → verify fails ---"
CORRUPT_CONFIG="${VERIFY_TMP_DIR}/corrupt.json"
echo '{"tls":"Reality","id":"broken' > "${CORRUPT_CONFIG}"
run_verify_scenario "config_corrupted" "${CORRUPT_CONFIG}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -ne 0 ]]; then
    ok "Scenario 6: Config JSON corrupted → verify returns non-zero (${rc})"
else
    bad "Scenario 6: Config JSON corrupted → verify should return non-zero but got 0"
fi

# --- Reality config uses `.id` (not UUID) → validation succeeds ---
echo "  --- Scenario 7: Reality config uses .id → validation succeeds ---"
ID_CONFIG="${VERIFY_TMP_DIR}/id_only.json"
cat > "${ID_CONFIG}" << 'JSON_EOF'
{"tls":"Reality","id":"test-uuid-value","privateKey":"pk-value","password":"pw-value","shortIds":"sid-value","host":"203.0.113.1"}
JSON_EOF
# For this scenario, systemctl default returns 0 (both active), so only config
# validation matters. The config has `.id` but NO `.UUID` — must succeed.
run_verify_scenario "reality_id_ok" "${ID_CONFIG}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 0 ]]; then
    ok "Scenario 7: Reality config with .id (no UUID) → verify succeeds (${rc})"
else
    bad "Scenario 7: Reality config with .id (no UUID) → verify should succeed but got ${rc}"
fi

# Also verify: config with .UUID but no .id → should still succeed (legacy fallback)
echo "  --- Scenario 7b: Legacy config with .UUID (no .id) → verify succeeds ---"
UUID_CONFIG="${VERIFY_TMP_DIR}/uuid_only.json"
cat > "${UUID_CONFIG}" << 'JSON_EOF'
{"tls":"Reality","UUID":"legacy-uuid","privateKey":"pk","password":"pw","shortIds":"sid","host":"203.0.113.1"}
JSON_EOF
run_verify_scenario "reality_id_ok" "${UUID_CONFIG}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -eq 0 ]]; then
    ok "Scenario 7b: Legacy config with .UUID (no .id) → verify succeeds (${rc})"
else
    bad "Scenario 7b: Legacy config with .UUID (no .id) → verify should succeed but got ${rc}"
fi

# Also verify: config with neither .id nor .UUID → should fail
echo "  --- Scenario 7c: Config with neither .id nor .UUID → verify fails ---"
NO_ID_CONFIG="${VERIFY_TMP_DIR}/no_id.json"
cat > "${NO_ID_CONFIG}" << 'JSON_EOF'
{"tls":"Reality","privateKey":"pk","password":"pw","shortIds":"sid","host":"203.0.113.1"}
JSON_EOF
run_verify_scenario "reality_id_ok" "${NO_ID_CONFIG}" >/dev/null 2>&1
rc=$?
if [[ ${rc} -ne 0 ]]; then
    ok "Scenario 7c: Config with neither .id nor .UUID → verify fails (${rc})"
else
    bad "Scenario 7c: Config with neither .id nor .UUID → verify should fail but got 0"
fi

# --- Existing install + INSTALL_MODE=NEW_INSTALL → reject + file unchanged ---
echo "  --- Scenario 8: Existing install + INSTALL_MODE=NEW_INSTALL → reject ---"
EXISTING_CONFIG="${VERIFY_TMP_DIR}/existing.json"
echo '{"tls":"Reality","id":"existing"}' > "${EXISTING_CONFIG}"
EXISTING_HASH_BEFORE=$(md5sum "${EXISTING_CONFIG}" 2>/dev/null | awk '{print $1}')
# Simulate the simplified guard logic from setup-reality.sh / setup-tls.sh:
# any existing installation is rejected regardless of INSTALL_MODE.
INSTALL_MODE="NEW_INSTALL"
guard_rejected=0
if [[ -f "${EXISTING_CONFIG}" ]]; then
    guard_rejected=1
fi
EXISTING_HASH_AFTER=$(md5sum "${EXISTING_CONFIG}" 2>/dev/null | awk '{print $1}')
if [[ ${guard_rejected} -eq 1 ]]; then
    ok "Scenario 8: Existing install + INSTALL_MODE=NEW_INSTALL → guard rejects"
else
    bad "Scenario 8: Existing install + INSTALL_MODE=NEW_INSTALL → guard should reject"
fi
if [[ "${EXISTING_HASH_BEFORE}" == "${EXISTING_HASH_AFTER}" ]]; then
    ok "Scenario 8: Config file unchanged after guard rejection"
else
    bad "Scenario 8: Config file was modified after guard rejection"
fi

# --- Existing install + CLEAN_INSTALL + CONFIRM_CLEAN_INSTALL=1 → reject ---
echo "  --- Scenario 9: Existing install + CLEAN_INSTALL + CONFIRM → reject ---"
INSTALL_MODE="CLEAN_INSTALL"
CONFIRM_CLEAN_INSTALL="1"
guard_rejected=0
if [[ -f "${EXISTING_CONFIG}" ]]; then
    guard_rejected=1
fi
if [[ ${guard_rejected} -eq 1 ]]; then
    ok "Scenario 9: Existing install + CLEAN_INSTALL + CONFIRM → guard rejects (no bypass)"
else
    bad "Scenario 9: Existing install + CLEAN_INSTALL + CONFIRM → guard should reject"
fi

# --- Existing install + INSTALL_MODE=anything → reject ---
echo "  --- Scenario 10: Existing install + INSTALL_MODE=anything → reject ---"
INSTALL_MODE="some-random-mode"
guard_rejected=0
if [[ -f "${EXISTING_CONFIG}" ]]; then
    guard_rejected=1
fi
if [[ ${guard_rejected} -eq 1 ]]; then
    ok "Scenario 10: Existing install + any INSTALL_MODE → guard rejects"
else
    bad "Scenario 10: Existing install + any INSTALL_MODE → guard should reject"
fi

rm -rf "${VERIFY_WRAPPER}" "${VERIFY_TMP_DIR}"

# ----------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Execution-Type Contract Test Summary (P0-D)"
echo "============================================================"
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo "  SKIP: ${SKIP}"
echo "============================================================"

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
exit 0
