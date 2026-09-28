# Do The YAMLs Analyse Dynatrace Metadata

## Decision Tree

```
Does the workflow analyse the Dynatrace event before sending to SNOW?
 OPEN  -> yes
   reads the trigger event (name, display_id, event.id, severity, entity_tags, security context, entity names)
   calls Problems API getProblem(event.id) for tags, root cause, evidence, management zones
   derives system -> SYSTEM_MAP -> business service, offering, group, env
   builds short description, notes, Additional Information JSON -> POST to SILVA
 CLOSE -> partly
   reads display_id + getProblem for title, cause, duration
   finds INC by correlation_id -> PATCH Resolved with notes
   routing values are not re-sent (not needed at close)
 gaps found with your COMPASSPROXY event
   severity reads event.severity "3" instead of SLOWDOWN
   no host.name -> service name used as CI and in the title
   COMPASSPROXY not in SYSTEM_MAP -> defaults used
   fixed test values (env, impact, urgency) override the event
```

## Short Takeaway

| Question | Answer |
|---|---|
| Does OPEN analyse the Dynatrace input? | Yes. It reads the event and the Problems API, then maps the values to SNOW fields. |
| Does CLOSE analyse it? | Only what it needs for close notes: title, cause, duration and business service. |
| Is the analysis complete? | Not yet. Four gaps show up with your COMPASSPROXY sample event. |
| Biggest gap | Severity reads "3" (numeric) instead of SLOWDOWN, so category rules and severity-based priority do not work. |

## Summary

Yes, the OPEN workflow does analyse the Dynatrace metadata. The `prepare-payload` task reads the trigger event, fetches more detail from the Problems API, and turns it into SNOW fields. CLOSE only uses the metadata to write the close notes. Running your COMPASSPROXY event through the code in your head shows four gaps. They do not break ticket creation, but they make some fields less accurate.

## What OPEN Reads And Where It Goes

| Dynatrace input | Code | SNOW field it feeds |
|---|---|---|
| `event.name` = Response time degradation | `problemTitle` | short_description, description, notes |
| `display_id` = P-260915351 | `problemId` | correlation_id (links OPEN and CLOSE) |
| `event.id` | `problemsClient.getProblem` and problem URL | Links in notes, u_external_url |
| `event.severity` / `event.category` | `severity` | Impact, urgency, PD severity (overridden by FIXED_IMPACT / FIXED_URGENCY) |
| `host.name` | `hostName` | u_host, cmdb_ci, short description |
| `entity_tags` (app, dt.cost.product, system) | `systemCandidates` then `findSystem` | business_service, service_offering, assignment_group, u_environment |
| `dt.security.context` | `systemCandidates` | Same as above (fallback) |
| `root_cause_entity_name`, `affected_entity_names` | `systemCandidates` | Same as above (last fallback) |
| Problems API `entityTags` | `tagValue` | env, snow-service, ago_axa_supportgroup, dashboard |
| Problems API `rootCauseEntity` | `where`, `ciName` | Short description, cmdb_ci, notes |
| Problems API `evidenceDetails` | `evidence` | "Cause" section in notes |
| Problems API `managementZones` | `zones` | Notes and Additional Information |

## What CLOSE Reads

| Dynatrace input | Used for |
|---|---|
| `display_id` | Find the INC by correlation_id, PD dedup_key |
| `event.id` + Problems API | Title, root cause, evidence, start and end time |
| `entity_tags` + SYSTEM_MAP | Business service line in the notes |
| Result to SNOW | state 6 Resolved, close_code, close_notes, comments "Resolved", work_notes |

## Walk-Through With Your COMPASSPROXY Event

| Step | What the code gets | Result |
|---|---|---|
| Title | event.name | "Response time degradation" |
| Problem id | display_id | P-260915351 |
| Severity | `event.severity` is checked before `event.category` | "3", not SLOWDOWN |
| Impact / urgency | FIXED_IMPACT / FIXED_URGENCY = "4" | 4 - Low (event ignored) |
| Host | No host.name in the event | "" |
| CI / where | Root cause entity name | "[COMPASSPROXY.TST] compass-proxy-ccifa-*, ..." |
| Short description | Prefix + where + title | "[DYNATRACE JAPAN][[COMPASSPROXY.TST] compass-proxy-ccifa-*, ...] - Response time degradation" (long, trimmed to 160) |
| System | app / dt.cost.product = COMPASSPROXY | Not in SYSTEM_MAP, so no match |
| Business service | Default | uk-sap-fscd-dev |
| Offering | Default | uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard |
| Group | Default L2 | Ops_Middleware_Monitoring_AXAJP, assigned to Shuge KUI |
| Environment | FIXED_ENVIRONMENT | Development (env:TST ignored) |

## Gaps And Fixes

| Gap | Why it matters | Fix in the OPEN YAML |
|---|---|---|
| Severity reads `event.severity` ("3") before `event.category` ("SLOWDOWN") | Category rules and severity-based impact never match | Put `ev["event.category"]` before `ev["event.severity"]` in the `severity` lookup |
| No host for service-level problems | The service name is sent as cmdb_ci and SILVA cannot match it | Set `SEND_CONFIGURATION_ITEM = false` |
| Long service name in the title | Short description is hard to read | Use the first `affected_entity_names` value up to the first comma, or use the system key |
| COMPASSPROXY not in SYSTEM_MAP | Ticket gets default service and group | Add a COMPASSPROXY row once the SILVA names are known |
| Fixed test values override the event | env:TST and real severity are ignored | Set FIXED_ENVIRONMENT, FIXED_IMPACT, FIXED_URGENCY to "" when ready |
| Problems API call needs permission | If it fails, tags, root cause and evidence are empty (system detection still works from the event) | Make sure the workflow actor can read problems |

### Severity fix (code)

```js
const severity = String(
  ev["problem.severity"] ||
    ev["event.category"] ||
    ev["event.severity"] ||
    ev.severity ||
    "ERROR"
).toUpperCase();
```

SLOWDOWN will then show in notes. To make it change impact, add a rule such as `else if (severity.includes("SLOWDOWN")) { snowImpact = "3"; snowUrgency = "3"; }`, and set FIXED_IMPACT / FIXED_URGENCY to "".

## Data Flow Map

```
Dynatrace trigger event ----------------------+
   event.name, display_id, event.id,          |
   event.severity/category, entity_tags,      |
   security context, entity names             |
                                              v
Problems API getProblem(event.id) ------> prepare-payload
   entityTags, rootCauseEntity,              system -> SYSTEM_MAP
   evidence, managementZones                 title, notes, Additional Information JSON
                                              |
                          +-------------------+-------------------+
                          v                                       v
             post-silva-incident-http                     trigger-pagerduty
             sys_id lookup -> POST INC -> PATCH services   dedup_key dt-problem-<id>

CLOSE: display_id + getProblem -> close notes -> find INC by correlation_id -> PATCH Resolved
```

## Related Files

| File | Purpose |
|---|---|
| `../20-silva-system-data-map/1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN workflow checked |
| `../20-silva-system-data-map/2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow checked |
| `../19-analyse-dt-event-for-silva-mapping/` | Field-by-field event analysis |
| `23.sh` | Command to check the created INC |

## Commands

See `23.sh` (not run by me).
