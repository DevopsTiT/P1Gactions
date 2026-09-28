# Open Workflow Like INC30339531

## Decision Tree

```
Problem opens -> prepare-payload
 1. read trigger event (tags, security context, affected entities)          no API
 2. Problems API       -> title, severityLevel, impactLevel, root cause, evidence, zones
 3. root-cause event   -> event_properties, dt.event.description, metric selector
 4. Entities API       -> root entity -> its HOST -> display name, IP addresses, tags
 host found?
   entity API host name -> event host -> host tag + AGO_DOMAIN -> "on host X" in text
 route
   assignment group  <- tag AGO_AXA_SUPPORTGROUP (then AGO_DEFAULT_ASSIGNMENT_GROUP, map, default L2)
   environment       <- tag AGO_AXAENVIRONMENTNAME (Integration-Test -> Integration / Test), env, context
   business service  <- map / tag, else NOT sent -> SILVA derives it from the CI
 post-silva
   CI lookup (full, short, fqdn) -> send cmdb_ci sys_id
   after insert: business service still blank? -> svc_ci_assoc -> defaults
```

## Short Takeaway

| Question | Answer |
|---|---|
| What was copied from INC30339531? | Short description, Summary with Additional Information JSON, CI as host, group and environment from AGO tags, business service derived by SILVA. |
| Where do group and environment come from? | Tags `AGO_AXA_SUPPORTGROUP` and `AGO_AXAENVIRONMENTNAME` on the entity. |
| Why does business service fill now? | The host is sent as CI by sys_id, and SILVA fills business service and offering from the CMDB, like in the example. |
| What if SILVA still leaves it blank? | The workflow reads svc_ci_assoc, then falls back to uk-sap-fscd-dev. |
| Does CLOSE still work? | Yes. The SNOW correlation_id field stays the problem display id. |
| New folder | `26-open-like-inc30339531/` (OPEN rewritten, CLOSE same as seq 25) |

## Summary

INC30339531 was created by the classic integration, and it shows how SILVA wants the data. It sends the host as the configuration item, the support group and environment from AGO tags, and a Summary made of the event description plus an "Additional Information" JSON. The new OPEN workflow does the same. It pulls the extra data (event properties, IP addresses, management zones, host name) from the Problems API and the Entities API, so the ticket matches the example field by field.

## Example Ticket vs New Workflow

| Ticket field | INC30339531 | Where the new workflow gets it |
|---|---|---|
| Short description | [DYNATRACE JAPAN][WRGCRAPP01.axa-id.intraxa] - Garbage collection is suspending process ... | Prefix + host display name + root-cause event `dt.event.description` |
| Summary first line | Garbage collection is suspending process ... | Same event description |
| Summary JSON | Additional Information {...} | Built with the same keys (table below) |
| Configuration item | wrgcrapp01.axa-id.intraxa | Host found in cmdb_ci, sent by sys_id |
| Business service | Third Party Services Monitoring Application | Not sent; SILVA derives it from the CI |
| Service offering | Third Party Services Monitoring Application | Same |
| Assignment group | InfraSupport_Dist-WindowsID_L2_ASIA | Tag AGO_AXA_SUPPORTGROUP |
| Assigned to | Empty | Empty (only set for the default group) |
| Environment | Integration / Test | Tag AGO_AXAENVIRONMENTNAME = Integration-Test, mapped |
| Impact / Urgency / Priority | 4 - Low | FIXED_IMPACT / FIXED_URGENCY = "4" |
| Contact type, Company | Event, AXA GROUP OPERATIONS | Constants |
| Category / Subcategory | Other / Other | Constants |

## Additional Information JSON Keys

| Key | Example value | Source |
|---|---|---|
| correlation_id | PROCESS_GROUP_INSTANCE-D9C3E1794273903E | Root cause entity id |
| discovered_name | [INFRA.ACC] IIS app pool DefaultAppPool | Root cause entity name |
| dynatrace_severity | RESOURCE_CONTENTION | Problems API severityLevel |
| environmentId | wuh86725 | Tenant id from the environment URL |
| environmentName | AXA AS STG | Setting DT_ENVIRONMENT_NAME |
| event_properties | [{key, value}, ...] | Root-cause evidence event properties |
| ip_addresses | ["10.55.10.10", "10.47.11.136"] | Host entity property ipAddress |
| isRootCause | "true" | Root cause entity exists |
| managementZones | ["non_Japan", "AGO_OS_WIN_ACC", ...] | Problems API, then entity |
| metricName | builtin:tech.jvm.memory.gc.suspensionTime:avg... | Event property dt.event.metric_selector |
| problemDescription | OPEN INFRASTRUCTURE Problem P-260915090: Long garbage-collection time | "OPEN " + impactLevel + " Problem " + id + ": " + title |
| problem_displayId | P-260915090 | display_id |
| problem_id | -9084836147865866476... | Problems API problemId |
| tags | ["company:AGI", "AGO_AXA_SUPPORTGROUP:...", ...] | Event entity_tags (original text), else entity tags |
| u_business_service | <<UNKNOWN>> | Mapped or tagged value, else <<UNKNOWN>> |
| u_external_url | Problem link | Problem URL, else <<UNKNOWN>> |

