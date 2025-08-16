# vios-autoconfig

Shell script toolkit to automate VIOS operations (vSCSI, NPIV, SEA) via HMC CLI and viosvrcmd.

## Prerequisites
- Bash shell with SSH client
- Access to an HMC with privileges to run VIOS commands
- `viosvrcmd` available on the HMC
- Network connectivity to target VIOS partitions

## Quickstart
1. Copy `.env.example` to `.env` and edit values for your environment:
   ```bash
   cp .env.example .env
   $EDITOR .env
   ```
2. Dry-run a script to review the commands it would execute:
   ```bash
   scripts/create_vscsi.sh app-lpar --dry-run
   ```
3. Apply changes by setting `APPLY=1`:
   ```bash
   APPLY=1 scripts/create_vscsi.sh app-lpar
   ```

## Safety notes and rollback
- Scripts are idempotent; markers in `/var/tmp/vios-autoconfig` prevent duplicates.
- No devices are removed unless explicitly coded and confirmed.
- Review output before applying and use standard VIOS tools to undo changes if necessary.

## Known limitations
- No SAN zoning or LUN provisioning.
- SEA high availability is not covered.
- Focuses on basic mappings; advanced networking/storage features are out of scope.
