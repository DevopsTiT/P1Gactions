# Data Flow Detail PPT

```
Need a detailed data-flow page
  page 1 → eight hops, fields, and the red dot
  page 2 → what SRE, Scribe, Insights, and Shift read and write
  Shift → no hop
  phone number → stays in the PagerDuty notification
```

| Key point | Detail |
|---|---|
| File | 23-pagerduty-ai-data-flow-detail.pptx |
| Page 1 | Eight hops from the detector to ServiceNow / Silva. |
| Page 2 | The four agents, plus one sample walk-through. |
| Red dot | Employee display name, Teams identity, or a name spoken on the bridge. |

## Summary

Page 1 is the path, with the fields on each hop. Page 2 says what each agent reads and what text it writes back to Teams.

## Investigation

| Source | Finding |
|---|---|
| Earlier data-flow slide | Six short boxes. This deck replaces that level of detail. |
| Input page | SRE, Scribe, and Insights have different inputs. Shift is not sent. |
| Sample ids | INC-48291 and P-88421 are examples on page 2. They are not live tickets. |

## Result

Open the pptx. Present page 1 from hop 1 to hop 8. Use page 2 when someone asks what a specific agent receives.

## Data flow map

```
detector
    -> PagerDuty incident
    -> call / SMS to BAM-India
    -> assist reads incident + runbook + red-dot name
    -> Teams question + red-dot identity
    -> bridge audio -> Scribe text
    -> Insights question, only if enabled
    -> text reply
    -> person checks
    -> PagerDuty action
    -> ServiceNow / Silva
```

## Related files

| File | What it is |
|---|---|
| 23-pagerduty-ai-data-flow-detail.pptx | The two pages. |
| 23-data-flow-ppt-detail-follow.txt | The same hops in text. |
| 0-pic.md | The path. |
| 1-investigation.md | What was checked. |
| 2-result.md | How to present the pages. |
| 3-glossary.md | Words on the pages. |
| 23.sh | Copy commands. Run them yourself. |
