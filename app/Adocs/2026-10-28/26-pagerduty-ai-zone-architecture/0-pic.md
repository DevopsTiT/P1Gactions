# Picture

```
[Signal sources] --HTTPS event--> [PagerDuty cloud]
                                      incident, escalation, call, SMS
                                      [PagerDuty AI Assistant]
                                      summary, causes, status, Scribe
                                 --notify--> [Teams monitoring-2026-prod]
                                 --call-->   [BAM-India]
[Primary] --prompt--> assistant
[Primary] --file--> [ServiceNow / Silva]
[Primary] --edit--> [Final PIR]
```
