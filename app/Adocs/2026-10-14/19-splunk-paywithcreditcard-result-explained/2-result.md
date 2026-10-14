# Splunk PayWithCreditCard Result

| Item | Result |
|---|---|
| Meaning of the screen | 75 completed credit-card payment calls in the last hour. Healthy. |
| DQL fix | Use `contains(msg_url, "...")` for #23–#27, #83–#85. |
| DQL fix for #82 | Use `endsWith(msg_url, "/save")` and similar. |
| Source filter | `startsWith(src, "portals-amp-backend-")`. |
| Open risk | Logs come via S3. Run the check query to confirm they are in Dynatrace. |
