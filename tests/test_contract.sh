#!/bin/bash
#
# Xray_bash_onekey_skill — Contract Test (Task D, Section 8.4)
#
# Verifies that Skill templates and documentation match the actual install.sh
# contract: paths, variable names, function signatures, transport_mode values,
# and required arguments for UUIDv5_tranc / generate_random_port.
#
# The test reads the real install.sh from the sibling Xray_bash_onekey repo
# (or a URL if not available locally) and checks the Skill's templates against
# the actual source. It does NOT execute any installation.
#
# Usage: bash test_contract.sh
# Exits 0 if all contract checks pass, 1 otherwise.
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

assert_file_exists() {
    local f="$1"
    if [[ -f "$f" ]]; then ok "file exists: $f"; else bad "missing file: $f"; return 1; fi
}

assert_grep_in_file() {
    local pattern="$1"
    local file="$2"
    local label="${3:-grep match}"
    if grep -qE -- "$pattern" "$file" 2>/dev/null; then
        ok "$label"
    else
        bad "$label (pattern: $pattern in $file)"
    fi
}

assert_not_grep_in_file() {
    local pattern="$1"
    local file="$2"
    local label="${3:-no grep match}"
    if grep -qE -- "$pattern" "$file" 2>/dev/null; then
        bad "$label (unexpected match: $pattern in $file)"
    else
        ok "$label"
    fi
}

echo "============================================================"
echo "  Xray Skill Contract Test (Task D, Section 8.4)"
echo "============================================================"
echo ""

# ----------------------------------------------------------------
# Section 1: install.sh must exist locally (or fetch from GitHub)
# ----------------------------------------------------------------
echo "--- Section 1: install.sh availability ---"
if [[ ! -f "${INSTALL_SH}" ]]; then
    echo "  install.sh not found locally, fetching from GitHub..."
    INSTALL_SH="/tmp/install.sh.contract.$$"
    if ! curl -fsSL "https://raw.githubusercontent.com/hello-yunshu/Xray_bash_onekey/main/install.sh" -o "${INSTALL_SH}"; then
        echo "  ❌ Cannot fetch install.sh from GitHub. Aborting."
        exit 1
    fi
    FETCHED=1
else
    FETCHED=0
fi
assert_file_exists "${INSTALL_SH}"

# ----------------------------------------------------------------
# Section 2: Paths contract
# ----------------------------------------------------------------
echo ""
echo "--- Section 2: install_config.json path (conf/, not info/) ---"
# install.sh must define xray_install_config_file as ${idleleo_conf_dir}/install_config.json
assert_grep_in_file 'xray_install_config_file=.*conf.*install_config\.json' "${INSTALL_SH}" \
    "install.sh defines install_config.json under conf/"
assert_not_grep_in_file 'xray_install_config_file=.*info.*install_config\.json' "${INSTALL_SH}" \
    "install.sh does NOT define install_config.json under info/"

# Skill templates must reference /etc/idleleo/conf/install_config.json (NOT info/)
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_file_exists "$f"
    assert_grep_in_file '/etc/idleleo/conf/install_config\.json' "$f" \
        "$f references /etc/idleleo/conf/install_config.json"
    assert_not_grep_in_file '/etc/idleleo/info/install_config\.json' "$f" \
        "$f does NOT reference /etc/idleleo/info/install_config.json"
done

# ----------------------------------------------------------------
# Section 3: Nginx binary path contract
# ----------------------------------------------------------------
echo ""
echo "--- Section 3: Nginx binary path (/usr/local/nginx/sbin/nginx) ---"
assert_grep_in_file '^nginx_dir=' "${INSTALL_SH}" "install.sh defines nginx_dir"
assert_grep_in_file 'nginx_dir="\$\{local_bin\}/nginx"|nginx_dir="/usr/local/nginx"' "${INSTALL_SH}" \
    "nginx_dir is /usr/local/nginx (via local_bin=/usr/local)"

