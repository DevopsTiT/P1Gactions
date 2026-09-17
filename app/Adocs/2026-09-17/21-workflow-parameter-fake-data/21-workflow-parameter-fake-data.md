# Workflow Parameter Fake Data

```
Need to fill what before activate?
  │
  ├─ Connection (URL + user/password or OAuth)
  ├─ Placeholders in YAML (__PD_*, __SNOW_*)
  ├─ Allowlist hosts
  ├─ Classic ITSM OFF
  └─ App tags on monitored entities (drives assignMap)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| You type these | Connection, PD routing key, SNOW sys_ids, assignMap names, allowlist |
| Dynatrace fills these | Problem id, title, severity, URL, entity tags |
| Workflow computes these | impact/urgency, dedup_key, shortDescription, description |
| Fake data below | Safe examples only — replace with your real values before prod |

## Summary

Below is every parameter the Connector + PagerDuty pack needs, grouped by where you set it, with **fake example values** so you can see the shape. Real secrets and sys_ids must come from your ServiceNow and PagerDuty admins.

---

## Investigation

Pulled required fields from seq 19 OPEN/CLOSE YAML: Connection, placeholders, `snow-create-incident` inputs, PD Events API body, close search/resolve inputs, and Problem event fields read by `prepare-payload`.

## Result

Use the tables as a fill-in checklist. File `fake-filled-examples.json` in this folder holds one end-to-end fake sample.

---

## 1) Setup parameters (you configure once)

| Parameter | Where | Required | Fake example | What it means |
| --- | --- | --- | --- | --- |
| ServiceNow instance URL | Connection | Yes | `https://silvastg.service-now.com` | Target SNOW instance |
| Connection name | Connection | Yes | `SNOW-Silva-STG-Connector` | Label you pick in Dynatrace UI |
| SNOW username | Connection | Yes (basic auth) | `Tech_DynatraceJP_WS` | Integration user |
| SNOW password | Connection | Yes (basic auth) | `FakePassw0rd!NotReal` | Stored in Connection, not in YAML |
| OAuth client id/secret | Connection | If OAuth | `dt_snow_client` / `fake-oauth-secret` | Alternate to basic auth |
| Connection id on tasks | UI map at upload | Yes | mapped in UI (`connectionId` left `""` in file) | Links snow tasks to Connection |
| PD routing key | OPEN + CLOSE JS | Yes | `R03AMPLEFAKEROUTINGKEY00000000000` | PagerDuty Events API integration key |
| Allowlist SNOW host | Dynatrace external requests | Yes | `silvastg.service-now.com` | Outbound to Connector |
| Allowlist PD host | Dynatrace external requests | Yes | `events.pagerduty.com` | Outbound for `fetch` |
| Classic ITSM | Problem notification `servicenowstg` | Yes (set OFF) | `ITSM = OFF` | Avoids duplicate INC |
| Classic ITOM | Same notification | Optional | `ITOM = ON` | Events only, if you want them |

---

## 2) Placeholders you must replace in YAML

| Placeholder in file | Fake replace-with value | Used for |
| --- | --- | --- |
| `__PD_ROUTING_KEY__` | `R03AMPLEFAKEROUTINGKEY00000000000` | PD trigger + resolve |
| `__SNOW_CALLER_SYS_ID__` | `a1b2c3d4e5f6789012345678abcdef01` | Caller user sys_id (in prepare return; description text) |
| `__SNOW_GROUP_SYS_ID_EIP__` | `11111111111111111111111111111111` | EIP assignment group |
| `__SNOW_BIZ_SYS_ID_EIP__` | `22222222222222222222222222222222` | EIP business service |
| `__SNOW_GROUP_SYS_ID_CCI__` | `33333333333333333333333333333333` | CCI assignment group |
| `__SNOW_BIZ_SYS_ID_CCI__` | `44444444444444444444444444444444` | CCI business service |
| `__SNOW_GROUP_SYS_ID_DEFAULT__` | `55555555555555555555555555555555` | Default Ops group |
| `__SNOW_BIZ_SYS_ID_DEFAULT__` | `66666666666666666666666666666666` | Default business service |

