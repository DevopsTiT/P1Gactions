# EIP ND Mode Null Investigation

| What I checked | What I found |
|---|---|
| Description | Fire when there are no ND Mode entries for 10 minutes. |
| Filter | OR of `ACTIVEMQMODE!=X` terms, which only means "the field has a value". |
| Pipeline | timechart span=10m, then stats count, which always gives 1 row. |
| Trigger | Results > 1, which can never be true. |
| Time range | Last 1 minute, not 10. |
| Action | Email, priority High. |
