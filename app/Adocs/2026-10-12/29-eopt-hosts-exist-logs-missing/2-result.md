# eopt Hosts Exist Logs Missing Result

| Step | Action |
|---|---|
| 1 | Run queries A to E to rule out other field names. |
| 2 | If found, send fields so the detector filter can be rewritten. |
| 3 | If not found, ask the platform team for the log module or S3 forwarding. |
| 4 | Keep the Splunk alert running until logs reach Dynatrace. |
| 5 | Optional: run query F and consider a failed-request alert as a stopgap. |
