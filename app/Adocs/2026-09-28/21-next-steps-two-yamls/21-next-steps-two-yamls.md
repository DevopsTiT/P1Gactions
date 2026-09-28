# Next Steps For The Two YAMLs

## Decision Tree

```
Seq 20 YAMLs (OPEN + CLOSE with SYSTEM_MAP)
 1. Values known?
    EIP L2 group / offering unknown   -> ask Abhay, fill SYSTEM_MAP
    ALJ_EIP_PRD exact name unverified -> check in SILVA (21.sh)
    COMPASSPROXY names unknown        -> search SILVA "compass", add a row
 2. Placeholders left?
    __L3_GROUP__, __EIP_DASHBOARD_URL__, __PD_SERVICE_URL__ -> replace or set ""
 3. Safety settings
    OPEN fires on UPDATED           -> duplicate INC risk -> add duplicate check (or drop UPDATED)
    service-level problem, no host  -> SEND_CONFIGURATION_ITEM = false
    FIXED_ENVIRONMENT "Development" -> "" when ready to trust env tags
    FIXED_IMPACT / URGENCY "4"      -> "" when ready for severity-based priority
 4. Import + test
    Run workflow with a sample event -> check post-silva result (system, serviceLookup, stored, notFilled)
    Close the problem                -> check INC Resolved + PD resolved
 5. Go live
    turn trigger on, keep classic SNOW notification off, do not push app/Adocs copy
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is still missing? | Real SILVA names for the map rows (EIP group and offering, COMPASSPROXY row). |
| What must be replaced? | Three placeholders: `__L3_GROUP__`, `__EIP_DASHBOARD_URL__`, `__PD_SERVICE_URL__`. |
| Biggest risk? | The OPEN trigger includes UPDATED, so one problem can create several incidents. |
| Which file do I edit most? | The OPEN YAML, `prepare-payload` settings block at the top. |
| What does CLOSE need? | Only the same SYSTEM_MAP keys and business services as OPEN. |

## Summary

The structure is finished. What is left is filling in real values, removing placeholders, fixing the duplicate risk, and testing once end to end. Almost every change is in the settings block at the top of the OPEN `prepare-payload` script.

## Step 1: Collect The Values

| Value | Where to get it | Goes into |
|---|---|---|
| ALJ_EIP_PRD exact name | SILVA `cmdb_ci_service` (21.sh line 1) | `SYSTEM_MAP.EIP.businessService` (OPEN and CLOSE) |
| EIP service offering full name | SILVA `service_offering` where parent is ALJ_EIP_PRD (21.sh line 2) | `SYSTEM_MAP.EIP.serviceOffering` |
| EIP L2 group | Abhay, or `support_group` on ALJ_EIP_PRD | `SYSTEM_MAP.EIP.l2Group` |
| EIP L1 group (optional) | Abhay | `SYSTEM_MAP.EIP.l1Group` |
| COMPASSPROXY business service, offering, group | SILVA search "compass" (seq 19) | New `SYSTEM_MAP.COMPASSPROXY` row |
| L3 group | Abhay | `DEFAULT_GROUPS.L3` (only shown in notes) |
| Dashboard URL | Your Dynatrace dashboard | `DASHBOARD_URL` (OPEN and CLOSE) |
| PagerDuty service URL | PagerDuty service page | `PD_SERVICE_URL` (OPEN and CLOSE) |

## Step 2: Edit The OPEN YAML

All edits are inside `prepare-payload` → `// ---------- enrichment settings (edit) ----------`.

### 2a. Fill the EIP row

```js
EIP: {
  businessService: "ALJ_EIP_PRD",
  serviceOffering: "<full offering name from SILVA>",
  l1Group: "",
  l2Group: "<EIP L2 group name>",
  environment: "Production"
},
```

### 2b. Add a COMPASSPROXY row (uncomment and fill)

```js
COMPASSPROXY: {
  businessService: "<exact cmdb_ci_service name>",
  serviceOffering: "<exact service_offering name>",
  l1Group: "",
  l2Group: "<exact sys_user_group name>",
  environment: "Test"
}
```

Remember the comma between rows.

### 2c. Replace placeholders

```js
const DASHBOARD_URL = "https://<your-tenant>.apps.dynatrace.com/ui/apps/dynatrace.dashboards/dashboard/<id>";
const PD_SERVICE_URL = "https://<your-subdomain>.pagerduty.com/service-directory/<id>";
const DEFAULT_GROUPS = {
  L1: "Dynatrace Support",
  L2: "Ops_Middleware_Monitoring_AXAJP",
  L3: "<L3 group or empty>"
};
```

If you do not have a value yet, set it to `""` rather than leaving `__...__`, so the ticket does not show placeholder text.

### 2d. Safety settings

