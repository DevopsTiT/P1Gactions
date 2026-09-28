# Analyse Dynatrace Event For SILVA Mapping

## Decision Tree

```
Dynatrace problem event (the JSON on the "Run workflow" screen)
 Is this what SILVA receives?
   No. It is the workflow INPUT. SILVA only gets the fields our prepare-payload JS builds.
 Does the event carry a SILVA business service name (e.g. snow-service tag)?
   Yes -> use it directly
   No (this event) -> derive from app / product tags
 Which tag identifies the application?
   dt.cost.product:COMPASSPROXY  -> strongest (one app name, owned by cost team)
   app:COMPASSPROXY              -> same value, backup
   k8s.namespace.name            -> compassproxy-testing-axa-li-jp, useful for env + app
 Which tag identifies the environment?
   env:TST -> map to SILVA environment (Test)
 Is there a real CMDB host?
   No. "host:" tag lists Kubernetes POD names (compass-proxy-ccifa-10-7b879b7fd9-kfxzt)
   Pods are temporary -> never in CMDB -> do NOT send as cmdb_ci
 Search SILVA for "compass" in business services, offerings, groups
   Found one match -> put into mapping table in the YAML
   Found many      -> ask Abhay/Davesh which one is correct
   Found none      -> use the default (uk-sap-fscd-dev / Ops_Middleware_Monitoring_AXAJP)
```

## Short Takeaway

| Question | Answer |
|---|---|
| Is this the data sent to SILVA? | No. It is the Dynatrace problem event that triggers the workflow. |
| What does SILVA actually receive? | Only the incident fields our JavaScript builds, such as short_description, business_service and assignment_group. |
| Does the event contain the business service? | No. There is no snow-service tag and no SILVA name anywhere. |
| Does it contain the assignment group? | No. It only has ownership hints like bu and cost center. |
| Best key to map from | `dt.cost.product:COMPASSPROXY` together with `env:TST`. |
| Where do the SILVA values come from? | A lookup in SILVA (groups, services, offerings), then a mapping table inside the YAML. |

## Summary

The event tells us **which application** (COMPASSPROXY) and **which environment** (TST) had the problem, but it says nothing in SILVA language. So the analysis is a translation job. First pick stable identifying tags from the event. Then find the matching SILVA business service, offering and group. Finally write that pair into a small mapping table in the OPEN workflow, keeping today's defaults as a fallback.

## Step 1: Read The Event Field By Field

### Fields that identify the problem (not useful for routing)

| Field | Value in your event | What it means |
|---|---|---|
| `display_id` | P-260915351 | The problem number. We use it as the SILVA correlation_id. |
| `event.name` | Response time degradation | Goes into the ticket title. |
| `event.category` | SLOWDOWN | Type of problem. It can drive priority. |
| `event.status` | ACTIVE | The problem is open. |
| `event.status_transition` | UPDATED | The problem changed, not newly created. This is why duplicates are possible. |
| `event.severity` | 3 | Dynatrace severity level. |
| `affected_entity_ids` | SERVICE-4C92DDBDD78986D0 | The affected thing is a SERVICE, not a host. |
| `affected_entity_types` | dt.entity.service | Confirms it is service-level. |
| `related_entity_ids` | PROCESS_GROUP-FBFA7DE3E44C269C | The nginx process group behind the service. |

### Fields that can drive routing (the useful ones)

| Tag in `entity_tags` | Value | Useful for | How reliable |
|---|---|---|---|
| `dt.cost.product` | COMPASSPROXY | Business service | High. It is one clear product name. |
| `dt.cost.product` | ILLUSTRATION-PROPOSAL-AXA-COMPASS | Business service (a second candidate) | Medium. There are two products, so we need a rule for which one wins. |
| `app` | COMPASSPROXY | Business service backup | High. Same as the cost product. |
| `app` | ILLUSTRATION-PROPOSAL-AXA-COMPASS | Business service (a second candidate) | Medium. |
| `env` | TST | Environment | High. Maps to SILVA "Test". |
| `bu` | NB-IT-COMPASS-AXAJP | Assignment group hint | Medium. It names the owning team area. |
| `bu` | APPLICATION | Category | Low. It is too generic. |
| `company` | ALJ | Company | Medium. ALJ is AXA Life Japan. |
| `dt.cost.costcenter` | ALJ | Company or cost center | Medium. |
| `k8s.namespace.name` | compassproxy-testing-axa-li-jp | Application and environment | Medium. Useful if the tags are missing. |
| `tier` | APP and NGINX | Layer | Low. Informational only. |
| `dt.security.context` | ALJ_APPLICATION_COMPASSPROXY_TST | Application plus environment in one value | High. It is a clean key if tags are messy. |

### Fields to ignore for routing

| Field | Why ignore it |
|---|---|
| `[Kubernetes]app:compass-proxy-ccifa-1..11` and `pbco-1..11` | These are per-deployment labels. There are too many and they change. |
| `host:compass-proxy-ccifa-10-7b879b7fd9-kfxzt, ...` | These are pod names. Pods are recreated all the time and are never in the SILVA CMDB. |
| `[Environment]DT_RELEASE_PRODUCT` and `DT_RELEASE_VERSION` | These are empty placeholders here. |
| `logforwarder...` and `resources.pod-adm-ctr...` | These are platform settings, not ownership. |

