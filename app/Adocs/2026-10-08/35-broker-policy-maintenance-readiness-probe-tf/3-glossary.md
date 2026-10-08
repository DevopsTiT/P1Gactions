# Readiness Probe Glossary

| Term | What it means | Why you care |
|---|---|---|
| Readiness probe | Kubernetes check that decides if a pod may receive traffic | A failing probe removes the pod from the Service |
| /meta/health | The URL the probe calls | Its log lines are what this alert reads |
| statusCode | HTTP response code, 200 means healthy | The alert needs this field to exist |
| head 2 | Splunk keeps only the newest 2 events | Mixes both pods, which causes flapping |
| takeLast | DQL takes the last value after sorting | Gives the newest status per pod |
| Unhealthy event | Kubernetes event when a probe fails | A backup signal if the app does not log statusCode |
