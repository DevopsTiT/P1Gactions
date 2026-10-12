# eopt Onboarding Flow Explained Result

| Step | Owner | What |
|---|---|---|
| 1 | You | Send the onboarding request (answer 2). |
| 2 | You, today | Check query 1 on capportalsystemapi to see which field holds the pod name. |
| 3 | Platform team | Add eopt-prod-axa-li-jp to the Dynatrace pipeline. |
| 4 | You | Check query 2 to see eopt lines arrive. |
| 5 | You | If host.name is not the pod name, update alerts 31 and 34 to use k8s.pod.name in a new folder. |
| 6 | You | Compare with Splunk for one day, then retire Splunk eopt alerts. |
