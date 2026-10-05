# OpenPaaS Splunk Alerts Pic

```
7 Splunk alerts → 5 detectors (Terraform only)
  egress IPs absent    → BELOW 1, 15 of 15 minutes, High
  Emma BE timeout ×3   → merged, rolling 5-min sum > 20, High
  PIS ESG120           → > 0, Normal
  eopt backend         → parse ISO8601 + level, > 0, Normal
  eopt frontend        → parse JSON level, > 0, Normal
  CONFIRM index/sourcetype mapping (check.dql 1)
  no workflows → no email; _Normal would page via standard flow → decide
```
