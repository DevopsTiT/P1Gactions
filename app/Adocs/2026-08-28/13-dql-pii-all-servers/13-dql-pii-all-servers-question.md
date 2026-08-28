# Question — DQL PII All Servers (seq 13)

## User ask

give for all servers

## Context

Extend seq 12 (HATS rawDataList example) and seq 11 (PII dashboard for all host groups) to **all 44 host group IDs** in `unique.sh` (includes HATS + CUSTMDMGM added in seq 12).

## Requirements

1. **Query A-all** — Count HATS-style logs (ProcessNdServiceImpl / HatsProcessResponse / rawDataList) per `dt.host_group.id` across all 44 host groups
2. **Query B-all** — Same filters + drill-down by `host.name`, `log.source`
3. **Query C-all** — rawDataList + Japanese characters per host group (all servers)
4. **Query D-all** — Sample `content`, `limit 10`, optional single-host-group filter
5. **Query E-all** — Combined PII keyword sweep (seq 7 + seq 10 insurance/HULFT regex) per host group — seq 11 Query 1A pattern
6. **Master query** — One query summarizing BOTH keyword PII hits AND rawDataList hits per host group (use `countIf` if supported)
7. **Inventory query** — Log count per host group with no PII filter (confirm all servers send logs)
8. Full `in(dt.host_group.id, { ... })` block with all 44 IDs from `unique.sh`
9. Dual-write seq 13 to CursorFiles + Adocs; update indexes

## Answer

`13-dql-pii-all-servers.md`
