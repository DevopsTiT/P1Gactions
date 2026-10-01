# P-261090 Real Input Walkthrough

## Decision tree

```
P-261090 event arrives (CUSTOM_ALERT, Infrastructure, process group instance on host ts12)
 OPEN T1  tags decide:
          team tag        AGO_AXA_SUPPORTGROUP → InfraSupport_Dist-WindowsHK_L2_ASIA
          environment     AGO_AXAENVIRONMENTNAME:Development wins over env:ACC and ACCEPTANCE
          host            host:ts12 + AGO_DOMAIN hk.intraxa → ts12.hk.intraxa
          trigram ATK, platform COREIT, region HKLDC, app INFRA
          PROCESS_GROUP_INSTANCE id dropped from CI search (it is a Dynatrace id)
 OPEN T2  SILVA: team exists? → server ts12.hk.intraxa → linked service → no offering
          → last 20 tickets on ts12 → offering cfbf255f → parent 37273dbc → AXA XL
 OPEN T3  ticket body: Development, team from tag, correlation_id P-261090
          PD body: severity "error" (Infrastructure), component ATK
 OPEN T4a/T5a → no duplicate → POST → INC30341416
 OPEN T4b/T5b → POST trigger dt-problem-P-261090
 CLOSE    same display_id → find INC30341416 → PATCH Resolved; PD resolve
```

## Short takeaway

| Question | Answer |
|---|---|
| What does this input give us? | A Davis problem P-261090, type CUSTOM_ALERT, impact Infrastructure, on a process group instance, with 19 entity tags. |
| Which team gets the ticket? | `InfraSupport_Dist-WindowsHK_L2_ASIA`, from tag `AGO_AXA_SUPPORTGROUP` (if that group exists in SILVA). |
| Which environment? | **Development**, from `AGO_AXAENVIRONMENTNAME:Development`. It wins because it is checked before `env:ACC`. |
| Which server? | `ts12`, expanded with `AGO_DOMAIN:hk.intraxa` to `ts12.hk.intraxa`. Your terminal shows SILVA has it. |
| Which offering and business service? | Offering `cfbf255f` from the last 20 tickets on ts12, its parent business service `37273dbc`, company AXA XL. |
| PagerDuty severity? | `error`, because `dt.davis.impact_level` is Infrastructure. |
| What ticket was created? | INC30341416. CLOSE later resolved it. |

## Summary

The tags on this host are rich, so most decisions come straight from them: the team (support group tag), the environment (AXA environment name tag), the host and domain. SILVA is then used to find the server record, and because the server's linked service is a technical one without an offering, the workflow copies the offering people used on the last 20 tickets for ts12. The ticket and the PagerDuty alert are both tagged with P-261090, which is how CLOSE finds and resolves them later.

What I could not see in your screenshot and therefore marked as "depends": `event.name`, `root_cause_entity_name`, `affected_entity_names`, `dt.security_context`, `maintenance.is_under_maintenance`, and the exact SILVA answers. The event name used below is the one from our earlier P-261090 runs.

---

## 0. The input, field by field

| Field | Value | What the workflow uses it for |
|---|---|---|
| `event.kind` | DAVIS_PROBLEM | Trigger filter |
| `event.status` | ACTIVE | Trigger filter (OPEN) |
| `display_id` | P-261090 | SILVA `correlation_id`, PD `dedup_key` |
| `event.category` | CUSTOM_ALERT | Backup for severity (not used, because `event.severity` exists) |
| `event.severity` | "3" | Written as `dynatrace_severity: 3` in the description |
| `dt.davis.impact_level` | Infrastructure | PD severity becomes `error` |
| `dt.davis.mute.status` | NOT_MUTED | Not used |
| `dt.analysis.ready` | true | Not used |
| `affected_entity_types` | dt.entity.process_group_instance | Reads `ev["dt.entity.process_group_instance"]` for names |
| `affected_entity_ids` | PROCESS_GROUP_INSTANCE-97B76630471F05A7 | `entity_id` in the description; dropped from CI search |
| `labels.alerting_profile` | EIP Test, AppErrorProfile..., Default | Written in the description |
| `entity_tags` | 19 tags (table below) | Team, environment, host, domain, trigram, platform, region, app |