Fake assignMap names (already in YAML as text; safe to keep or edit):

| App key | groupName (fake) | bizName (fake) | L1 / L2 / L3 (fake) | runbook (fake) |
| --- | --- | --- | --- | --- |
| EIP | `EIP-Support` | `EIP Checkout` | `EIP-L1` / `EIP-L2` / `EIP-L3` | `https://confluence.example/runbooks/eip` |
| CCI | `CCI-Support` | `CCI FA Comm Calc` | `CCI-L1` / `CCI-L2` / `CCI-L3` | `https://confluence.example/runbooks/cci` |
| default | `Ops-Default` | `Unknown Business Service` | `Ops-L1` / `Ops-L2` / `Ops-L3` | `https://confluence.example/runbooks/default` |

---

## 3) Dynatrace Problem event inputs (auto — you do not type these)

These come from the Problem trigger into `prepare-payload`:

| Event field (read by script) | Fake example | What it means |
| --- | --- | --- |
| `display_id` / `problem.id` | `P-240917001` | Problem id |
| `event.name` / `problem.title` | `Failure rate increase on checkout API` | Title |
| `problem.url` / `event.url` | `https://abc12345.apps.dynatrace.com/#problems/problemdetails;pid=P-240917001` | Link back to DT |
| `problem.severity` | `ERROR` | Drives impact/urgency |
| `entity_tags` | `["app:EIP", "env:stg", "team:payments"]` | `app` picks assignMap row |
| status / transition | `ACTIVE` / `CREATED` | Opens the OPEN workflow |

Entity tag you must maintain on monitored entities:

| Tag | Fake example | Why |
| --- | --- | --- |
| `app` | `EIP` | Selects EIP row in assignMap |

---

## 4) Values `prepare-payload` computes (fake walkthrough)

Assume fake Problem above with tag `app:EIP` and severity `ERROR`:

| Output field | Fake value | What it means |
| --- | --- | --- |
| `problemId` | `P-240917001` | Passed as correlationId |
| `dedupKey` | `dt-problem-P-240917001` | PD sync key |
| `app` | `EIP` | From tag |
| `assignmentGroupName` | `EIP-Support` | From assignMap |
| `assignmentGroupSysId` | `11111111111111111111111111111111` | From placeholder |
| `businessServiceName` | `EIP Checkout` | From assignMap |
| `businessServiceSysId` | `22222222222222222222222222222222` | From placeholder |
| `impact` | `2` | From ERROR mapping |
| `urgency` | `3` | From ERROR mapping |
| `pLevel` | `P3` | Intent label in description |
| `pdSeverity` | `error` | PD payload severity |
| `shortDescription` | `[Dynatrace] Failure rate increase on checkout API — EIP` | INC short description |
| `category` | `Software` | Fixed in script |
| `subcategory` | `Application` | Fixed in script |
| `caller` | `Dynatrace Workflow` | Display caller string |
| `l1` / `l2` / `l3` | `EIP-L1` / `EIP-L2` / `EIP-L3` | In description |
| `runbookUrl` | `https://confluence.example/runbooks/eip` | In description + PD links |

---

## 5) `snow-create-incident` task parameters

| Input | Source | Fake example |
| --- | --- | --- |
| `connectionId` | UI map | (selected Connection `SNOW-Silva-STG-Connector`) |
| `correlationId` | `prepare-payload.problemId` | `P-240917001` |
| `caller` | prepare | `Dynatrace Workflow` |
| `category` | prepare | `Software` |
| `subCategory` | prepare | `Application` |
| `impact` | prepare | `2` |
| `urgency` | prepare | `3` |
| `group.id` | prepare | `11111111111111111111111111111111` |
| `group.displayName` | prepare | `EIP-Support` |
| `shortDescription` | prepare | `[Dynatrace] Failure rate increase on checkout API — EIP` |
| `description` | prepare | Multi-line text with Problem URL, L1/L2/L3, runbook |

