# PagerDuty Event Orchestration POC

## Decision tree

```
PagerDuty POC from the notepad — which job?
  Many related alerts → one page?
    Same app fires repeatedly              → #1 Intelligent grouping
    Many processes down on one host        → #2 Group by host
    disk + cpu + memory on one host        → #3 Host-related content grouping
    Disk space repeats on one host         → #4 Disk + host grouping
  Send the page to the right team?
    Oracle / DB keywords                   → #5 Route to DB team Service
    Linux / OS keywords                    → #6 Route to Infra team Service
    Java / Tomcat / app name               → #7 Route to Application team Service
    Unknown / no rule matched              → #10 Default team catch-all
  Do not wake people for noise?
    Flapping / self-resolves quickly       → #8 Pause (auto-pause / no page)
    Caused by a known deployment           → #9 Change context + suppress or self-close
  Shared gate
    Have AIOps / Event Orchestration?
      NO  → enable AIOps (or use service Event Rules where still present)
      YES → build TEST Services + one Orchestration → prove #1–10 in order
    Always: test Integration Keys only — never prod routing keys
```

```
Notepad categories → PD features
  Noise reduction          → Alert Grouping (#1–4) + Pause (#8) + Deploy suppress (#9)
  Correct team routing     → Event Orchestration Route (#5–7) + Default (#10)
  Auto-Pause → notifications → Pause before page (#8); Change Events for #9
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this POC is | Your notepad list: 10 Dynatrace → PagerDuty scenarios for grouping, routing, and auto-pause |
| What it is not | Not the four AI agents (SRE / Scribe / Shift / Insights). Those sit **after** a clean incident exists |
| Main PD features | Event Orchestration (route / pause / suppress / annotate) + Alert Grouping (intelligent / content-based) + Change Events |
| Three notepad categories | Noise reduction, Correct team routing, Auto-Pause → Incident notifications |
| Safe demo rule | Dedicated test Services and test Integration Keys that page only you |
| Suggested order | Shared setup → grouping (#1–4) → routing (#5–7, #10) → pause/deploy (#8–9) |

---

## Summary

Your notepad is an **Event Intelligence** POC, not an AI-agents POC. Dynatrace (or Events API) sends problems into PagerDuty. **Event Orchestration** decides route, pause, suppress, or annotate. **Alert Grouping** collapses related alerts into one incident. You prove each of the 10 lines with a checkable outcome: one incident instead of many, the correct team Service, or no page when the alert self-heals. After this pipeline is clean, the four AI agents (seq 8 / 11) become more useful because they see fewer, better-routed incidents.

---

## Main content

### What this is (beginner)

**Alert** = one signal from monitoring (“disk 95% on host-a”).

**Incident** = what the human gets paged for. One incident can contain many alerts if grouping works.

**Event Orchestration** = the rule engine that looks at every incoming event **before** (or as) it becomes an alert/incident. Rules run top-to-bottom. First match wins.

**Alert Grouping** = Service setting that merges related alerts into one incident so you do not get 20 pages for one host failure.

**Pause** = hold the event for N minutes. If Dynatrace sends a resolve in that window, nobody gets paged.

**Change Event** = a deploy or config change recorded in PagerDuty so responders (and later the SRE Agent) see “we shipped at 10:02.”

### This POC vs the four AI agents

| Topic | This notepad POC | Four agents POC (seq 8 / 11) |
| --- | --- | --- |
| Job | Stop noise and route to the right team | Help humans triage, note, cover, analyze |
| Layer | Before / at incident creation | After an incident already exists |
| Main tools | Event Orchestration, Alert Grouping, Change Events | Advance: SRE, Scribe, Shift, Insights |
| Success look | 20 alerts → 1 incident; DB alert → DB Service | Agent reply, transcript, override, MTTR answer |

Do both eventually. Do **this** first if your problem today is alert storms and wrong-team pages.

### Architecture

```
[Dynatrace Problem]  (or Events API v2 test payload)
        |
        v
[PagerDuty Events / Integration Key]
        |
        v
