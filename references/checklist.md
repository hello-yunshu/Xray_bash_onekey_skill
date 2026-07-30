# Deployment Quality Checklist

Pre-flight and post-flight checklist for AI-driven Xray deployment. All P0 items must pass before reporting success.

## P0 — Must Pass (Blockers)

- [ ] **OS compatibility**: Target is Debian 12+ / Ubuntu 24.04+ / CentOS Stream 10+
- [ ] **Architecture**: x86_64 or aarch64 confirmed
- [ ] **Root access**: Running as root or with sudo
- [ ] **Port availability**: 443 (or chosen port) not in use by other services
- [ ] **Network reachability**: Server can reach GitHub (for downloading install.sh and binaries)
- [ ] **install.sh sourced**: `_TEST_MODE=1` mechanism loads all functions without errors
- [ ] **Interactive functions overridden**: All `read -r` / `read_optimize` functions replaced with non-interactive versions
- [ ] **old_config_status set**: Must be `"off"` to skip old config interactions
- [ ] **keys_set still calls binary**: `xray x25519` must execute to generate Reality key pair
- [ ] **shortIds_set still calls binary**: `openssl rand -hex 8` must execute
- [ ] **transport_qr NOT overridden**: Let it run after setting transport variables
- [ ] **Xray service running**: `systemctl is-active xray` returns `active`
- [ ] **Config file valid**: `/etc/idleleo/conf/xray/config.json` is valid JSON
- [ ] **Connection info readable**: `/etc/idleleo/conf/install_config.json` exists and is parseable (path is `conf/`, NOT `info/`)

## P1 — Should Pass (Important)

- [ ] **Nginx running** (TLS mode): `systemctl is-active nginx` returns `active`
- [ ] **Nginx config valid** (TLS mode): `/usr/local/nginx/sbin/nginx -t` passes
- [ ] **Certificate valid** (TLS mode): `acme.sh` issued certificate, not self-signed
- [ ] **VLESS link generated**: Link format is correct and contains all required fields
- [ ] **Firewall configured**: Chosen port open in iptables/nftables/ufw
- [ ] **BBR enabled**: `sysctl net.ipv4.tcp_congestion_control` shows `bbr` (recommended)
- [ ] **Auto-update enabled**: Crontab entry for auto_update.sh exists
- [ ] **Log rotation configured**: logrotate config for Xray exists

## P2 — Nice to Have (Recommended)

- [ ] **Fail2ban installed** (option 29): Protects against brute force
- [ ] **Traffic blocker configured** (option 31): Geo-based blocking if needed
- [ ] **UUID is auto-generated**: Not a predictable or default value
- [ ] **Port is non-default**: Not using 443 if in a restricted environment
- [ ] **Backup created**: `/etc/idleleo/` backed up after installation
- [ ] **Client guide provided**: User knows which client to use for their platform

## P3 — Optional (Polish)

- [ ] **DNS configured** (TLS mode): A record points to server IP
- [ ] **Multiple users added**: Additional VLESS accounts if needed
- [ ] **Load balancing configured**: Multiple backend servers if applicable
- [ ] **Custom paths set**: Non-default ws/gRPC/xHTTP paths for obscurity

## Common Failure Patterns

| Pattern | Cause | Fix |
|---------|-------|-----|
| install.sh source fails | Network timeout downloading script | Retry, check GitHub access |
| Xray won't start | Port already in use | `ss -tlnp \| grep <port>`, kill conflicting process |
| Nginx SIGSEGV | glibc ABI mismatch on Ubuntu 24.04+ | Use musl-built Nginx binary |
| Certificate fails | DNS not pointing to server | Verify A record, wait for propagation |
| VLESS link invalid | Missing fields in install_config.json | Re-read config, reconstruct link manually |
| Reality handshake fails | Target doesn't support TLS 1.3 + H2 | Use different target (e.g., www.microsoft.com) |
| `keys_set` produces empty keys | xray binary not found | Verify xray_bin_dir path |
| `transport_qr` sets wrong mode | Transport variables not set before calling | Set transport mode before calling install function |
