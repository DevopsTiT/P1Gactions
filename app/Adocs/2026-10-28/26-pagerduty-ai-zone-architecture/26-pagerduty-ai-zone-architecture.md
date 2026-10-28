# PagerDuty AI Zone Architecture

```
Architecture page, zone style
  left → signal sources AXA already runs
  middle → PagerDuty cloud, with the AI box inside it
  right → Teams war room, Primary, BAM-India
  below → ServiceNow / Silva and the final PIR
  copy the APM boxes onto this slide? → no
```

| Key point | Detail |
|---|---|
| File | 26-pagerduty-ai-zone-architecture.pptx |
| How to read it | Left to right, the same way as the APM architecture page. |
| New box | PagerDuty AI Assistant, inside the PagerDuty cloud. |
| Sign-in | Microsoft Entra ID, SAML 2.0, and MFA. The IdP sits outside that cloud. |

## Summary

The slide is a zone picture for the war-room assist. Detectors send an event to PagerDuty. PagerDuty pages people and runs the assistant. The Teams channel is where Primary asks and checks the reply.

## Investigation

| Source | Finding |
|---|---|
| Example page | Confluence “00. Architecture.” Zones, a platform in the middle, HTTPS on the lines, and a yellow constraint note. |
| What this picture is | The 24x7 PagerDuty path. It does not reuse the APM account, WAF, or MultiSoft boxes. |
| Region | Confirm the PagerDuty service region with the account owner. The APM Singapore layout is a different system. |

## Result

Open the pptx. Point at zone 1, then zone 2, then zone 3, then the two records along the bottom.

## Data flow map

```
[Signal sources]
    --HTTPS event-->
[PagerDuty cloud]
    incident, call, SMS, escalation
    [PagerDuty AI Assistant]
         summary, causes, status, Scribe
    --notify / call-->
[Teams monitoring-2026-prod]
    Primary asks and checks
    BAM-India receives the page
    --file--> [ServiceNow / Silva]
    --edit--> [Final PIR]
```

## Related files

| File | What it is |
|---|---|
| 26-pagerduty-ai-zone-architecture.pptx | The slide. |
| 26-pagerduty-ai-zone-architecture-follow.txt | The same zones in text. |
| 0-pic.md | The picture. |
| 1-investigation.md | What was checked. |
| 2-result.md | How to present it. |
| 3-glossary.md | The zone names. |
| 26.sh | Copy commands. Run them yourself. |