### The 19 tags and what each one does

| Tag | Parsed key | Value | Used by the workflow? |
|---|---|---|---|
| AGO_ALERTING_ACC | AGO_ALERTING_ACC | (empty) | No: no value |
| AGO_ALERTING_PRD | AGO_ALERTING_PRD | (empty) | No: no value |
| AGO_AXAATSLEGALENTITY:AXA-GROUP-OPERATIONS-HONG-KONG | AGO_AXAATSLEGALENTITY | AXA-GROUP-OPERATIONS-HONG-KONG | No |
| AGO_AXAENVIRONMENTNAME:Development | AGO_AXAENVIRONMENTNAME | Development | **Yes: environment (wins)** |
| AGO_AXAGOSCOPE:True | AGO_AXAGOSCOPE | True | No |
| AGO_AXAOPCOTRIGRAM:ATK | AGO_AXAOPCOTRIGRAM | ATK | **Yes: trigram** |
| AGO_AXAPATCHENVIRONMENT:ACCEPTANCE | AGO_AXAPATCHENVIRONMENT | ACCEPTANCE | Candidate for environment, but loses |
| AGO_AXAPLATFORM:COREIT | AGO_AXAPLATFORM | COREIT | Yes: platform (output only) |
| AGO_AXAROLE:BASE | AGO_AXAROLE | BASE | No |
| AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsHK_L2_ASIA | AGO_AXA_SUPPORTGROUP | InfraSupport_Dist-WindowsHK_L2_ASIA | **Yes: team (first priority)** |
| AGO_CSP_REGION:HKLDC | AGO_CSP_REGION | HKLDC | Yes: region (search hint) |
| AGO_DOMAIN:hk.intraxa | AGO_DOMAIN | hk.intraxa | **Yes: domain for host search** |
| AGO_OS:Windows | AGO_OS | Windows | No |
| app:INFRA | app | INFRA | Yes: app name (output only) |
| bu:OS | bu | OS | No |
| company:AGO | company | AGO | Not used here (trigram already found) |
| env:ACC | env | ACC | Candidate for environment, but loses |
| host:ts12 | host | ts12 | **Yes: host** |
| tier:BASE | tier | BASE | No |

---

# Part A: OPEN workflow step by step

## Step 1. Trigger

| Check | This event | Result |
|---|---|---|
| `event.kind == "DAVIS_PROBLEM"` | DAVIS_PROBLEM | pass |
| `event.status == "ACTIVE"` | ACTIVE | pass |
| `event.status_transition == "CREATED"` | (first event of the problem) | pass |

The OPEN workflow starts.

## Step 2. Task 1 `extract-event-tags`

### 2.1 Read the event and the Problems API

| Function | What happens |
|---|---|
| `ex.event()` | Returns the JSON in your screenshot. |
| `usedSample` | `event.kind` exists, so false. Real event. |
| `getProblem({problemId: event.id})` | Dynatrace returns the problem with its tags and root cause. Extra tags are merged in without duplicates. |

### 2.2 Team (group candidates)

Code: `allByKey(parsed, [test1, test2, test3])`

| Test | Rule | Match in this input |
|---|---|---|
| 1 | key is `ago_axa_supportgroup` | **AGO_AXA_SUPPORTGROUP → InfraSupport_Dist-WindowsHK_L2_ASIA** |
| 2 | key ends with `assignment_group` or `support_group` (other keys) | none |
| 3 | key is `ago_default_assignment_group` | none |

Result: `group_candidates = [ {key: "AGO_AXA_SUPPORTGROUP", value: "InfraSupport_Dist-WindowsHK_L2_ASIA"} ]`

### 2.3 Environment

Code: `allByKey` with environment tests, then the first candidate that `envLabel()` understands wins.

| Order | Rule | Match | `envLabel` result |
|---|---|---|---|
| 1 | key `ago_axaenvironmentname` | Development | **"Development" → wins** |
| 2 | key `env` or `environment` | ACC | would be "Integration / Test" |
| 3 | key contains `environment`, not `patch` | (same Development tag, already listed) | |
| 4 | key `k8s.namespace.name` | none | |
| 5 | key like `patch...environment` | ACCEPTANCE | would be "Integration / Test" |

