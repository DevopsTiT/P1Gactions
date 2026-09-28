# How Environment Service And Group Are Derived

## Decision Tree

```
Problem opens -> workflow reads tags on the affected entity (host / process)
 ENVIRONMENT
   SYSTEM_MAP row has environment?            -> use it
   tag AGO_AXAENVIRONMENTNAME?                -> map value (Integration-Test -> Integration / Test)
   tag env? (PRD / TST / DEV)                 -> map value
   security context ends with _PRD / _TST?    -> map value
   none, or value not allowed in SILVA        -> Development (FIXED_ENVIRONMENT)
 BUSINESS SERVICE (+ offering)
   SYSTEM_MAP row (e.g. EIP -> ALJ_EIP_PRD)?   -> send it
   tag snow-service / ago_axa_businessservice? -> send it
   else host found in SILVA CMDB?              -> send only the CI, SILVA fills the service itself
       SILVA left it blank?                    -> svc_ci_assoc (host -> service link)
       still blank?                            -> uk-sap-fscd-dev (default)
   host not found                              -> uk-sap-fscd-dev + its offering
 ASSIGNMENT GROUP
   TEST_ASSIGNMENT_GROUP set?                  -> use it (testing only)
   tag AGO_AXA_SUPPORTGROUP?                   -> use it
   tag AGO_DEFAULT_ASSIGNMENT_GROUP?           -> use it
   SYSTEM_MAP l2Group?                         -> use it
   else                                        -> Ops_Middleware_Monitoring_AXAJP (default L2)
```

## Short Takeaway

| Field | Main source | Example 1 (INC30339531) | Example 2 (INC30339746) |
|---|---|---|---|
| Environment | Tag `AGO_AXAENVIRONMENTNAME` | Integration-Test becomes Integration / Test | Development |
| Business service | SILVA fills it from the configuration item (host) | Third Party Services Monitoring Application | Third Party Services Monitoring Application |
| Service offering | Same as business service | Third Party Services Monitoring Application | Third Party Services Monitoring Application |
| Assignment group | Tag `AGO_AXA_SUPPORTGROUP` | InfraSupport_Dist-WindowsID_L2_ASIA | InfraSupport_Dist-WindowsHK_L2_ASIA |

## Summary

Environment and assignment group come straight from AGO tags that AXA puts on every Dynatrace host. The business service is not in the tags. It comes from SILVA itself: the workflow sends the host as the configuration item, and SILVA looks up in its CMDB which business service that host belongs to. Defaults are used only when these sources give nothing.

## 1. Environment

### Where the tag lives

On the host in Dynatrace, for example:

```
AGO_AXAENVIRONMENTNAME:Integration-Test     (example 1)
AGO_AXAENVIRONMENTNAME:Development          (example 2)
```

### Order the workflow checks

| Order | Source | Example value | Result |
|---|---|---|---|
| 1 | SYSTEM_MAP row `environment` | EIP row: Production | Production |
| 2 | Tag `AGO_AXAENVIRONMENTNAME` | Integration-Test | Integration / Test |
| 3 | Tag `env` | TST | Integration / Test |
| 4 | Security context suffix | ALJ_EIP_PRD | Production |
| 5 | FIXED_ENVIRONMENT | nothing found | Development |

### Translation table (ENVIRONMENT setting)

| Tag value | SILVA label |
|---|---|
| Production, PROD, PRD | Production |
| Development, DEV | Development |
| Integration-Test, Integration, Test, TST | Integration / Test |

A value is only sent if it is in `SILVA_ENVIRONMENTS` (Production, Development, Integration / Test), because SILVA silently drops unknown labels and Environment is mandatory.

## 2. Business Service (and Service Offering)

### Why there is no tag for it

Neither example has a business service tag (`u_business_service` shows `<<UNKNOWN>>`). SILVA still filled "Third Party Services Monitoring Application". It did this from the **configuration item** (the host): the CMDB links each host to its business service.

### How the workflow gets it

| Step | What happens | Example 2 |
|---|---|---|
| 1 | Find the host from Dynatrace (Entities API, then host + AGO_DOMAIN tags) | TS12.hk.intraxa |
| 2 | Look it up in SILVA cmdb_ci (full name, short name, fqdn) | ts12.hk.intraxa found |
| 3 | Send the incident with the CI and no business service | cmdb_ci = sys_id of ts12 |
| 4 | SILVA insert rules fill business service and offering from the CI | Third Party Services Monitoring Application |
| 5 | If still blank: read svc_ci_assoc for the host | (not needed) |
| 6 | If still blank: default uk-sap-fscd-dev | (not needed) |

### When a fixed value is used instead

| Case | Value sent |
|---|---|
| System found in SYSTEM_MAP (e.g. EIP) | Map value, e.g. ALJ_EIP_PRD |
| Tag `snow-service` or `ago_axa_businessservice` exists | Tag value |
| Host not found in SILVA | uk-sap-fscd-dev and its Development offering |

## 3. Assignment Group

### Where the tag lives

On the host in Dynatrace:

```
AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsID_L2_ASIA     (example 1)
AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsHK_L2_ASIA     (example 2)
AGO_DEFAULT_ASSIGNMENT_GROUP:InfraSupport_Dist-WindowsID_L2_ASIA
```

### Order the workflow checks

| Order | Source | Example |
|---|---|---|
| 1 | TEST_ASSIGNMENT_GROUP (testing only, now "") | not used |
| 2 | Tag `AGO_AXA_SUPPORTGROUP` | InfraSupport_Dist-WindowsHK_L2_ASIA |
| 3 | Tag `AGO_DEFAULT_ASSIGNMENT_GROUP` | backup |
| 4 | SYSTEM_MAP `l2Group` | EIP L2 group once filled |
| 5 | DEFAULT_GROUPS.L2 | Ops_Middleware_Monitoring_AXAJP |

Assigned to is filled (Shuge KUI) only when the default group is used. With a tag group it stays empty, like both examples.

## Quick Check On A New Ticket

The work notes show a "Metadata used" block:

```
Assignment group  : InfraSupport_Dist-WindowsHK_L2_ASIA (tag ago_axa_supportgroup)
Environment       : Development (tag ago_axaenvironmentname = Development)
Business service  : from CI in SILVA, fallback uk-sap-fscd-dev
```

| If you see | Meaning | Action |
|---|---|---|
| Group "(default L2)" | Host has no AGO_AXA_SUPPORTGROUP tag | Tag the host in Dynatrace |
| Environment "(default ...)" | No usable environment tag, or value not mapped | Add the value to ENVIRONMENT and SILVA_ENVIRONMENTS |
| Business service blank on the ticket | Host not in CMDB and default lookup failed | Check `ciLookup` in the task result |

## Data Flow Map

```
Dynatrace host tags ──> AGO_AXAENVIRONMENTNAME ──> ENVIRONMENT map ──> u_environment
                   └──> AGO_AXA_SUPPORTGROUP  ─────────────────────────> assignment_group
Dynatrace host name ──> SILVA cmdb_ci lookup ──> cmdb_ci sys_id
                                                    │
                                        SILVA CMDB links host -> service
                                                    v
                                     business_service + service_offering
```

## Related Files

| File | Purpose |
|---|---|
| `../27-open-match-inc30339746/1-open-silva-http-and-pagerduty.workflow.yaml` | Current OPEN workflow |
| `28.sh` | Check a host's tags-to-SILVA result |

## Commands

See `28.sh` (not run by me).