| Setting | Now | Change to | Why |
|---|---|---|---|
| `SEND_CONFIGURATION_ITEM` | true | false | Service-level problems have no host. The service name is sent as CI, SILVA cannot find it, and may swap in a default offering. |
| `FIXED_ENVIRONMENT` | "Development" | keep for testing, "" later | With "" the env tag decides (TST becomes Test). Mapped systems use the map value anyway. |
| `FIXED_IMPACT` / `FIXED_URGENCY` | "4" | keep for testing, "" later | With "" priority follows Dynatrace severity. |
| `TEST_ASSIGNMENT_GROUP` | "" | keep "" | Set a group only if you want every ticket forced to one team while testing. |
| `ASSIGNED_TO` | "Shuge KUI" | "" before go-live | Real tickets should not all land on you. |

### 2e. Fix the duplicate incident risk (recommended)

The OPEN trigger fires on CREATED, UPDATED and REOPENED. Every UPDATED event creates another incident. Pick one fix.

**Option A (simplest):** remove UPDATED from the trigger.

```yaml
      filterQuery: >-
        event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND
        (event.status_transition == "CREATED" OR event.status_transition == "REOPENED")
```

**Option B (safer):** keep the trigger, but in `post-silva-incident-http` check for an open incident with the same correlation_id before the POST. Paste this right after the `headers` block:

```js
const dupRes = await fetch(
  baseUrl + "/api/now/v2/table/incident?sysparm_query=" +
    encodeURIComponent("correlation_id=" + p.correlationId + "^active=true") +
    "&sysparm_fields=number,sys_id&sysparm_limit=1",
  { method: "GET", headers: headers }
);
let dupJson = {};
try { dupJson = JSON.parse(await dupRes.text()); } catch (e) { dupJson = {}; }
const dup = (dupJson.result || [])[0];
if (dup) {
  return {
    created: false,
    incidentNumber: dup.number,
    incidentSysId: dup.sys_id,
    note: "Open INC already exists for this problem; no new ticket",
    correlationId: p.correlationId,
    dedupKey: p.dedupKey
  };
}
```

PagerDuty is already safe, because the same `dedup_key` updates the same alert.

## Step 3: Edit The CLOSE YAML

Only the settings block in `prepare-close-ids` needs changes.

| Setting | What to do |
|---|---|
| `SYSTEM_MAP` | Same keys as OPEN, each with the same `businessService`. |
| `DASHBOARD_URL` | Same value as OPEN. |
| `PD_SERVICE_URL` | Same value as OPEN. |
| `RESOLVE_COMMENT` | Keep "Resolved" unless the team wants other wording. |

```js
const SYSTEM_MAP = {
  EIP: { businessService: "ALJ_EIP_PRD" },
  COMPASSPROXY: { businessService: "<exact cmdb_ci_service name>" }
};
```

## Step 4: Import And Test

| Step | Action | What good looks like |
|---|---|---|
| 1 | Workflows → Upload, pick the OPEN YAML (repeat for CLOSE) | Both import with no error |
| 2 | Settings → External requests: allow `silvastg.service-now.com` and `events.pagerduty.com` | Tasks do not fail with a network error |
| 3 | OPEN → Run workflow with a sample event (for example the COMPASSPROXY one) | All 3 tasks green |
| 4 | Open `post-silva-incident-http` result | `system` shows the expected match, `serviceLookup.*.matches` is 1, `notFilled` is empty or near empty |
| 5 | Check the INC in SILVA | Business service, offering, group and priority as expected |
| 6 | Run the same event again (Option B only) | `created: false`, no second INC |
| 7 | Close the problem in Dynatrace, or run CLOSE with the same display_id | INC state Resolved, comment "Resolved", PD alert resolved |

### Reading test results

| Result field | Problem | Fix |
|---|---|---|
| `system` says "no SYSTEM_MAP match" | The tag value does not contain the key as a whole word | Check the event tags, and add a `system` tag or change the key |
| `serviceLookup.businessService.matches` is 0 | Name in the map differs from SILVA | Copy the exact name from SILVA |
| `matches` is 2 | Two records share the name | Ask the SILVA admin, or use a more exact name |
| `notFilled` lists `assignedTo` | The group is not the default L2 group | Expected behaviour |
| HTTP 401 / 403 | Password or table permission | Check credentials and ACLs |

## Step 5: Go Live Checklist

| Check | Done when |
|---|---|
| No `__...__` placeholders left | Search both files for `__` |
| ASSIGNED_TO emptied | `const ASSIGNED_TO = "";` |
| Duplicate fix applied | Option A or B in place |
| Classic SNOW Problem notification off | No second INC from the old integration |
| app/Adocs copy not pushed | It contains the real password and routing key |

## Data Flow Map

```
You: collect SILVA names  ->  edit OPEN settings (map, placeholders, safety)
                           ->  edit CLOSE settings (same map keys)
   -> upload both YAMLs -> allowlist hosts
   -> Run OPEN test -> check post-silva result -> check INC in SILVA
   -> Run CLOSE test -> INC Resolved + PD resolved
   -> go live checklist
```

## Related Files

| File | Purpose |
|---|---|
| `../20-silva-system-data-map/1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN YAML to edit |
| `../20-silva-system-data-map/2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE YAML to edit |
| `../19-analyse-dt-event-for-silva-mapping/` | How to find names from the event |
| `../18-silva-export-groups-business-services/` | Export groups and services |
| `21.sh` | Lookup commands |

## Commands

See `21.sh` (not run by me).
