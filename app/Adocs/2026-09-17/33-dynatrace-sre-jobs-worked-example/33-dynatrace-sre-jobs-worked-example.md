# Dynatrace Sre Jobs Worked Example

```
How to USE the four SRE jobs (worked example)
  A) Onboard EIP checkout monitoring + tags
  B) Triage Problem P-240917001
  C) Confirm / run SNOW+PD automation
  D) Investigate with PD → DT → Splunk → SNOW → fix → close
```

## Short takeaway

| Job | In this example you will… |
| --- | --- |
| A Deploy | Make checkout visible with `app:EIP` |
| B Triage | Read Problem `P-240917001` and pick next digs |
| C Automate | See OPEN create `INC0017788` + PD page; CLOSE resolve both |
| D Investigate | Ack PD, Splunk proof, rollback, confirm sync |

## Summary

This is a **hands-on worked example** of seq 32 day-to-day jobs (which expand seq 30 §5). All names and ids are **fake** — same story as the four-tools detailed example, but ordered as “what you click / type” for each job.

Parents: `../32-dynatrace-sre-jobs-day-to-day/` · `../30-dynatrace-components-how-to-use/` · `../31-four-tools-detailed-example/`

---

## Investigation

User asked for a detailed example of how to use “it” — in context, the Dynatrace SRE day-to-day jobs (deploy, triage, automate, investigate).

## Result

Follow Acts 1–4 below in order for a full rehearsal, or jump to Act 2–4 if monitoring and Workflows already exist.

---

## Cast and fake inventory

| Item | Fake value |
| --- | --- |
| App | EIP Checkout API |
| Host / service tag | `app:EIP`, `env:stg`, `team:payments` |
| Dynatrace UI | `https://abc12345.apps.dynatrace.com` |
| Problem | `P-240917001` — Failure rate increase on checkout API |
| ServiceNow | `https://silvastg.service-now.com` → `INC0017788` |
| PagerDuty dedup | `dt-problem-P-240917001` |
| PD routing key | `R03AMPLEFAKEROUTINGKEY00000000000` |
| Splunk | `index=app_eip sourcetype=checkout_api` |
| Bad build | `checkout-api:1.8.4` → rollback `1.8.3` |

---

## Act 1 — Job A: Deploy monitoring (how to use)

**Goal:** Dynatrace sees checkout and tags it so Workflows route to EIP-Support.

### 1.1 Install (pick one path)

**Host path**

| Step | You do | Expect |
| --- | --- | --- |
| 1 | In Dynatrace: Deploy OneAgent → download Linux installer | Installer file |
| 2 | On checkout host: run installer with your env / tenant flags | Success message |
| 3 | Wait 3–5 minutes | — |

**Kubernetes path**

| Step | You do | Expect |
| --- | --- | --- |
| 1 | Install Dynatrace Operator for the cluster | Operator Running |
| 2 | Ensure checkout namespace is monitored | Pods visible |

### 1.2 Verify in UI

| Step | Click / look | Pass |
| --- | --- | --- |
| 1 | **Infrastructure → Hosts** (or K8s workload view) | Checkout host listed |
| 2 | Open host → Processes | `checkout-api` (or similar) present |
| 3 | **Services** | Checkout service appears |
| 4 | Generate a few test requests | Metrics move |

### 1.3 Add tags (required for your pack)

| Step | You do | Fake value |
| --- | --- | --- |
| 1 | Open the service/host → Tags (or use auto-tag rules) | — |
| 2 | Add | `app:EIP` |
| 3 | Add | `env:stg` |
| 4 | Add | `team:payments` |
| 5 | Save; refresh entity | Tags visible on entity |

### 1.4 Done criteria for Act 1

| Check | Pass? |
| --- | --- | --- |
| Entity in UI | Yes |
| Tag `app:EIP` present | Yes |
| You could open a chart for error rate | Yes |

If Act 1 is already done in real life, skip to Act 2.

---

## Act 2 — Job B: Detect and triage (how to use)

**Scene:** 02:15 — users report Pay failures. You are on-call (or watching Problems).

### 2.1 Open the Problem

