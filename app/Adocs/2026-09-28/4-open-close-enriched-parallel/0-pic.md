# Pic

```
OPEN:  prepare-payload (enrich) → [post-silva-incident-http | trigger-pagerduty] same time → add-cross-links
CLOSE: prepare-close-ids (enrich) → [resolve-silva-incident-http | resolve-pagerduty] same time
Retired CI → skip both; missing INC at close → soft
```
