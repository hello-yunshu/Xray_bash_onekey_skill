# Troubleshooting Reference

Common issues encountered during AI-driven Xray deployment and their solutions.

---

## Pre-Installation Issues

### OS Not Supported
**Symptom**: `check_system` fails or warns about unsupported OS
**Cause**: OS is not Debian 12+ / Ubuntu 24.04+ / CentOS Stream 10+
**Fix**: Upgrade OS or use a compatible VPS provider

### Architecture Not Supported
**Symptom**: Script detects non-x86_64/non-aarch64 architecture
**Cause**: VPS uses uncommon architecture (e.g., ARMv7, MIPS)
**Fix**: Use a VPS with x86_64 or aarch64 architecture

### Not Root
**Symptom**: `is_root` check fails
**Cause**: Running as non-root user
**Fix**: `sudo -i` or `su -` to switch to root

### Port Already in Use
**Symptom**: `port_exist_check` reports port occupied
**Cause**: Another service (web server, another proxy) using the port
**Fix**: `ss -tlnp | grep <port>` to identify, then stop the service or choose a different port

### GitHub Unreachable
**Symptom**: `curl`/`wget` fails to download install.sh or Xray binary
**Cause**: Server in region with GitHub access issues, or DNS failure
**Fix**:
1. Test: `curl -I https://github.com`
2. If DNS issue: `echo "nameserver 8.8.8.8" > /etc/resolv.conf`
3. If network blocked: Use a mirror or proxy for downloads

---

## Installation Issues

### install.sh Source Fails
**Symptom**: `source install.sh` returns errors
**Cause**: Downloaded file is incomplete or corrupted
**Fix**: Re-download with `curl -fsSL`, verify file size, check network

### Xray Binary Not Found
**Symptom**: `xray_bin_dir` path doesn't contain xray binary
**Cause**: Download failed or architecture mismatch
**Fix**: Manually download Xray binary for correct architecture

### Nginx SIGSEGV on Ubuntu 24.04+
**Symptom**: Nginx worker process crashes with segmentation fault
**Cause**: Precompiled Nginx binary (built on Ubuntu 22.04/glibc 2.35) has ABI conflict with glibc 2.39+
**Fix**: Use musl-built Nginx binary (available in newer script versions)

### Certificate Issuance Fails (TLS mode)
**Symptom**: `acme.sh` cannot issue certificate
**Cause**: DNS A record not pointing to server, or port 80 not accessible
**Fix**:
1. Verify DNS: `dig +short example.com` should return server IP
2. Verify port 80: `curl -I http://example.com` from external network
3. Wait for DNS propagation (up to 48 hours for some TLDs)

### Reality Handshake Fails
**Symptom**: Client cannot connect, handshake error
**Cause**: Target domain doesn't support TLS 1.3 + H2
**Fix**: Use a known-compatible target:
- ✅ `www.microsoft.com` (default, recommended)
- ✅ `www.apple.com`
- ✅ `dl.google.com`
- ❌ Avoid targets that don't support TLS 1.3 or H2

### keys_set Produces Empty Keys
**Symptom**: Reality private/public key is empty
**Cause**: `xray x25519` command failed (binary not found or permission issue)
**Fix**: Verify `${xray_bin_dir}/xray` exists and is executable

---

## Post-Installation Issues

### Xray Won't Start
**Symptom**: `systemctl start xray` fails
**Diagnosis**:
1. `journalctl -u xray -e` — check error logs
2. `ss -tlnp | grep <port>` — check port conflict
3. Validate config: `xray run -test -c /etc/idleleo/conf/xray/config.json`
**Common Fixes**:
- Port conflict: Change port or stop conflicting service
- Invalid config: Fix JSON syntax errors
- Permission issue: `chown -R root:root /etc/idleleo/`

### Nginx Won't Start (TLS mode)
**Symptom**: `systemctl start nginx` fails
**Diagnosis**:
1. `/usr/local/nginx/sbin/nginx -t` — test config
2. `journalctl -u nginx -e` — check error logs
**Common Fixes**:
- Config syntax error: Fix nginx config
- Port conflict: Change nginx port
- Missing certificate: Re-issue with acme.sh

### Client Can't Connect
**Symptom**: VLESS client shows connection timeout or refused
**Diagnosis**:
1. Server-side: `systemctl is-active xray nginx` — services running?
2. Server-side: `ss -tlnp | grep <port>` — port listening?
3. Server-side: `iptables -L -n` — firewall blocking?
4. Client-side: Verify VLESS link matches server config exactly
**Common Fixes**:
- Firewall: Open port in iptables/nftables/ufw
- Wrong link: Re-generate VLESS link from install_config.json
- ISP blocking: Try different port (not 443)

### VLESS Link Invalid
**Symptom**: Client rejects the VLESS link
**Cause**: Link format incorrect or missing fields
**Fix**: Reconstruct link from install_config.json:
```bash
cat /etc/idleleo/conf/install_config.json | jq .
```
Then build link manually based on mode (see modes.md for format).

### High Latency / Slow Speed
**Symptom**: Connection works but slow
**Diagnosis**:
1. Check BBR: `sysctl net.ipv4.tcp_congestion_control`
2. Check MTU: `ping -M do -s 1472 <server_ip>`
3. Check server load: `top`, `free -h`
**Fixes**:
- Enable BBR: `idleleo` → option 28
- Adjust MTU if needed
- Upgrade VPS plan

---

## Management Issues

### `idleleo` Command Not Found
**Cause**: Script not properly installed or PATH not updated
**Fix**: Run `source /etc/profile` or re-login SSH

### Auto-Update Not Working
**Cause**: Crontab entry missing or script path wrong
**Fix**:
1. Check: `crontab -l | grep auto_update`
2. Re-enable: `idleleo` → option 27

### Log Files Too Large
**Cause**: No log rotation configured
**Fix**: `idleleo` → option 26 (clean logs), or enable auto-clean

### Can't Add User
**Symptom**: `idleleo` → option 14 fails
**Cause**: Email already exists or Xray config invalid
**Fix**: Use a different email address, or check config validity

---

## Emergency Recovery

### Complete Reset
```bash
idleleo → 36 (uninstall all)
# Then re-install
```

### Backup Before Changes
```bash
tar czf xray-backup-$(date +%Y%m%d).tar.gz /etc/idleleo/
```

### Restore from Backup
```bash
tar xzf xray-backup-YYYYMMDD.tar.gz -C /
systemctl restart xray nginx
```

### Manual Service Control
```bash
systemctl start xray      # Start Xray
systemctl stop xray       # Stop Xray
systemctl restart xray    # Restart Xray
systemctl status xray     # Check status
systemctl start nginx     # Start Nginx (TLS mode)
systemctl stop nginx      # Stop Nginx
systemctl restart nginx   # Restart Nginx
```

### Key File Paths
| Purpose | Path |
|---------|------|
| Xray config | `/etc/idleleo/conf/xray/config.json` |
| Nginx config dir | `/etc/idleleo/conf/nginx/` |
| Install config | `/etc/idleleo/conf/install_config.json` |
| Xray binary | `/usr/local/bin/xray` |
| Nginx binary | `/usr/local/nginx/sbin/nginx` |
| Logs | `/etc/idleleo/logs/` |
| Management command | `idleleo` |
