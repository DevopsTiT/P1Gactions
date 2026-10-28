# Result

Use this slide as the data-flow page. Read the objects from top to bottom.

| Line | What happens |
|---|---|
| page | PagerDuty reaches Primary. |
| notify | The Teams channel monitoring-2026-prod is told. |
| prompt | Primary asks PagerDuty AI Assistant. |
| fact-check | Primary checks the reply, then escalates or resolves. |
| edit | Confirmed evidence replaces the draft cause, and the PIR draft becomes the final PIR. |
