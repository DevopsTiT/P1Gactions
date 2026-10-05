# Cisco VPN LDAP Alert Terraform Pic

```
Splunk alert (network*, asa_networksyslog, > 3 per minute, Critical)
  → main.tf: dynatrace_davis_anomaly_detectors
       query     = fetch logs | bucket network* | sourcetype | "Windows_LDAP as FAILED" | count per 1m
       threshold = 3 ABOVE, window 1, violating 1, dealert 5
       event     = CUSTOM_ALERT, same title, alert.severity critical
  → terraform init → plan → apply
  → alert live → problem → workflow → SILVA + PD

no sourcetype field? → sourcetype_filter = ""
other bucket name?   → bucket_pattern = "<name>"
auth error?          → DT_PLATFORM_TOKEN or OAuth client
```
