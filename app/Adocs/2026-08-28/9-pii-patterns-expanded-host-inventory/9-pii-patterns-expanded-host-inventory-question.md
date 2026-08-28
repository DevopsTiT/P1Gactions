# Question — Seq 9

**Date:** 2026-08-28  
**Time:** ~14:17 UTC+9

## User question (verbatim)

> how to filter if any pii in these info, and what are these pii , patren?

## Context

User attached an expanded Excel/inventory screenshot with more production hosts (26 visible rows). Includes APP and DB hosts for ETL, UDM, Load Runner, Filenet, additional Customer MDM, and database servers.

## Deliverable requested

1. Decision tree: which app → what PII → which pattern → discovery DQL → mask
2. Per-application table: App name | Host(s) | PII types | Example field names/patterns | Risk tier
3. Pattern reference table (Japanese names, My Number, email, phone, EMPLID, insurance fields from seq 7, DB SQL, ETL, Load Runner, Filenet)
4. Discovery DQL (Logs and Events Advanced — not Data explorer)
5. How to filter/mask after discovery (OneAgent + OpenPipeline) scoped by host.name
6. DB hosts note: SQL with PII, bind variables
7. Link seq 5, 6, 7, 8

## Related prior sequences

- Seq 5: Dynatrace PII host group masking
- Seq 6: DQL search PII discovery
- Seq 7: Insurance PII keywords from Excel
- Seq 8: DQL wrong UI (Data explorer fix)