for f in "${SKILL_REPO_ROOT}/assets/setup-tls.sh" "${SKILL_REPO_ROOT}/references/checklist.md" "${SKILL_REPO_ROOT}/references/troubleshooting.md"; do
    assert_file_exists "$f"
    assert_grep_in_file '/usr/local/nginx/sbin/nginx' "$f" "$f references /usr/local/nginx/sbin/nginx"
    # Check only executable lines (skip comments containing "NOT /etc/idleleo/nginx/...")
    # A real bad reference would be a command/path like `/etc/idleleo/nginx/sbin/nginx -t`
    # or `$(/etc/idleleo/nginx/sbin/nginx` — NOT a comment saying "NOT /etc/idleleo/nginx/...".
    bad_match=$(grep -nE '/etc/idleleo/nginx/sbin/nginx' "$f" 2>/dev/null | grep -vE '^[0-9]+:\s*#|NOT /etc/idleleo/nginx' || true)
    if [[ -z "$bad_match" ]]; then
        ok "$f does NOT reference /etc/idleleo/nginx/sbin/nginx (executable lines)"
    else
        bad "$f does NOT reference /etc/idleleo/nginx/sbin/nginx (found: $bad_match)"
    fi
done

# ----------------------------------------------------------------
# Section 4: UUIDv5_tranc requires an argument
# ----------------------------------------------------------------
echo ""
echo "--- Section 4: UUIDv5_tranc signature ---"
# install.sh: UUIDv5_tranc() body contains `[[ $# = 0 ]] && return` on the line after the function definition.
# Allow newline between function name and the empty-arg guard.
if awk '/^UUIDv5_tranc\(\)/{found=1} found && /\[\[ \$# = 0 \]\] && return/{print "found"; exit}' "${INSTALL_SH}" | grep -q found; then
    ok "UUIDv5_tranc requires an argument (returns on empty)"
else
    bad "UUIDv5_tranc requires an argument (returns on empty)"
fi

# Skill templates must NOT call UUIDv5_tranc with no argument
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_not_grep_in_file 'UUIDv5_tranc\)' "$f" \
        "$f does NOT call UUIDv5_tranc with no argument"
    assert_grep_in_file 'UUIDv5_tranc "[^"]+"' "$f" \
        "$f passes an argument to UUIDv5_tranc"
done

# ----------------------------------------------------------------
# Section 5: generate_random_port requires min/max
# ----------------------------------------------------------------
echo ""
echo "--- Section 5: generate_random_port signature ---"
assert_grep_in_file 'generate_random_port\(\)[^}]*local min="\$1"|local max="\$2"' "${INSTALL_SH}" \
    "generate_random_port requires min and max arguments"

# Skill templates must NOT call generate_random_port with no argument
for f in "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_not_grep_in_file 'generate_random_port\)' "$f" \
        "$f does NOT call generate_random_port with no argument"
    assert_grep_in_file 'generate_random_port [0-9]+ [0-9]+' "$f" \
        "$f passes min/max to generate_random_port"
done

# ----------------------------------------------------------------
# Section 6: transport_mode valid values
# ----------------------------------------------------------------
echo ""
echo "--- Section 6: transport_mode values ---"
# install.sh should NOT have transport_mode="all" anywhere
assert_not_grep_in_file 'transport_mode="all"' "${INSTALL_SH}" \
    "install.sh does NOT use transport_mode=\"all\""

# install.sh should support the documented values
for val in onlyws onlygRPC onlyxhttp wsxhttp wsgRPCxhttp; do
    assert_grep_in_file "transport_mode=\"${val}\"" "${INSTALL_SH}" \
        "install.sh supports transport_mode=\"${val}\""
done

# Skill docs must NOT claim "all" is a valid value
for f in "${SKILL_REPO_ROOT}/references/modes.md" "${SKILL_REPO_ROOT}/SKILL.md" \
         "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_not_grep_in_file 'transport_mode="all"|TRANSPORT_MODE="all"|transport_mode.*`all`' "$f" \
        "$f does NOT claim \"all\" is a valid transport_mode"
done

# ----------------------------------------------------------------
# Section 7: Variable name contract (inbound ports / paths / Reality keys)
# ----------------------------------------------------------------
echo ""
echo "--- Section 7: Variable name contract ---"
# install.sh should use xport/gport/xhttpport (NOT ws_port/grpc_port/xhttp_port)
assert_grep_in_file '\bxport=' "${INSTALL_SH}" "install.sh uses xport (ws inbound port)"
assert_grep_in_file '\bgport=' "${INSTALL_SH}" "install.sh uses gport (gRPC inbound port)"
assert_grep_in_file '\bxhttpport=' "${INSTALL_SH}" "install.sh uses xhttpport (xHTTP inbound port)"

# install.sh should use path/serviceName/xhttppath (NOT ws_path/grpc_path/xhttp_path)
assert_grep_in_file '\bserviceName=' "${INSTALL_SH}" "install.sh uses serviceName (gRPC path)"
assert_grep_in_file '\bxhttppath=' "${INSTALL_SH}" "install.sh uses xhttppath (xHTTP path)"

