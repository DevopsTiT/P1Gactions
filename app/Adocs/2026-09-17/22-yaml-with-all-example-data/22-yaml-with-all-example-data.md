# Yaml With All Example Data

```
Want YAML with example values already filled?
  │
  ├─ OPEN: 1-open-with-example-data.workflow.yaml
  └─ CLOSE: 2-close-with-example-data.workflow.yaml
       PD key + SNOW sys_ids + assignMap embedded (FAKE)
       Connection still mapped in UI (password not in YAML)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you get | Full OPEN + CLOSE workflow YAML with **fake example data** inside |
| Filled in file | PD routing key, all `__SNOW_*` sys_ids, assignMap names/runbooks |
| Still UI-only | ServiceNow Connection credentials; map `connectionId` at upload |
| Production | Replace every fake value before go-live |

## Summary

These YAML files are the Connector workflows with every placeholder replaced by the fake examples from seq 21. Upload them for structure testing; swap to real sys_ids and PD key before production.

---

## Investigation

Built from seq 19 Connector YAML + seq 21 fake parameter set. Replaced all `__PD_*` / `__SNOW_*` placeholders.

## Result

| File | Role |
| --- | --- |
| `1-open-with-example-data.workflow.yaml` | OPEN with example data |
| `2-close-with-example-data.workflow.yaml` | CLOSE with example data |
| `fake-filled-examples.json` | Same fake values as reference |

Path: `Daily Files/2026-09-17/22-yaml-with-all-example-data/`

---

## Example values embedded in YAML

| Item | Fake value in file |
| --- | --- |
| PD routing key | `R03AMPLEFAKEROUTINGKEY00000000000` |
| Caller sys_id | `a1b2c3d4e5f6789012345678abcdef01` |
| EIP group / biz | `1111…` / `2222…` |
| CCI group / biz | `3333…` / `4444…` |
| Default group / biz | `5555…` / `6666…` |
| EIP group name | `EIP-Support` |
| EIP biz name | `EIP Checkout` |
| EIP runbook | `https://confluence.example/runbooks/eip` |

## Still configure in Dynatrace UI

| Item | Fake example to create |
| --- | --- |
| Connection name | `SNOW-Silva-STG-Connector` |
| Connection URL | `https://silvastg.service-now.com` |
| Connection user | `Tech_DynatraceJP_WS` |
| Connection password | set in UI only (`FakePassw0rd!NotReal` is not put in YAML) |
| Map Connection | On every snow task after upload |
| Classic ITSM | OFF on `servicenowstg` |
| Allowlist | `silvastg.service-now.com` + `events.pagerduty.com` |

---

## Data flow map

```
Upload example YAML
  → map Connection SNOW-Silva-STG-Connector
  → Problem event supplies id/title/tags (live)
  → prepare uses embedded assignMap + fake sys_ids
  → snow-create + PD (fake routing key) → cross-link
  → close uses same fake PD key + correlation search
```

## Related files

| Path | Why |
| --- | --- |
| This folder | Example-filled YAML |
| `../19-snow-connector-workflow-again/` | Placeholder version |
| `../21-workflow-parameter-fake-data/` | Parameter tables |
| `22.sh` | Paths |

## Commands

See `22.sh` in this folder.
