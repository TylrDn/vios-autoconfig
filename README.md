# vios-autoconfig

`vios-autoconfig` is a shell script toolkit for automating Virtual I/O Server (VIOS)
configuration tasks such as vSCSI, NPIV and Shared Ethernet Adapter (SEA).
The toolkit wraps the HMC CLI (`ssh`) and `viosvrcmd` to provide safe,
repeatable operations with clear dry‑run support.

## Directory layout

| Path | Description |
|------|-------------|
| `lib/` | Shared shell utilities (environment loading, logging, SSH helpers) |
| `scripts/` | Operational logic for vSCSI, NPIV, SEA and more |
| `maps/` | User-supplied mapping files consumed by scripts |
| `tests/` | Automated tests using [bats-core](https://bats-core.readthedocs.io) |
| `extensions/` | Optional plugin hooks auto-discovered by `vios-auto.sh` |

## Environment configuration

Scripts read configuration from a `.env` file in the project root.  See
[`.env.example`](./.env.example) for the full list of variables and their
meaning.  Copy and edit the example:

```bash
cp .env.example .env
chmod 600 .env      # required for security
$EDITOR .env
```

If `.env` is absent you will be prompted for credentials at runtime.

## Usage

The `vios-auto.sh` wrapper dispatches subcommands and provides standard flags:

```bash
# Preview operations for an LPAR
./vios-auto.sh create-vscsi --dry-run --target app-lpar

# Apply changes, skipping interactive confirmation
./vios-auto.sh create-vscsi --target app-lpar --yes
```

Most subcommands accept additional options; invoke `--help` on any command for
usage details.

## Safety and idempotency

- All scripts execute with `set -euo pipefail`.
- Commands default to dry‑run mode; nothing changes until explicitly confirmed.
- Idempotency markers in `${TMPDIR:-/var/tmp}/vios-autoconfig-*` prevent repeated work
  unless `--force` is supplied.
- Logging uses INFO/WARN/ERROR levels and masks credentials.

## Testing

Tests are located in `tests/` and executed via `bats`:

```bash
bats tests
```

## Contributing

Issues and pull requests are welcome.  Please run `shellcheck` and the full test
suite before submitting changes.  Continuous integration is provided via
GitHub Actions (`.github/workflows/ci.yaml`).

## CI / Tests

Run developer checks with `make`:

```bash
make fmt       # formatting check
make lint      # shellcheck and gitleaks
make test      # run bats tests with mocks
```

Use `make fmt-write` to apply formatting. CI executes `make lint test` on pushes and pull requests.