# install.sh should use privateKey/password (Reality keys), NOT private_key/public_key
assert_grep_in_file '\bprivateKey=' "${INSTALL_SH}" "install.sh uses privateKey (camelCase)"
assert_grep_in_file '\bpassword=.*parse_reality_public_key|password=\$\(parse_reality_public_key' "${INSTALL_SH}" \
    "install.sh uses password (holds public key)"
# install.sh may have a local `private_key` alias in compat helpers (e.g. ensure_reality_public_key),
# but the canonical config variable written to JSON is privateKey. We only verify that privateKey
# is present (above). The Skill templates must NOT use private_key/public_key at all (checked below).

# Skill templates must use the correct variable names
for f in "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_grep_in_file '\bxport=' "$f" "$f uses xport"
    assert_grep_in_file '\bgport=' "$f" "$f uses gport"
    assert_grep_in_file '\bxhttpport=' "$f" "$f uses xhttpport"
    assert_grep_in_file '\bpath=' "$f" "$f uses path (ws path)"
    assert_grep_in_file '\bserviceName=' "$f" "$f uses serviceName (gRPC path)"
    assert_grep_in_file '\bxhttppath=' "$f" "$f uses xhttppath"
    assert_not_grep_in_file '\bws_port=' "$f" "$f does NOT use ws_port"
    assert_not_grep_in_file '\bgrpc_port=' "$f" "$f does NOT use grpc_port"
    assert_not_grep_in_file '\bxhttp_port=' "$f" "$f does NOT use xhttp_port"
    assert_not_grep_in_file '\bws_path=' "$f" "$f does NOT use ws_path"
    assert_not_grep_in_file '\bgrpc_path=' "$f" "$f does NOT use grpc_path"
    assert_not_grep_in_file '\bxhttp_path=' "$f" "$f does NOT use xhttp_path"
done

for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh"; do
    assert_grep_in_file '\bprivateKey=' "$f" "$f uses privateKey (camelCase)"
    assert_grep_in_file '\bpassword=' "$f" "$f uses password (holds public key)"
    assert_grep_in_file 'parse_reality_public_key' "$f" "$f uses parse_reality_public_key helper"
    assert_not_grep_in_file '\bprivate_key=' "$f" "$f does NOT use private_key"
    assert_not_grep_in_file '\bpublic_key=' "$f" "$f does NOT use public_key"
done

# ----------------------------------------------------------------
# Section 8: _TEST_MODE mechanism
# ----------------------------------------------------------------
echo ""
echo "--- Section 8: _TEST_MODE mechanism ---"
assert_grep_in_file '_TEST_MODE' "${INSTALL_SH}" "install.sh has _TEST_MODE mechanism"
assert_grep_in_file '\[\[ "\$\{_TEST_MODE:-0\}" == "1" \]\] && return 0' "${INSTALL_SH}" \
    "_TEST_MODE=1 returns early (skips main menu)"

# ----------------------------------------------------------------
# Section 9: ip_check variable contract
# ----------------------------------------------------------------
echo ""
echo "--- Section 9: ip_check variable contract ---"
# install.sh ip_check sets local_ip and ip_version (NOT IP)
assert_grep_in_file 'local_ip=' "${INSTALL_SH}" "install.sh uses local_ip"
assert_grep_in_file 'ip_version=' "${INSTALL_SH}" "install.sh uses ip_version"

# Skill templates must NOT set IP= in ip_check override (should set local_ip/ip_version)
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    assert_grep_in_file 'local_ip=' "$f" "$f sets local_ip in ip_check"
    assert_grep_in_file 'ip_version=' "$f" "$f sets ip_version in ip_check"
done

# ----------------------------------------------------------------
# Section 10: Shell syntax check on templates
# ----------------------------------------------------------------
echo ""
echo "--- Section 10: Shell syntax check ---"
for f in "${SKILL_REPO_ROOT}/assets/setup-reality.sh" "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
    if bash -n "$f" 2>/dev/null; then
        ok "bash -n $(basename "$f")"
    else
        bad "bash -n $(basename "$f") (syntax error)"
    fi
done

# ----------------------------------------------------------------
# Section 11: parse_reality_public_key helper exists
# ----------------------------------------------------------------
echo ""
echo "--- Section 11: parse_reality_public_key helper ---"
assert_grep_in_file 'parse_reality_public_key\(\)' "${INSTALL_SH}" \
    "install.sh defines parse_reality_public_key helper"

