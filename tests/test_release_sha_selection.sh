#!/usr/bin/env bash
# Release SHA selection regression for explicit historical XRAY_VERSION values.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf '  PASS: %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1"; }

run_case() {
    local template="$1" requested="$2" expected="$3" want_sums="$4"
    local resolver api_json output
    resolver=$(mktemp)
    trap 'rm -f "${resolver}"' RETURN
    sed -n '62,85p' "${ROOT}/${template}" >"${resolver}"
    cat >>"${resolver}" <<'EOF'
printf '%s|%s|%s\n' "$XRAY_VERSION" "$EXPECTED_SHA256" "${SUMS_URL:-}"
EOF
    api_json='{"shell_online_version":"3.2.4","shell_release_sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}'
    export api_json
    curl() {
        local url=""
        for arg in "$@"; do
            [[ "$arg" == http://* || "$arg" == https://* ]] && url="$arg"
        done
        case "$url" in
            *xray_shell_versions.json) printf '%s' "$api_json" ;;
            */v3.2.3/SHA256SUMS) printf '%s  install.sh\n' bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb ;;
            *) return 22 ;;
        esac
    }
    export -f curl
    if output=$(XRAY_VERSION="$requested" bash "$resolver" 2>&1); then
        IFS='|' read -r actual_version actual_sha actual_sums <<<"$output"
        [[ "$actual_version" == "$requested" && "$actual_sha" == "$expected" ]] || {
            bad "$template v${requested} selected ${actual_version}/${actual_sha}"
            return
        }
        if [[ "$want_sums" == yes && "$actual_sums" == *"/v3.2.3/SHA256SUMS" ]]; then
            ok "$template explicit v${requested} uses its Release SHA256SUMS"
        elif [[ "$want_sums" == no && -z "$actual_sums" ]]; then
            ok "$template current v${requested} uses API release SHA"
        else
            bad "$template v${requested} used unexpected SHA source: ${actual_sums}"
        fi
    else
        bad "$template v${requested} resolver failed: ${output}"
    fi
}

for template in assets/setup-reality.sh assets/setup-tls.sh; do
    run_case "$template" 3.2.3 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb yes
    run_case "$template" 3.2.4 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa no
done

printf '\nSummary: PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
