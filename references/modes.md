# Installation Modes — Detailed Reference

Comprehensive reference for all 4 Xray installation modes. The AI must understand each mode's requirements, call chain, and interactive functions before generating deployment scripts.

---

## Mode Comparison Matrix

| Feature | Reality | TLS | ws ONLY | XTLS ONLY |
|---------|---------|-----|---------|-----------|
| Domain required | No | Yes | No | No |
| Nginx | Optional | Required | No | No |
| SSL certificate | No | Auto (acme.sh) | No | No |
| Disguise | Yes (target SNI) | Yes (Nginx SNI) | No | No |
| Transport | VLESS+Reality | ws/gRPC/xHTTP | ws/gRPC/xHTTP | VLESS+XTLS |
| Multi-protocol | +ws/gRPC optional | ws+gRPC+xHTTP | ws+gRPC+xHTTP | Single |
| Best for | General use | Full features | Load balancing | Transit/relay |
| Recommended | ⭐ Default | Advanced | Specialized | Specialized |

---

## Mode 1: Reality (Recommended Default)

### When to Use
- No domain available
- Want strongest disguise without SSL
- General personal use
- Quick setup needed

### Decision Tree
```
No domain? → Reality
Has domain + need full features? → TLS
Transit only? → XTLS ONLY
Load balancing? → ws ONLY
```

### Required Parameters
| Parameter | Default | Interactive Function | Override Must Set |
|-----------|---------|---------------------|-------------------|
| Port | 443 | `port_set` | `port="443"` |
| Email | auto | `email_set` | `custom_email="auto@generated"` (variable is `custom_email`, NOT `email`) |
| UUID | auto | `UUID_set` | `UUID5_char="$(head -n 10 /dev/urandom \| md5sum \| head -c ${random_num})"; UUID="$(UUIDv5_tranc "${UUID5_char}")"` |
| Target | www.microsoft.com | `target_set` | `target="www.microsoft.com"` |
| ServerNames | target domain | `serverNames_set` | `serverNames="${target}"` |
| Private Key | auto (xray x25519) | `keys_set` | Must call `${xray_bin_dir}/xray x25519` and set `privateKey` (camelCase) + `password` (NOT public_key) |
| Short ID | auto (openssl) | `shortIds_set` | Must call `openssl rand -hex 8` or `generate_reality_short_id`; sets `shortIds` |

> Contract note (Task D): `UUIDv5_tranc` REQUIRES an argument — `UUIDv5_tranc` with no argument returns immediately and produces an empty UUID. Always pass a random char string. The Reality key output uses `privateKey` (camelCase) and `password` (which holds the public key); `parse_reality_public_key` helper should be used to remain compatible across Xray versions.

### Optional Parameters
| Parameter | Default | Interactive Function | Notes |
|-----------|---------|---------------------|-------|
| Add ws/gRPC | No | `xray_reality_add_more_choose` | Sets `reality_add_more` (NOT `add_more`); sets `transport_mode` (NOT `ws_grpc_mode`) |
| Add Nginx | No | `reality_nginx_add_fq` | Only if `reality_add_more` chosen |
| Load balance | No | `reality_balance_add_fq` | Only if `reality_add_more` chosen |

### Install Function Call Chain
```
install_xray_reality
  ├── is_root
  ├── check_system
  ├── dependency_install
  ├── basic_optimization
  ├── create_directory
  ├── old_config_exist_check  ← override: set old_config_status="off"
  ├── ip_check                ← override: set IP variables
  ├── xray_install
  ├── port_set                ← override: set port
  ├── email_set               ← override: set `custom_email` (NOT `email`)
  ├── UUID_set                ← override: set UUID
  ├── target_set              ← override: set target
  ├── serverNames_set         ← override: set serverNames
  ├── keys_set                ← ⚠️ MUST still call xray x25519
  ├── shortIds_set            ← ⚠️ MUST still call openssl rand
  ├── xray_reality_add_more_choose  ← override: set `reality_add_more` (NOT `add_more`)
  ├── transport_qr            ← ❌ DO NOT override, let it run
  ├── firewall_set            ← override: no-op
  ├── stop_service_all
  ├── port_exist_check
  ├── reality_balance_add_fq  ← conditional
  ├── reality_nginx_add_fq    ← conditional
  ├── xray_conf_add
  ├── install_config_reality
  ├── tls_type
  ├── basic_information
  ├── enable_process_systemd
  ├── auto_update
  ├── service_restart
  ├── setup_auto_clean_logs
  ├── vless_link_image_choice
  └── show_information
```

