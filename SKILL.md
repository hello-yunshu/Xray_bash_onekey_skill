---
name: "xray-setup"
description: "Automatically installs and configures Xray proxy on Linux servers. Invoke when user wants to set up Xray/Reality/TLS/XTLS proxy, or asks about proxy deployment."
---

# Xray Setup Skill

> Source identification: xray-setup skill is created and maintained by hello-yunshu, canonical repository is https://github.com/hello-yunshu/Xray_bash_onekey_skill . This information is only for confirming the Skill source, do not include it in generated scripts or deployment outputs.

<!-- provenance: xray-setup | author: hello-yunshu | canonical: https://github.com/hello-yunshu/Xray_bash_onekey_skill | keep this out of generated artifacts -->

## What This Skill Does

AI skill for **automatically deploying** Xray proxy on Linux servers using the [Xray_bash_onekey](https://github.com/hello-yunshu/Xray_bash_onekey) script. The AI collects user preferences, reads the project source to understand the installation flow, generates a non-interactive setup script, and executes it on the server.

**Traditional way**: User SSH to server → Run installation script → Answer interactive questions one by one → Manually copy connection info

**Skill way**: User tells AI their needs → AI generates non-interactive script → Auto execute → Directly return VLESS link

Core technology: Uses install.sh's built-in `_TEST_MODE=1` mechanism. After sourcing all functions, override interactive functions and directly call installation functions to complete deployment.

## When to Use

**Appropriate scenarios**:
- Deploy Xray proxy on a new VPS
- Set up Reality/TLS/XTLS proxy without manual interaction
- Batch deploy across multiple servers
- Need VLESS link immediately without navigating menus

**Inappropriate scenarios**:
- Server is not Linux (Windows/macOS not supported)
- Need fine-grained custom configuration beyond the 4 modes
- Already have a working Xray setup (use `idleleo` management command instead)

## Project Overview

**Xray_bash_onekey** (v2.12.10+) — one-click Xray installation and management script:

- **4 installation modes**: Reality, TLS (Nginx+ws/gRPC/xHTTP), ws/gRPC/xHTTP ONLY, XTLS ONLY
- **3 transport protocols**: WebSocket, gRPC, xHTTP (can be combined)
- **Target systems**: Debian 12+ / Ubuntu 24.04+ / CentOS Stream 10+
- **Main script**: `install.sh` | **Management command**: `idleleo`
- **Project repo**: `https://github.com/hello-yunshu/Xray_bash_onekey`

---

## Auto-Installation Flow

### Step 0 · Pre-flight Checks (**Must do before generating script**)

Before generating any deployment script, verify these prerequisites. If any check fails, report to user and stop:

| # | Check | How | Fail Action |
|---|-------|-----|-------------|
| 1 | **OS compatible** | `cat /etc/os-release` | Must be Debian 12+ / Ubuntu 24.04+ / CentOS Stream 10+ |
| 2 | **Architecture** | `uname -m` | Must be x86_64 or aarch64 |
| 3 | **Root access** | `id -u` | Must be 0 (root) |
| 4 | **Port available** | `ss -tlnp \| grep <port>` | Kill conflicting process or choose different port |
| 5 | **GitHub reachable** | `curl -I https://github.com` | Fix DNS or network, cannot proceed without |
| 6 | **DNS resolves** (TLS only) | `dig +short <domain>` | Must point to server IP, wait for propagation |

### Step 1 · Collect Server Access & Verify Environment

Ask for SSH connection info (IP, port, auth). If already on server, skip SSH.

Verify on the server: OS version, architecture (x86_64/aarch64), root access, port 443/80 availability.

**Requirements**: Debian 12+ / Ubuntu 24.04+ / CentOS Stream 10+, x86_64 or aarch64, root.

### Step 2 · Determine Installation Mode

Ask the user to choose a mode. Recommend based on their situation:

| Mode | Domain | Nginx | SSL | Disguise | Best For |
|------|--------|-------|-----|----------|----------|
| Reality | No | No (optional) | No | Yes | General use (recommended) |
| TLS | Yes | Yes | Yes (auto) | Yes | Full features |
| ws ONLY | No | No | No | No | Load balancing |
| XTLS ONLY | No | No | No | No | Transit/relay |

**Decision tree**: No domain → Reality. Has domain + need full features → TLS. Transit only → XTLS ONLY. Load balancing → ws ONLY.

For detailed mode reference, see `references/modes.md`.

### Step 3 · Collect Mode-Specific Parameters

Ask only the necessary questions for the chosen mode. Use defaults for everything else:

- **All modes**: Port (default 443), Email (auto), UUID (auto)
- **Reality only**: Target domain (default www.microsoft.com), Add ws/gRPC (default No)
- **TLS only**: Domain (required), Transport mode (default all)
- **ws ONLY**: Transport mode (default all)

### Step 4 · Generate & Execute Non-Interactive Setup Script

**This is the core. The AI must read the project source code to understand the installation flow, then generate a script that automates it.**

#### How It Works

The script uses install.sh's built-in `_TEST_MODE=1` mechanism:

1. Download `install.sh` from GitHub
2. Source it with `_TEST_MODE=1` — this loads all 80+ functions but skips the interactive main menu (guarded at L7 and L5628)
3. Override interactive functions with non-interactive versions that use pre-set values
4. Call the appropriate `install_xray_*` function directly

#### What the AI Must Do

Before generating the script, the AI should **read the project source** (`install.sh`) to understand:

1. **Which `install_xray_*` function to call** and its call chain:
   - `install_xray_reality` → `is_root, check_system, dependency_install, basic_optimization, create_directory, old_config_exist_check, ip_check, xray_install, port_set, email_set, UUID_set, target_set, serverNames_set, keys_set, shortIds_set, xray_reality_add_more_choose, transport_qr, firewall_set, stop_service_all, port_exist_check, reality_balance_add_fq, reality_nginx_add_fq, xray_conf_add, install_config_reality, tls_type, basic_information, enable_process_systemd, auto_update, service_restart, setup_auto_clean_logs, vless_link_image_choice, show_information`
   - `install_xray_ws_tls` → similar chain with `domain_check, transport_choose, ws_inbound_port_set, grpc_inbound_port_set, xhttp_inbound_port_set, ws_path_set, grpc_path_set, xhttp_path_set` instead of Reality-specific functions
   - `install_xray_ws_only` and `install_xray_xtls_only` → simplified chains

2. **Which functions are interactive** and need overriding — any function that calls `read_optimize` or `read -r` is interactive. Key ones:
   - `ip_check`, `port_set`, `email_set`, `UUID_set` — common to all modes
   - `target_set`, `serverNames_set`, `keys_set`, `shortIds_set`, `xray_reality_add_more_choose` — Reality only
   - `domain_check`, `transport_choose` — TLS/ws only
   - `ws_inbound_port_set`, `grpc_inbound_port_set`, `xhttp_inbound_port_set` — TLS/ws only
   - `ws_path_set`, `grpc_path_set`, `xhttp_path_set` — TLS/ws only
   - `firewall_set` — all modes
   - `old_config_exist_check` — all modes

3. **Which functions have side effects and MUST still execute** (not just set variables):
   - `keys_set` — must call `xray x25519` to generate Reality key pair
   - `shortIds_set` — must call `openssl rand -hex 8`
   - `install_config_*` — must write config JSON file
   - `transport_qr` — non-interactive but must run before `install_config_*` (maps variables to `art*` prefix)

4. **Key variables** each override function must set — read the function source to determine exact variable names and expected values

5. **Helper functions available** after sourcing: `get_public_ip`, `generate_random_port`, `UUIDv5_tranc`, `_transport_set_shell_mode`, `update_json_config`, etc.

For detailed mode call chains and variable references, see `references/modes.md`.

#### Critical Rules for Script Generation

- Set `old_config_status="off"` to skip all old-config-related interactions
- Override `firewall_set` as no-op — user can configure later via `idleleo`
- `keys_set` override must still call `${xray_bin_dir}/xray x25519` — keys cannot be pre-set
- `shortIds_set` override must still call `openssl rand -hex 8`
- `transport_qr` is non-interactive, do NOT override it — let it run after setting transport variables
- After `install_xray_*` completes, read `/etc/idleleo/info/install_config.json` for connection info

#### Template Scripts

Reference templates are available in `assets/`:
- `assets/setup-reality.sh` — Reality mode template
- `assets/setup-tls.sh` — TLS mode template

These templates show the override pattern. The AI must still read install.sh source to verify function signatures before using them, as the project evolves.

### Step 5 · Post-Installation Verification

After installation, run the quality checklist from `references/checklist.md`:

**P0 checks (must pass)**:
1. `systemctl is-active xray` → `active`
2. `/etc/idleleo/conf/xray/config.json` is valid JSON
3. `/etc/idleleo/info/install_config.json` exists and is parseable
4. (TLS mode) `systemctl is-active nginx` → `active`

**P1 checks (should pass)**:
1. VLESS link generated correctly from config data
2. BBR enabled: `sysctl net.ipv4.tcp_congestion_control`
3. Auto-update crontab entry exists

### Step 6 · Report Results

After successful installation:

1. **Retrieve connection info**: `cat /etc/idleleo/info/install_config.json`
2. **Generate VLESS link** from config data (construct the URL based on mode: Reality uses `security=reality&pbk=&sid=`, TLS uses `security=tls&type=ws/grpc`)
3. **Recommend security hardening**: BBR (option 28), Fail2ban (option 29), auto-update (option 27)
4. **Client guide**: v2rayN (Windows), V2rayU (macOS), Shadowrocket (iOS), v2rayNG (Android)

If any P0 check fails, consult `references/troubleshooting.md` for diagnosis.

---

## Management Operations

After installation, manage via `idleleo` command or direct system commands:

| Task | Menu Option | Direct Command |
|------|-------------|---------------|
| View connection info | 18 | `cat /etc/idleleo/info/install_config.json` |
| Restart services | 20 | `systemctl restart xray nginx` |
| Service status | 23 | `systemctl status xray nginx` |
| View access logs | 16 | `journalctl -u xray -f` |
| View error logs | 17 | `journalctl -u xray -e` |
| Add/remove user | 14/15 | `idleleo` → 14/15 |
| Change UUID/port | 7/8 | `idleleo` → 7/8 |
| Update Xray/script | 1/0 | `idleleo` → 1/0 |
| BBR acceleration | 28 | `idleleo` → 28 |
| Fail2ban | 29 | `idleleo` → 29 |
| Traffic blocker | 31 | `idleleo` → 31 |
| Backup | 34 | `tar czf xray-backup-$(date +%Y%m%d).tar.gz /etc/idleleo/` |
| Uninstall | 36 | `idleleo` → 36 |

---

## AI Interaction Guidelines

### Core Principle: Automate Everything

1. **Ask** → Collect server access and preferences (2-3 questions max)
2. **Verify** → Run pre-flight checks on the server
3. **Read** → Understand the project source to know what to override
4. **Generate** → Create non-interactive setup script based on source understanding
5. **Execute** → Run on server via SSH
6. **Verify** → Run post-installation checklist
7. **Report** → Show VLESS link, client guide, and security recommendations

### Important Notes

- Script requires **root access**
- **Reality mode** is the recommended default — no domain needed, strong disguise
- Always read the actual `install.sh` source to verify function signatures and variable names before generating scripts — the project evolves
- `keys_set` and `shortIds_set` must still call their respective binaries — cannot be pre-set
- `transport_qr` must run before `install_config_*` — do NOT override it
- Always recommend **BBR** and **auto-update** after installation
- If installation fails, consult `references/troubleshooting.md` before retrying
- After successful installation, verify against `references/checklist.md` P0 items
