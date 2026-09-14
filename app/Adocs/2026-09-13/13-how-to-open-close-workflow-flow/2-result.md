# Result

Implement two workflows: open = prepare → parallel SNOW+PD → cross-link; close = find by `correlation_id` → resolve SNOW+PD. Fill §4.2 SNOW fields and §4.4 `assignMap` before activate; keep `dedup_key = dt-problem-<ProblemID>` identical on open and close.

| Fastest path | Edit and upload the two files in `../4-snow-pd-workflow-yaml-and-json/` |
| --- | --- |
| Keys that must match | `correlation_id` and `dt-problem-<id>` |
