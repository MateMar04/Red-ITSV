# AGENTS.md

## Repo purpose
This repository contains network infrastructure artifacts for ITSV, including:
- MikroTik router/export scripts in `Fase1/`
- Pi-hole deployment and persisted data in `Pi-hole/`
- Project documentation and diagrams in `PresentacionDeProyecto/` and `docs/`

## General working rules
- Prefer minimal, targeted changes. Do not reorganize folders unless explicitly requested.
- Preserve Spanish language in documentation unless the user asks for another language.
- Keep existing filenames and network naming conventions unless there is a clear reason to change them.
- When changing documentation, keep operational steps concrete and easy to execute by an infrastructure admin.
- Call out security-sensitive findings clearly, especially around credentials, certificates, firewall rules, DNS, DHCP, VPN, and exposed services.

## Directory guidance
### `Fase1/`
- Treat `.rsc` files as RouterOS configuration artifacts.
- Preserve RouterOS command syntax and ordering where possible.
- Avoid cosmetic rewrites of exports; change only the commands relevant to the task.
- Flag risky networking changes that could affect addressing, NAT, firewall behavior, VLANs, or remote access.

### `Pi-hole/`
- Treat `docker-compose.yml` as the source of service configuration.
- Assume files under `Pi-hole/etc-pihole/` may contain live state, backups, secrets, certificates, and databases.
- Do not delete or regenerate persisted Pi-hole data unless the user explicitly asks.
- Redact or warn about plaintext secrets if they appear in diffs or docs.

### `PresentacionDeProyecto/` and `docs/`
- Prefer Markdown for documentation updates.
- Keep high-level planning documents aligned with the current technical artifacts in the repo.
- Preserve existing project terminology such as phases, labs, VLANs, and device names.

## Validation
- For documentation-only changes, proofread for consistency and command accuracy.
- For RouterOS or Docker changes, validate syntax as far as possible without applying changes to live systems.
- Do not assume this repo has automated tests; verify with focused checks when relevant.

## Safety
- Never assume IPs, passwords, certificates, or exported configs are disposable.
- Highlight any discovered hardcoded secret and recommend rotation when appropriate.
- Avoid destructive actions on generated backups, databases, leases, or certificates unless explicitly requested.
