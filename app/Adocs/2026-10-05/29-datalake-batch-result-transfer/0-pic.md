# Datalake Batch Result Picture

```
Splunk: every line, table, daily 08:00, Today, > 0 → email
 report, not alert → scheduled workflow (not detector)

08:00 JST → query from:now()-8h → lines?
   > 0 → email list
   = 0 → skip
```
