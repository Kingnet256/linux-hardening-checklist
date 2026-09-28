# Linux Server Hardening Checklist

A practical, vendor-neutral checklist for a general-purpose Linux server.
Grouped by priority. Adapt to your distro and threat model — not every item
fits every host. Run [`audit.sh`](audit.sh) first to see where you stand.

## Tier 1 — Do these first
- [ ] Apply all pending security updates; enable **automatic security updates**.
- [ ] SSH: disable root login (`PermitRootLogin no`).
- [ ] SSH: **key-based auth only** (`PasswordAuthentication no`).
- [ ] Enable a **host firewall**; default-deny inbound, allow only needed ports.
- [ ] Ensure **no accounts have empty passwords**; only `root` has UID 0.
- [ ] Create a non-root admin user with `sudo`; stop logging in as root.

## Tier 2 — Strongly recommended
- [ ] SSH: change from default port only as noise reduction (not a real control).
- [ ] Install **fail2ban** (or equivalent) to throttle brute-force attempts.
- [ ] Enforce a strong password/lockout policy (`pam_pwquality`, `pam_faillock`).
- [ ] Disable unused services and remove unneeded packages (shrink attack surface).
- [ ] Enable and keep enforcing **SELinux** or **AppArmor**.
- [ ] Configure **time sync** (chrony/systemd-timesyncd) — logs need accurate time.

## Tier 3 — Logging, integrity, resilience
- [ ] Centralize logs (or at least persist and rotate them); protect from tampering.
- [ ] Enable `auditd` for security-relevant events.
- [ ] File integrity monitoring (AIDE/Tripwire) for critical paths.
- [ ] Restrict `cron`/`at` to authorized users.
- [ ] Review SUID/SGID binaries; remove where unneeded.
- [ ] Encrypt data at rest where appropriate (LUKS).
- [ ] Have tested, **offline** backups and a documented restore procedure.

## Verify, don't assume
Re-run `audit.sh` after changes. Hardening is a loop: measure → change →
re-measure. Document deviations so the next person knows they were intentional.

## References
- CIS Benchmarks — https://www.cisecurity.org/cis-benchmarks
- NIST SP 800-123 (Server Security) — https://csrc.nist.gov/pubs/sp/800/123/final
- ssh-audit — https://github.com/jtesta/ssh-audit
