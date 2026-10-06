# Investigation

| Checked | Finding |
|---|---|
| Alert name | Prod_Life_Emma_EmmaBETmeoutToESGProduction_High |
| Search | Same as ESG - Emma BE timeout to ESG Production |
| Trigger | > 20, Once, For each result, throttle 60 seconds |
| Actions | Triggered Alerts High, PagerDuty, Send email |
| Backend events | 5 on 10/6 |
| API gateway | EEAA2015, /SYSLOG/APIGW/prod/local4.log |
