# Dynatrace AI Replace PD Confluence

## Decision tree

```
Need Confluence page for DT AI replace PD event path?
 → use 3-dt-ai-replace-pd-event-path.wiki
 Paste: Confluence → Insert → Markup → Confluence Wiki → paste → Insert
 Cloud editor that prefers Markdown?
 → use 3-dt-ai-replace-pd-event-path.md (clean paste)
 After paste: set page title, labels (dynatrace, pagerduty, ai, workflows), watchers
```

## Short takeaway

| File | Use when |
|---|---|
| `3-dt-ai-replace-pd-event-path.wiki` | Classic Confluence wiki markup paste (recommended) |
| `3-dt-ai-replace-pd-event-path.md` | Confluence Cloud markdown paste / import |
| Source | `../1-event-dynatrace-ai-replace-pd-ai/` + `../2-dt-ai-replace-pd-all-files/` |

## Summary

Confluence-ready copies of the Dynatrace AI Assistant event path that replaces PagerDuty AI triage. Prefer the `.wiki` file with Insert → Markup → Confluence Wiki. Local paths, git one-liners, and secrets were removed from the page body.

## Investigation

### How to publish

1. Open Confluence → Create page (or Edit).
2. **Insert → Markup → Confluence Wiki**.
3. Paste the full contents of `3-dt-ai-replace-pd-event-path.wiki`.
4. Set title: **Dynatrace AI Replace PagerDuty AI (Event Path)**.
5. Add labels: `dynatrace`, `pagerduty`, `ai`, `workflows`, `on-call`.
6. Review tables and info/warning panels.
7. Publish.

If Markup is unavailable, paste `3-dt-ai-replace-pd-event-path.md` and fix tables manually.

## Result

| Done | Evidence |
|---|---|
| Wiki pasted | Info/warning macros and tables render |
| Title set | Page name matches |
| Labels set | Searchable |

## Data flow map

```
seq 1 event path + seq 2 bundle
  → .wiki (Confluence Wiki markup)
  → Insert Markup in Confluence
  → published page
```

## Related files

| File | Purpose |
|---|---|
| `3-dt-ai-replace-pd-event-path.wiki` | **Paste this into Confluence** |
| `3-dt-ai-replace-pd-event-path.md` | Markdown alternate |
| `3-dt-ai-replace-pd-confluence.md` | This how-to |
| `../1-event-dynatrace-ai-replace-pd-ai/` | Event-path source |
| `../2-dt-ai-replace-pd-all-files/` | Full file bundle (WF-A/WF-B) |
| `3.sh` | Git one-liners (not run) |

## Commands

See `3.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-18/3-dt-ai-replace-pd-confluence
git commit -m "dynatrace ai replace pd confluence page ready"
git push
```
