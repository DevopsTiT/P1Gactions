# PagerDuty AI Slack Confluence Page

## Decision tree

```
Need Confluence page from seq 4 guide?
 → use 14-pagerduty-ai-agent-slack-confluence.wiki
 Paste: Confluence → Insert → Markup → Confluence Wiki → paste → Insert
 Cloud editor that prefers Markdown?
 → use 14-pagerduty-ai-agent-slack-confluence.md (clean paste)
 After paste: set page title, labels (pagerduty, slack, ai), watchers
```

## Short takeaway

| File | Use when |
|---|---|
| `14-pagerduty-ai-agent-slack-confluence.wiki` | Classic Confluence wiki markup paste (recommended) |
| `14-pagerduty-ai-agent-slack-confluence.md` | Confluence Cloud markdown paste / import |
| Source | `../4-pagerduty-ai-agent-slack-instructions/4-pagerduty-ai-agent-slack-instructions.md` |

## Summary

Confluence-ready copies of the PagerDuty AI on Slack instructions. Prefer the `.wiki` file with Insert → Markup → Confluence Wiki. Git one-liners and local CursorFiles paths were removed from the page body.

## Investigation

### How to publish

1. Open Confluence → Create page (or Edit).  
2. **Insert → Markup → Confluence Wiki**.  
3. Paste the full contents of `14-pagerduty-ai-agent-slack-confluence.wiki`.  
4. Insert → set title: **PagerDuty AI Agent on Slack**.  
5. Add labels: `pagerduty`, `slack`, `ai`, `on-call`.  
6. Review tables and info/warning panels.  
7. Publish.

If Markup is unavailable, paste `14-pagerduty-ai-agent-slack-confluence.md` into the editor and fix tables manually.

## Result

| Done | Evidence |
|---|---|
| Wiki pasted | Info/warning macros and tables render |
| Title set | Page name matches |
| Labels set | Searchable |

## Data flow map

```
seq 4 markdown
  → .wiki (Confluence Wiki markup)
  → Insert Markup in Confluence
  → published page
```

## Related files

| File | Purpose |
|---|---|
| `14-pagerduty-ai-agent-slack-confluence.wiki` | **Paste this into Confluence** |
| `14-pagerduty-ai-agent-slack-confluence.md` | Markdown alternate |
| `14-pagerduty-ai-slack-confluence-page.md` | This how-to |
| `../4-pagerduty-ai-agent-slack-instructions/` | Original guide |
| `14.sh` | Git one-liners (not run) |

## Commands

See `14.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/14-pagerduty-ai-slack-confluence-page
git commit -m "pagerduty ai slack confluence page ready"
git push
```