Result: `environment = { tag_value: "Development", label: "Development", from: "tag AGO_AXAENVIRONMENTNAME" }`

Watch out: this host has mixed signals. `env:ACC` and `AGO_AXAPATCHENVIRONMENT:ACCEPTANCE` say acceptance, but `AGO_AXAENVIRONMENTNAME` says Development, and the code checks that one first. If the ticket should say "Integration / Test", either fix the tag on the host or change the order in the environment tests (OPEN lines 203 to 209).

### 2.4 Other tags

| Item | Rule | Result |
|---|---|---|
| Business service tag | keys `snow-service`, `ago_axa_businessservice`, `business-service`, `u_business_service` | none |
| App code | keys `dt.cost.product`, `ago_axaappcode`, `app_code`, `appcode`, else `[CODE.ENV]` prefix of the name | none (unless the entity name starts with `[...]`) |
| App name | key `app` | INFRA |
| Domain | key `ago_domain` | hk.intraxa |
| Trigram | key contains `trigram` | ATK |
| Platform | key contains `platform` | COREIT |
| Region | key contains `region` | HKLDC |
| Host | key `host` | ts12 |
| Maintenance | event field, then tag `ago_maintenance` | false (field not visible in the screenshot; assumed false since a ticket was created) |

### 2.5 Names and ids

| Item | Value |
|---|---|
| `entity_id` | PROCESS_GROUP_INSTANCE-97B76630471F05A7 |
| `entity_type` | dt.entity.process_group_instance |
| `impact_level` | Infrastructure |
| `severity` | "3" (from `event.severity`) |
| `ciNames` | The PROCESS_GROUP_INSTANCE id is removed by the rule `^[A-Z_]+-[0-9A-F]{16}$`, because SILVA never names a CI like that. Only real names (if any) remain. |
| `service_name` | root cause name if present, else the first affected name, else the process group instance id, else `ts12` |

### 2.6 What task 1 returns (key parts)

```json
{
  "usedSample": false,
  "dynatrace_alert": {
    "problem_id": "P-261090",
    "severity": "3",
    "impact_level": "Infrastructure",
    "entity_id": "PROCESS_GROUP_INSTANCE-97B76630471F05A7",
    "entity_type": "dt.entity.process_group_instance",
    "host": "ts12",
    "environment": "Development",
    "environment_tag": "Development",
    "app_name": "INFRA",
    "trigram": "ATK",
    "platform": "COREIT",
    "region": "HKLDC",
    "alerting_profile": "EIP Test, AppErrorProfile..., Default",
    "maintenance": false
  },
  "snow_inputs": {
    "group_candidates": [ { "key": "AGO_AXA_SUPPORTGROUP", "value": "InfraSupport_Dist-WindowsHK_L2_ASIA" } ],
    "service_tag": null,
    "environment": { "tag_value": "Development", "label": "Development", "from": "tag AGO_AXAENVIRONMENTNAME" },
    "app_code": null,
    "domain": { "key": "AGO_DOMAIN", "value": "hk.intraxa" },
    "trigram": { "key": "AGO_AXAOPCOTRIGRAM", "value": "ATK" },
    "region": { "key": "AGO_CSP_REGION", "value": "HKLDC" },
    "host": "ts12",
    "db_or_entity_names": []
  }
}
```

## Step 3. Task 2 `resolve-snow-values` (SILVA lookups)

### 3.1 Team from the tag

```
GET {SN}/sys_user_group?sysparm_query=name=InfraSupport_Dist-WindowsHK_L2_ASIA^active=true
```

| If SILVA answers | Then |
|---|---|
| 1 row | `tagGroup` = that team, with its sys_id and company. **This becomes the final team** (tag is first in `GROUP_ORDER`). |
| 0 rows | `tagGroup` keeps the name but sys_id is empty ("not verified"). The final team then falls to `enrichment` or later. Preview 4a would flag assignment_group if it ends up as a name. |

### 3.2 Business service: no map, no tag, so use the server

