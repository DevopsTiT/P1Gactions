# Investigation

| Item | Finding |
| --- | --- |
| User state | Important / customer data not yet meaningfully in Dynatrace |
| Available asset | Existing PII keyword / blocklist (`policyHolder*`, bank, phone, email, …) |
| Goal | Prevent **future** imported logs from including raw PII |
| Best practice | Configure App + OneAgent + OpenPipeline **before** enabling real log sources |
| Risk if waiting | First production import can land PII in Grail with no net |
| Scope reminder | First-wave personal keys only; product/contract metadata still excluded |
