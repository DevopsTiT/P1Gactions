# SILVA Verify Investigation

| What was looked at | Finding |
|---|---|
| PREVIEW result for P-260916434 (seq 20) | All payload keys are filled with sys_ids. |
| ServiceNow Table API behaviour | Unknown keys are silently dropped, and bad references are not rejected. |
| Earlier key work (seq 10 to 16) | Confirmed keys are u_business_service, cmdb_ci (offering) and u_configuration_item. |
| Open points from seq 20 | The offering environment differs from the incident environment, and the maintenance tag blocks posting. |

Conclusion: the workflow output alone cannot prove SILVA will accept and keep the values. Each one must be checked in its SILVA table, then read back after one real stg POST.
