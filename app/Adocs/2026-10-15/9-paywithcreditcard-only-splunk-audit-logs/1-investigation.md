# PayWithCreditCard Only Splunk Audit Logs Investigation

| What was checked | Finding |
|---|---|
| Step 1 rows | 3 rows, all with null k8s fields. |
| Sources | `/app/splunk/var/log/splunk/remote_searches.log` (two Splunk hosts) and `splunkd_ui_access.log` (one host). |
| Meaning | Splunk writes the search text into those files, so they contain "payWithCreditCard_Adj". |
| Step 2 | 0 records. |
| Step 3 | 0 records. |
| Conclusion | portals-amp-backend application logs are not in Dynatrace. |
