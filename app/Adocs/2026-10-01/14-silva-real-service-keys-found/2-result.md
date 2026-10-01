# Result

| Step | Do |
|---|---|
| 1 | Re-import `4-v7-test-extraction-validate.workflow.yaml` and run it |
| 2 | Expect `u_business_service` PASS and `cmdb_ci (service offering)` PASS with parent rule PASS |
| 3 | Run Q1 to Q3 in `14.sh` to find the "Configuration item" key |
| 4 | Put that key in `HOST_CI_FIELD` in build-payload |
| 5 | When TEST passes, build OPEN v7 with the same keys |
