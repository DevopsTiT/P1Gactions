# Architecture Object Map

```
Architecture slide
  style → same object map as the data flow
  new object → PagerDuty AI Assistant
  page → Primary
  notify → Teams monitoring-2026-prod
  call / SMS → BAM-India
  after fact-check → escalate or resolve, final PIR, ServiceNow / Silva
```

| Key point | Detail |
|---|---|
| File | 25-architecture-object-map.pptx |
| Picture | Standing systems, drawn as objects and labeled lines. |
| Only new object | PagerDuty AI Assistant. |
| Red dot | Primary, the on-call employee. |

## Summary

The architecture slide uses the same object style as the data-flow map. Detection feeds PagerDuty. PagerDuty pages Primary, notifies the Teams channel, and calls BAM-India. Primary prompts the assistant, checks the reply, then escalates or resolves, edits the PIR, and files the correlation.

## Investigation

| Source | Finding |
|---|---|
| Object map the user asked to follow | Boxes, a verb on each line, Primary in the path, four reply objects, then the PIR edit. |
| Monitoring picture | BAM-India still receives the 24x7 call and SMS. |
| Teams channel on the map | monitoring-2026-prod. |

## Result

Open the pptx. Read the top row first, then the prompt, then the four reply objects, then the three things Primary does after the fact-check.

## Data flow map

```
[Detection zone] --event--> [PagerDuty]
                                |--page--> [Primary]
                                |--notify--> [Teams: monitoring-2026-prod]
                                |--call/SMS--> [BAM-India]
[Primary] --prompt--> [PagerDuty AI Assistant]
        |
        v
[summary] [causes] [status] [Scribe wrap-up]
        |
        v
[Primary] --fact-check--> [escalate or resolve]
        |--edit--> [Final PIR]
        |--file--> [ServiceNow / Silva]
```

## Related files

| File | What it is |
|---|---|
| 25-architecture-object-map.pptx | The slide. |
| 25-architecture-object-map-follow.txt | The same map in text. |
| 0-pic.md | The map. |
| 1-investigation.md | What was checked. |
| 2-result.md | How to read it. |
| 3-glossary.md | The line labels. |
| 25.sh | Copy commands. Run them yourself. |
