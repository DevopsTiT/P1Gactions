# PREVIEW v7.1 Result Investigation

| Evidence (screenshots) | Finding |
|---|---|
| preview-silva-incident field_check | 16 rows, all status OK. problems is empty. |
| u_business_service source | "search (score 5: group Database_AXAJP, operational, business service)". |
| cmdb_ci source | "first offering of the business service (environment NOT matched)". |
| u_configuration_item display | "deaa310b.prprivmgmt.intraxa_2023-08-23 06:00:36". |
| assignment_group source | "tag AGO_ORACLE_ASSIGNMENT_GROUP". |
| open_v7_would | "SKIP (maintenance is on)". |
| duplicate_check | http 200, open_incident empty. |
| preview-pagerduty | ready true, 5 checks OK, link to Dynatrace problem, routing key hidden. |
| Tags in description | AGO_Maintenance:True, Test_Maintenance:True, AGO_DEFAULT_ASSIGNMENT_GROUP:Database_AXAJP. |
