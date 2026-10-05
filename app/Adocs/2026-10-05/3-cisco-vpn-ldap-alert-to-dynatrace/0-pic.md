# Cisco VPN LDAP Alert Pic

```
Splunk:    every 1m → search networksyslog cisco:asa "Windows_LDAP as FAILED" (last 1m) → results > 3 → Critical, PD, email
Dynatrace: logs in Grail → DQL count per 1m → threshold Above 3 → problem → workflow → SILVA, PD, email

logs found in Grail?         no  → fix network syslog ingest
                             yes → note bucket and fields
volume small?                    → Anomaly Detection on log DQL
volume huge?                     → OpenPipeline counter metric + alert
ASA has no AGO tags              → set SILVA group and PD severity in workflow
test                             → threshold 0 temporarily, or 4 synthetic lines in 1 minute
```
