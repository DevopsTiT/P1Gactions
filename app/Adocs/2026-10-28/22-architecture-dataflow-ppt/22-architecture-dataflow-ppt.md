# Architecture And Data Flow PPT

```
Need both pictures in PowerPoint
  architecture → slide 1, zones and a hub
  data flow → slide 2, six steps and three red dots
  open the pptx → notes pane has the words to say
```

| Key point | Detail |
|---|---|
| File | 22-pagerduty-ai-architecture-data-flow.pptx |
| Slide 1 | Proposed Business Architecture. PagerDuty is the hub. The orange box is PagerDuty AI. |
| Slide 2 | Data Flow. The red dot is an employee name, on steps 2, 3, and 5. |
| Notes | Each slide has speaker notes under View → Notes. |

## Summary

The deck has two widescreen slides. Slide 1 is the zone picture. Slide 2 is the same path drawn as data, with the personal-information marks.

## Investigation

| Source | Finding |
|---|---|
| Architecture text | The six boxes, the line labels, and the yellow note from the EIP-style slide. |
| Data flow text | The use case, the three red dots, and the fields that stay off the picture. |
| Layout check | Every shape sits inside a 13.33 by 7.5 inch slide. |

## Result

Open `22-pagerduty-ai-architecture-data-flow.pptx`.

Slide 1 reads left to right. The detection zone sends a critical event to PagerDuty. PagerDuty sends call and SMS to BAM-India, and an escalation into the Teams war room. The orange box inside the war room is PagerDuty AI. ServiceNow and Silva sit under the hub.

Slide 2 reads step 1 to step 6. The red dot sits on the assignee name, the Teams identity, and a spoken name if the note repeats it.

## Data flow map

```
slide 1 boxes
    detection -> PagerDuty -> BAM-India
               -> Teams -> PagerDuty AI
               -> ServiceNow / Silva

slide 2 facts
    detector -> incident + red-dot name
             -> Teams question + red-dot identity
             -> AI text
             -> reply + red dot if a name repeats
             -> person checks -> correlation
```

## Related files

| File | What it is |
|---|---|
| 22-pagerduty-ai-architecture-data-flow.pptx | The PowerPoint. Two slides. |
| 22-architecture-dataflow-ppt-follow.txt | What each slide says. |
| 0-pic.md | The two pictures. |
| 1-investigation.md | What was checked. |
| 2-result.md | How to open the deck. |
| 3-glossary.md | Words on the slides. |
| 22.sh | Copy commands. Run them yourself. |
