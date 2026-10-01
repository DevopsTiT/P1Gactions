# Test Workflow To Validate Extraction

## Decision Tree

```
Run TEST v7 (Run button = sample P-260916863, or a real problem via trigger)
 │
 ├─ 4 validate-extraction → verdict
 │    PASS                → payload is right, copy settings into OPEN
 │    PASS WITH WARNINGS  → read WARN rows (environment default? caller is a name?)
 │    FAIL                → read FAIL rows, top of the "checks" list
 │
 ├─ FAIL "assignment_group = servicenow_enrichment"
 │      → group did not come from the business service → check GROUP_ORDER in task 2
 ├─ FAIL "offering parent = business_service"
 │      → offering belongs to another service → check offering_candidates in task 2
 ├─ WARN "offering environment = incident environment"
 │      → service has no offering for this environment → ask SILVA team or accept
 ├─ FAIL choice u_environment
 │      → label not valid → valid_choices.u_environment shows real values → fix PREPROD_LABEL / ENV_VALUE
 ├─ WARN caller_id / u_on_behalf_of "sent as a name"
 │      → copy the reported sys_id into CALLER_SYS_ID / ON_BEHALF_OF_SYS_ID
 └─ WARN business service method "default"
        → no service found from tags → add SERVICE_MAP entry (AGPOCLOUDWEBNGINX: "<service>")
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is this workflow? | A read-only copy of the OPEN logic with a validation task at the end |
| Does it create anything? | No. No POST or PATCH to SILVA, no PagerDuty call. Only GET lookups. |
| Main fix you asked for | The payload assignment group now comes from `servicenow_enrichment` (the business service's group) |
| What would it send for P-260916863? | Group `AGS_FR_QAS_Service-Managers` instead of `Ops_Middleware_Monitoring_AXAJP` |
| Other bugs fixed | Environment PRE ignored, wrong security context key, Production offering for a PRE problem, `[object Object]` and raw JSON in the Summary |
| How do I see right or wrong? | Task 4 returns `verdict` plus a `checks` list with PASS, WARN, FAIL per field |

## Summary

Your screenshots showed the payload used the default group and the default environment, even though the business service record (servicenow_enrichment) had its own group and the event clearly said PRE. The new TEST v7 workflow fixes the extraction, builds the same payload OPEN would send, then checks every value in SILVA. It never sends anything.

## What Was Wrong In Your Run (P-260916863)

| What you saw | Why it happened | Fix in v7 |
|---|---|---|
| `assignment_group` = Ops_Middleware_Monitoring_AXAJP (`b2b14199...`) | No group tag, so the default set put DEFAULT_GROUP in the payload. The business service's own group was ignored. | Group follows `GROUP_ORDER`: tag, then `servicenow_enrichment.assignment_group`, then support group, CI, default |
| Enrichment says `AGS_FR_QAS_Service-Managers` (`6a511cc6...`) but payload does not | Payload read `snow_required.assignment_group`, not the enrichment | Payload group = enrichment group when no tag exists; task 4 checks they are equal |
| Environment = "PoC / VoA / Demo", tag_value PRE | `pre` was not in the ENVIRONMENT map, and the default set overwrote the environment | `pre`, `preprod`, `stg` mapped; default set no longer overwrites a real environment |
| `dt.security_context` = ALJ_ALJ_PRE ignored | Code read `dt.security.context` (dot), the event uses `dt.security_context` (underscore) | Both keys read |
| Offering = "...Production - QA Platforms generic subscription" | Default set took the first default offering, no environment match | Offering for the problem's environment first; task 4 warns on mismatch |
| `event_properties` showed `[object Object]` | `String(object)` on smartscape fields | Objects are turned into JSON text |
| Summary had a huge escaped JSON block | `JSON.stringify(additional)` with all event properties | Summary is now plain `key: value` lines |
| `caller_id` = "Dynatrace JP" (a name) | Table API ignores names in reference fields unless `sysparm_input_display_value=true` | Task 4 finds the user's sys_id; paste it into `CALLER_SYS_ID` |
| Business service = QA Platforms (default) | Tags have no service tag; app code `AGPOCLOUDWEBNGINX` was never searched | App code (from `dt.cost.product` or the `[CODE.ENV]` name prefix) is searched first |

## Tasks And What They Pass

| Task | Job | Passes to next |
|---|---|---|
| 1 `extract-event-tags` | Reads event and tags. Finds group tags, environment, app code, OpCo, hosts, maintenance. | `dynatrace_alert`, `snow_inputs`, `tags`, `event_properties` |
| 2 `resolve-snow-values` | GET lookups in SILVA: business service (map, CI, search, first answer, default), final group by `GROUP_ORDER`, offering by environment | `snow_required`, `servicenow_enrichment`, `group_sources`, `offering_candidates`, `steps` |
| 3 `build-payload` | Builds the incident body exactly as OPEN would. Lists the source of every field. | `snow_incident_payload`, `field_sources` |
| 4 `validate-extraction` | GET checks of every value; compares with enrichment, with `EXPECTED`, and with INC30340215 | `verdict`, `checks`, `reference_incident`, `valid_choices` |

## Group Order (task 2 setting)

| Order | Source | When it is used |
|---|---|---|
| 1 | `tag` | The entity has a group tag such as `AGO_ORACLE_ASSIGNMENT_GROUP` (or a `GROUP_MAP` entry) |
| 2 | `enrichment` | The business service record has an assignment group. This is your case. |
| 3 | `enrichment_support` | The business service has only a support group |
| 4 | `ci` | The host or DB CI has a support group |
| 5 | `default` | Nothing else; uses `Ops_Middleware_Monitoring_AXAJP` |

If you want the enrichment group to win even over tags, change it to `["enrichment", "tag", ...]`.

## Checks In Task 4

| Area | Check | FAIL or WARN means |
|---|---|---|
| extract | problem_id and event_name present | Event is incomplete |
| extract | Environment came from the event | WARN: fell back to the default label |
| extract | App code found | WARN: service search has less to go on |
| extract | Group tag present | WARN: group comes from enrichment or default (expected for P-260916863) |
| resolve | Business service method | WARN: default service used |
| silva | `assignment_group` sys_id exists and is active | FAIL: wrong or inactive group |
| rule | Payload group equals `servicenow_enrichment.assignment_group_id` | FAIL: payload is not using the enrichment group |
| silva | `business_service` sys_id exists | FAIL: wrong service |
| silva | `service_offering` exists | FAIL: wrong offering |
| rule | Offering parent equals the business service | FAIL: offering belongs to another service |
| rule | Offering environment equals the incident environment | WARN: for example a PRE problem on the Production offering |
| silva | `company` exists and equals the enrichment company | FAIL: wrong company |
| silva | `caller_id` and `u_on_behalf_of` are user sys_ids | WARN: name given; the sys_id to use is shown |
| choice | `u_environment`, category, subcategory, impact, urgency, contact_type are valid stored values | FAIL: shows the valid values or the right value for a label |
| expected | Matches what you typed in `EXPECTED` | FAIL: differs from your expectation |
| reference | Side by side with INC30340215 | Not scored; read it to compare |

## How To Use

| Step | What to do |
|---|---|
| 1 | Import `4-v7-test-extraction-validate.workflow.yaml` as a new workflow |
| 2 | Optional: fill `EXPECTED` in task 4 with the values you know are right |
| 3 | Press Run. With no event it tests the sample P-260916863. |
| 4 | Open task 4 Result. Read `verdict`, then the `checks` list (FAIL rows first). |
| 5 | Fix settings (PREPROD_LABEL, CALLER_SYS_ID, SERVICE_MAP) and run again until PASS |
| 6 | Copy the fixed tasks 1 to 3 into OPEN (I can produce OPEN v7 when you are happy) |

## Expected Result For P-260916863

| Field | Before (v6) | After (v7 test) |
|---|---|---|
| assignment_group | Ops_Middleware_Monitoring_AXAJP | AGS_FR_QAS_Service-Managers (from enrichment) |
| business_service | QA Platforms | QA Platforms, unless the app code search finds a better service |
| company | AXA GROUP OPERATIONS | AXA GROUP OPERATIONS (from enrichment) |
| environment | PoC / VoA / Demo | Pre-Production (confirm label in `valid_choices`) |
| service_offering | QA Platforms ... Production ... | The QA Platforms offering for Pre-Production, if one exists; otherwise WARN |

## Data Flow

```
Davis event / SAMPLE_EVENT
  → 1 extract-event-tags   (env tag PRE, dt.security_context, app code AGPOCLOUDWEBNGINX, OpCo ALJ)
  → 2 resolve-snow-values  (SILVA GET: service → enrichment → group by GROUP_ORDER → offering by environment)
  → 3 build-payload        (incident body preview + field_sources)
  → 4 validate-extraction  (SILVA GET: sys_user_group, cmdb_ci_service, service_offering,
                            core_company, sys_user, sys_choice, incident INC30340215)
  → verdict + checks       (nothing is created anywhere)
```

## Related Files

| File | What it is |
|---|---|
| `4-v7-test-extraction-validate.workflow.yaml` | The test workflow (contains the SILVA password, keep out of git) |
| `../../2026-09-30/9-v6-full-open-silva-pagerduty/` | OPEN v6 that produced the wrong payload |
| `4.sh` | YAML check, SILVA GET one-liners to confirm values by hand, mirror copies |

## Commands

All in [`4.sh`](4.sh); nothing was run for you.

```bash
python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1])); print('YAML OK')" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/4-v7-test-extraction-validate/4-v7-test-extraction-validate.workflow.yaml"
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/v2/table/sys_choice" --data-urlencode "sysparm_query=name=incident^element=u_environment^inactive=false" --data-urlencode "sysparm_fields=value,label"
```