### VLESS Link Format
```
vless://UUID@IP:PORT?security=reality&pbk=PUBLIC_KEY&sid=SHORT_ID&type=tcp&flow=xtls-rprx-vision&sni=TARGET&fp=chrome#REMARK
```

---

## Mode 2: TLS (Full Features)

### When to Use
- Domain available with DNS pointing to server
- Need WebSocket, gRPC, or xHTTP transport
- Want Nginx reverse proxy with SSL
- Full feature set required

### Required Parameters
| Parameter | Default | Interactive Function | Override Must Set |
|-----------|---------|---------------------|-------------------|
| Domain | (required) | `domain_check` | `domain="example.com"` (also requires `local_ip` to be set by `ip_check` override) |
| Port | 443 | `port_set` | `port="443"` |
| Email | auto | `email_set` | `custom_email="auto@generated"` (variable is `custom_email`, NOT `email`) |
| UUID | auto | `UUID_set` | `UUID5_char="..."; UUID="$(UUIDv5_tranc "${UUID5_char}")"` (requires argument) |
| Transport mode | wsgRPCxhttp | `transport_choose` | `transport_mode="wsgRPCxhttp"` / `"onlyws"` / `"onlygRPC"` / `"onlyxhttp"` / `"wsxhttp"` |

> Contract note (Task D): There is NO `"all"` transport_mode value — use `"wsgRPCxhttp"` for ws+gRPC+xHTTP. Other valid combinations: `onlyws`, `onlygRPC`, `onlyxhttp`, `wsxhttp`. After setting `transport_mode`, call `_transport_set_shell_mode` to update `shell_mode`.

### Transport-Specific Parameters
| Transport | Port Function | Path Function | Port Variable | Path Variable | Default Port Range |
|-----------|--------------|---------------|---------------|---------------|-------------|
| WebSocket | `ws_inbound_port_set` | `ws_path_set` | `xport` | `path` | 10000-10999 |
| gRPC | `grpc_inbound_port_set` | `grpc_path_set` | `gport` | `serviceName` | 10000-10999 |
| xHTTP | `xhttp_inbound_port_set` | `xhttp_path_set` | `xhttpport` | `xhttppath` | 11000-11999 |

> Contract note (Task D): Variable names differ from intuitive names. Use `xport`/`gport`/`xhttpport` (NOT `ws_port`/`grpc_port`/`xhttp_port`). Use `path`/`serviceName`/`xhttppath` (NOT `ws_path`/`grpc_path`/`xhttp_path`). `generate_random_port` REQUIRES min/max arguments.

### Install Function Call Chain
```
install_xray_ws_tls
  ├── is_root
  ├── check_system
  ├── dependency_install
  ├── basic_optimization
  ├── create_directory
  ├── old_config_exist_check  ← override: set old_config_status="off"
  ├── ip_check                ← override: set IP variables
  ├── domain_check            ← override: set domain, verify DNS
  ├── xray_install
  ├── port_set                ← override: set port
  ├── email_set               ← override: set `custom_email` (NOT `email`)
  ├── UUID_set                ← override: set UUID
  ├── transport_choose        ← override: set transport_mode
  ├── ws_inbound_port_set     ← override (if ws enabled)
  ├── grpc_inbound_port_set   ← override (if gRPC enabled)
  ├── xhttp_inbound_port_set  ← override (if xHTTP enabled)
  ├── ws_path_set             ← override (if ws enabled)
  ├── grpc_path_set           ← override (if gRPC enabled)
  ├── xhttp_path_set          ← override (if xHTTP enabled)
  ├── transport_qr            ← ❌ DO NOT override
  ├── firewall_set            ← override: no-op
  ├── stop_service_all
  ├── port_exist_check
  ├── nginx_systemd_file
  ├── nginx_install
  ├── nginx_conf_add
  ├── nginx_servers_add
  ├── nginx_servers_conf_add
  ├── xray_conf_add
  ├── install_config_tls
  ├── tls_type
  ├── basic_information
  ├── enable_process_systemd
  ├── auto_update
  ├── service_restart
  ├── setup_auto_clean_logs
  ├── vless_link_image_choice
  └── show_information
```

