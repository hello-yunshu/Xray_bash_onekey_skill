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
| Email | auto | `email_set` | `email="auto@generated"` |
| UUID | auto | `UUID_set` | `UUID="$(UUIDv5_tranc)"` |
| Target | www.microsoft.com | `target_set` | `target="www.microsoft.com"` |
| ServerNames | target domain | `serverNames_set` | `serverNames="${target}"` |
| Private Key | auto (xray x25519) | `keys_set` | Must call `${xray_bin_dir}/xray x25519` |
| Short ID | auto (openssl) | `shortIds_set` | Must call `openssl rand -hex 8` |

### Optional Parameters
| Parameter | Default | Interactive Function | Notes |
|-----------|---------|---------------------|-------|
| Add ws/gRPC | No | `xray_reality_add_more_choose` | Adds Nginx + ws/gRPC transport |
| Add Nginx | No | `reality_nginx_add_fq` | Only if add_more chosen |
| Load balance | No | `reality_balance_add_fq` | Only if add_more chosen |

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
  ├── email_set               ← override: set email
  ├── UUID_set                ← override: set UUID
  ├── target_set              ← override: set target
  ├── serverNames_set         ← override: set serverNames
  ├── keys_set                ← ⚠️ MUST still call xray x25519
  ├── shortIds_set            ← ⚠️ MUST still call openssl rand
  ├── xray_reality_add_more_choose  ← override: set add_more choice
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
| Domain | (required) | `domain_check` | `domain="example.com"` |
| Port | 443 | `port_set` | `port="443"` |
| Email | auto | `email_set` | `email="auto@generated"` |
| UUID | auto | `UUID_set` | `UUID="$(UUIDv5_tranc)"` |
| Transport mode | all | `transport_choose` | `transport_mode="all"` / `"onlyws"` / `"onlygRPC"` / `"onlyxhttp"` |

### Transport-Specific Parameters
| Transport | Port Function | Path Function | Default Port | Default Path |
|-----------|--------------|---------------|-------------|-------------|
| WebSocket | `ws_inbound_port_set` | `ws_path_set` | auto | auto |
| gRPC | `grpc_inbound_port_set` | `grpc_path_set` | auto | auto |
| xHTTP | `xhttp_inbound_port_set` | `xhttp_path_set` | auto | auto |

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
  ├── email_set               ← override: set email
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
| Email | auto | `email="auto@generated"` |
| UUID | auto | `UUID="$(UUIDv5_tranc)"` |

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
  ├── email_set
  ├── UUID_set
  ├── transport_qr            ← ❌ DO NOT override
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

Used by `transport_choose` override:

| Value | Protocols Enabled | Nginx Upstreams |
|-------|------------------|-----------------|
| `all` | ws + gRPC + xHTTP | All 3 upstream blocks |
| `onlyws` | ws only | ws upstream only |
| `onlygRPC` | gRPC only | gRPC upstream only |
| `onlyxhttp` | xHTTP only | xHTTP upstream only |

## Key Variables Reference

Variables that override functions must set (read from install.sh source to verify):

| Variable | Set By | Used By |
|----------|--------|---------|
| `old_config_status` | `old_config_exist_check` override | Multiple functions |
| `IP` | `ip_check` override | Config generation |
| `port` | `port_set` override | Xray + Nginx config |
| `email` | `email_set` override | acme.sh certificate |
| `UUID` | `UUID_set` override | Xray config |
| `target` | `target_set` override | Reality config |
| `serverNames` | `serverNames_set` override | Reality config |
| `transport_mode` | `transport_choose` override | Xray + Nginx config |
| `ws_port` / `grpc_port` / `xhttp_port` | Port set overrides | Xray config |
| `ws_path` / `grpc_path` / `xhttp_path` | Path set overrides | Xray + Nginx config |
