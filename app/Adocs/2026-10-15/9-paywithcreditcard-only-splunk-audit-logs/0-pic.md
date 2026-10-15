# PayWithCreditCard Only Splunk Audit Logs Pic

```
Step 1 = 3 rows → log.source /app/splunk/... → Splunk's own search logs
 → not app logs → Step 2 and 3 = 0 is correct → onboarding
```

```
portals-amp → S3 → Splunk (68)
            ✗ Dynatrace
Splunk servers (OneAgent) → their own search logs → Dynatrace (3 rows)
```
