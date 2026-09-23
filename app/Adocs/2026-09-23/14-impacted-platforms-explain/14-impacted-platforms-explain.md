# Impacted Platforms Explain

```
What is this slide for?
  → ARB / design review: who is touched by Four Agents?
  → Read by COLOR first, then by box

Color meaning:
  Green  → reuse (little change)
  Orange → modify / enable
  Blue   → primary design / highlighted impact
  Gray   → out of scope (do not rewrite apps)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What it is | **Impacted Platforms** map for Dynatrace → PagerDuty Four AI Agents |
| Key message | Agents consolidate **assist** work after Dynatrace pages — speed triage, not rewrite apps |
| Biggest change | **PagerDuty Advance** (enable agents + AI Actions budget) |
| Least change | **Dynatrace** reuse as detect ingress; **Business Apps** stay gray |
| POC hygiene | Test Service/EP, test key, standard Teams channel, linkUser |

## Summary

This is an ARB-style impact slide. It answers: “If we turn on the four agents, which platforms do we touch?” Green means keep using what you have. Orange means configure or connect. Blue means this is where design attention and ownership live. Gray means product/business apps do **not** need a code rewrite for these agents.

## Investigation

User shared **Impacted Platforms** (whole pack Part B). Explained legend + each platform box in beginner SRE language. Cross-checked seq 10 Slide 18.

## Result

Use this in design review to set expectations: Advance and chat wiring are the real work; Dynatrace stays ingress; apps stay out of scope.

---

## 1) Key Message

| Claim | Plain English |
| --- | --- |
| Four AI Agents consolidate assist work | Triage, notes, coverage, trends move onto the **incident path** helpers |
| Speed troubleshooting after Dynatrace pages | Help starts **after** the page — not a new monitor replacing Dynatrace |

**Assist work** = the middle toil (dig docs, type notes, fix coverage, pull CSVs) that AS-IS left to humans.

---

## 2) Legend (ARB-style colors)

| Color | Label | What it means | Example on this slide |
| --- | --- | --- | --- |
| Green | Reuse existing | Keep current tool; small config only | Dynatrace detect; Calendar extension |
| Orange | Modify / enable | Turn on, map, consent, test wiring | PD Core test Service; Teams/Slack bot |
| Blue | Primary design surface | Where the solution “lives” / ownership focus | PagerDuty Advance; IT Platform IR tooling |
| Gray | Out of scope | Do not redesign for this project | Business Apps code |

**ARB** here means Architecture Review Board style: color = impact type, not traffic-light health.

---

## 3) First row — core tools

### Dynatrace (Green — Reuse)

| Point | What it means | Why you care |
| --- | --- | --- |
| Reuse — detect ingress | Dynatrace still finds Problems and creates/notifies PD | You are not replacing monitoring |
| Keep problem URL in event | Put URL in payload / `custom_details` early | Humans + SRE Agent can deep-link |
| Test key for POC | Use a **test** integration/routing key | Never point prod Dynatrace at a POC Service by accident |

### PagerDuty Core (Orange — Modify)

| Point | What it means | Why you care |
| --- | --- | --- |
| Modify — test Service / EP | Create POC Service and Escalation Policy | Safe place for fake pages |
| Level-1 test schedule | On-call for POC is Level-1 on a **test** schedule | Shift POC must not touch prod primary |
| Integration key hygiene | Know which key is test vs prod | Stops cross-wiring noise into real rotations |

**EP** = Escalation Policy (who gets notified, in what order).

### PagerDuty Advance (Blue — Primary)

| Point | What it means | Why you care |
| --- | --- | --- |
| Primary — enable agents | This is the main new product surface | Without Advance, agent toggles do nothing |
| AI Actions budget | SRE/Scribe spend usage units | Plan cost before a big demo |
| Team Advance access | Limit who can use Advance if needed | Reduces blast radius of experiments |

### Teams / Slack (Orange — Modify)

| Point | What it means | Why you care |
| --- | --- | --- |
| Modify — bot + linkUser | Install PD bot; each user links identity | Agents need to know who you are in chat |
| Graph consent (Teams) | MS Admin approves message-read scopes | Advance chat cannot work without it |
| Standard channel map | Map one **standard** channel ↔ test Service | Private/shared channels often unsupported |

---

## 4) Second row — supporting and out of scope

### IT / IT Platform (Blue)

| Point | What it means |
| --- | --- |
| Highlighted impact | Incident Response (IR) tooling process changes |
| Why blue | Platform/SRE owners feel this in runbooks, training, and on-call habits |

### Cloud / SaaS Ops (Blue)

| Point | What it means |
| --- | --- |
| Monitoring-Alerting layer | Dynatrace + PagerDuty SaaS is the ops stack in scope |
| Why blue | Design lives in SaaS IR tooling, not in app microservices |

### Calendar (optional) (Green)

| Point | What it means |
| --- | --- |
| Reuse | Google Calendar Extension for Shift conflicts |
| Optional | Needed more for Teams-only **Shift Path B**; skip if you are not proving Shift yet |

### Business Apps (Gray)

| Point | What it means | Why you care |
| --- | --- | --- |
| Out of scope | Checkout / payment / product code | No rewrite for “product agents” |
| No code rewrite | Agents attach to PD incident + chat | App teams are not blocked on this design |

---

## 5) How to use this slide in a meeting

| Question from the room | Point at |
| --- | --- |
| Do we change Dynatrace a lot? | Green — reuse; keep URL; test key |
| Where is the real project work? | Blue Advance + Orange Teams/PD Core |
| Will app teams need sprints? | Gray — no |
| What about Shift without Slack? | Green Calendar + Orange PD Core schedule |
| Who owns IR process change? | Blue IT / IT Platform |

---

## 6) Common misreads

| Misread | Correct reading |
| --- | --- |
| Green = “healthy / done” | Green = **reuse**, not “already perfect” |
| Blue = “broken” | Blue = **primary design focus** |
| Gray = “unimportant forever” | Gray = **out of scope for this agent project** |
| “We must rebuild chat” | Orange = enable bot + consent + map — not rebuild Teams |
| “Dynatrace is the SRE connector” | Dynatrace is **ingress**; Advance is the agent surface |

---

## Data flow map (impact view)

```
Business Apps (gray — no rewrite)
        │ monitored
        ▼
Dynatrace (green — reuse detect + problem URL + test key)
        │
        ▼
PagerDuty Core (orange — test Service / EP / schedule / key hygiene)
        │
        ▼
PagerDuty Advance (blue — enable agents + Actions budget + access)
        │
        ▼
Teams / Slack (orange — bot, linkUser, Graph, channel map)
        │
        ├─► IT / IT Platform (blue — IR tooling impact)
        ├─► Cloud / SaaS Ops (blue — monitoring-alerting layer)
        └─► Calendar optional (green — Shift conflicts)
```

---

## Related files

| File | Role |
| --- | --- |
| Whole pack Slide 18 | This slide |
| `13-solution-context-to-be-diagram-explain/` | TO-BE context pair |
| `10-four-agents-ppt-each-page-explain/` | Full page guide |
| `14.sh` | Optional open helpers (user runs) |

## Commands

See `14.sh`.
