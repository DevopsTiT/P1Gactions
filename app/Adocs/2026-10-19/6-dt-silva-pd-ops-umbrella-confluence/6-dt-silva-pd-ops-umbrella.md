# Dynatrace SILVA PagerDuty Operations Umbrella

> **Audience:** SRE / on-call and platform who need when detection starts, which apps own each step, and where related runbooks live.

> **Safety:** OPEN/CLOSE send when Deployed. Draft or DRY_RUN until tested. No secrets in Confluence. One OPEN + one CLOSE per scope.

---

## Decision tree

```
Something wrong in monitored apps/hosts?
  → Davis detects a Problem (Problems app)
  → ACTIVE + CREATED? → S0 OPEN → SILVA + PagerDuty
  → CLOSED? → S2 CLOSE → SILVA Resolved + PD resolve
 Need AI in Slack without PD Advance? → WF-A / DT AI runbooks
 Need Paige in Slack/Teams? → PagerDuty AI runbooks
```

---

## Short takeaway

| Question | Answer |
| --- | --- |
| When does detection start? | Davis opens a Problem on monitored entities |
| When does S0 start? | Problem Active + CREATED (+ categories) |
| When does S2 start? | Problem Closed |
| Which DT app runs graphs? | Automations / Workflows |
| External apps | SILVA + PagerDuty |
| Deep pages | S0 seq 4 + S2 seq 5 Confluence wikis |

---

## Summary

Detection is Dynatrace Davis/Problems. Ticketing and paging are Automations workflows calling SILVA and PagerDuty. This umbrella links when each stage starts, which app owns it, and the related instruction/runbook set.

---

## When detection starts

Dynatrace monitors entities → Davis opens a **Problem** → you see it in the Problems app. That is detection. A SILVA ticket appears only after **S0 OPEN** runs (Deployed).

Problems relate to affected entities (host, K8s service, process group, …). Entity tags feed S0 `extract-event-tags` / `resolve-snow-values`. Missing tags → preview MISSING → skip create.

---

## When workflows start

| Workflow | Starts when |
| --- | --- |
| S0 OPEN | `DAVIS_PROBLEM` Active + CREATED; categories error/resource/slowdown/availability/custom |
| S2 CLOSE | Problem closed; align categories with OPEN |

Drafts are not triggered.

```
T0  Problem opens → S0 → SILVA create + PD trigger
T2  Problem closes → S2 → SILVA Resolved + PD resolve
```

---

## Related apps

| App | Role |
| --- | --- |
| Dynatrace Problems / Davis | Detect / close problems |
| Dynatrace Automations | Run S0 / S2 |
| SILVA | ITSM incidents |
| PagerDuty | Page / resolve |
| Optional DT Slack/Teams | WF-A AI catch-up |
| Optional PD Slack/Teams AI | Paige / Scribe (not required for S0/S2) |

---

## Child Confluence pages

| Page | Workflow |
| --- | --- |
| S0 Preview Then Post | OPEN — `4-s0-preview-post-silva-pd-event-path.wiki` |
| S2 CLOSE Problem | CLOSE — `5-s2-close-silva-pd-event-path.wiki` |

Shared: `correlation_id = P-…`, `dedup_key = dt-problem-P-…`

---

## Relative instructions and runbooks

### A — OPEN / CLOSE

| Runbook | Use when |
| --- | --- |
| This umbrella | Orientation |
| S0 Confluence (2026-10-19/4) | OPEN tasks + APIs |
| S2 Confluence (2026-10-19/5) | CLOSE tasks + APIs |
| 2026-10-01/36-standard-flow… | OPEN YAML (local secrets) |
| 2026-10-01/39-close-direct… | CLOSE YAML (local secrets) |
| 2026-10-01 SILVA field seqs 10/14/15/21 | Form keys / CI / verify |

### B — Optional DT AI → Slack/Teams

| Runbook | Use when |
| --- | --- |
| 2026-10-18/1 event path | AI replace PD triage |
| 2026-10-18/2 all files | WF-A / WF-B templates |
| 2026-10-18/3 Confluence | AI replace Confluence |
| 2026-10-18/4–6 | Inputs, explain, get Slack/Teams |

### C — PagerDuty AI chat

| Runbook | Use when |
| --- | --- |
| 2026-10-18/7 instructions | PD AI Slack/Teams steps |
| 2026-10-18/8 Confluence | PD AI Confluence paste |

### D — Symptom → runbook

| Symptom | Go to |
| --- | --- |
| Drafts not triggered | S0/S2 Deploy checklist |
| Preview MISSING | S0 + SILVA key runbooks |
| CLOSE no-op | S2 (no open correlation / Draft) |
| Wrong close_code | S2 CLOSE_CODE / sys_choice |
| Want Slack AI without PD Advance | Section B |
| Want @PagerDuty AI | Section C |

---

## Data flow map

```
Monitored app/host
  → Davis Problem (detection)
  → Automations
       S0 OPEN → SILVA POST + PD trigger
       S2 CLOSE → SILVA PATCH + PD resolve
  → Optional WF-A / PD AI chat
```

---

## Suggested Confluence tree

```
Umbrella (this page)
  ├─ S0 OPEN detail
  ├─ S2 CLOSE detail
  ├─ (Optional) DT AI replace PD AI
  └─ (Optional) PagerDuty AI Slack/Teams
```

---

## Document control

| Field | Value |
| --- | --- |
| Source | S0/S2 + OPEN/CLOSE standards + AI/PD AI runbooks |
| Secrets | None |
