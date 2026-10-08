# EIP ND Mode Null Glossary

| Term | What it means | Why you care |
|---|---|---|
| ND Mode | EIP status log showing the ActiveMQ mode | The alert watches that this log keeps arriving |
| ACTIVEMQMODE | Field with the mode letter (A, B, C, D, S, P) | Entries without it count as NULL |
| Absence alert | Alert that fires when expected data is missing | Needs a query that returns a row even when nothing matched |
| countIf | Counts only rows that match a condition | Lets the count be 0 instead of no row |
| summarize without by | Always returns exactly one row | Makes `filter event_count == 0` work |
| Number of Results | Splunk trigger that counts result rows, not events | Why the Splunk alert never fires |
| Records detector | Each returned row is a violation | One row when count is 0 means one problem |