[Global Event Orchestration]   ← route / pause / suppress / annotate  (#5–10, #8–9)
        |
        v
[Target Service]               ← DB / Infra / App / Default
        |
        v
[Alert Grouping on Service]    ← intelligent + content-based  (#1–4)
        |
        v
[One Incident] → Escalation (test: page only you)
        |
        +---- optional later: SRE / Scribe / Insights agents
```

### POC objects (build once)

| Object | Example name | Why you care |
| --- | --- | --- |
| Default Service | `poc-eo-default` | Catch-all for #10 |
| DB Service | `poc-eo-db` | Oracle / DB route (#5) |
| Infra Service | `poc-eo-infra` | Linux / OS / host metrics (#6, also grouping demos) |
| App Service | `poc-eo-app` | Java / Tomcat / app name (#7, #1) |
| Test EP | `poc-eo-ep` | Escalation that notifies **only you** |
| Global Orchestration | `poc-eo-orchestration` | Holds route / pause / suppress rules |
| Dynatrace or Events API | Test integration keys only | Never use prod routing keys |
| Change source | Jenkins / GitHub / manual Change Event | Needed for #9 |

Put every Service on the same test escalation that pages only you. Use **standard** Teams/Slack mapping only if you also want cards; the core POC is visible in the PD web UI.

### Notepad → feature map

| # | Notepad line | PD feature | Category |
| --- | --- | --- | --- |
| 1 | Same Application generating repeated alerts — Intelligent grouping | Intelligent Alert Grouping | Noise reduction |
| 2 | 20 processes unavailable on same host → 1 incident | Intelligent or content-based grouping by `host` | Noise reduction |
| 3 | Host related alerts (disk/cpu/memory) → group into 1 | Content-based grouping by `host` | Noise reduction |
| 4 | Disk space alerts for same host → group into 1 | Content-based grouping by `host` + class | Noise reduction |
| 5 | Oracle DB alerts → route to DB team | Orchestration **Route** → `poc-eo-db` | Correct team routing |
| 6 | Linux/OS alerts → route to infra team | Orchestration **Route** → `poc-eo-infra` | Correct team routing |
| 7 | Java/Tomcat alert → route by application | Orchestration **Route** → `poc-eo-app` | Correct team routing |
| 8 | Wait time / self-resolves → Auto pause / No alert | Orchestration **Pause** | Auto-Pause → notifications |
| 9 | Alert caused by deployment → change context and self close | Change Events + Pause/Suppress + Dynatrace resolve | Noise reduction + Auto-Pause |
| 10 | New/unknown alerts → default team | Orchestration default / catch-all → `poc-eo-default` | Correct team routing |

---

### 0) Shared enablement (do once)

#### Prerequisites

| Need | What it means | Why you care |
| --- | --- | --- |
| AIOps / Event Orchestration | Account feature for global orchestration | Without it you only have older per-service Event Rules |
| PD Admin (or higher) | Can create Services, Orchestration, integrations | You must own the test objects |
| Test escalation | Pages only you | No prod wake-ups |
| Event source | Dynatrace test problem **or** Events API v2 curl/Postman | Repeatable demos |
| Optional Change feed | Jenkins/GitHub → PD Change Events | Required for a clean #9 |

#### Numbered steps

1. Create four Services: `poc-eo-default`, `poc-eo-db`, `poc-eo-infra`, `poc-eo-app`.
2. Attach all four to escalation `poc-eo-ep` (notify only you).
3. On each Service: Integrations → add **Events API v2** (or Dynatrace). Copy each Integration Key. Label them clearly.
4. On `poc-eo-infra` and `poc-eo-app`: Settings → Alert Grouping → enable **Intelligent** and/or **Content-based** (fields below under #1–4).
5. AIOps → Event Orchestration → create `poc-eo-orchestration` (Global). Point Dynatrace/global ingress at it if your tenant uses Global EO; otherwise attach rules on the ingress Service your Dynatrace key hits first.
6. Add orchestration rules in **this order** (top to bottom): pause/deploy (#8–9), specific routes (#5–7), default (#10). Grouping is mostly Service-level (#1–4).
7. Confirm you can send a test event (Events API v2) without using any production key.

#### Success criteria (§0)

| Check | Pass if |
| --- | --- |
| Four Services exist | Named as above; EP pages only you |
| Keys isolated | Test keys only; prod keys unused |
| Orchestration exists | Global (or ingress) EO named and editable |
| Grouping on | Infra + App Services show grouping enabled |

#### Safety (§0)

| Rule | Why |
| --- | --- |
| Never paste prod Integration Keys into Dynatrace POC | Prevents real rotations from getting storms |
| One test EP for all four Services | Blast radius stays you |
| Document rule order | First match wins — wrong order breaks routing |

---

### 1) Same application generating repeated alerts — Intelligent grouping

#### Goal

Repeated alerts from one application collapse into **one** incident.

#### Architecture

Service `poc-eo-app` → Alert Grouping → **Intelligent**. Events share similar summary / CEF class / custom details for the same app.

#### Usage case

Checkout app flaps: five “Checkout latency high” problems in three minutes. Without grouping you get five pages. With Intelligent Grouping you get one incident with five alerts underneath.

#### Demo steps

1. On `poc-eo-app` → Settings → Alert Grouping → enable **Intelligent**.
2. Send 3–5 Events API triggers within a few minutes with the same `source` / app name and similar `summary` (example: `Checkout latency high`).
3. Open Incidents. Confirm **one** open incident on `poc-eo-app`.
4. Open the incident → Alerts tab. Confirm multiple alerts are attached.
5. Resolve when done.

#### Pass if

| Check | Pass if |
| --- | --- |
| One incident | Not one incident per alert |
| Alerts linked | Alerts tab shows the repeats |
| Page count | You were not paged five separate times for the same flap |

---

### 2) Twenty processes unavailable on same host → one incident

#### Goal

Many process-down alerts on **one host** become one incident.

#### Architecture

Prefer content-based grouping on field `host` (or Dynatrace `dt.entity.host` / `custom_details.host`). Intelligent grouping often works too when payloads are similar.

#### Usage case

Host `app-01` loses 20 Tomcat/worker processes. Monitoring fires 20 “process unavailable” events. On-call should see **one** host-level incident, not twenty phone buzzes.

#### Demo steps

1. On `poc-eo-infra` (or `poc-eo-app`) enable content-based grouping keyed by `host` (and optionally `class`).
2. Send ~5–10 trigger events (20 if you want the full story) with the **same** `host=app-01` and summaries like `Process foo unavailable`.
3. Confirm one incident; Alerts tab lists the process alerts.
4. Optional: send one event for `host=app-02` and confirm it does **not** join the first incident.

#### Pass if

| Check | Pass if |
| --- | --- |
| Same host | Multiple process alerts → one incident |
| Different host | Separate incident (proves the group key) |

---

### 3) Host-related alerts (disk / CPU / memory) → group into one

#### Goal

Different metric types on the same host still group together.

#### Architecture

Content-based grouping by `host` only (do **not** require matching summary). Intelligent grouping can help when CEF fields are consistent.

#### Usage case

`app-01` is sick: disk 95%, CPU 99%, memory pressure. Three different alert titles. Still one “host is unhealthy” incident.

#### Demo steps

1. Grouping key = `host` on `poc-eo-infra`.
2. Send three triggers for `host=app-01`:
   - summary `Disk space critical`
   - summary `CPU saturation`
   - summary `Memory pressure`
3. Confirm one incident containing all three alerts.
4. Send `Disk space critical` for `host=app-02` → expect a second incident.

#### Pass if

| Check | Pass if |
| --- | --- |
| Cross-metric group | Disk + CPU + memory on one host → one incident |
| Host boundary | Other host does not merge |

---

### 4) Disk space alerts for same host → group into one

#### Goal

Repeated disk alerts for one host do not create a storm.

#### Architecture

Same as #3 with a tighter story: same `host` + same class/summary family (`disk`). Content-based on `host` is enough; adding `class=disk` is optional if you want disk-only groups.

#### Usage case

Disk fills slowly. Dynatrace re-opens or re-notifies “Disk /var 90%”, then 92%, then 95% on `db-01`. One incident tracks the story.

#### Demo steps

1. Keep content-based grouping by `host` on `poc-eo-infra`.
2. Send three disk triggers for `host=db-01` with rising percents in the summary or custom_details.
3. Confirm one incident; alerts show the progression.
4. Resolve.

#### Pass if

| Check | Pass if |
| --- | --- |
| Disk storm collapsed | Multiple disk alerts → one incident on that host |

---

### 5) Oracle DB alerts → route to DB team

#### Goal

DB-shaped events land on `poc-eo-db`, not the default queue.

#### Architecture

Event Orchestration rule (near the top of routing section):

```
IF summary OR custom_details contains Oracle|ORA-|tablespace|listener
THEN route to Service poc-eo-db
```

#### Usage case

Oracle tablespace alert fires. DB on-call owns it. Infra should not be woken first.

#### Demo steps

1. In `poc-eo-orchestration`, add Route rule for Oracle/DB keywords → `poc-eo-db`.
2. Send a test event: summary `Oracle tablespace USERS 95% full`.
3. Confirm the incident opens on **`poc-eo-db`** only.
4. Send a non-DB event and confirm it does **not** hit `poc-eo-db`.

#### Pass if

| Check | Pass if |
| --- | --- |
| Correct Service | Incident on `poc-eo-db` |
| Negative path | Non-DB event stays off DB Service |

---

### 6) Linux / OS alerts → route to Infra team

#### Goal

OS/host alerts land on `poc-eo-infra`.

#### Architecture

```
IF class/summary/custom_details matches Linux|systemd|kernel|OS|host unavailable
THEN route to Service poc-eo-infra
```

Place **after** more specific DB rules if an event could match both (usually DB first, then OS).

#### Usage case

Kernel OOM or systemd unit failed on a host. Infra owns the box. App team should not be first.

#### Demo steps

1. Add Route rule → `poc-eo-infra` for Linux/OS keywords.
2. Send summary `Linux systemd unit httpd.service failed on app-01`.
3. Confirm incident on `poc-eo-infra`.
4. Optional: combine with #2/#3 grouping on that Service.

#### Pass if

| Check | Pass if |
| --- | --- |
| Infra owns OS | Incident on `poc-eo-infra` |

---

### 7) Java / Tomcat alert → route by application to App team

#### Goal

App runtime alerts land on `poc-eo-app`, using application identity when present.

#### Architecture

```
IF summary/custom_details matches Tomcat|JVM|GC pause|java
   OR custom_details.application / dt.entity.service is set
THEN route to Service poc-eo-app
   (optional annotate application=<name>)
```

If you have many apps, later split into per-app Services. For the POC, one App Service is enough.

#### Usage case

Tomcat thread pool exhausted on Checkout. Application team owns the runtime. Infra is secondary.

#### Demo steps

1. Add Route rule → `poc-eo-app` for Java/Tomcat/JVM keywords (and/or `application` field).
2. Send summary `Tomcat thread pool exhausted` with `custom_details.application=checkout`.
3. Confirm incident on `poc-eo-app`.
4. Optional: enable Intelligent grouping (#1) on the same Service so repeats stay one incident.

#### Pass if

| Check | Pass if |
| --- | --- |
| App owns runtime | Incident on `poc-eo-app` |
| Enrichment (optional) | Application name visible on the alert |

---

### 8) Wait time / self-resolving alert → Auto-pause / no alert

#### Goal

Flapping alerts that clear quickly never page a human.

#### Architecture

Event Orchestration **Pause** (hold) for N minutes (start with **3–5**). If a resolve event arrives in the window, discard / do not notify. If it is still open after the pause, continue to the Service and page.

```
IF summary matches wait time|GC pause|transient|flapping  (tune to your real titles)
THEN pause 5 minutes
```

#### Usage case

A “DB wait time high” spike lasts 90 seconds and Dynatrace auto-closes. Without pause, someone gets a phantom page. With pause, silence.

#### Demo steps

1. Add Pause rule (5 minutes) for your flapping signature.
2. **Happy path:** send trigger, then send matching **resolve** within 2 minutes. Confirm **no** open incident (or incident never notifies).
3. **Negative path:** send trigger and do **not** resolve. After the pause, confirm an incident appears on the routed Service.
4. Tighten the match so production-critical titles are not paused by accident.

#### Pass if

| Check | Pass if |
| --- | --- |
| Self-heal | Resolve inside pause → no page |
| Real outage | Still open after pause → incident created |

#### Safety

| Rule | Why |
| --- | --- |
| Start with a narrow match | Broad pause hides real outages |
| Document pause minutes | Stakeholders must know the delay |

---

### 9) Alert caused by deployment → change context and self-close

#### Goal

During a known deploy, add change context and avoid a lasting false incident (suppress/pause, then auto-resolve when monitoring clears).

#### Architecture

Two pieces work together:

1. **Change Events** into PagerDuty (Jenkins/GitHub/manual) so the incident timeline shows the deploy.
2. **Orchestration** during deploy window:
   - Prefer **Pause** or time-bounded **Suppress** for known noisy titles (CPU spike, brief 5xx).
   - Or allow the incident but annotate `related_change=true` and rely on Dynatrace **resolve** to auto-resolve the PD alert.

Honest POC split:

| Path | What you prove |
| --- | --- |
| Path A (recommended) | Change Event appears on the Service/incident timeline + brief Pause during deploy |
| Path B | Incident opens with change context, then Dynatrace resolve closes it without human ack |

#### Usage case

Jenkins deploys Checkout at 10:02. CPU and error-rate blip for two minutes. On-call should see “deploy in progress,” not a midnight fire drill. When Dynatrace clears, PD clears.

#### Demo steps

1. Send a Change Event to `poc-eo-app` (UI “Add change” or API) with summary `Deploy checkout 1.2.3`.
2. Add Orchestration: if recent deploy tag / summary matches known deploy noise → **Pause 10 minutes** (or suppress for the maintenance window).
3. Send a matching noisy trigger (`CPU spike on checkout`) within that window.
4. Path A: confirm no page (or delayed) and Change Event is visible on the Service.
5. Path B: if an incident opened, send resolve; confirm auto-resolve when all alerts clear.
6. Do **not** suppress “payment unavailable” style customer-impact titles in the same rule.

#### Pass if

| Check | Pass if |
| --- | --- |
| Change visible | Deploy shows on Service/incident timeline |
| Noise handled | Deploy blip did not leave a lasting false page |
| Safety | Real impact titles are not blanket-suppressed |

---

### 10) New / unknown alerts → default team

#### Goal

Anything that matches no specific rule still lands somewhere owned — the default team — instead of disappearing.

#### Architecture

Last rule in Orchestration (catch-all):

```
ELSE route to Service poc-eo-default
```

Never put the catch-all above specific routes. First match wins.

#### Usage case

A brand-new Kafka lag alert appears. No DB/OS/Java rule matches. Default platform team gets it, then later you add a specific route.

#### Demo steps

1. Ensure #5–7 rules exist above the catch-all.
2. Add final Route → `poc-eo-default` (or mark Orchestration default Service).
3. Send summary `Something completely new xyz-unknown-42`.
4. Confirm incident on **`poc-eo-default`**.
5. Re-send an Oracle-shaped event and confirm it still hits `poc-eo-db` (proves order).

#### Pass if

| Check | Pass if |
| --- | --- |
| Unknown owned | Lands on default Service |
| Specific still wins | DB/OS/App rules still beat the catch-all |

---

### Suggested run order (half day)

| Order | Block | Time box |
| --- | --- | --- |
| 0 | Shared Services + EO + keys | 45–60 min |
| 1–4 | Grouping demos on infra/app | 30–40 min |
| 5–7, 10 | Routing + default | 30–40 min |
| 8–9 | Pause + deploy change | 30–40 min |

### Rule order cheat sheet (Orchestration)

```
1. Pause / suppress deploy noise (#8, #9)     ← narrow matches only
2. Route Oracle / DB (#5)
3. Route Java / Tomcat / app (#7)
4. Route Linux / OS (#6)
5. Default → poc-eo-default (#10)
```

Grouping (#1–4) is configured on the **destination Services**, not as the last Orchestration route.

### Common mistakes

| Mistake | Fix |
| --- | --- |
| Catch-all listed first | Move default to the bottom |
| Grouping off on the target Service | Enable Intelligent/content-based on `poc-eo-infra` / `poc-eo-app` |
| Grouping by summary only | Use `host` for #2–4 so disk+CPU can merge |
| Pause match too broad | Narrow keywords; prove the negative path still pages |
| Suppress all during deploy | Only suppress known deploy blips; keep customer-impact titles |
| Using prod Integration Keys | Swap to test keys before Dynatrace points here |
| Expecting AI agents to fix storms | Agents help after the incident exists; EO fixes the storm |

### Sample Events API v2 shape (for demos)

Review only — run yourself when ready. Replace `ROUTING_KEY` with a **test** key.

```json
{
  "routing_key": "ROUTING_KEY",
  "event_action": "trigger",
  "dedup_key": "poc-host-app-01-disk",
  "payload": {
    "summary": "Disk space critical on app-01",
    "severity": "error",
    "source": "dynatrace-poc",
    "component": "disk",
    "group": "app-01",
    "class": "disk",
    "custom_details": {
      "host": "app-01",
      "application": "checkout"
    }
  }
}
```

For resolve tests (#8/#9), send the same `dedup_key` with `"event_action": "resolve"`.

---

## Data flow map

```
[Notepad POC categories]
  Noise reduction .......... #1 #2 #3 #4 #8 #9
  Correct team routing ..... #5 #6 #7 #10
  Auto-Pause notifications . #8 #9

[Dynatrace / Events API]
        |
        v
[Event Orchestration poc-eo-orchestration]
   pause/suppress (#8/#9)
   route DB (#5) / App (#7) / Infra (#6)
   default (#10) → poc-eo-default
        |
        v
[Service Alert Grouping]
   Intelligent (#1)
   by host (#2 #3 #4)
        |
        v
[One Incident] → test EP (only you)
        |
        v
[Optional later] Advance agents (seq 8/11)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [7.sh](./7.sh) | Doc bookmarks + echo checklist (no live PD API) |
| [7-pagerduty-event-orchestration-poc-follow.txt](./7-pagerduty-event-orchestration-poc-follow.txt) | Chat-ready full steps |
| Source notepad | User screenshot “Paget duty POC” (10 lines + 3 categories) |
| Prior EO deep dive | Daily Files `2026-07-24/31_pagerduty-e2e/` |
| Best practices EO | Daily Files `2026-07-28/6_pagerduty-best-practices/` |
| Four agents (separate) | Daily Files `2026-08-25/8-…` / `11-…` and `2026-08-31/6-…` |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/7-pagerduty-event-orchestration-poc/` |

### Official docs

| Topic | URL |
| --- | --- |
| Event Orchestration | https://support.pagerduty.com/main/docs/event-orchestration |
| Alert grouping | https://support.pagerduty.com/main/docs/alert-grouping |
| Events API v2 | https://developer.pagerduty.com/docs/ZG9jOjExMDI5NTgw-send-an-alert-event |
| Change Events | https://support.pagerduty.com/main/docs/change-events |
| Dynatrace + PagerDuty | https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/pagerduty-integration |

---

## Commands

UI-first POC. One-liners in [7.sh](./7.sh). **Do not** call live PagerDuty APIs unless you explicitly ask later.

```bash
open "https://support.pagerduty.com/main/docs/event-orchestration"
open "https://support.pagerduty.com/main/docs/alert-grouping"
```
