# PagerDuty Four Agents Teams Only POC PPT

## Decision tree

```
Need a detailed PPT from the Teams-only four-agents runbook?
  Open the 20-slide deck below
  Still see AXA / ARB Template footer?
    Wrong file — use seq 17 (this), not older ARB-style decks
  Want the source markdown steps?
    Daily Files 2026-08-25/11-pagerduty-four-agents-teams-only-poc/
  Regenerate after edit?
    Edit 17_generate_teams_only_poc_pptx.py → run with python-pptx venv
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | Detailed **20-slide** PowerPoint of the Teams-only Four Agents POC |
| Source | `2026-08-25/11-pagerduty-four-agents-teams-only-poc/11-pagerduty-four-agents-teams-only-poc.md` |
| File | `17-PagerDuty-Four-Agents-Teams-Only-POC.pptx` |
| Footer | `PagerDuty Four Agents — Teams-Only POC` (no AXA / ARB branding) |
| Covers | Decision tree, §0 enablement, SRE, Scribe, Shift Path A/B, Insights, cost sheet, afternoon plan |

---

## Summary

This deck turns the full Teams-only four-agents POC markdown into a presentation you can walk through with Admins and responders. It keeps the honest Teams gaps (Shift coverage DMs and Insights weekly DMs are Slack-first) and the safe-demo rule (test Service only).

---

## Main content

### Slide map

| # | Slide |
| --- | --- |
| 1 | Title — Teams-Only POC |
| 2 | Agenda |
| 3 | Decision tree — which agent |
| 4 | Shared gate — Advance + Admins |
| 5 | Short takeaway |
| 6 | §0 Prerequisites |
| 7 | §0 Steps 1–5 |
| 8 | §0 Steps 6–10 |
| 9 | §0 Success + Safety + cost |
| 10 | §1 SRE — goal and prerequisites |
| 11 | §1 SRE — click / say steps |
| 12 | §1 SRE — success, safety, cost |
| 13 | §2 Scribe — Teams meeting steps |
| 14 | §2 Scribe — success, safety, cost |
| 15 | §3 Shift — honest Teams status |
| 16 | §3 Shift Path B steps (recommended) |
| 17 | §3 Path A + success / safety |
| 18 | §4 Insights — conversational steps |
| 19 | Insights success + cost / surface cheat sheet |
| 20 | Afternoon plan + data flow + Teams commands |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../17-.../17-PagerDuty-Four-Agents-Teams-Only-POC.pptx` | Open this |
| `17_generate_teams_only_poc_pptx.py` | Regenerator |
| Adocs twin | `app/Adocs/2026-08-31/17-pagerduty-four-agents-teams-only-poc-ppt/` |
| Source md | `2026-08-25/11-pagerduty-four-agents-teams-only-poc/` |

---

## Data flow map

```
Source md (2026-08-25 seq 11)
        |
        v
17_generate_teams_only_poc_pptx.py
        |
        v
17-PagerDuty-Four-Agents-Teams-Only-POC.pptx
  §0 → SRE → Scribe → Shift (Path B) → Insights
```

---

## Related files

| File | Purpose |
| --- | --- |
| [17.sh](./17.sh) | Open / regenerate |
| [17-pagerduty-four-agents-teams-only-poc-ppt-follow.txt](./17-pagerduty-four-agents-teams-only-poc-ppt-follow.txt) | Chat-ready |
| Source runbook | `2026-08-25/11-pagerduty-four-agents-teams-only-poc/` |

---

## Commands

See [17.sh](./17.sh).
