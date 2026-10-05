# Result

| Step | Do this |
|---|---|
| 1 | Run `check.dql` query 1 and replace every CONFIRM filter |
| 2 | Run queries 2 to 4 to check egress history, eopt parses and timeout peaks |
| 3 | Decide whether `_Normal` and email-only alerts may page through the standard flow |
| 4 | `terraform validate` and `plan` (expect 5 detectors) |
| 5 | Disable the 7 Splunk alerts after testing |
