# What Is HLD

```
Someone says "HLD"?
  → High-Level Design
  → Big boxes and arrows (who talks to whom)
  → NOT click-by-click runbook
  → NOT low-level code / API field lists

On this pack:
  "Technical Infrastructure — HLD Overview"
  = Dynatrace → PagerDuty → chat/meeting surfaces map
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| HLD | **High-Level Design** |
| What it shows | Systems, responsibilities, main data flows |
| What it is not | Detailed setup steps, code, or full LLD |
| This slide | Dynatrace problems → PD incident → Advance agents on Teams/Slack/PD web |
| Pair with | Impacted Platforms (who changes) + POC runbook (how to click) |

## Summary

**HLD** means High-Level Design. It is the architecture sketch you show in a design review: which platforms exist, how they connect, and where humans and agents sit. The slide titled **Technical Infrastructure — HLD Overview** is that sketch for Dynatrace + PagerDuty Advance + Teams/Slack.

## Investigation

User asked “what is HLD” while viewing the Technical Infrastructure HLD Overview slide. Defined the acronym, contrasted HLD vs LLD vs runbook, and mapped the slide’s boxes to the definition.

## Result

Read HLD as “big picture wiring.” Use Impacted Platforms for change scope and Part C for POC clicks.

---

## 1) Plain English

| Term | What it means | Why you care |
| --- | --- | --- |
| HLD | High-Level Design | Shared picture so teams agree on the shape before build |
| High-level | Few boxes, main arrows, main rules | Easy for ARB / managers / SREs to review together |
| Design | Intended target wiring (often TO-BE) | Not a screenshot of today’s accidental mess only |

**Analogy:** A subway map. You see lines and stations. You do not see every bolt on the rail.

---

## 2) HLD vs other docs

| Doc type | Shows | Example in this pack |
| --- | --- | --- |
| **HLD** | Systems + flows + surfaces | This Technical Infrastructure slide |
| Solution Context | Business/ops story boxes (AS-IS / TO-BE) | TO-BE diagram with four agents |
| Impacted Platforms | Who is green/orange/blue/gray | Reuse vs modify vs out of scope |
| LLD (Low-Level Design) | Detailed fields, APIs, configs | Not the main job of this slide |
| Runbook / POC | Click steps, commands, pass/fail | Part C §0–§4 Teams POC |

| Question | Use |
| --- | --- |
| How do the tools connect? | HLD |
| What changes for each platform? | Impacted Platforms |
| How do I demo SRE Agent tomorrow? | POC runbook |

---

## 3) What THIS HLD slide is saying

**Key message on the slide:**

| Claim | Plain English |
| --- | --- |
| Dynatrace sends problems to PagerDuty | Monitoring creates/notifies the PD incident |
| Advance agents attach to the incident + chat/meeting | Assist layer sits on PD + Teams/Slack/PD web |
| Teams needs Graph message-read | MS permission so Advance can read chat |
| Shift full DMs prefer Slack | Teams-only orgs use Path B for coverage |

**Boxes in beginner words:**

| Box | Role on the HLD |
| --- | --- |
| Responder | You in Teams/Slack (`linkUser`, maybe `graphAuth*`) |
| Admin | Turns on PD AI Settings + Graph consent |
| Calendar | Optional Google Calendar Ext for Shift |
| PagerDuty | Service, Incident, Advance Agents, Analytics hub |
| Optional EO | Noise route/group before the page |
| Dynatrace | Problem / Davis → notify with PD key + problem URL |
| Apps / Infra | What Dynatrace watches (Checkout, hosts, DB, JVM) |
| Teams meeting | Scribe join + transcript |
| Teams / Slack chat | `@pagerduty` asks for SRE / Insights |
| PD web | SRE Agent tab + schedule override |

**Footnote:** Prefer Application permission `ChatMessage.Read.All`. Use `graphAuth` only if the tenant is Delegated-heavy.

---

## 4) How to read an HLD in a meeting

```
1. Find the hub          → PagerDuty Incident
2. Find the source       → Dynatrace (Apps/Infra behind it)
3. Find optional filters → EO
4. Find human surfaces   → Teams chat / meeting / PD web
5. Find admin gates      → AI Settings + Graph consent
6. Note product gaps     → Shift DMs Slack-first
```

---

## Data flow map (HLD shape)

```
Apps / Infra
  → Dynatrace (Problem + problem URL + PD key)
  → optional EO
  → PagerDuty (Incident + Advance Agents + Analytics)
       ├── Teams/Slack chat (@pagerduty → SRE / Insights)
       ├── Teams meeting (Scribe)
       └── PD web (SRE tab / schedule override)
Admin: AI Settings + Graph consent
Responder: linkUser (± graphAuth)
Calendar: optional for Shift
```

---

## Related files

| File | Role |
| --- | --- |
| Whole pack Slide 20 | Technical Infrastructure — HLD Overview |
| `14-impacted-platforms-explain/` | Impact colors |
| `13-solution-context-to-be-diagram-explain/` | TO-BE context |
| `15.sh` | Optional open helpers (user runs) |

## Commands

See `15.sh`.
