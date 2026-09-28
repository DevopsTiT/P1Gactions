# Open Workflow Matched To Two Examples

## Decision Tree

```
Second classic ticket INC30339746 (custom alert, host TS12.hk.intraxa)
 same pattern as INC30339531?
   CI = host (ts12.hk.intraxa)                      -> yes, already done in seq 26
   business service = derived by SILVA from CI      -> yes (Third Party Services Monitoring Application)
   group = AGO_AXA_SUPPORTGROUP                     -> yes (InfraSupport_Dist-WindowsHK_L2_ASIA)
   env = AGO_AXAENVIRONMENTNAME (Development)       -> yes
 differences found
   isRootCause "false" (no root cause entity)       -> fixed
   event_properties in key order                    -> fixed
   extra key "title" = dt.event.title after tags    -> added
   JSON printed as "key" : value                    -> matched
```

## Short Takeaway

| Question | Answer |
|---|---|
| Does the second example follow the same rules? | Yes. Host as CI, SILVA derives business service, AGO tags give group and environment. |
| What changed in the workflow? | Four details in the Summary JSON so it matches both examples. |
| New folder | `27-open-match-inc30339746/` (OPEN updated, CLOSE unchanged) |

## Summary

INC30339746 confirms the seq 26 approach. The only differences were in the Summary JSON: `isRootCause` must be "false" when the problem has no root cause entity, event properties are listed alphabetically, a `title` key holds the event title, and the JSON uses `"key" : value` spacing. All four are now in the OPEN workflow.

## Both Examples Side By Side

| Field | INC30339531 | INC30339746 | Workflow source |
|---|---|---|---|
| Problem type | Long garbage-collection time (RESOURCE_CONTENTION) | Windows log error (CUSTOM_ALERT) | Problems API severityLevel |
| Short description host | WRGCRAPP01.axa-id.intraxa | TS12.hk.intraxa | Host display name (Entities API) |
| Headline | Garbage collection is suspending process ... | EPAS Filter Error: All defined EPAS servers unreachable ... | Event property dt.event.description |
| CI | wrgcrapp01.axa-id.intraxa | ts12.hk.intraxa | cmdb_ci lookup, lower case FQDN |
| Business service | Third Party Services Monitoring Application | Third Party Services Monitoring Application | SILVA derives from CI |
| Assignment group | InfraSupport_Dist-WindowsID_L2_ASIA | InfraSupport_Dist-WindowsHK_L2_ASIA | Tag AGO_AXA_SUPPORTGROUP |
| Environment | Integration / Test | Development | Tag AGO_AXAENVIRONMENTNAME |
| correlation_id (JSON) | PROCESS_GROUP_INSTANCE-D9C3E1794273903E | PROCESS_GROUP_INSTANCE-97B76630471F05A7 | Root cause, else first affected entity |
| isRootCause | true | false | Problem has a root cause entity or not |
| title (JSON) | not shown | Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa | Event property dt.event.title |
| Priority | 4 - Low | 4 - Low | FIXED_IMPACT / FIXED_URGENCY |

## Code Changes (OPEN prepare-payload)

| Change | Code |
|---|---|
| Sort properties | `.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0))` on eventProps |
| isRootCause | `isRootCause: prob.rootCauseEntity ? "true" : "false"` |
| title key | `title: propValue("dt.event.title") \|\| undefined` (left out when empty) |
| JSON layout | `JSON.stringify(obj, null, 2).replace(/^(\s*)"([^"]+)":/gm, '$1"$2" :')` |

## Data Flow Map

```
event + Problems API + Entities API
   -> host (display name, IPs), root/affected entity, event properties (sorted), tags
   -> Summary: headline + "Additional Information:" + JSON ("key" : value)
   -> POST: CI sys_id, group from AGO tag, env from AGO tag, no business service
   -> SILVA derives business service / offering from CI
```

## Related Files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN matched to both examples (import this) |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE, unchanged |
| `../26-open-like-inc30339531/` | First example and full field mapping |
| `27.sh` | Check both example tickets and the new one |

## Commands

See `27.sh` (not run by me). YAMLs contain real secrets; do not push the app/Adocs copy.