**Find the server** (`findCis`). Domains list = `hk.intraxa` (from the tag), then `axa-id.intraxa`, `jp.intraxa`, `intraxa`.

```
GET {SN}/cmdb_ci?sysparm_query=name=ts12^ORname=ts12^ORname=ts12^ORfqdn=ts12
    ^ORfqdn=ts12.hk.intraxa^ORfqdn=ts12.axa-id.intraxa^ORfqdn=ts12.jp.intraxa^ORfqdn=ts12.intraxa
    ^ORname=ts12.hk.intraxa^ORname=ts12.axa-id.intraxa^ORname=ts12.jp.intraxa^ORname=ts12.intraxa
→ server ts12.hk.intraxa   (your terminal shows u_configuration_item display_value "ts12.hk.intraxa")
```

**Services linked to the server** (`servicesForCi`):

```
GET {SN}/svc_ci_assoc?sysparm_query=ci_id=<TS12_ID>
GET {SN}/cmdb_rel_ci?sysparm_query=child=<TS12_ID>
```

**Load the first linked service** (`serviceById`) → service found, method `CI ts12 -> <via>`.

### 3.3 Final team (`GROUP_ORDER`)

| Order | Source | This run |
|---|---|---|
| 1 | tag | **InfraSupport_Dist-WindowsHK_L2_ASIA (if it exists in SILVA)** |
| 2 | enrichment | not needed |
| 3 | enrichment_support | not needed |
| 4 | ci | not needed |
| 5 | default | not needed |

### 3.4 Offering

Environment label is **Development**.

```
GET {SN}/service_offering?sysparm_query=parent=<linked service>
```

| If | Then |
|---|---|
| The linked service has an offering whose `u_environment` is Development | That offering is used. |
| None (technical service) | Go to history. This is what happened for P-261090. |

**Past tickets on ts12:**

```
GET {SN}/incident?sysparm_query=u_configuration_item=<TS12_ID>^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on  (20 rows)
→ cfbf255f on 20 of 20
GET {SN}/service_offering?sysparm_query=sys_id=cfbf255f...
→ parent 37273dbc
GET {SN}/cmdb_ci_service?sysparm_query=sys_id=37273dbc...
→ business service replaced with 37273dbc
```

### 3.5 Company

From business service `37273dbc` → AXA XL.

### 3.6 What task 2 returns (key parts)

```json
{
  "snow_required": {
    "assignment_group": { "name": "InfraSupport_Dist-WindowsHK_L2_ASIA", "sys_id": "<group sys_id>", "from": "tag AGO_AXA_SUPPORTGROUP" },
    "business_service": { "sys_id": "37273dbc...", "from": "CI ts12.hk.intraxa -> ... -> replaced by ... (business service of the history offering)" },
    "service_offering": { "sys_id": "cfbf255f...", "from": "incident history on host CI (20 of 20 recent incidents)" },
    "company": { "name": "AXA XL", "from": "servicenow_enrichment.company" },
    "cmdb_ci": { "name": "ts12.hk.intraxa", "sys_id": "<TS12_ID>", "fqdn": "ts12.hk.intraxa" },
    "environment": { "label": "Development", "from": "tag AGO_AXAENVIRONMENTNAME" }
  }
}
```

## Step 4. Task 3 `build-payload` (no network)

### 4.1 Title

`target` = server FQDN `ts12.hk.intraxa`

`short_description` = `[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa`

### 4.2 Ticket body

| Field | Value | From |
|---|---|---|
| caller_id | 8ddef691fb34cf547b0dfe7b4eefdcbc | setting (Dynatrace JP) |
| u_on_behalf_of | 8ddef691fb34cf547b0dfe7b4eefdcbc | setting |
| contact_type | event | setting |
| company | AXA XL sys_id | business service 37273dbc |
| u_environment | Development | tag AGO_AXAENVIRONMENTNAME |
| u_business_service | 37273dbc... | history offering's parent |
| cmdb_ci | cfbf255f... | last 20 tickets on ts12 |
| u_configuration_item | ts12 sys_id | server search |
| category, subcategory | other, other | setting |
| impact, urgency | 4, 4 | setting |
| assignment_group | InfraSupport_Dist-WindowsHK_L2_ASIA sys_id | tag AGO_AXA_SUPPORTGROUP |
| short_description | see 4.1 | |
| description | event text + Additional Information | see 4.3 |
| correlation_id | P-261090 | display_id |

