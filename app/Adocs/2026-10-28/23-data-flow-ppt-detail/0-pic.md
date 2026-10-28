# Picture

```
Need a detailed data-flow page
  page 1 → eight hops, fields, and the red dot
  page 2 → what SRE, Scribe, Insights, and Shift read and write
  Shift → no hop
  phone number → stays in the PagerDuty notification
```

```
detector
    -> PagerDuty incident
    -> call / SMS to BAM-India
    -> assist reads incident + runbook + red-dot name
    -> Teams question + red-dot identity
    -> bridge audio -> Scribe text
    -> Insights question, only if enabled
    -> text reply
    -> person checks
    -> PagerDuty action
    -> ServiceNow / Silva
```
