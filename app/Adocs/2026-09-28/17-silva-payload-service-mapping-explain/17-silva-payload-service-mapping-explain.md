# SILVA Payload Service Mapping Explained

```
Why did business service come out blank?
 Event affected entity = SERVICE ("[COMPASSPROXY.TST] compass-proxy-ccifa-*...")
   → no host.name in the event
   → workflow sent cmdb_ci = the Dynatrace service name
   → SILVA CMDB has no CI with that name
   → SILVA cannot derive business service / group → default offering, blank service
What the team asks for (payload must carry)
   1) system name     → the CI name SILVA knows (usually the host)
   2) business service → a name that exists in SILVA
   3) L1 / L2 group    → SILVA assignment group
 Where to get them
   → Dynatrace tags on the entity (set once per app / host)
   → service problem? → follow Dynatrace relationships service → host
 No match in SILVA?
   → fall back to a default SILVA business service (and default group)
```

## Short takeaway

| Question | Answer |
|---|---|
| What is Davesh saying? | The classic integration sends metadata such as the host name. SILVA uses the host to find the business service and group already configured in SILVA. |
| What is Abhay asking? | Our payload should carry the system name, business service name and L1/L2 group. If SILVA has no matching business service, use a default one. |
| Why was business service blank in our test? | This problem is on a Dynatrace service, not a host, so our workflow sent a service name as the CI. SILVA could not match it. |
| What needs to change? | Read the three values from Dynatrace tags per entity, and keep fixed values only as fallbacks. |
| Silva = ServiceNow? | Yes. SILVA is AXA's name for their ServiceNow instance. |

## Summary

SILVA works out business service and assignment group from the CI (usually the host). Our workflow only knows what the Dynatrace event contains. For service-level problems that is a service name, which SILVA does not know. The fix is to send values SILVA recognises, taken from tags, with a default when nothing matches.

## The chat, line by line

| Who | What they said | What it means for us |
|---|---|---|
| Davesh | The configuration or connection sends metadata such as the host name when a problem triggers. | The old Dynatrace to ServiceNow integration passed the host. |
| Davesh | From that host name, SILVA picks the business service and assignment group configured on the SILVA side. | The host is the key. SILVA's CMDB maps host to service to group. |
| Abhay | Pass system name, business service name and L1 or L2 group name as payload. | Three values must be in our POST. |
| Abhay | SILVA has those business services; check how the payload carries the SILVA service and tag it to the service. | In Dynatrace, tag each monitored service or host with its SILVA business service name. |
| Abhay | If there is no business service match in ServiceNow, assign to the default SILVA business service. | Needs a fallback path in the workflow. |
| Abhay | Silva = ServiceNow. | Same system. |

## The event, field by field

| Event field | Value | What it tells us |
|---|---|---|
| `display_id` | P-260915351 | Problem ID. This becomes correlation_id. |
| `event.status` | ACTIVE | The problem is open. |
| `event.status_transition` | UPDATED | This run was an update, not a create. Our OPEN trigger also fires on UPDATED, which can create a second ticket. |
| `affected_entity_types` | dt.entity.service | The problem is on a service, not a host. |
| `affected_entity_names` | [COMPASSPROXY.TST] compass-proxy-ccifa-*, ... | A Dynatrace service name. SILVA has no CI with this name. |
| `affected_entity_ids` / `root_cause_entity_id` | SERVICE-4C92DDBDD78986D0 | The service's Dynatrace ID. We can use it to find the host. |
| `related_entity_ids` | PROCESS_GROUP-FBFA7DE3E44C269C | The process group behind the service. It runs on one or more hosts. |
| `dt.security_context` | ALJ_APPLICATION_COMPASSPROXY_TST, ALJ_TST, ... | Access-control labels. These are not tags, but they hint at the app (COMPASSPROXY) and environment (TST). |
| `host.name` | Not present | Our workflow's hostName was empty, so it used the service name as the CI. |

## Why our ticket looked wrong

| Step | What happened |
|---|---|
| 1 | The event had no host name. |
| 2 | The workflow used the root cause entity name, the Dynatrace service name, as `cmdb_ci`. |
| 3 | SILVA did not find a CI with that name. |
| 4 | With no CI, SILVA could not derive a business service. The field stayed blank. |
| 5 | A SILVA rule filled in a default offering: "- AXA GROUP OPERATIONS - Development - Standard_2026-07-27...". |

## What the payload should carry

| Value | SNOW field | Best source |
|---|---|---|
| System name | `cmdb_ci` (plus `u_host`) | The host name SILVA knows. For service problems, find the host through Dynatrace relationships (service to host). |
| Business service | `business_service` | A Dynatrace tag, for example `silva_business_service:uk-sap-fscd-dev`. |
| Service offering | `service_offering` | A tag, or derived from the business service plus environment. |
| L1 group | `assignment_group` | A tag, for example `silva_group_l1:<group>`. |
| L2 group | Escalation / notes | A tag, for example `silva_group_l2:<group>`. |
| Default business service | Used when no match | A setting in the workflow, agreed with the SILVA team. |

## Proposed workflow logic (not built yet)

| Step | What the workflow would do |
|---|---|
| 1 | Read tags on the affected entity: business service, L1 group, L2 group, system name. |
| 2 | If the entity is a service, look up the host it runs on and use that host name as the system name. |
| 3 | Look up the business service sys_id in SILVA. The seq 16 code already does this. |
| 4 | If found, send it. If not, send the default SILVA business service and default group. |
| 5 | Report what was used in the task result: tag value, lookup result, and whether the fallback was used. |
| 6 | Optional: drop UPDATED from the OPEN trigger, or check for an existing INC by correlation_id before creating. |

This flips the seq 13 to seq 16 order. Tags come first, and the fixed values become the fallback.

## Questions to settle with Abhay and Davesh

| Question | Why it matters |
|---|---|
| What tag names should hold the SILVA business service and groups? | The workflow reads exactly these keys. |
| Who tags the entities in Dynatrace, and at which level (host, process group, service)? | Auto-tagging rules can set them once per app. |
| What is the default SILVA business service and default group? | Needed for the no-match fallback. |
| Does SILVA's CMDB hold the Dynatrace host names as CIs? | If yes, sending the right host may be enough for SILVA to fill the service itself. |
| Should we send the CI at all when we also send business service? | Some SILVA rules overwrite the service from the CI. |

## Data flow map

```
Dynatrace problem (service-level)
   │  affected: SERVICE-4C92..., no host.name
   ▼
Workflow prepare-payload
   ├─ tags on entity → silva_business_service, silva_group_l1, silva_group_l2
   ├─ service → runs on host → system name
   ▼
post-silva-incident-http
   ├─ lookup business service in SILVA ── found ──► send sys_id
   │                                   └─ not found ► default SILVA business service
   ├─ cmdb_ci = host name, assignment_group = L1 group
   ▼
SILVA INC with correct service, offering and group
```

## Related files

| File | Purpose |
|---|---|
| `17.sh` | Commands to find the host behind the service and check SILVA CIs |
| `../16-open-close-service-sysid-low-priority/` | Current YAMLs with sys_id lookup, which the next change builds on |

Commands: see `17.sh` in this folder.