# ----------------------------------------------------------------
# Section 12: JSON field contract and parseability (Task D, Section 8.4)
# Verify that JSON field names used by update_json_config in install.sh
# are consistent with Skill template documentation, and that a mock
# install_config.json with those fields parses with jq.
# ----------------------------------------------------------------
echo ""
echo "--- Section 12: JSON field contract and parseability ---"

# 12a. install.sh uses these JSON field names in update_json_config calls
#      Fields can be passed via --arg (string) or --argjson (number/null).
_JSON_FIELDS=("port" "ws_port" "grpc_port" "xhttp_port" "path" "serviceName"
              "privateKey" "publicKey" "serverNames" "target"
              "uuid" "shell_version" "xray_version")
for _field in "${_JSON_FIELDS[@]}"; do
    if grep -qE -- "--arg(json)?[[:space:]]+${_field}[[:space:]]" "${INSTALL_SH}" 2>/dev/null; then
        ok "install.sh update_json_config uses field: ${_field}"
    else
        bad "install.sh update_json_config missing field: ${_field} (grep --arg(json) ${_field} in ${INSTALL_SH})"
    fi
done

# 12b. Skill templates reference the same JSON field names in their documentation
#      (modes.md and setup-*.sh must mention at least port/ws_port/grpc_port/xhttp_port)
for _field in "port" "ws_port" "grpc_port" "xhttp_port"; do
    _found=0
    for _f in "${SKILL_REPO_ROOT}/references/modes.md" \
              "${SKILL_REPO_ROOT}/assets/setup-reality.sh" \
              "${SKILL_REPO_ROOT}/assets/setup-tls.sh"; do
        if grep -qE -- "\\b${_field}\\b" "$_f" 2>/dev/null; then
            _found=1
            break
        fi
    done
    if [[ ${_found} -eq 1 ]]; then
        ok "Skill references JSON field: ${_field}"
    else
        bad "Skill does not reference JSON field: ${_field}"
    fi
done

# 12c. Construct a mock install_config.json with the contract fields and verify jq parses it
_MOCK_JSON=$(mktemp)
cat > "${_MOCK_JSON}" <<'EOF'
{
  "shell_version": "3.0.0",
  "xray_version": "25.12.8",
  "host": "example.com",
  "domain": "example.com",
  "port": 443,
  "ws_port": 10001,
  "grpc_port": 10002,
  "xhttp_port": 10003,
  "path": "/ws",
  "serviceName": "grpc-service",
  "xhttppath": "/xhttp",
  "uuid": "test-uuid-string",
  "privateKey": "test-private-key",
  "publicKey": "test-public-key",
  "password": "test-password",
  "shortIds": "abcdef12",
  "serverNames": "www.example.com",
  "target": "www.example.com"
}
EOF
if command -v jq >/dev/null 2>&1; then
    if jq empty "${_MOCK_JSON}" >/dev/null 2>&1; then
        ok "Mock install_config.json is valid JSON (jq empty)"
    else
        bad "Mock install_config.json failed jq empty validation"
    fi
    # 12d. Verify key fields are non-empty and non-null
    _null_count=$(jq '[paths(scalars) as $p | select(getpath($p) == null or getpath($p) == "")] | length' "${_MOCK_JSON}" 2>/dev/null || echo 1)
    if [[ "${_null_count}" == "0" ]]; then
        ok "Mock install_config.json has no null/empty values"
    else
        bad "Mock install_config.json has ${_null_count} null/empty values"
    fi
    # 12e. Verify specific field types (port must be number)
    _port_type=$(jq -r '.port | type' "${_MOCK_JSON}" 2>/dev/null || echo "")
    if [[ "${_port_type}" == "number" ]]; then
        ok "Mock install_config.json port field is number type"
    else
        bad "Mock install_config.json port field should be number, got ${_port_type}"
    fi
else
    skip "jq not available — skipping JSON parse validation"
fi
rm -f "${_MOCK_JSON}"

# ----------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------
if [[ "${FETCHED:-0}" == "1" ]]; then
    rm -f "${INSTALL_SH}"
fi

echo ""
echo "============================================================"
echo "  Contract Test Summary"
echo "============================================================"
echo "  PASS: ${PASS}"
echo "  FAIL: ${FAIL}"
echo "  SKIP: ${SKIP}"
echo "============================================================"

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
exit 0