Fake INC number returned by SNOW (example):

| Output | Fake example |
| --- | --- |
| `number` | `INC0017788` |
| `sys_id` | `abcdef0123456789abcdef0123456789` |

---

## 6) PagerDuty trigger parameters (fake body)

| Field | Fake example | What it means |
| --- | --- | --- |
| `routing_key` | `R03AMPLEFAKEROUTINGKEY00000000000` | Which PD service gets the alert |
| `event_action` | `trigger` | Open / update alert |
| `dedup_key` | `dt-problem-P-240917001` | Same alert for open and close |
| `client` | `Dynatrace` | Shown in PD |
| `client_url` | Problem URL | Click-back |
| `payload.summary` | same as shortDescription | Alert title |
| `payload.source` | `EIP` | Source field |
| `payload.severity` | `error` | PD severity |
| `payload.component` | `EIP` | Component |
| `payload.group` | `EIP-Support` | Group label |
| `payload.class` | `dynatrace-problem` | Class label |
| `custom_details.problem_id` | `P-240917001` | Extra context |
| `custom_details.runbook` | runbook URL | Extra context |

---

## 7) Cross-link comment parameters

| Input | Fake example |
| --- | --- |
| `connectionId` | same Connection |
| `number` | `INC0017788` |
| `comment` | `PagerDuty sync: dedup_key=dt-problem-P-240917001 \| Dynatrace Problem=<url> \| Runbook=<url> \| Problem ID=P-240917001` |

---

## 8) CLOSE workflow parameters

| Task / field | Fake example | What it means |
| --- | --- | --- |
| `problemId` (from close event) | `P-240917001` | Same Problem |
| `dedupKey` | `dt-problem-P-240917001` | Same as open |
| `closeNotes` | `Resolved automatically: Dynatrace Problem closed (P-240917001)` | Resolution notes |
| `sysparmQuery` | `correlation_id=P-240917001` | Find INC |
| `sysparmLimit` | `1` | First match |
| `sysparmFields` | `number,sys_id,correlation_id,state` | Fields returned |
| resolve `number` | `INC0017788` | From search `[0].number` |
| `resolutionCode` | `Solved (Permanently)` | Fixed in YAML |
| PD resolve `event_action` | `resolve` | Clears the page |
| PD resolve `routing_key` | same fake key as open | Must match open |

---

## 9) One fake end-to-end story

| Step | Fake data |
| --- | --- |
| Problem opens | `P-240917001`, title checkout failure rate, tag `app:EIP`, severity `ERROR` |
| Connection | `SNOW-Silva-STG-Connector` → `https://silvastg.service-now.com` |
| INC created | `INC0017788`, group `EIP-Support`, impact `2`, urgency `3` |
| PD alert | dedup `dt-problem-P-240917001`, routing key fake sample above |
| Comment | PD key written on `INC0017788` |
| Problem closes | search `correlation_id=P-240917001` → resolve INC + resolve PD |

---

## Data flow map

```
You fill once
  Connection URL/user/pass
  __PD_ROUTING_KEY__
  __SNOW_*_SYS_ID__
  allowlist + ITSM OFF
  entity tag app:*
        │
        ▼
Problem event (auto)
  id, title, severity, url, tags
        │
        ▼
prepare-payload (computes)
  impact, urgency, group, dedupKey, texts
        │
        ├─ snow-create-incident (needs Connection + computed fields)
        └─ PD trigger (needs routing_key + dedup_key + summary)
                │
                ▼
        snow-comment (INC number + PD key)
                │
CLOSE           ▼
        search correlation_id → resolve INC + resolve PD
```

## Related files

| Path | Why |
| --- | --- |
| `fake-filled-examples.json` | One JSON blob of fake values |
| `../19-snow-connector-workflow-again/` | Real YAML to edit |
| `../20-dynatrace-snow-pd-architecture/` | Full architecture |
| `21.sh` | Paths |

## Commands

See `21.sh` in this folder.
