# FCR NG Audit Trail Filter Investigation

| What I checked | What I found |
|---|---|
| Alert screenshots | Same as seq 25. |
| Raw search | 14,715,642 events, visible ones are audit_trail fingerprint updates by SYSTEM. |
| Splunk | `where isnotnull(job_duration)` drops audit_trail. |
| Dynatrace change | Filter on job_duration and drop audit_trail first. |
