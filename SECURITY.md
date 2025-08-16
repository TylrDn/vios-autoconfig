# Security Policy

## Supported versions
`main` branch.

## Reporting a vulnerability
Please open a **private** Security advisory in GitHub (Security → Advisories) or email <security@example.com>.
Do not file public issues for security reports.

## Hardening defaults
- CI enforces ShellCheck, shfmt, Bats, Gitleaks, and actionlint.
- `.env` is local-only; never commit secrets. Use SSH keys for HMC access.
- SSH host keys are pinned under `/var/tmp/vios-autoconfig/known_hosts`.

