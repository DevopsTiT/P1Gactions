# Dynatrace PagerDuty Four Agents PPT

## Decision tree

```
Need ARB-style PPT for Dynatrace + 4 agents?
  Open the .pptx below
  Story = Dynatrace detect → PagerDuty page → Advance agents assist
  Four agents = SRE · Scribe · Shift · Insights
  Regenerate?
    Edit 13_generate_four_agents_pptx.py → run with python-pptx venv
  Want Teams-only click steps too?
    Pair with Daily Files seq 6 / 11 (Teams-only) and seq 7 (Event Orchestration)
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | ARB-style widescreen PPT for **Dynatrace → PagerDuty Four AI Agents** |
| File | `13-Dynatrace-PagerDuty-Four-AI-Agents-ARB-style.pptx` |
| Slides | 12 slides: summary, AS-IS/TO-BE, E2E flow, each agent, enablement, POC plan |
| Design | Same navy ARB-like style as the P260120F Splunk→Dynatrace deck |
| Important | The four agents are **PagerDuty Advance** agents; Dynatrace is the **detect/ingress** source |

---

## Summary

A 12-slide deck tells the story: Dynatrace finds the problem, PagerDuty pages someone, and four Advance agents cut triage/notes/coverage/analytics toil. Style matches the earlier ARB working PPT (navy headers, Key Message bars, tables, AS-IS/TO-BE). Safe demos always use a test Service.

---

## Main content

### Slide list

| # | Slide | Content |
| --- | --- | --- |
| 1 | Title | Dynatrace → PagerDuty Four AI Agents |
| 2 | Summary Sheet | WHY, design overview, cost model, safety |
| 3 | Which agent? | Job → SRE / Scribe / Shift / Insights |
| 4 | AS-IS | Dynatrace → PD → human toil |
| 5 | TO-BE | Same path + four agents beside the human |
| 6 | E2E data flow | Detect → Notify → Page → Assist → Resolve → Learn |
| 7 | Four agents matrix | Surfaces, AI Actions, Teams-only honesty |
| 8 | SRE Agent | Triage surfaces, POC story, limits |
| 9 | Scribe Agent | Meeting join steps and caps |
| 10 | Shift + Insights | Coverage Path B; Insights Q&A vs Slack DMs |
| 11 | Enablement / cost / safety | Advance, Graph, Dynatrace test keys |
| 12 | POC afternoon + open items | Run order and gaps |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../13-dynatrace-pagerduty-four-agents-ppt/13-Dynatrace-PagerDuty-Four-AI-Agents-ARB-style.pptx` | Main PPT |
| `13_generate_four_agents_pptx.py` | Regenerator |
| Adocs twin | `app/Adocs/2026-08-31/13-dynatrace-pagerduty-four-agents-ppt/` |
| python-pptx venv | Reuse `.../11-axa-arb-splunk-dynatrace-ppt/.venv` (do not git-commit venv) |

### Related knowledge

| Topic | Daily Files |
| --- | --- |
| Four agents detailed | `2026-08-25/8-pagerduty-ai-agents-detailed/` |
| Teams-only POC | `2026-08-25/11-...` and `2026-08-31/6-...` |
| Event Orchestration (noise before agents) | `2026-08-31/7-pagerduty-event-orchestration-poc/` |
| Splunk→Dynatrace ARB PPT style twin | `2026-08-31/11-axa-arb-splunk-dynatrace-ppt/` |

---

## Data flow map

```
[Dynatrace Problem]
   → [PagerDuty Incident] (+ optional Event Orchestration)
   → [Page human]
   → [Advance: SRE / Scribe / Shift / Insights]
   → [Human confirms]
   → [Resolve → SRE memory / Insights later]

[Generator]
   13_generate_four_agents_pptx.py + python-pptx
   → 13-Dynatrace-PagerDuty-Four-AI-Agents-ARB-style.pptx
```

---

## Related files

| File | Purpose |
| --- | --- |
| [13.sh](./13.sh) | Open PPT / regenerate one-liners |
| [13-dynatrace-pagerduty-four-agents-ppt-follow.txt](./13-dynatrace-pagerduty-four-agents-ppt-follow.txt) | Chat-ready note |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/13-dynatrace-pagerduty-four-agents-ppt/` |

---

## Commands

See [13.sh](./13.sh). Review and run yourself.