| Step | You do | What you see (fake) |
| --- | --- | --- |
| 1 | Dynatrace → **Problems** | List of Problems |
| 2 | Filter **Open** | — |
| 3 | Click `P-240917001` | Problem card |
| 4 | Read title | Failure rate increase on checkout API |
| 5 | Read severity / start | ERROR · started ~02:14 |
| 6 | Check tags on entities | `app:EIP` |

### 2.2 Understand blast radius

| Step | You do | Why |
| --- | --- | --- |
| 1 | Open **Impacted / affected entities** | Know what is hurt |
| 2 | Note service name | Use in Splunk later |
| 3 | Skim Davis root-cause hint | Hypothesis only |

### 2.3 Dig signals inside Dynatrace

| Step | You do | Fake finding |
| --- | --- | --- |
| 1 | Problem → metrics / failure rate | Spike from 02:14 |
| 2 | Open a **trace** with HTTP 500 | Fails in DB call span |
| 3 | Copy Problem URL | Paste into notes later |
| 4 | Write down start time | `02:14 JST` |

### 2.4 Triage decision (this example)

| Decision | Choice |
| --- | --- |
| Real outage? | Yes — ERROR + user impact |
| Next tool? | Confirm automation created INC/PD (Act 3), then Splunk (Act 4) |
| Severity intent | Treat as P3-style (matches your prepare mapping for ERROR) |

### 2.5 Done criteria for Act 2

| Check | Pass? |
| --- | --- | --- |
| You know Problem id | `P-240917001` |
| You know start time | `02:14` |
| You know app tag | `EIP` |
| You have Problem URL | Yes |

---

## Act 3 — Job C: Automate ticket + page (how to use)

Two modes: **first-time setup** vs **already live — verify during incident**.

### 3.1 First-time setup (do once)

| Step | Where | You do | Fake example |
| --- | --- | --- | --- |
| 1 | Settings → Connections → ServiceNow | Create Connection | URL `https://silvastg.service-now.com` |
| 2 | Settings → External requests | Add hosts | `silvastg.service-now.com`, `events.pagerduty.com` |
| 3 | Problem notifications → `servicenowstg` | Set ITSM **OFF** | ITOM optional ON |
| 4 | Workflows | Upload OPEN YAML | From seq 19/22 |
| 5 | Workflows | Upload CLOSE YAML | Same pack |
| 6 | Each snow task | Map Connection | `SNOW-Silva-STG-Connector` |
| 7 | PD JS | Set routing key | Your real key (fake: `R03AMPLE...`) |
| 8 | assignMap | EIP group/biz sys_ids | Real sys_ids |
| 9 | Activate both | On | — |

### 3.2 During this incident — verify automation ran

| Step | Where | You do | Expect (fake) |
| --- | --- | --- | --- |
| 1 | Workflows → **Executions** | Open latest OPEN run for `P-240917001` | Status OK |
| 2 | Task list | Confirm prepare → snow-create → PD → comment | All OK |
| 3 | ServiceNow | Search `INC0017788` or `correlation_id=P-240917001` | INC exists, group EIP-Support |
| 4 | PagerDuty | Find alert | dedup `dt-problem-P-240917001` |
| 5 | INC work notes | Read cross-link comment | PD key + Problem URL present |

### 3.3 If something failed (how to use Executions)

| Failure you see | What you fix | Re-test |
| --- | --- | --- |
| Host not allowed | External requests | Re-run / new Problem |
| SNOW 401/403 | Connection user roles | Re-run create |
| PD HTTP error | Routing key / PD allowlist | Re-run PD task |
| Two INCs | Classic ITSM still ON | Turn OFF; close duplicate |

### 3.4 Done criteria for Act 3 (open path)

| Check | Pass? |
| --- | --- | --- |
| Exactly one new INC | Yes |
| PD alert open | Yes |
| correlation_id = Problem id | Yes |
| dedup_key = `dt-problem-<id>` | Yes |

---

## Act 4 — Job D: Investigate with other tools (how to use)

**Goal:** Clear the page path and prove root cause, then recover.

### 4.1 PagerDuty (first 60 seconds)

| Step | You do | Why |
| --- | --- | --- |
| 1 | Open PD mobile/web alert | — |
| 2 | **Acknowledge** | Stop escalation |
| 3 | Open linked Dynatrace URL (or from INC) | Jump to Problem |

### 4.2 ServiceNow (orientation)

