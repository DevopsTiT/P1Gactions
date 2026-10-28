# Picture

```
Data Flow slide
  use case → 24x7 critical-incident catch-up in Teams
  personal information? → employee name or Teams identity only
  mark those hops with the red dot
  customer, financial, health fields → leave them off this picture
  paging phone → stays in the PagerDuty notification
  Shift schedule → do not draw it; it is not sent
```

```
detector signal
    -> PagerDuty incident
         🔴 assignee display name
    -> Teams question
         🔴 asker identity
    -> PagerDuty AI
         SRE text
         Scribe audio -> text note (🔴 spoken name)
         Insights question, only if enabled
    -> Teams reply (🔴 if a name is repeated)
    -> person checks
    -> PagerDuty action
    -> ServiceNow / Silva
```
