# PREVIEW v7.1 Investigation

| What was checked | Finding |
|---|---|
| Base file | PREVIEW v7 (seq 18), already parallel and with USE_MAINTENANCE_TAG. |
| Tag matching in task 1 | Keys were only lowercased, so hyphen keys like AGO-DEFAULT-ASSIGNMENT-GROUP did not match. |
| Fix | Try the raw lowercase key, then the same key with "-" changed to "_". |
| Grep for POST, PagerDuty URL, routing key | Zero matches in the v7.1 file. |
| YAML parse | Valid. 4a and 4b both have predecessor build-payload. |
| OPEN v7 and TEST v7 | Same tag fix applied. |
