# Question

**Date:** 2026-08-28  
**Seq:** 15

## User question (verbatim)

Dynatrace DQL error on Master query (seq 13):

> `'by' isn't allowed here` on line with `by: { dt.host_group.id }`

## Context

- Screenshot shows Master query tail (lines 55–64) with multiple `countIf` columns then `by: { dt.host_group.id }`
- Inventory query from the same session **worked** — `log_count` per `dt.host_group.id` (e.g. `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` — 14,506,149)
- UI: Logs and Events → Advanced mode, Simple Mode toggle visible
- Related: seq 13 Master query, seq 14 explain doc

## Deliverable

1. Explain error in plain English (SRE beginner)
2. Corrected full Master query
3. Simpler fallback Master (split into 2 queries if needed)
4. Dual-write CursorFiles + Adocs
