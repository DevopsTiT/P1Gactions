# Open Close Service Sys ID And Low Priority

```
Workflow ran → Business service blank, offering "- AXA GROUP OPERATIONS - Development - Standard_2026-07-27..."
 Why? SILVA did not accept the names → left service blank → a rule picked a default offering
 Fix (seq 16):
   1) look up sys_id of business service (cmdb_ci_service) and offering (service_offering) by name
   2) POST with sys_ids
   3) PATCH the two sys_ids again right after create
 After a test run, read the post-silva-incident-http result:
   serviceLookup.*.matches = 0      → name wrong, or API user cannot read the table (status 403)
   serviceLookup.*.matches = 2      → name not unique → put the sys_id in the setting directly
   serviceFix.businessService blank → a SILVA rule clears it → set SEND_CONFIGURATION_ITEM = false and retry
   all filled                       → done
 Impact / Urgency fixed 4 → Priority 4 - Low
```

## Short takeaway

| Question | Answer |
|---|---|
| Why were business service and offering empty? | SILVA did not match the names we sent. It left business service blank and a default rule filled in an offering. |
| What does seq 16 do differently? | It looks up each record's sys_id first, sends the sys_ids, then sets them again with a PATCH after create. |
| Default business service | uk-sap-fscd-dev |
| Default offering | uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard |
| Impact / Urgency / Priority | 4 - Low / 4 - Low / 4 - Low |
| Unchanged from seq 15 | Environment Development, group Ops_Middleware_Monitoring_AXAJP, Shuge KUI, title format, "Resolved" comment, password and routing key. |

## Summary

Reference fields like business service are safest to set by sys_id. The workflow now finds the sys_ids itself, so you keep editing plain names in the settings. The task result shows exactly what was found and what SNOW stored, so a blank field can be traced in one run.

## What you saw

| Screenshot | Field | Value | Meaning |
|---|---|---|---|
| Target ticket | Business service | uk-sap-fscd-dev | What we want |
| Target ticket | Service offering | uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard | What we want |
| Target ticket | Impact / Urgency / Priority | 4 - Low | What we want |
| Workflow ticket | Business service | Blank | Our name was not accepted |
| Workflow ticket | Service offering | - AXA GROUP OPERATIONS - Development - Standard_2026-07-27 11:49:26 | A default offering (no service in front) chosen by a SILVA rule |

## OPEN changes

| Where | Change |
|---|---|
| Settings | New `FIXED_IMPACT = "4"` and `FIXED_URGENCY = "4"`. |
| Settings | New `SEND_CONFIGURATION_ITEM = true` (switch off if the service is still blank). |
| prepare-payload | Impact and urgency use the fixed values when set. |
| post-silva-incident-http | New `lookupSysId` helper. |
| post-silva-incident-http | Looks up the business service in `cmdb_ci_service` and the offering in `service_offering`. |
| post-silva-incident-http | Sends sys_ids in the POST, falling back to the names. |
| post-silva-incident-http | PATCHes the two sys_ids after create. |
| post-silva-incident-http | The result now includes `serviceLookup` and `serviceFix`. |

Settings:

```javascript
const BUSINESS_SERVICE = "uk-sap-fscd-dev";
const SERVICE_OFFERING = "uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard";
const FIXED_ENVIRONMENT = "Development";
// "4" + "4" gives Priority "4 - Low"; set "" to derive impact / urgency from problem severity
const FIXED_IMPACT = "4";
const FIXED_URGENCY = "4";
// SILVA rules may re-derive business service from the CI; set false if the service still comes out blank
const SEND_CONFIGURATION_ITEM = true;
```

Lookup and send:

```javascript
const bsLookup = await lookupSysId(baseUrl, headers, "cmdb_ci_service", p.businessService);
const soLookup = await lookupSysId(baseUrl, headers, "service_offering", p.serviceOffering);
// in the POST body
business_service: bsLookup.sysId || p.businessService,
service_offering: soLookup.sysId || p.serviceOffering,
```

After create:

```javascript
const fixBody = {};
if (bsLookup.sysId) fixBody.business_service = bsLookup.sysId;
if (soLookup.sysId) fixBody.service_offering = soLookup.sysId;
// PATCH /api/now/v2/table/incident/<sys_id> with raw sys_ids
```

CLOSE: no change. It already uses uk-sap-fscd-dev in its notes.

## Reading the task result

| Result field | Good value | If not |
|---|---|---|
| `serviceLookup.businessService.matches` | 1 | 0 means the name is wrong or the API user cannot read `cmdb_ci_service`. 2 means the name is not unique. |
| `serviceLookup.serviceOffering.matches` | 1 | Same checks on `service_offering`. |
| `serviceLookup.*.status` | 200 | 403 means ask the SILVA admin for read access on that table. |
| `serviceFix.status` | 200 | 403 means the API user cannot update those fields. |
| `serviceFix.businessService` | uk-sap-fscd-dev | Blank means a rule clears it. Set `SEND_CONFIGURATION_ITEM = false` and test again. |
| `stored.priority` | 4 - Low | Different means SILVA's priority matrix differs, so check with the admin. |

## Data flow map

```
prepare-payload
  impact 4, urgency 4, names of service + offering
        │
post-silva-incident-http
  GET cmdb_ci_service?name=uk-sap-fscd-dev             → bs sys_id
  GET service_offering?name=uk-sap-fscd-dev - ... - Standard → so sys_id
  POST incident (sys_ids, impact 4, urgency 4, group, assignee)
  PATCH incident business_service + service_offering (sys_ids)
        │
        ▼
  INC: Development / uk-sap-fscd-dev / ... Development - Standard / 4 - Low
  result: serviceLookup, serviceFix, stored, notFilled
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN with sys_id lookup and 4 - Low |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE, same as seq 15 |
| `16.sh` | Manual lookups and a check of the latest ticket |

Commands: see `16.sh` in this folder.