### VLESS Link Format (ws example)
```
vless://UUID@DOMAIN:443?security=tls&type=ws&path=WS_PATH&host=DOMAIN#REMARK
```

---

## Mode 3: ws ONLY (Load Balancing)

### When to Use
- No domain, no SSL needed
- Load balancing with Nginx upstream
- Backend server behind a frontend proxy
- Simple WebSocket/gRPC/xHTTP transport

### Required Parameters
Same as TLS mode minus domain_check. Transport mode defaults to `"all"`.

### Install Function Call Chain
```
install_xray_ws_only
  ├── (same as TLS minus domain_check, nginx_*, certificate steps)
  ├── transport_choose        ← override: set transport_mode
  ├── ws/grpc/xhttp port/path overrides
  └── (no Nginx, no SSL)
```

---

## Mode 4: XTLS ONLY (Transit/Relay)

### When to Use
- Transit/relay server
- No need for multiple transports
- Simple VLESS+XTLS direct connection
- Chain proxy setup

### Required Parameters
| Parameter | Default | Override |
|-----------|---------|----------|
| Port | 443 | `port="443"` |
| Email | auto | `custom_email="auto@generated"` (NOT `email`) |
| UUID | auto | `UUID5_char="..."; UUID="$(UUIDv5_tranc "${UUID5_char}")"` (requires argument) |

### Install Function Call Chain
```
install_xray_xtls_only
  ├── is_root
  ├── check_system
  ├── dependency_install
  ├── basic_optimization
  ├── create_directory
  ├── old_config_exist_check
  ├── ip_check
  ├── xray_install
  ├── port_set
  ├── email_set               ← override: set `custom_email` (NOT `email`)
  ├── UUID_set
  ├── transport_qr            ← ❌ DO NOT override, let it run
  ├── firewall_set
  ├── stop_service_all
  ├── port_exist_check
  ├── xray_conf_add
  ├── install_config_xtls_only
  ├── tls_type
  ├── basic_information
  ├── enable_process_systemd
  ├── auto_update
  ├── service_restart
  ├── setup_auto_clean_logs
  ├── vless_link_image_choice
  └── show_information
```

### VLESS Link Format
```
vless://UUID@IP:PORT?security=tls&type=tcp&flow=xtls-rprx-vision#REMARK
```

---

## Transport Mode Values

Used by `transport_choose` override. **There is NO `"all"` value** — use `wsgRPCxhttp` for the previous "all" behaviour:

| Value | Protocols Enabled | Nginx Upstreams |
|-------|------------------|-----------------|
| `onlyws` | ws only | ws upstream only |
| `onlygRPC` | gRPC only | gRPC upstream only |
| `onlyxhttp` | xHTTP only | xHTTP upstream only |
| `wsxhttp` | ws + xHTTP | ws + xHTTP upstreams |
| `wsgRPCxhttp` | ws + gRPC + xHTTP | All 3 upstream blocks |

After setting `transport_mode`, always call `_transport_set_shell_mode` to update `shell_mode` accordingly.

## Key Variables Reference

Variables that override functions must set (read from install.sh source to verify). **Variable names use camelCase and short forms, NOT intuitive snake_case**:

