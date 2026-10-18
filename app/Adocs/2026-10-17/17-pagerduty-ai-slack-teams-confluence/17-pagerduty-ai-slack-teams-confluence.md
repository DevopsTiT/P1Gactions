# PagerDuty AI Slack Teams Confluence

## Decision tree

```
Need Confluence page from seq 15 guide?
 → use 17-pagerduty-ai-on-slack-or-teams.wiki
 Paste: Confluence → Insert → Markup → Confluence Wiki → paste → Insert
 Cloud editor that prefers Markdown?
 → use 17-pagerduty-ai-on-slack-or-teams.md (clean paste)
 After paste: set page title, labels (pagerduty, slack, teams, ai), watchers
```

## Short takeaway

| File | Use when |
|---|---|
| `17-pagerduty-ai-on-slack-or-teams.wiki` | Classic Confluence wiki markup paste (recommended) |
| `17-pagerduty-ai-on-slack-or-teams.md` | Confluence Cloud markdown paste / import |
| Source | `../15-pagerduty-ai-slack-teams-steps/15-pagerduty-ai-slack-teams-steps.md` |

## Summary

Confluence-ready copies of the PagerDuty AI on Slack or Teams step list (seq 15). Prefer the `.wiki` file with Insert → Markup → Confluence Wiki. Local CursorFiles paths and git one-liners were removed from the page body.

## Investigation

### How to publish

1. Open Confluence → Create page (or Edit).
2. **Insert → Markup → Confluence Wiki**.
3. Paste the full contents of `17-pagerduty-ai-on-slack-or-teams.wiki`.
4. Insert → set title: **PagerDuty AI on Slack or Teams**.
5. Add labels: `pagerduty`, `slack`, `teams`, `ai`, `on-call`.
6. Review tables and info/warning panels.
7. Publish.

If Markup is unavailable, paste `17-pagerduty-ai-on-slack-or-teams.md` into the editor and fix tables manually.

## Result

| Done | Evidence |
|---|---|
| Wiki pasted | Info/warning macros and tables render |
| Title set | Page name matches |
| Labels set | Searchable |

## Data flow map

```
seq 15 markdown
  → .wiki (Confluence Wiki markup)
  → Insert Markup in Confluence
  → published page
```

## Related files

| File | Purpose |
|---|---|
| `17-pagerduty-ai-on-slack-or-teams.wiki` | **Paste this into Confluence** |
| `17-pagerduty-ai-on-slack-or-teams.md` | Markdown alternate |
| `17-pagerduty-ai-slack-teams-confluence.md` | This how-to |
| `../15-pagerduty-ai-slack-teams-steps/` | Original step list |
| `../14-pagerduty-ai-slack-confluence-page/` | Slack-only Confluence (seq 4) |
| `17.sh` | Git one-liners (not run) |

## Commands

See `17.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/17-pagerduty-ai-slack-teams-confluence
git commit -m "pagerduty ai slack teams confluence page ready"
git push
```
