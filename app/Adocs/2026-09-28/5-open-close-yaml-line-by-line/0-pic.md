# Open And Close YAML Reading Map

## Decision tree

```
Which part of the file am I looking at?
 starts with #                → comment, ignored
 metadata:                    → required app version
 trigger:                     → when it runs
 tasks: → <task-name>:        → one box on the canvas
    predecessors              → what must finish first
    conditions / custom / else → run or skip
    script: |                 → JavaScript
       return { ... }         → task result, read later with ex.result("<task-name>")
```

## Data flow

```
OPEN:  Problem opens → prepare-payload (enrich + checks)
                         ├─► post-silva-incident-http  ┐ same time
                         └─► trigger-pagerduty         ┘
                       → add-cross-links (PagerDuty link into the notes, INC into PagerDuty)

CLOSE: Problem closes → prepare-close-ids (duration, close notes, same keys)
                         ├─► resolve-silva-incident-http ┐ same time
                         └─► resolve-pagerduty           ┘
```
