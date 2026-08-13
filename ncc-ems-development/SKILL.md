---
name: ncc-ems-development
description: Use for NCC/NCCloud EMS modules — BMF metadata, generated Java, React index.js, page templates, custom references, Action/Authorize XML, Oracle tables, app/permission registration, approval flows, .do requests.
---

# NCC EMS Development

Evidence first: source tree, deployed files, runtime payloads, DB schema are facts. Never guess a file or line.

## Workflow

1. Locate module/app/page/bill/field from real files (`rg --files`, `rg -n`).
2. Trace change across metadata → template → frontend → backend → config → deploy → DB.
3. Smallest complete change; preserve file encoding and user edits.
4. Compile/deploy/restart, then test via UI/Network/Apifox. Report verified facts separately from inferences.

## References

- [project-map.md](references/project-map.md) — roots & locating
- [metadata-codegen.md](references/metadata-codegen.md) — BMF / VO / template
- [frontend-development.md](references/frontend-development.md) — index.js / initMeta
- [backend-actions.md](references/backend-actions.md) — .do Action / XML
- [references-autofill.md](references/references-autofill.md) — custom refs / autofill
- [database-map.md](references/database-map.md) — tables & joins
- [deployment-permissions.md](references/deployment-permissions.md) — deploy / menu / permission
- [debugging-playbook.md](references/debugging-playbook.md) — error → evidence
- [oracle-access.md](references/oracle-access.md) — SQLcl (read before any DB command)
- [quality-objection-case.md](references/quality-objection-case.md) + [quality-objection-approval-sync.md](references/quality-objection-approval-sync.md) — QC case & downstream sync
- [approval-picture.md](references/approval-picture.md) — approval-picture fields / suffix / stage / App

## Database policy

Read-only `SELECT` (or `WITH ... SELECT`) only; add a row limit. Any other SQL/PLSQL: show exact command, target schema, impact, rollback, commit strategy and get approval. Never store passwords, tokens, phone numbers, or test PKs.

## Guardrails

- Don't invent line numbers; locate the block first.
- Metadata REF ≠ runtime reference; inspect template + initMeta.
- Don't assume a class is active; verify XML, deployed class, restart.
- Don't filter by display code when backend expects a PK.
- Prefer parameterized SQL; escape legacy builders.
- Don't confuse HTTP 200 with success; check body + DB effect.

## Check

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/check-ncc-module.ps1 -Root 'D:\nccproject' -Module qualityobjection -AppCode 90HA0707
```