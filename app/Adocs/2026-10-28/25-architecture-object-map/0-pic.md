# Picture

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
