---
name: ncc-ems-development
description: Use when developing, extending, diagnosing, deploying, or testing NCC/NCCloud EMS modules involving BMF metadata, generated Java, React index.js, page templates, custom references, Action/Authorize XML, Oracle tables, application registration, permissions, approval flows, or .do requests.
---

# NCC EMS Development

Treat the checked source tree, deployed files, runtime payloads, and database schema as evidence. Never turn an earlier guess into a fact.

## Core workflow

1. Identify module, app code, page code, bill type, field, and expected behavior.
2. Inspect the actual files before naming a file or line. Prefer `rg --files` and `rg -n`.
3. Find a working implementation in the same EMS project and compare every layer.
4. Trace the change across metadata, page template, frontend, backend, configuration, deployment, and database.
5. Verify table names, primary keys, types, `dr`, joins, cardinality, and returned JSON field names.
6. Make the smallest complete change. Preserve generated-file encoding and user changes.
7. Compile or statically check the affected code, deploy required artifacts, restart only the required service, then test through UI/Network/Console or Apifox.
8. Report verified facts separately from inferences.

## Route references

- Project roots and locating files: read [project-map.md](references/project-map.md).
- BMF, generated VO, table creation, and page templates: read [metadata-codegen.md](references/metadata-codegen.md).
- `index.js`, `initMeta`, events, enum/list rendering: read [frontend-development.md](references/frontend-development.md).
- `.do` Action classes and XML registration: read [backend-actions.md](references/backend-actions.md).
- Custom references, filtering, paging, and auto-fill: read [references-autofill.md](references/references-autofill.md).
- Known tables and relationship-validation method: read [database-map.md](references/database-map.md).
- Application/menu/permission/deployment issues: read [deployment-permissions.md](references/deployment-permissions.md).
- Error-to-evidence diagnosis: read [debugging-playbook.md](references/debugging-playbook.md).
- Oracle SQLcl MCP access: read [oracle-access.md](references/oracle-access.md) before any database command.
- Verified quality-objection example: read [quality-objection-case.md](references/quality-objection-case.md).
- Approval auto-generates a downstream bill (quality objection -> supplier deduction): read [quality-objection-approval-sync.md](references/quality-objection-approval-sync.md).
- Approval-stage image uploads, dual React pages, attachment suffix mapping, workflow validation, and patch packaging: read [approval-picture-workflow.md](references/approval-picture-workflow.md).
- DingTalk App approval REST endpoints, field/suffix mapping, and approval-node name resolution: read [dingtalk-app-approval.md](references/dingtalk-app-approval.md).

## Non-negotiable database policy

Execute directly only one read-only `SELECT`, a read-only `WITH ... SELECT`, or read-only connection/schema inspection. Add a sensible row limit for exploratory queries.

Before every other SQL/PLSQL/SQLcl command, show the exact command, saved connection, target schema/objects, expected impact, rollback ability, commit strategy, and risks; then obtain explicit approval for that exact command. Re-ask if any of them changes. Treat ambiguous or multi-statement input as non-read-only.

Never expose or store database passwords, tokens, cookies, personal phone numbers, or test primary keys in this skill or project files.

## Guardrails

- Do not invent line numbers. Locate the current block first and return a clickable absolute path with the current line.
- Do not assume a metadata REF automatically appears as a runtime reference; inspect the page template and `initMeta` override.
- Do not assume a Java class is callable; verify Action XML, Authorize XML, deployed config, compiled class, and restart state.
- Do not filter with a display code when the backend expects a primary key.
- Do not concatenate unchecked request values into SQL. Prefer parameterized project APIs; when maintaining legacy builders, validate and escape input and document residual risk.
- Do not regenerate or overwrite user-modified generated files without checking the diff and obtaining scope confirmation.
- Do not confuse HTTP 200 with business success; inspect response body and database effect.

## Reusable check

Run the read-only checker when locating a module:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/check-ncc-module.ps1 -Root 'D:\nccproject' -Module qualityobjection -AppCode 90HA0707
```

Use its output as leads, then inspect matched files directly.
