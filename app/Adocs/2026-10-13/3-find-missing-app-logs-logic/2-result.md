# Find Missing App Logs Logic Result

| Verdict | eopt is not onboarded to the Dynatrace log forwarder. |
|---|---|

## Reuse for any app

| Replace | With |
|---|---|
| "eopt" | Your app name or prefix. |
| eopt-prod-axa-li-jp | Your namespace. |
| multilogforwarder-log-handler-dynatrace | The path found in step 4. |

## Common mistakes

| Mistake | Why it misleads |
|---|---|
| Trusting the host page | A host entity does not mean logs exist. |
| Searching only host.name | k8s logs often keep the pod name in k8s.pod.name. |
| 1 hour window | Quiet apps may log nothing in 1 hour. |
| Reading scanned bytes as data size | Grail skips blocks that cannot match. |
| Matching Splunk text | Hits can come from Splunk's own logs. |