| Step | You do | Fake |
| --- | --- | --- |
| 1 | Open `INC0017788` | Assigned EIP-Support |
| 2 | Read short description + description | Runbook + L1/L2/L3 |
| 3 | Keep tab open for work notes | — |

### 4.3 Dynatrace (scope) — already partly done in Act 2

| Step | You do |
| --- | --- |
| 1 | Confirm still OPEN |
| 2 | Re-check error rate — still high? |
| 3 | Note any deploy event around 02:10–02:14 |

### 4.4 Splunk (proof)

| Step | You do |
| --- | --- |
| 1 | Open Splunk |
| 2 | Run search for the Problem window |

```
index=app_eip sourcetype=checkout_api status>=500 earliest=-30m
| table _time, request_id, status, message, build_version
| sort _time
```

| Step | You see (fake) |
| --- | --- |
| 3 | Smoking gun | `build=1.8.4` + DB connection timeout, `request_id=req-9f3a` |

### 4.5 Write evidence back to ServiceNow

| Step | You do |
| --- | --- |
| 1 | INC → Work notes |
| 2 | Paste |

```
Acked PD. DT Problem P-240917001.
Splunk: request_id=req-9f3a build=1.8.4
SQLException connection timeout to payments-db after deploy.
Next: rollback checkout-api 1.8.4 → 1.8.3 with app owner.
```

| Step | Save |
| --- | --- |
| 3 | Save INC | Audit trail updated |

### 4.6 Fix and verify

| Step | You do | Expect |
| --- | --- | --- |
| 1 | Rollback to `1.8.3` | Deploy succeeds |
| 2 | Dynatrace error rate | Returns to baseline |
| 3 | Splunk 5xx | Stops for new traffic |
| 4 | Wait for Davis | Problem → **CLOSED** (~02:40 in story) |

### 4.7 Confirm CLOSE automation

| Step | Where | Expect |
| --- | --- | --- |
| 1 | Workflows → Executions | CLOSE run OK |
| 2 | ServiceNow | `INC0017788` Resolved; auto resolution notes |
| 3 | PagerDuty | Alert resolved (same dedup) |

If INC still open: search `correlation_id=P-240917001` and resolve manually; fix mapping for next time.  
If PD still open: resolve manually; verify dedup_key matched open.

### 4.8 Done criteria for Act 4

| Check | Pass? |
| --- | --- | --- |
| PD acked then cleared | Yes |
| Splunk evidence in INC | Yes |
| Fix applied | Rollback done |
| Problem CLOSED | Yes |
| INC + PD resolved | Yes |

---

## One-page “how to use it” script (copy)

```
ACT A (once per new service)
  Install OneAgent/Operator → verify in UI → tag app:EIP env:stg

ACT B (when Problem appears)
  Problems → open card → entities → metrics/traces → note start time + URL

ACT C (once + verify each incident)
  Setup: Connection, allowlist, ITSM OFF, OPEN/CLOSE workflows, PD key
  During: Executions OK? one INC? one PD? cross-link comment?

ACT D (every page)
  Ack PD → open INC → open DT Problem → Splunk → work note → fix
  → wait Problem CLOSED → confirm INC+PD resolved
```

---

## Happy-path picture for this example

```
Act A: EIP tagged in Dynatrace
        │
Act B:  P-240917001 OPEN (you triage)
        │
Act C:  INC0017788 + PD trigger (automation)
        │
Act D:  Ack → Splunk finds 1.8.4 DB timeout → rollback
        │
        P-240917001 CLOSED
        → INC resolved + PD resolved (automation)
```

---

## Data flow map

```
You (Job A) → OneAgent + tags
Davis       → Problem
You (Job B) → read Problem
Workflow    → SNOW + PD          (Job C)
You (Job D) → PD ack + Splunk + SNOW notes + fix
Davis       → Problem close
Workflow    → SNOW resolve + PD resolve
```

## Related files

| Path | Why |
| --- | --- |
| `../32-dynatrace-sre-jobs-day-to-day/` | Job definitions |
| `../30-dynatrace-components-how-to-use/` | Components + §5 |
| `../31-four-tools-detailed-example/` | Same night story, tool-centric |
| `../19-snow-connector-workflow-again/` | YAML for Act C |
| `33.sh` | Paths |

## Commands

See `33.sh` in this folder.
