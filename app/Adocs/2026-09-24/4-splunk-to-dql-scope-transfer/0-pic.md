# Pic — Splunk vs DQL scope

```
Splunk index (wide)
  → "error" + message filters
  → many rows

DQL with only …-prod log group (narrow)
  → same text filters
  → few rows

Transfer:
  discover log groups for cs-digital-document-management
  → widen scope
  → then apply error / exclude
```
