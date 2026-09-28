#!/usr/bin/env bash
# linux-hardening-audit — READ-ONLY posture check for a Linux host.
#
# It only reads state and reports PASS/WARN/FAIL. It changes NOTHING.
# Run it, read the findings, then decide what to fix yourself.
#
# Usage:  ./audit.sh
# Exit:   0 if no FAILs, 1 if any FAIL.
set -u

pass=0; warn=0; fail=0
ok()   { printf '  [ PASS ] %s\n' "$1"; pass=$((pass+1)); }
wn()   { printf '  [ WARN ] %s\n' "$1"; warn=$((warn+1)); }
bad()  { printf '  [ FAIL ] %s\n' "$1"; fail=$((fail+1)); }
section() { printf '\n== %s ==\n' "$1"; }

sshd="/etc/ssh/sshd_config"
sshd_get() { [ -r "$sshd" ] && grep -iE "^[[:space:]]*$1[[:space:]]+" "$sshd" | tail -1 | awk '{print $2}'; }

section "SSH daemon"
if [ -r "$sshd" ]; then
  v=$(sshd_get PermitRootLogin);  [ "${v,,}" = "no" ] && ok "PermitRootLogin no" || wn "PermitRootLogin is '${v:-default}' (prefer no)"
  v=$(sshd_get PasswordAuthentication); [ "${v,,}" = "no" ] && ok "PasswordAuthentication no (keys only)" || wn "PasswordAuthentication '${v:-default}' (prefer no, use keys)"
  v=$(sshd_get PermitEmptyPasswords);   [ "${v,,}" = "no" ] || [ -z "$v" ] && ok "PermitEmptyPasswords not enabled" || bad "PermitEmptyPasswords is '$v'"
  v=$(sshd_get X11Forwarding); [ "${v,,}" = "no" ] && ok "X11Forwarding no" || wn "X11Forwarding '${v:-default}' (disable if unused)"
else
  wn "sshd_config not readable here (skipping SSH checks)"
fi

section "Firewall"
if command -v ufw >/dev/null 2>&1; then
  ufw status 2>/dev/null | grep -qi "Status: active" && ok "ufw is active" || wn "ufw present but inactive"
elif command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --state 2>/dev/null | grep -qi running && ok "firewalld running" || wn "firewalld present but not running"
elif command -v nft >/dev/null 2>&1 && [ -n "$(nft list ruleset 2>/dev/null)" ]; then
  ok "nftables ruleset present"
else
  wn "no active firewall detected (ufw/firewalld/nft)"
fi

section "Automatic updates"
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ] && grep -q '"1"' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null; then
  ok "unattended-upgrades configured"
elif systemctl is-enabled --quiet dnf-automatic.timer 2>/dev/null; then
  ok "dnf-automatic enabled"
else
  wn "automatic security updates not detected"
fi

section "Accounts & passwords"
empty=$(awk -F: '($2==""){print $1}' /etc/shadow 2>/dev/null)
if [ -r /etc/shadow ]; then
  [ -z "$empty" ] && ok "no accounts with empty passwords" || bad "empty password(s): $empty"
else
  wn "/etc/shadow not readable (run with sudo for this check)"
fi
uid0=$(awk -F: '($3==0){print $1}' /etc/passwd)
[ "$uid0" = "root" ] && ok "only root has UID 0" || bad "extra UID 0 account(s): $uid0"

section "World-writable & SUID hotspots (sample)"
ww=$(find /etc /usr/bin /usr/sbin -xdev -type f -perm -0002 2>/dev/null | head -5)
[ -z "$ww" ] && ok "no world-writable files in scanned system dirs" || wn "world-writable files found (review): $(echo "$ww" | tr '\n' ' ')"

printf '\n== Summary ==\n  PASS=%d  WARN=%d  FAIL=%d\n' "$pass" "$warn" "$fail"
[ "$fail" -eq 0 ] && exit 0 || exit 1
