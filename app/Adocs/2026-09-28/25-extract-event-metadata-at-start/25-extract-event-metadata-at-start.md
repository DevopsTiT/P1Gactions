# Extract Event Metadata At Workflow Start

## Decision Tree

```
Workflow starts -> readEventMeta(event)  (no API call needed)
 entity_tags "[Context]key:value"  -> tag list
 dt.cost.product, dt.cost.costcenter, k8s.namespace.name, k8s.cluster.name -> tag list
 affected_entity_types has HOST?   -> affected_entity_names become the host
 dt.security.context               -> most specific one (ALJ_EIP_PRD) -> env suffix PRD
 then per SILVA field (first hit wins):
   business service  -> SYSTEM_MAP -> tag snow-service / ago_axa_businessservice / ... -> default
   service offering  -> SYSTEM_MAP -> tag snow-offering / ... -> default only with default service
   assignment group  -> tag ago_axa_supportgroup / support-group / ... -> map L2 -> default L2
   environment       -> SYSTEM_MAP -> tag ago_axaenvironmentname / env -> security context -> Development
                        (only if the value is in SILVA_ENVIRONMENTS)
 Problems API tags are added after, as extra input
 work notes show every value and where it came from
```

## Short Takeaway

| Question | Answer |
|---|---|
| Does the workflow now read the event metadata at start? | Yes. `readEventMeta` runs first and needs no API call. |
| What does it read? | Tags, cost and Kubernetes fields, security context, affected entity names and types, host, category. |
| Which tag names feed SILVA fields? | Listed in `META_KEYS` at the top; add the names your tenant uses. |
| Does metadata beat the fixed defaults? | Yes. Defaults are used only when metadata has nothing. |
| How do I see what it found? | Work notes block "Event metadata used at workflow start", and `eventMeta` in the prepare-payload result. |
| New folder | `25-extract-event-metadata-at-start/` (OPEN changed, CLOSE same as seq 24) |

## Summary

The OPEN workflow now starts by reading everything the Dynatrace trigger event carries. It turns tags and top-level fields into one list, finds the host and the environment, and then routes each SILVA field from that metadata first. The work notes on the ticket list every value and its source, so you can see immediately why a field has the value it has.

## The New Settings (top of prepare-payload)

```js
const META_KEYS = {
  businessService: ["snow-service", "ago_axa_businessservice", "business-service", "businessservice", "u_business_service"],
  serviceOffering: ["snow-offering", "ago_axa_serviceoffering", "service-offering"],
  assignmentGroup: ["ago_axa_supportgroup", "support-group", "supportgroup", "assignment-group", "snow-group"],
  environment: ["ago_axaenvironmentname", "env", "environment"],
  system: ["system", "app", "dt.cost.product"]
};
const META_FIELDS = ["dt.cost.product", "dt.cost.costcenter", "k8s.namespace.name", "k8s.cluster.name"];
const SILVA_ENVIRONMENTS = ["Production", "Development"];
```

| Setting | What it means | When to change |
|---|---|---|
| `META_KEYS.businessService` | Tag names that hold a SILVA business service name | Add the tag name your team puts on hosts |
| `META_KEYS.assignmentGroup` | Tag names that hold a SILVA group name | Same |
| `META_KEYS.environment` | Tag names that hold the environment | Same |
| `META_KEYS.system` | Tag names that hold the system for SYSTEM_MAP | Same |
| `META_FIELDS` | Event fields that are not in entity_tags but are useful | Add other top-level fields you see in `eventKeys` |
| `SILVA_ENVIRONMENTS` | Environment labels confirmed to exist in SILVA | Add "Test", "Staging" etc. only after checking SILVA's choice list |

## What It Would Find In Your Two Sample Events

| Field | COMPASSPROXY event (service problem) | zdahka204b event (host problem) |
|---|---|---|
| System | COMPASSPROXY (no SYSTEM_MAP row yet) | Depends on host tags |
| Business service | Default, unless a snow-service style tag exists | Default, or CMDB lookup (seq 24) |
| Assignment group | Default L2 | Default L2, unless the host has a support-group tag |
| Environment wanted | Test (from env:TST) | From host tags or security context |
| Environment sent | Development, because Test is not in SILVA_ENVIRONMENTS yet | Depends |
| Host | None (service names are skipped) | zdahka204b.pprivmgmt.intraxa |
| Security context | ALJ_APPLICATION_COMPASSPROXY_TST and others | Whatever the host has |

## What The Work Notes Will Show

```
Event metadata used at workflow start
  System            : no SYSTEM_MAP match, defaults used
  Business service  : uk-sap-fscd-dev (default)
  Service offering  : uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard
  Assignment group  : Ops_Middleware_Monitoring_AXAJP (default L2)
  Environment       : Development (default (metadata said Test, not in SILVA_ENVIRONMENTS))
  Host              : none (not a host problem)
  Affected types    : dt.entity.service
  Security context  : ALJ, ALJ_APPLICATION_COMPASSPROXY_TST, ...
  Problems API      : ok
  Tag keys (14)     : kubernetesnamespace, app, bu, company, dt.cost.costcenter, dt.cost.product, env, host, ...
```

The "Tag keys" line is the key output. It tells you which tag names really exist, so you can add the right names to `META_KEYS` or `SYSTEM_MAP`.

## Important Limit

The workflow can only use what Dynatrace puts in the event. Neither sample event contains a SILVA business service or SILVA group name. To get real values from metadata, one of these must be true:

| Option | Example |
|---|---|
| A tag with the SILVA service on the entity | `snow-service:ALJ_EIP_PRD` |
| A tag with the SILVA group on the entity | `AGO_AXA_SUPPORTGROUP:<exact group>` |
| A system tag plus a SYSTEM_MAP row | `system:EIP` and the EIP row |
| An app / cost product tag plus a SYSTEM_MAP row | `app:COMPASSPROXY` and a COMPASSPROXY row |

Tags can be added in Dynatrace with an automatic tagging rule (Settings, Tags, Automatically applied tags), for example based on host group or Kubernetes namespace.

## Data Flow Map

```
Trigger event
   |
readEventMeta ---> tagList, hosts, securityContext, affected types/names, eventKeys
   |
+ Problems API tags (extra)
   |
routing (first hit wins, source recorded)
   business service / offering / group / environment / system
   |
metaNote -> work notes ; eventMeta -> task result
   |
post-silva-incident-http (seq 24 lookups: sys_id, CI, CMDB service) -> INC
```

## Related Files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN with metadata extraction (import this) |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE, same as seq 24 |
| `25.sh` | Commands to check tags and SILVA environment choices |

## Commands

See `25.sh` (not run by me). YAMLs contain real secrets; do not push the app/Adocs copy.
