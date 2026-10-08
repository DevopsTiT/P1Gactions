# Job Status MyAXA UL Email Copy Glossary

| Term | What it means | Why you care |
|---|---|---|
| 複製 | Japanese for "copy". Splunk adds it when an alert is cloned. | It usually marks a test or personal copy. |
| CHDE010M | The Control-M batch that creates MyAXA UL data. | Both alerts watch it. |
| odate | Control-M order date (yyMMdd here). | The check looks at yesterday's order date. |
| Ended OK | Control-M status for a successful run. | Anything else means 要確認. |
| Notification route | The Dynatrace setting that decides who gets a problem. | Recipients are added here, not in the detector. |
| enabled = false | Terraform creates the detector but it never runs. | Keeps the copy on file without duplicate problems. |
