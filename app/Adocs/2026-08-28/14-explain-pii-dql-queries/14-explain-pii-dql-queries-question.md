# Question

**Date:** 2026-08-28  
**Seq:** 14

## User question (verbatim)

> explain about these querys

## Context

Plain-English explanation of ALL DQL queries built in today's PII discovery session (seq 1–13), with focus on the latest all-servers set (seq 13):

- Inventory query
- Master query (countIf columns)
- Query A-all, B-all, C-all, D-all, E-all
- Earlier: seq 12 HATS queries (A-D)
- seq 11 per host group dashboard
- seq 7 insurance keywords
- seq 6 general discovery
- seq 8 wrong UI (Data explorer vs Logs Advanced)

## Deliverable

Explanation only — no new queries unless clarifying examples.

## Structure requested

1. Decision tree — which query when
2. Short takeaway table: Query name | What it does | When to use | What you learn
3. Plain English walkthrough of each query line-by-line (fetch, filter, summarize, sort, limit)
4. Explain countIf, matchesRegex, matchesPhrase, matchesValue, in()
5. Explain difference: keyword PII vs HATS rawDataList vs inventory
6. Workflow diagram (pic style)
7. Common mistakes (wrong UI, regex typo, wrong host group ID)
8. How queries connect: Inventory → Master → drill → sample → mask (seq 5)