## Settings You May Edit

| Setting | Value now | What it does |
|---|---|---|
| `LET_SILVA_DERIVE_SERVICE` | true | Do not send business service / offering when there is no map or tag value; SILVA fills them from the CI |
| `DT_ENVIRONMENT_NAME` | "AXA AS STG" | environmentName in the JSON |
| `ENVIRONMENT` | Integration-Test and TST map to "Integration / Test" | Tag value to SILVA environment label |
| `SILVA_ENVIRONMENTS` | Production, Development, Integration / Test | Only these labels are sent |
| `META_KEYS.assignmentGroup` | ago_axa_supportgroup, ago_default_assignment_group, ... | Tags read for the group |
| `FIXED_ENVIRONMENT` | "Development" | Used only when metadata has no environment |
| `ASSIGNED_TO` | "Shuge KUI" | Only when the default group is used |
| `DASHBOARD_URL`, `PD_SERVICE_URL` | "" | Placeholders removed; lines are skipped when empty |
| `DESCRIPTION_MAX` | 12000 | Summary length cap |

## What To Check After A Test Run

Open the run, task `post-silva-incident-http`, Result.

| Field | Good value | If not |
|---|---|---|
| `extraction.problemApi` | ok | Workflow cannot read problems; grant permission |
| `extraction.entityApi` | ok | Workflow cannot read entities; host name and IPs may be missing |
| `extraction.hostName` | Host FQDN | Not a host-related problem, or no host found |
| `ciLookup.matches` | 1 | Host not in cmdb_ci under full, short or fqdn name |
| `businessServiceFrom` | SILVA from CI | "svc_ci_assoc" or "default" means SILVA did not derive it |
| `extraction.sources.assignmentGroup` | tag ago_axa_supportgroup | "default L2" means the tag is missing on that entity |
| `extraction.sources.environment` | tag ago_axaenvironmentname = ... | "default" means no usable tag |
| `notFilled` | Empty | Lists fields SILVA left blank |

## Common Issues

| Symptom | Likely cause | Fix |
|---|---|---|
| Business service blank, CI blank | Host not found in CMDB | Check `ciLookup`; compare with the CMDB name (24.sh / 26.sh) |
| Business service blank, CI filled | SILVA has no service for that CI | svc_ci_assoc or defaults fill it; check `businessServiceFrom` |
| Environment "Development" on a test host | AGO_AXAENVIRONMENTNAME value not in ENVIRONMENT | Add the value to ENVIRONMENT and the label to SILVA_ENVIRONMENTS |
| Group is Ops_Middleware_Monitoring_AXAJP | No AGO_AXA_SUPPORTGROUP tag on the entity | Tag the host in Dynatrace |
| Summary cut off | Longer than the SILVA field | Lower DESCRIPTION_MAX or accept the cut |
| Two incidents for one problem | Trigger includes UPDATED | Drop UPDATED or add the duplicate check (seq 21) |

## Data Flow Map

```
Trigger event ─┐
Problems API ──┼─> prepare-payload ──> host, IPs, zones, event_properties, tags
Entities API ──┘        │                group (AGO tag), env (AGO tag), service source
                        │
                        ├─> post-silva-incident-http
                        │     lookupCi -> POST (CI sys_id, no service if deriving)
                        │     SILVA insert rules fill business service / offering from CI
                        │     still blank -> svc_ci_assoc -> defaults -> PATCH
                        │
                        └─> trigger-pagerduty (dedup_key dt-problem-<id>)
```

## Related Files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | New OPEN (import this) |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE, same as seq 25 |
| `26.sh` | Checks for the example host and ticket |

## Commands

See `26.sh` (not run by me). YAMLs contain real secrets; do not push the app/Adocs copy.
