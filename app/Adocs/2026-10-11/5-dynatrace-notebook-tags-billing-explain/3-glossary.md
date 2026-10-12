# Dynatrace Notebook Tags And Billing Glossary

| Term | What it means | Why you care |
|---|---|---|
| Default fields | The few fields an entity fetch returns without fieldsAdd. | tags is not one of them. |
| fieldsAdd | Adds more fields to the rows. | Needed to load tags. |
| Tag | A label like [AWS]global:env:Preprod. | Exact text matters. |
| List field | A field with many values. | == against one text never matches. |
| in(value, list) | True if the value is in the list. | Correct way to test a tag list. |
| dt.system.events | Dynatrace internal events. | Holds billing records. |
| BILLING_USAGE_EVENT | One record of billed usage. | Source of the billing charts. |
| Infrastructure Monitoring | Host-only monitoring mode. | Billed in host-hours. |
| Host-hour | One host monitored for one hour. | 720 per host means on all 30 days. |
| dedup | Keeps one copy per key. | Stops double counting of billing events. |
| makeTimeseries | Builds a time series from records. | Draws the per-day bars. |
| usage.start | Start time of the billed usage. | Puts usage on the right day. |
