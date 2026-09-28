# SILVA System Data Map

## Decision Tree

```
Problem opens in Dynatrace
 find the system name
   tag system / app / dt.cost.product  -> e.g. EIP, COMPASSPROXY
   else dt.security.context            -> e.g. ALJ_EIP_PRD contains the word EIP
   else affected / root cause entity name
 system is in SYSTEM_MAP?
   yes -> business service, offering, env, L1/L2 group from the map
          (any value left "" falls back to the default)
   no  -> defaults: uk-sap-fscd-dev, its Development offering, Ops_Middleware_Monitoring_AXAJP
 assignment group
   TEST_ASSIGNMENT_GROUP set?          -> use it (testing only)
   tag AGO_AXA_SUPPORTGROUP present?   -> use it
   else L2 group (passed by default)   -> map L2, else DEFAULT_GROUPS.L2
 business service changed in SILVA?
   edit SYSTEM_MAP only (same row in OPEN and CLOSE)
```

## Short Takeaway

| Question | Answer |
|---|---|
| What did Abhay ask for? | A data map from Dynatrace system to SILVA values, so a business service change means editing the map only. |
| What is his example? | If the problem comes from system EIP, set business service ALJ_EIP_PRD. |
| Which group by default? | The L2 SILVA group. |
| Where is the map? | `SYSTEM_MAP` at the top of the prepare-payload script in the OPEN YAML (and a copy in CLOSE for the notes). |
| What if nothing matches? | The current defaults are used, so today's behaviour stays the same. |
| New YAML folder | `20-silva-system-data-map/` |

## Summary

Abhay wants routing driven by a small lookup table instead of hard-coded values. The workflow now finds the system name in the problem, looks it up in `SYSTEM_MAP`, and uses the row's business service, offering, environment and groups. The L2 group is sent by default. Unknown systems keep the current defaults.

## What Abhay's Message Means

| His words | What it means in the workflow |
|---|---|
| "L1 and L2 group on Silva we can get it from some data mapping from Dynatrace" | Each map row can hold `l1Group` and `l2Group`. |
| "in case any change in business service we can update that data map only" | All SILVA names live in `SYSTEM_MAP`. Nothing else in the code needs to change. |
| "L2_Silva_group -> Pass it by default" | `DEFAULT_TIER = "L2"`. Tickets go to the L2 group unless the map or a tag says otherwise. |
| "IN case error is from system EIP then fetch the business service from data map" | The workflow detects the system (EIP) and reads its row. |
| "EIP = ALJ_EIP_PRD (Business service)" | The first row: `EIP: { businessService: "ALJ_EIP_PRD" }`. |

## The Map (OPEN YAML)

```js
const SYSTEM_MAP = {
  EIP: {
    businessService: "ALJ_EIP_PRD",
    serviceOffering: "",
    l1Group: "",
    l2Group: "",
    environment: "Production"
  }
  // COMPASSPROXY: {
  //   businessService: "<exact cmdb_ci_service name>",
  //   serviceOffering: "<exact service_offering name>",
  //   l1Group: "",
  //   l2Group: "<exact sys_user_group name>",
  //   environment: "Test"
  // }
};
const SYSTEM_TAG_KEYS = ["system", "app", "dt.cost.product"];
const DEFAULT_GROUPS = {
  L1: "Dynatrace Support",
  L2: "Ops_Middleware_Monitoring_AXAJP",
  L3: "__L3_GROUP__"
};
const DEFAULT_TIER = "L2";
```

### Map fields

| Field | What it means | If left "" |
|---|---|---|
| `businessService` | Exact SILVA business service name (`cmdb_ci_service`) | Uses the snow-service tag, then `uk-sap-fscd-dev` |
| `serviceOffering` | Exact full offering name (`service_offering`) | No offering is sent, so SILVA picks one for that business service |
| `l1Group` | L1 SILVA group for this system | Uses `DEFAULT_GROUPS.L1` |
| `l2Group` | L2 SILVA group for this system (sent by default) | Uses `DEFAULT_GROUPS.L2` |
| `environment` | SILVA environment | Uses `FIXED_ENVIRONMENT`, then the env tag |

## How The System Is Detected

| Order | Where it looks | Example from your COMPASSPROXY event |
|---|---|---|
| 1 | Tag `system` | Not present |
| 2 | Tag `app` | COMPASSPROXY |
| 3 | Tag `dt.cost.product` | COMPASSPROXY |
| 4 | `dt.security.context` | ALJ_APPLICATION_COMPASSPROXY_TST |
| 5 | Root cause and affected entity names | [COMPASSPROXY.TST] compass-proxy-ccifa-* |

Matching is by **whole word**. The value is split on `_`, `-`, `.`, spaces and brackets, so `ALJ_EIP_PRD` matches `EIP`, but `RECEIPT` does not.

## What Changed vs Seq 16

| Area | Before (seq 16) | Now (seq 20) |
|---|---|---|
| Business service | Always uk-sap-fscd-dev | Map value, else snow-service tag, else uk-sap-fscd-dev |
| Service offering | Always the uk-sap-fscd-dev offering | Map value; mapped systems without one send none; unmapped keep the default |
| Assignment group | Fixed Ops_Middleware_Monitoring_AXAJP | L2 group from map, else Ops_Middleware_Monitoring_AXAJP |
| Assigned to | Always Shuge KUI | Shuge KUI only when the group is Ops_Middleware_Monitoring_AXAJP |
| Environment | Fixed Development | Map value first, else Development |
| Notes | No system line | Customer notes and PagerDuty show which system matched and why |
| CLOSE | Fixed business service in notes | Same map, so the close notes show the same service |

## How To Add A New System

| Step | Action |
|---|---|
| 1 | Find the exact business service, offering and group names in SILVA (see seq 18 and 19). |
| 2 | Add a row to `SYSTEM_MAP` in the OPEN YAML. |
| 3 | Add the same key and `businessService` to `SYSTEM_MAP` in the CLOSE YAML. |
| 4 | Test with "Run workflow" and check `system`, `serviceLookup` and `stored` in the post-silva result. |

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Name in the map differs slightly from SILVA | The sys_id lookup finds 0 rows and the field stays blank | Copy the exact name from the SILVA record. |
| Very short or generic map key such as `AXA` | Almost every problem matches it | Use distinct system names only. |
| Group set in the map but ASSIGNED_TO expected | Person is left empty on purpose | Assign inside SILVA, or ask for a person per group later. |
| Map updated in OPEN only | Close notes show a different business service | Keep both maps in sync. |

## Data Flow Map

```
Dynatrace problem event
   |
   v
prepare-payload
   systemCandidates(): tags system/app/dt.cost.product -> security context -> entity names
   findSystem(): whole-word match against SYSTEM_MAP keys
   match    -> businessService, serviceOffering, environment, l1Group, l2Group
   no match -> defaults
   group = TEST override -> AGO_AXA_SUPPORTGROUP tag -> L2 (map or default)
   |
   +--> post-silva-incident-http: sys_id lookup -> POST -> PATCH services
   +--> trigger-pagerduty: custom_details.system shows the match
```

## Related Files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN workflow with SYSTEM_MAP |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow with the same map for notes |
| `0-pic.md` | Picture of the routing |
| `1-investigation.md` | What was read |
| `2-result.md` | What to do next |
| `3-glossary.md` | Terms |
| `20.sh` | Commands to check the map values in SILVA |

## Commands

See `20.sh` (not run by me). The YAMLs contain the real password and routing key. Do not commit or push the app/Adocs copy.
