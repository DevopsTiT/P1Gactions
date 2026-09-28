# Fix Blank Business Service And CI

## Decision Tree

```
INC30339813: Business service, Service offering, Configuration item blank
 Was the value in the payload?
   Notes say "Business service: uk-sap-fscd-dev" -> yes, the workflow sent it
 Did the sys_id PATCH run?
   Only ONE "Field changes" entry, no business service in it -> no
   -> the name lookups returned no sys_id (0 matches, 2+ matches, or 403)
   -> SILVA dropped the plain names -> blank
 Why no CI?
   host sent as "zdahka204b.pprivmgmt.intraxa" (FQDN) as a plain name
   CMDB likely stores "zdahka204b" -> no match -> blank
   no CI -> SILVA cannot derive the business service itself
 Why "no SYSTEM_MAP match" and defaults?
   metadata has no system / snow-service / support-group tag for this host
   Management zone n/a and no tags -> Problems API returned nothing or the host has no tags
 Fix (seq 24 YAML)
   lookups accept several matches, CI looked up by FQDN or short name and sent by sys_id,
   business service read from CMDB for the host, tags fall back to the event,
   result shows exactly which step failed
```

## Short Takeaway

| Question | Answer |
|---|---|
| Did the workflow send a business service? | Yes, the name uk-sap-fscd-dev (the default). |
| Why is it blank? | The sys_id lookup found nothing usable, so SILVA got only a name and dropped it. The fix PATCH never ran. |
| Why is Configuration item blank? | The FQDN was sent as a plain name and does not match the CMDB record. |
| Why did it not use the metadata for group and service? | The metadata has no SILVA names for this host, and the SYSTEM_MAP only knows EIP. So defaults were used. |
| Was the assignment group filled? | Yes, the default L2 group Ops_Middleware_Monitoring_AXAJP. |
| What to do | Import the seq 24 OPEN YAML, run a test, and read the new diagnostics in the post-silva result. |

## Summary

There are two separate problems. First, the workflow did send business service and offering, but only as names, because the lookup for their sys_ids came back empty. SILVA silently drops names it cannot match. Second, the Dynatrace metadata for this host has no tag that says which SILVA service or group it belongs to, so the workflow had nothing to map and used the defaults. The seq 24 YAML makes the lookups more tolerant, finds the host in the CMDB and asks SILVA which service it belongs to, and reports every step in the task result.

## Evidence From The Screenshots

| What you see | What it tells us |
|---|---|
| Notes: "System (data map): no SYSTEM_MAP match, defaults used" | No tag matched EIP, so defaults were used. |
| Notes: "Business service: uk-sap-fscd-dev" | The workflow computed the value. |
| Form: Business service blank, Service offering blank | SILVA did not accept the values. |
| Field changes: one entry only, Service Offering "(Empty)", no business service | The follow-up PATCH by sys_id did not happen, so no sys_id was found. |
| Form: Configuration item blank | The host name was not matched in the CMDB. |
| Summary JSON: "managementZones": [] | The Problems API returned no details, or the host has no zones. |
| Notes: "Severity: 3" | Severity came from the numeric field, not the category. |
| Notes: `__PD_SERVICE_URL__`, `__EIP_DASHBOARD_URL__`, `__L3_GROUP__` | Placeholders not replaced yet. |

## Why The Lookup Can Return Nothing

| Cause | How it shows in the new result | Fix |
|---|---|---|
| Name matches several records (cmdb_ci_service includes child classes) | `serviceLookup.businessService.matches` is 2 or more | Seq 24 now takes the operational one instead of giving up |
| Name does not exist exactly | `matches` is 0, `status` 200 | Copy the exact name from SILVA |
| API user cannot read the table | `status` 403, or 200 with 0 rows while the UI shows the record | Ask the SILVA admin for read access to cmdb_ci_service, service_offering, cmdb_ci, svc_ci_assoc |
| Offering belongs to another service | Offering cleared by a SILVA rule | Use an offering whose parent is the chosen service |

## What Changed In Seq 24 (OPEN YAML)

| Area | Before | Now |
|---|---|---|
| Business service and offering lookup | Only exactly 1 match accepted | Up to 10 matches read; the operational one is used; classes listed in the result |
| Configuration item | Host FQDN sent as a name | Host looked up in cmdb_ci by FQDN, short name or fqdn field; sent by sys_id; not sent if not found |
| Business service when no map or tag | Always the default uk-sap-fscd-dev | Host's service from svc_ci_assoc if found; default offering then dropped |
| Fix PATCH | Business service and offering | Also the CI |
| Tags | Problems API only | Falls back to trigger event entity_tags |
| Severity | event.severity ("3") first | event.category (e.g. SLOWDOWN, RESOURCE) first |
| Diagnostics | serviceLookup, serviceFix | Plus metadata (problemApi, tagCount, source), ciLookup, cmdbService, serviceFix.sent and error |

## How To Read The New Result

Open the run, then the task `post-silva-incident-http`, then Result.

| Field | Good value | If bad |
|---|---|---|
| `metadata.problemApi` | "ok" | "failed: ..." means the workflow cannot read problems; tags come from the event instead |
| `metadata.tagCount` | Above 0 | 0 means the host has no tags in Dynatrace |
| `metadata.businessServiceSource` | map, tag or cmdb | default means nothing better was found |
| `ciLookup.matches` | 1 | 0 means the host is not in the CMDB under those names |
| `cmdbService.sysId` | Filled | Empty means SILVA has no service linked to that host |
| `serviceLookup.businessService.status` | 200 | 401 or 403 means credentials or ACL |
| `serviceLookup.businessService.matches` | 1 or more | 0 means the name is wrong or hidden by ACL |
| `serviceFix.attempted` | true | false means no sys_id was found at all |
| `notFilled` | Empty | Lists fields SILVA still left blank |

## How To Get Real Values From Metadata

The workflow can only map what Dynatrace provides. For hosts like zdahka204b, add tags in Dynatrace:

| Tag to add on the host (or via auto-tag rule) | Example | Effect |
|---|---|---|
| `system` | EIP | SYSTEM_MAP row is used |
| `snow-service` | ALJ_EIP_PRD | Business service used directly |
| `AGO_AXA_SUPPORTGROUP` | exact SILVA group name | Assignment group used directly |

Or add the host's system to SYSTEM_MAP, or rely on the CMDB lookup (svc_ci_assoc) that seq 24 adds.

## Data Flow Map

```
Dynatrace event (host zdahka204b.pprivmgmt.intraxa, Low disk space)
   |
prepare-payload: tags (API or event) -> system? no -> source "default"
   |
post-silva-incident-http
   lookupCi: cmdb_ci name=FQDN / short / fqdn  -> ci sys_id?
   lookupSysId: cmdb_ci_service, service_offering (tolerant)
   source default + CI found -> svc_ci_assoc -> business service sys_id
   POST INC (sys_ids) -> PATCH cmdb_ci / business_service / offering
   result: metadata, ciLookup, cmdbService, serviceLookup, serviceFix, notFilled
```

## Related Files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN with fixes (import this) |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE, unchanged from seq 20 |
| `24.sh` | Manual SILVA checks for the same lookups |

## Commands

See `24.sh` (not run by me). YAMLs contain real secrets; do not push the app/Adocs copy.
