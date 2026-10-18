# DT SILVA PD Ops Umbrella Confluence

## Decision tree

```
Need umbrella Confluence (detection + apps + runbooks)?
 → paste 6-dt-silva-pd-ops-umbrella.wiki
 Also publish child pages: S0 (seq 4) + S2 (seq 5)
 Title: Dynatrace SILVA PagerDuty Operations Umbrella
 Labels: dynatrace, silva, pagerduty, runbooks, workflows
```

## Short takeaway

| File | Use when |
|---|---|
| `6-dt-silva-pd-ops-umbrella.wiki` | **Paste this** (parent page) |
| `6-dt-silva-pd-ops-umbrella.md` | Markdown alternate |
| Children | seq 4 S0 wiki + seq 5 S2 wiki |

## Summary

Umbrella Confluence page: when Davis detection starts, which apps own each step, S0/S2 start conditions, and a catalog of related instructions/runbooks (OPEN/CLOSE, DT AI, PagerDuty AI).

## Investigation

### How to publish

1. Create parent page from `6-dt-silva-pd-ops-umbrella.wiki`.
2. Create/link child pages from seq 4 and seq 5 wikis.
3. Labels: `dynatrace`, `silva`, `pagerduty`, `runbooks`, `workflows`, `on-call`.
4. In Confluence, add page tree / related links between umbrella ↔ S0 ↔ S2.

## Result

| Done | Evidence |
|---|---|
| Umbrella live | Detection + apps + runbook table visible |
| Children linked | S0 and S2 reachable from umbrella |

## Data flow map

```
seq 6 umbrella wiki
  → Confluence parent
  → links to S0 + S2 + optional AI/PD AI pages
```

## Related files

| File | Purpose |
|---|---|
| `6-dt-silva-pd-ops-umbrella.wiki` | **Paste** |
| `6-dt-silva-pd-ops-umbrella.md` | Markdown alternate |
| `6-dt-silva-pd-ops-umbrella-confluence.md` | This how-to |
| `../4-s0-preview-post-silva-pd-confluence/` | OPEN child |
| `../5-s2-close-silva-pd-confluence/` | CLOSE child |
| `6.sh` | Git one-liners (not run) |

## Commands

See `6.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-19/6-dt-silva-pd-ops-umbrella-confluence
git commit -m "dynatrace silva pagerduty ops umbrella confluence"
git push
```
