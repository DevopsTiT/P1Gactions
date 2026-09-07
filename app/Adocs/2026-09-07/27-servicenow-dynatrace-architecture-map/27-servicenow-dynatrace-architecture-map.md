# ServiceNow Dynatrace Architecture Map

```
Need the picture?
  │
  ├─ Big picture → §1 system context
  ├─ Ticket path → §2 Incident data flow
  ├─ Inventory path → §3 CMDB / Service Graph
  └─ Who owns what → §4 ownership + trust boundaries
```

| Key point | Detail |
| --- | --- |
| What this is | Architecture map for Dynatrace ↔ ServiceNow manage (seq 25/26) |
| Core path | Problem → alerting profile → notification → Incident |
| Optional paths | ITOM Events, CMDB / Service Graph CI sync |
| Goal of the map | Show components, data direction, and day-2 control points |

## Summary

Dynatrace detects and explains Problems. An alerting profile decides what may leave Dynatrace. A Problem notification pushes into ServiceNow, where a transform creates/updates an Incident on the right CI and assignment group. Optional CMDB sync improves CI linking. Humans work the ticket using the Problem URL, then both sides close.

---

## 1. System context (pic)

```
                    ┌─────────────────────────────────────┐
                    │           Operators / On-call         │
                    │  ServiceNow UI  +  Dynatrace UI       │
                    └──────────────┬──────────┬────────────┘
                                   │          │
                                   ▼          ▼
┌──────────────────────┐    ┌──────────────────────────────────┐
│      Dynatrace       │    │           ServiceNow             │
│                      │    │                                  │
│  OneAgent / RUM      │    │  ITSM Incidents                   │
│  Smartscape / Davis  │───►│  Transform / Assignment          │
│  Problems            │    │  CMDB / Service Graph (CIs)      │
│  Alerting profiles   │    │  Optional: ITOM em_event         │
│  Problem notify      │    │                                  │
└──────────────────────┘    └──────────────────────────────────┘
         ▲                              ▲
         │ monitored                    │ inventory sync
         │                              │ (optional pull)
┌────────┴────────┐                     │
│ Apps / Hosts    │─────────────────────┘
│ EIP checkout …  │   (entities known to both if CMDB synced)
└─────────────────┘
```

---

## 2. Incident path (main architecture)

```
[Users / traffic]
        │
        ▼
[App + Hosts]  ←── OneAgent / monitoring
        │
        ▼
[Dynatrace Davis]
   opens Problem (impact + root cause)
        │
        ▼
[Alerting profile] ──── no match ──► (no ticket)
        │ yes (prod + severity + tags)
        ▼
[Problem notification]
   type = ServiceNow
   ITSM send = ON
        │
        │  HTTPS (title, severity, URL, entities, state)
        ▼
[ServiceNow Incident Integration]
        │
        ▼
[Import set] → [Transform map]
        │
        ├─► short_description / priority / work notes
        ├─► Affected CI (lookup from CMDB)
        └─► Assignment group (e.g. EIP-Support)
        │
        ▼
[Incident INC…]  ◄── on-call acks / works
        │
        │  Problem URL → back to Dynatrace RCA
        ▼
[Fix in app/infra]
        │
        ▼
[Problem CLOSED] ──notify──► [Incident Resolved]
```

---

## 3. Three lanes on one map

```
                    Dynatrace Problem / Topology
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
   ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
   │ Lane A      │    │ Lane B      │    │ Lane C          │
   │ Incident    │    │ Events      │    │ CMDB / Service  │
   │ (ITSM)      │    │ (ITOM)      │    │ Graph           │
   └──────┬──────┘    └──────┬──────┘    └────────┬────────┘
          │                  │                    │
          ▼                  ▼                    ▼
   Incident table      em_event + rules     CI + relationships
   (day-2 tickets)     (correlate later)    (Affected CI link)
```

| Lane | Direction | What moves | When you need it |
| --- | --- | --- | --- |
| A Incident | Dynatrace → ServiceNow | Problem open/update/close → Incident | Default for SRE tickets |
| B Events | Dynatrace → ServiceNow | Events into ITOM | If Event Management licensed / used |
| C CMDB | Dynatrace → ServiceNow (pull) | Hosts, services, apps as CIs | So Incidents attach correct CI |

---

## 4. Control points (where “manage” lives)

```
Dynatrace                          ServiceNow
─────────                          ──────────
[1] Entity tags (env, app)         [4] Integration user (least privilege)
[2] Alerting profile (noise)       [5] Transform map (fields)
[3] Problem notification (wire)    [6] Assignment rules (group)
                                   [7] CI identity rules (dedupe)
                                   [8] Import set health (errors)
```

| # | Control | Healthy look |
| --- | --- | --- |
| 1 | Tags | `env:prod`, `app:eip` present on entities |
| 2 | Alerting profile | STG / Info do not create prod tickets |
| 3 | Notification | Test notify succeeds; one per env |
| 4 | Integration user | Only required roles |
| 5 | Transform map | Title, URL, priority, state correct |
| 6 | Assignment | EIP → EIP-Support (not wrong queue) |
| 7 | CI identity | No duplicate hosts; names match |
| 8 | Import set | Failed rows ≈ 0 |

---

## 5. Example overlay — EIP checkout (same map, filled)

```
Shopper → eip-checkout (slow)
              │
              ▼
Dynatrace Problem P-240906
  Davis: DB behind eip-checkout
              │
              ▼
Profile: prod-eip-to-servicenow  (MATCH)
              │
              ▼
Notify ServiceNow
              │
              ▼
INC0012345
  CI: eip-checkout / eip-app-01
  Group: EIP-Support
  Notes: Problem URL
              │
              ▼
On-call → fix → Problem CLOSED → INC Resolved
```

---

## 6. Trust / security boundary

```
┌──────── Dynatrace tenant ────────┐     HTTPS      ┌──── ServiceNow instance ────┐
│ Problems, entities, RCA          │ ─────────────► │ Incidents, CMDB, users      │
│ Egress IPs must be allowed       │                │ Integration user scoped     │
│ No customer PII in test payloads │                │ Audit on ticket changes     │
└──────────────────────────────────┘                └─────────────────────────────┘
```

| Boundary item | Why it matters |
| --- | --- |
| Auth | Bad creds → 403 on test notify |
| IP allow list | Dynatrace cannot reach ServiceNow without it |
| Least privilege | Integration user should not be full admin |
| Payload content | Problem URL + metadata; avoid dumping raw PII logs into tickets |

---

## Data flow map (compact)

```
App/Host → Dynatrace (Davis Problem)
        → Alerting profile?
              yes → Problem notification
                    → ServiceNow import/transform
                    → Incident + CI + group
                    → Human (Problem URL)
                    → Fix → Problem CLOSED → Incident Resolved
              no  → stop (no ticket)
```

## Related files

| File | Purpose |
| --- | --- |
| `27.sh` | Path reminders |
| `../25-manage-servicenow-step-example/` | Step-by-step + example |
| `../26-manage-servicenow-ppt/` | PPT deck |

## Commands

See `27.sh`.
