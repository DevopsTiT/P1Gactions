# Investigation

Evidence from the four screenshots of the v6 run for P-260916863.

| Screenshot | What it showed |
|---|---|
| resolve-snow-values result | Environment from "default set", label PoC / VoA / Demo, tag_value PRE. Group Ops_Middleware_Monitoring_AXAJP from DEFAULT_GROUP. Service QA Platforms BSN0005741 from default set. Offering "QA Platforms - AXA GROUP OPERATIONS - Production - QA Platforms generic subscription". `default_set_used: true`. |
| Same result, enrichment block | QA Platforms record: assignment_group AGS_FR_QAS_Service-Managers (`6a511cc6db2f07440dbda3e84b96192c`), company AXA GROUP OPERATIONS (`b949afc10f1ac20094a9716ce1050e92`), u_bbsa_id 031781 |
| display-result | Payload assignment_group `b2b1419997f8e61c07c0fdffe153af52` (default group), caller_id and u_on_behalf_of "Dynatrace JP" as names, Summary with escaped JSON |
| display-result event properties | `dt.security_context` = ALJ_ALJ_PRE, ALJ_STG, ALJ_TST. Tags env:PRE, dt.cost.product:AGPOCLOUDWEBNGINX, company:ALJ, k8s.namespace.name agportalfrontend-preprod-axa-li-jp. Some values `[object Object]`. |
| post-silva-incident input | Body comes straight from `display-result.snow_incident_payload`, so every wrong value above would be posted |

| Code cause (OPEN v6) | Line |
|---|---|
| ENVIRONMENT map has no `pre` | 90–96 |
| Security context key `dt.security.context` | 209 |
| Default set sets group and environment unconditionally | 571–583 |
| Payload group reads `snow_required.assignment_group` | 775 |
| `String(object)` in event_properties | 293 |
| `JSON.stringify(additional)` in description | 778 |
