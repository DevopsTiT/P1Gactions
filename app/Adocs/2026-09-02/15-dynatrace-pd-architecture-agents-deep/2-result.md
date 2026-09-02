# Result

## What to do with this architecture

1. Wire **Dynatrace → PagerDuty** with problem URL in payload
2. Add **Event Orchestration** if you have alert storms
3. Enable **PagerDuty Advance** + Teams/Slack + four agent toggles
4. POC on **test Service** only — EP pages only you
5. Run agents in order: **SRE → Scribe → Shift (Path B) → Insights**
6. Human always **confirms** remediations and **Resolves** for SRE memory

## Mental model

**Dynatrace = eyes · PagerDuty = pager + incident record · Four agents = assistants after the page**
