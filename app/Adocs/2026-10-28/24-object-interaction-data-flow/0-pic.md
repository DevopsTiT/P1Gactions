# Picture

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
