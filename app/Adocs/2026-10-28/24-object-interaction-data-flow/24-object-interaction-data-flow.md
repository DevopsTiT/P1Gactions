# Object Interaction Data Flow

```
Data flow page
  use the object map → yes
  sample ids → P-88421 and INC-48291
  who is paged → Primary
  who is notified → Teams channel monitoring-2026-prod
  who prompts → Primary
  reply objects → summary, causes, status, Scribe wrap-up
  before publish → Primary replaces the draft cause with confirmed evidence
```

| Key point | Detail |
|---|---|
| File | 24-object-interaction-data-flow.pptx |
| Picture | The object interaction map, drawn as boxes and labeled lines. |
| Sample | INC-48291 and Dynatrace problem P-88421. Not a live ticket. |
| Red dot | Primary, the on-call employee. |

## Summary

The data-flow slide now follows the object interaction map. Dynatrace feeds PagerDuty. PagerDuty pages Primary and notifies the Teams channel. Primary prompts the assistant, fact-checks the reply, then escalates or resolves. The PIR draft is edited into the final PIR only after the draft cause is replaced with confirmed evidence.

## Investigation

| Source | Finding |
|---|---|
| Map on the screen | Dynatrace problem, PagerDuty incident, Primary, Teams channel, assistant, four reply objects, fact-check, PIR edit. |
| Line above the map | Primary replaces the root-cause draft with confirmed evidence before the PIR is published. |
| Ids | P-88421 and INC-48291 stay sample ids. |

## Result

Open the pptx and read it from the top. The five line labels are page, notify, prompt, fact-check, and edit.

## Data flow map

```
[Dynatrace Problem P-88421]
        |
        v
[PagerDuty INC-48291] --page--> [Primary]
        |
        +--notify--> [Teams: monitoring-2026-prod]
        |
        v
[Primary] --prompt--> [PagerDuty AI Assistant]
        |
        v
[summary] [causes] [status] [Scribe wrap-up]
        |
        v
[Primary] --fact-check--> [escalate or resolve]
        |
        v
[PIR draft object] --edit--> [Final PIR]
```

## Related files

| File | What it is |
|---|---|
| 24-object-interaction-data-flow.pptx | The slide. |
| 24-object-interaction-data-flow-follow.txt | The same map in text. |
| 0-pic.md | The map. |
| 1-investigation.md | What was checked. |
| 2-result.md | How to read the slide. |
| 3-glossary.md | The five line labels. |
| 24.sh | Copy commands. Run them yourself. |
