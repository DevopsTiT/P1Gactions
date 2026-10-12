# eopt Log Paths In Detail Result

## Fix options

| Option | What changes | Recommended |
|---|---|---|
| Add eopt to the Dynatrace forwarder | One input and pipeline entry | Yes |
| Dynatrace Operator log monitoring | Cluster wide log module | Only if the platform team prefers it |

## After the fix

| Step | Why |
|---|---|
| Query namespace eopt-prod-axa-li-jp | Confirm arrival. |
| Check host.name and k8s.pod.name | Pick the right field for alerts. |
| Adjust alerts 31 and 34 if needed | Use k8s.pod.name prefixes. |
| Compare with Splunk for a day | Trust the counts. |
| Retire Splunk eopt alerts | Only after proof. |