### 4.3 Additional Information block in the description

```
problem_displayId: P-261090
u_external_url: https://<env>/ui/apps/dynatrace.davis.problems/problem/<event.id>
correlation_id: PROCESS_GROUP_INSTANCE-97B76630471F05A7
discovered_name: <service name>
dynatrace_severity: 3
error_rate: -
environmentId: <env id>
environmentName: AXA AS STG
environment: Development (tag AGO_AXAENVIRONMENTNAME)
app_code: -
hosts: ts12
alerting_profile: EIP Test, AppErrorProfile..., Default
entity_tags: AGO_ALERTING_ACC, AGO_ALERTING_PRD, ... , tier:BASE
```

The line `correlation_id: PROCESS_GROUP_INSTANCE-...` is only text inside the description. The real `correlation_id` field is P-261090.

### 4.4 Decision

Missing check: group, business service, offering, environment and title all present; maintenance off → `{create_incident: true, reason: "ok"}`.

### 4.5 PagerDuty body

```json
{
  "event_action": "trigger",
  "dedup_key": "dt-problem-P-261090",
  "client": "Dynatrace",
  "payload": {
    "summary": "[DYNATRACE JAPAN][ts12.hk.intraxa] - Error in the Windows Application Log ...",
    "source": "ts12.hk.intraxa",
    "severity": "error",
    "group": "Development",
    "component": "ATK",
    "custom_details": {
      "problem_id": "P-261090",
      "host": "ts12",
      "environment": "Development",
      "assignment_group": "InfraSupport_Dist-WindowsHK_L2_ASIA",
      "trigram": "ATK",
      "snow_correlation_id": "P-261090"
    }
  }
}
```

| PD field | Why this value |
|---|---|
| severity `error` | `impact_level` is Infrastructure (otherwise it would be `warning`). |
| component `ATK` | Trigram found, so it is used before the service name. |
| group `Development` | Environment label. |

## Step 5. Task 4a `preview-silva-incident`

| Check | Result |
|---|---|
| Every form field | OK (all mandatory fields filled; reference fields are sys_ids) |
| Duplicate GET `correlation_id=P-261090^active=true` | none (first time) |
| `ready` | true |
| `open_v7_would` | CREATE incident |

## Step 6. Task 4b `preview-pagerduty`

| Check | Value | Status |
|---|---|---|
| event_action | trigger | OK |
| dedup_key | dt-problem-P-261090 | OK |
| summary | under 1,024 characters | OK |
| source | ts12.hk.intraxa | OK |
| severity | error | OK |

## Step 7. Task 5a `post-silva-incident`

| Step | Result |
|---|---|
| Gates | decision true, no preview problems, real event |
| Duplicate GET | none |
| POST /incident | 201, **INC30341416**, state New |

## Step 8. Task 5b `trigger-pagerduty`

| Step | Result |
|---|---|
| Gates | decision true, preview ready, real event |
| POST /v2/enqueue | 202 success, dedup_key dt-problem-P-261090 |
| PagerDuty | Opens an incident with severity error. |

---

# Part B: CLOSE workflow step by step

The same problem closes. The close event carries the same `display_id` P-261090 and the same tags, with `event.status: CLOSED`.

## Step 1. Trigger

| Check | Result |
|---|---|
| Event state "closed" (`triggerOn: close`) | pass |
| `event.status == "CLOSED"` | pass |

## Step 2. Task 1 `prepare-close`

| Item | Value |
|---|---|
| `getProblem` status | CLOSED |
| `is_closed` | true |
| `correlation_id` | P-261090 |
| `dedup_key` | dt-problem-P-261090 |
| `where` | root cause name (for example ts12.hk.intraxa) |
| `duration` | end minus start, for example "1 h 12 min" |

The tags are not used here. CLOSE only needs the display id.

## Step 3. Task 2a `close-silva-incident`

