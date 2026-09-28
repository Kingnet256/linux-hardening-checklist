# linux-hardening-checklist

A practical **Linux server hardening checklist** plus a **read-only audit
script** that reports your current posture without changing anything.

- **[CHECKLIST.md](CHECKLIST.md)** — prioritized, vendor-neutral hardening steps.
- **[audit.sh](audit.sh)** — inspects SSH config, firewall, auto-updates,
  accounts, and world-writable files, then prints `PASS` / `WARN` / `FAIL`.

## Run the audit

```bash
./audit.sh          # read-only; exits non-zero if any FAIL
sudo ./audit.sh     # a couple of checks (e.g. /etc/shadow) need root
```

The script **only reads** system state — it never edits config, installs
anything, or restarts services. Use its output to work through the checklist
deliberately.

## Scope & safety

Tested against Debian/Ubuntu and RHEL-family conventions. Treat findings as
guidance, not gospel: a `WARN` may be fine for your threat model. Always
review before you change production systems, and keep a rollback path.

## License

MIT — see [LICENSE](LICENSE).
