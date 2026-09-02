# Investigation

## What was checked

| Source | What it contributed |
| --- | --- |
| `14-dynatrace-pagerduty-four-agents-architecture.md` | AS-IS/TO-BE, HLD, security, cost, POC criteria |
| `8-pagerduty-ai-agents-detailed.md` | Per-agent surfaces, limits, example prompts, AI Actions |
| Whole PPT seq 19 (42 slides) | Part A narrative, Part B diagrams, Part C Teams runbook |
| Seq 14 page guide (2026-09-02) | Slide-by-slide mapping |

## Key architecture facts confirmed

- Hub object is **PagerDuty Incident**, not Dynatrace Problem
- Dynatrace = **ingress**; SRE connectors are separate observability tools
- Optional **Event Orchestration** before agents for noise
- Teams-only gaps: Shift DM coverage and Insights weekly DMs are **Slack-first**
- Human must approve remediations; SRE memory saves on **Resolve**