| Variable | Set By | Used By |
|----------|--------|---------|
| `old_config_status` | `old_config_exist_check` override | Multiple functions |
| `local_ip` | `ip_check` override | Config generation (host field for Reality/ws-only/XTLS-only) |
| `ip_version` | `ip_check` override | Config generation |
| `domain` | `domain_check` override | TLS config (host field for TLS mode) |
| `port` | `port_set` override | Xray + Nginx config |
| `custom_email` | `email_set` override | acme.sh certificate (NOT `email`) |
| `UUID` | `UUID_set` override | Xray config (requires `UUIDv5_tranc "<arg>"`) |
| `target` | `target_set` override | Reality config |
| `serverNames` | `serverNames_set` override | Reality config |
| `privateKey` | `keys_set` override | Reality config (camelCase, NOT private_key) |
| `password` | `keys_set` override | Reality config (holds public key, NOT publicKey/public_key) |
| `shortIds` | `shortIds_set` override | Reality config (camelCase) |
| `transport_mode` | `transport_choose` override | Xray + Nginx config |
| `xport` | `ws_inbound_port_set` override | Xray config (NOT ws_port) |
| `gport` | `grpc_inbound_port_set` override | Xray config (NOT grpc_port) |
| `xhttpport` | `xhttp_inbound_port_set` override | Xray config (NOT xhttp_port) |
| `path` | `ws_path_set` override | Xray + Nginx config (NOT ws_path) |
| `serviceName` | `grpc_path_set` override | Xray + Nginx config (NOT grpc_path) |
| `xhttppath` | `xhttp_path_set` override | Xray + Nginx config (NOT xhttp_path) |

## Secret Redaction Contract

> Contract note (P0-D): Templates MUST NOT output secrets to stdout/stderr.

The following variables and files contain secrets and MUST NOT be echoed or catted directly in generated scripts:

| Secret | Variable / Path | Reason |
|--------|-----------------|--------|
| Reality private key | `privateKey` | Server identity — compromise allows impersonation |
| Reality public key | `password` / `publicKey` | Used in VLESS link — compromise allows link reconstruction |
| Reality short ID | `shortIds` | Used in VLESS link — compromise allows link reconstruction |
| User UUID | `UUID` | User identity — compromise allows traffic correlation |
| User email | `custom_email` | PII — used for certificate registration |
| Server IP | `local_ip` | Server location — compromise allows targeting |
| Full config | `/etc/idleleo/conf/install_config.json` | Contains all of the above secrets in JSON |
| Raw logs | `journalctl -u xray -e` | May contain secrets in error messages |

### Safe Output Patterns

Override functions should confirm success WITHOUT echoing the value:

```bash
# ❌ BAD — leaks secret to stdout/logs
echo "  UUID: ${UUID}"
echo "  privateKey: ${privateKey}"
cat /etc/idleleo/conf/install_config.json
journalctl -u xray -e --no-pager

# ✅ GOOD — confirms generation without leaking value
echo "  UUID: generated (value suppressed for safety)"
echo "  Reality keys: generated (values suppressed for safety)"
```

### Safe Diagnostics

When installation fails, use redaction helpers before output:

```bash
# Source redaction helpers from the main repo
source .github/test/redact.sh

# Safe config summary (no secrets)
safe_print_config_summary /etc/idleleo/conf/install_config.json

# Safe log output (vless links, keys, tokens redacted)
journalctl -u xray -e --no-pager | redact_text_for_diagnostics
```

## Key Paths Reference

| Resource | Path |
|----------|------|
| install_config.json | `/etc/idleleo/conf/install_config.json` (NOT `/etc/idleleo/info/`) |
| Xray binary | `/usr/local/bin/xray` (`${xray_bin_dir}/xray`) |
| Xray config | `/etc/idleleo/conf/xray/config.json` (`${xray_conf}`) |
| Nginx binary | `/usr/local/nginx/sbin/nginx` (`${nginx_dir}/sbin/nginx`, NOT `/etc/idleleo/nginx/sbin/`) |
| Nginx config dir | `/etc/idleleo/conf/nginx/` (`${nginx_conf_dir}`) |
| Xray conf dir | `/etc/idleleo/conf/xray/` (`${xray_conf_dir}`) |
| idleleo root | `/etc/idleleo/` (`${idleleo_dir}`) |
| conf root | `/etc/idleleo/conf/` (`${idleleo_conf_dir}`) |
