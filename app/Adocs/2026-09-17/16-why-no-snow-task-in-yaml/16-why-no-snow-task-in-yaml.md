# Why No Snow Task In Yaml

```
You turned ON servicenowstg (ITSM + ITOM) in Problem notifications
  │
  ├─ Does that add a snow task into workflow YAML?
  │     NO — notification is NOT a workflow task
  │
  ├─ Keep YAML without snow task?  YES (correct for your pic)
  │     SNOW INC = notification; Workflow = PagerDuty only
  │
  └─ Want a snow task visible in the workflow?
        YES → use Connection YAML (seq 13)
        AND set notification ITSM OFF (avoid duplicate INC)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Why no snow task | Problem notification runs **outside** Workflows |
| Pic change | Enables auto INC/event to silvastg — does **not** edit workflow YAML |
| Change YAML? | **No** if SNOW stays on notification; **Yes** only if you want Connection `snow-create-incident` |
| Your current pic | ITSM ON + ITOM ON → SNOW already handled without a snow task |

## Summary

Seeing no `create-servicenow-incident` in the YAML is expected when ServiceNow is done by **Settings → Problem notifications → servicenowstg**. That integration is not a workflow action. Keep the seq-15 PD-only YAML. Only switch to Connection workflow YAML if you need a real snow task on the canvas.

---

## Investigation

You configured `servicenowstg` like the pic (ITSM ON, ITOM ON) and expected a snow task to appear in YAML. Workflows and Problem notifications are separate products.

## Result

| If your goal is… | Do this |
| --- | --- |
| SNOW via pic notification + PD in workflow | **Do not** add snow task; use seq **15** YAML |
| Snow task inside workflow YAML | Use seq **13** Connection YAML; set notification **ITSM OFF** |

---

## 1) Why YAML has no snow task

| Feature | Where it lives | Shows as workflow task? |
| --- | --- | --- |
| Problem notification `servicenowstg` | Settings → Problem notifications | **No** |
| `snow-create-incident` | Workflow + ServiceNow Connection | **Yes** |

```
Problem happens
  ├─ Notification servicenowstg (automatic) → SNOW INC + ITOM event
  └─ Workflow YAML (only what you listed as tasks) → e.g. PagerDuty
```

There is **no** YAML action like:

```yaml
action: dynatrace.problem-notification:servicenowstg   # DOES NOT EXIST
```

So we cannot “point” `create-servicenow-incident` at your pic. The pic already creates the INC when ITSM is ON.

---

## 2) Should you change the YAML?

| Situation | Change YAML? |
| --- | --- |
| Pic ITSM ON, want SNOW from notification | **No** — keep PD-only YAML (seq 15) |
| Want snow task + assignment/P3/L1 fields in workflow | **Yes** — use Connection YAML (seq 13), ITSM **OFF** on pic |
| Add snow-create while ITSM ON | **Do not** — duplicate INC |

---

## 3) What to use now (recommended with your pic)

**Keep:**

1. `servicenowstg` ON — ITSM ON, ITOM ON (as pic)  
2. Workflow files from seq 15 (no snow task):

`Daily Files/2026-09-17/15-workflow-snow-via-problem-notification/`

- `1-open-pd-snow-via-notification.workflow.yaml`  
- `2-close-pd-snow-via-notification.workflow.yaml`  

3. Replace `__PD_ROUTING_KEY__` → Activate  

**Flow:**

```
Problem OPEN
  ├─ servicenowstg → SNOW INC (+ event)
  └─ workflow → PagerDuty
```

---

## 4) If you still want a snow task in YAML

Upload seq 13 instead:

`Daily Files/2026-09-17/13-working-snow-pd-workflow-yaml/`

And on the pic: set **Send incidents ITSM = OFF** (workflow owns INC; ITOM can stay ON).

---

## Data flow map

```
Pic (notification)     ≠     Workflow snow task
     │                              │
     └─ auto on Problem             └─ only if Connection action in YAML
```

## Related files

| Path | Why |
| --- | --- |
| `../15-workflow-snow-via-problem-notification/` | Correct YAML for notification path |
| `../13-working-snow-pd-workflow-yaml/` | YAML with real snow tasks |
| `../14-snow-connector-vs-problem-notification/` | Full diff |
| `16.sh` | Paths |

## Commands

See `16.sh` in this folder.
