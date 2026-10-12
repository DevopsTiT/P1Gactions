# eopt Onboarding Flow Explained Investigation

| Block | Example line | Where it stops |
|---|---|---|
| Sibling (capportalsystemapi) | `... ERROR c.a.c.PortalController - timeout calling backend` | Reaches Grail with log.source multilogforwarder-log-handler-dynatrace |
| eopt today | `... ERROR c.a.e.SystemApiService - ESG call failed` | Reaches Splunk via S3. Never reaches Dynatrace. |
| eopt after onboarding | Same line | Reaches Grail. Alert 31 parses level ERROR. Alert 34 handles JSON lines. |
| Open question | host.name on forwarder logs | Node, pod or empty. Check query 1 on a sibling app. |