## Step 2: Find The Matching SILVA Values

Search SILVA using the words from Step 1: compass, compassproxy, NB-IT, ALJ.

| What to find | SILVA table | Search for |
|---|---|---|
| Business service | `cmdb_ci_service` | name contains `compass` |
| Service offering | `service_offering` | name contains `compass`, then choose the one with Test or Development environment |
| Assignment group | `sys_user_group` | name contains `compass`, `NB-IT` or `AXAJP` |
| Group that already supports the service | `cmdb_ci_service` field `support_group` / `assignment_group` | read it from the business service you found |

**UI way:** In the SILVA filter navigator, type `cmdb_ci_service.list`, then filter Name contains `compass`. Repeat for `service_offering.list` and `sys_user_group.list`.

**API way:** see `19.sh`. For example:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service?sysparm_query=nameLIKEcompass&sysparm_fields=name,sys_id,support_group,assignment_group,operational_status&sysparm_display_value=true&sysparm_exclude_reference_link=true&sysparm_limit=200"
```

**Best shortcut:** once you find the business service, its `support_group` field is usually the right assignment group. That is SILVA's own answer, so you do not need to guess.

## Step 3: Fill A Mapping Table

Write down what you found, one application per row.

| Dynatrace key (dt.cost.product) | env | SILVA business service | SILVA service offering | SILVA assignment group |
|---|---|---|---|---|
| COMPASSPROXY | TST | (from SILVA search) | (from SILVA search) | (from SILVA search) |
| ILLUSTRATION-PROPOSAL-AXA-COMPASS | TST | (from SILVA search) | (from SILVA search) | (from SILVA search) |
| anything not listed | any | uk-sap-fscd-dev | uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard | Ops_Middleware_Monitoring_AXAJP |

## Step 4: How The YAML Would Use It (Proposal, Not Applied Yet)

In the prepare-payload task, gather all tag values for a key, then pick the first one that exists in the map:

```js
function tagValues(tags, key) {
  const out = [];
  for (const t of tags || []) {
    const s = String(t).replace(/^\[[^\]]+\]/, "");
    const i = s.indexOf(":");
    if (i > 0 && s.slice(0, i) === key) out.push(s.slice(i + 1));
  }
  return out;
}

const SERVICE_MAP = {
  "COMPASSPROXY": {
    businessService: "__SILVA_BUSINESS_SERVICE__",
    serviceOffering: "__SILVA_SERVICE_OFFERING__",
    assignmentGroup: "__SILVA_GROUP__"
  }
};

const ENV_MAP = { TST: "Test", STG: "Staging", PRE: "Pre-Production", PRD: "Production" };

const products = tagValues(tags, "dt.cost.product").concat(tagValues(tags, "app"));
const hit = products.map(v => SERVICE_MAP[v.toUpperCase()]).find(Boolean);
const envTag = (tagValues(tags, "env")[0] || "").toUpperCase();

const businessService = (hit && hit.businessService) || BUSINESS_SERVICE;
const serviceOffering = (hit && hit.serviceOffering) || SERVICE_OFFERING;
const assignmentGroup = (hit && hit.assignmentGroup) || TEST_ASSIGNMENT_GROUP;
const environment = ENV_MAP[envTag] || FIXED_ENVIRONMENT;
```

The existing sys_id lookup and PATCH (seq 16) still run afterwards, so the names only need to match SILVA exactly.

## Common Mistakes

| Mistake | What happens | Do this instead |
|---|---|---|
| Sending a pod name as `cmdb_ci` | SILVA cannot find it, so the CI stays blank or the ticket gets the wrong default | Do not send pod names. Send nothing, or send the business service directly. |
| Using `[Kubernetes]app:compass-proxy-ccifa-7` | Every deployment number needs its own row | Use `dt.cost.product` or `app`, which have one value per application. |
| Guessing the group from `bu` text | The ticket goes to a team that does not exist | Take `support_group` from the SILVA business service record. |
| Picking a Production offering for `env:TST` | SILVA reports look wrong and the priority rules differ | Match the offering environment to the env tag. |

## Data Flow Map

```
Dynatrace problem (SERVICE-4C92DDBDD78986D0, env:TST)
   |
   v
Workflow trigger event (the JSON you screenshotted)
   |
   v
prepare-payload JS
   reads dt.cost.product / app  -> COMPASSPROXY
   reads env                    -> TST -> Test
   looks up SERVICE_MAP         -> business service, offering, group
   no hit                       -> defaults (uk-sap-fscd-dev, Ops_Middleware_Monitoring_AXAJP)
   |
   v
POST to SILVA incident (names)
   |
   v
sys_id lookup + PATCH (seq 16) -> business service and offering filled on the ticket
```

## Related Files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and flow |
| `1-investigation.md` | What was read from the event |
| `2-result.md` | What to do next |
| `3-glossary.md` | Terms |
| `19.sh` | SILVA search one-liners |
| `../18-silva-export-groups-business-services/` | Full exports of groups and services |
| `../16-open-close-service-sysid-low-priority/` | Current YAMLs with the sys_id fix |

## Commands

All commands are in `19.sh` (not run by me). Replace `__SNOW_PASSWORD__` before running.