| Step | Call | Result |
|---|---|---|
| 1 to 5 | `GET sys_choice` for state, close_code, In Progress, incident_state | Stored values for Resolved, In Progress, Solved (Permanently) |
| 6 | `GET incident correlation_id=P-261090^active=true` | INC30341416, New |
| 7 | `PATCH incident/<sys_id>` with state, incident_state = Resolved, close_code, close_notes, work_notes | 200, Incident State Resolved |

Work note written (example):

```
=== Dynatrace problem closed (P-261090) ===
Duration          : 1 h 12 min
Cause             : Error in the Windows Application Log with an eventID 258 on TS12.hk.intraxa on ts12.hk.intraxa
Assignment group  : InfraSupport_Dist-WindowsHK_L2_ASIA
Business service  : <name of 37273dbc>
Service offering  : <name of cfbf255f>
Configuration item: ts12.hk.intraxa
Dynatrace problem : https://<env>/ui/apps/dynatrace.davis.problems/problem/<event.id>
PagerDuty         : resolved with dedup_key dt-problem-P-261090
```

SILVA then records: "Incident State Resolved was New", Resolved by Dynatrace JP, Resolver Group (as in your screenshot).

## Step 4. Task 2b `close-pagerduty`

```
POST /v2/enqueue { "event_action": "resolve", "dedup_key": "dt-problem-P-261090" }
→ 202 success
```

PagerDuty resolves the incident opened in Part A step 8.

---

## Things this input teaches us

| Observation | Why it matters | What to do |
|---|---|---|
| Environment tags disagree (Development vs ACC vs ACCEPTANCE) | Ticket says Development | Confirm the correct one with the app owner; fix the tag or the test order. |
| The affected entity is a process group instance, not the host | Its id is useless for SILVA | The workflow falls back to `host:ts12` + `AGO_DOMAIN`, which works. |
| `AGO_AXA_SUPPORTGROUP` is present | Team comes from the tag, not from the technical service | Make sure the group name exists exactly in SILVA. |
| Impact Infrastructure | PD severity error | Expected; change line 890 if you want a different rule. |
| Tags without a value (AGO_ALERTING_ACC, AGO_ALERTING_PRD) | Ignored by the workflow | Fine. |

## Data flow map

```
P-261090 event
  tags ─► team InfraSupport_Dist-WindowsHK_L2_ASIA ─────────────────────► assignment_group
       ─► env Development ──────────────────────────────────────────────► u_environment
       ─► host ts12 + domain hk.intraxa ─► SILVA cmdb_ci ts12.hk.intraxa ─► u_configuration_item
                                         ─► past 20 tickets ─► cfbf255f ─► cmdb_ci (Service Offering)
                                                             ─► parent 37273dbc ─► u_business_service
                                                             ─► AXA XL ─► company
       ─► trigram ATK ─► PD component
  impact Infrastructure ─► PD severity error
  display_id P-261090 ─► correlation_id + dedup_key dt-problem-P-261090
  ─► INC30341416 + PD incident
close P-261090 ─► find by correlation_id ─► Resolved; PD resolve
```

## Investigation

| Source | What it gave |
|---|---|
| Your screenshot (input4.sh) | Event fields and the 19 tags |
| Terminal line in the screenshot | SILVA shows `u_configuration_item` = ts12.hk.intraxa |
| OPEN code (seq 36) lines 195 to 259, 469 to 719, 808 to 907 | Exact rules applied above |
| Earlier P-261090 results | Offering cfbf255f (20 of 20), business service 37273dbc, AXA XL, INC30341416 resolved |

## Result

For this input the workflow takes the team and environment from tags, the server from `host` plus `AGO_DOMAIN`, and the offering and business service from ts12's ticket history. The one thing to double check is the environment: the tags disagree, and Development wins by code order.

## Related files

| File | What it is |
|---|---|
| `54-workflows-trace-detailed-example/` | Generic detailed trace |
| `52-silva-field-mapping-plain-explained/` | Plain mapping of boxes |
| `55.sh` | Checks for the team, the server, and the ticket |

## Commands

See [`55.sh`](55.sh).
