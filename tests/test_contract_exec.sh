#!/bin/bash
#
# Xray_bash_onekey_skill — Execution-Type Contract Test for P0-D
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
# Section 1: Verify install.sh exists locally
# ----------------------------------------------------------------
echo "--- Section 1: install.sh availability ---"
if [[ ! -f "${INSTALL_SH}" ]]; then
    echo "  ❌ install.sh not found locally at ${INSTALL_SH}. Aborting."
    exit 1
fi
ok "install.sh exists locally at ${INSTALL_SH}"

# ----------------------------------------------------------------
# Section 2: Source install.sh with _TEST_MODE=1 in a subshell
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
# Section 3: Static grep checks for variable names in templates
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
# Section 4: Static grep checks for secret output in templates
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
# Section 5: Shell syntax check on templates
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
# Section 6: Documentation checks — ensure docs use correct variable names
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
# Section 7: Full content leak scan — run template functions and
# verify stdout/stderr does not contain test secrets
# ----------------------------------------------------------------
echo ""
echo "--- Section 13: Full content leak scan ---"
# This test is already done in Section 7 of the wrapper script above.
# Here we do an additional static check: grep for common secret-leak patterns.
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
# Section 8: Verify original contract tests still pass
# ----------------------------------------------------------------
echo ""
echo "--- Section 14: Original contract tests still pass ---"
if bash "${SKILL_REPO_ROOT}/tests/test_contract.sh" >/dev/null 2>&1; then
    ok "Original contract tests pass (test_contract.sh)"
else
    bad "Original contract tests pass (test_contract.sh) (failed)"
fi

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
