# Result

Use this slide as the architecture page. It is the standing picture. The incident sample stays on the data-flow slide.

| Line | What it means |
|---|---|
| event | A detector sends the critical event to PagerDuty. |
| page | PagerDuty reaches Primary. |
| notify | The Teams channel monitoring-2026-prod is told. |
| call / SMS | BAM-India receives the 24x7 page. |
| prompt | Primary asks PagerDuty AI Assistant. |
| edit | The draft cause is replaced, and the PIR becomes final. |
| file | Primary files the ServiceNow or Silva correlation. |
