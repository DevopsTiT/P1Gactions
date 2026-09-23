# SRE Agent POC Explain

```
Want to prove SRE Agent works?
  → Use TEST Service only (never prod)
  → Advance On + Teams mapped + linkUser done?
       NO → finish §0 enablement first
       YES → run POC story below (15–20 min)

Pass if:
  Teams reply grounded + runbook cited + no silent remediation + Resolve done
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What POC means | **Proof of Concept** — a short, safe demo that the SRE Agent really helps triage |
| Goal | On a **test** incident, ask in Teams, use a small runbook, get next steps, Resolve |
| Time box | About **15–20 minutes** (after shared enablement) |
| Cost | **4 AI Actions** per ask (budget ~3 asks ≈ 12 Actions) |
| Hard rule | TEST Service that pages **only you**; human confirms remediations |

## Summary

POC is not production rollout. It is a controlled rehearsal: fake (or Dynatrace-shaped) “Checkout latency high” on a test PagerDuty Service, talk to `@pagerduty` in the mapped Teams channel, upload `poc-checkout-latency.md`, try a few asks, then Resolve. If that works, you proved the agent path — not that prod is ready.

## Investigation

User asked “POC?” after the SRE Agent Live Triage slide explain. Clarified the slide’s POC story into prerequisites, numbered steps, success checks, and common fails. Built on seq 11 and whole-pack Part C §1.

## Result

Follow the step list below on a test Service. Do not attach prod routing keys or prod schedules.

---

## 1) What “POC” means here

| Term | What it means | Why you care |
| --- | --- | --- |
| POC | Proof of Concept | Show the feature works end-to-end before buying time / budget / prod change |
| SRE Agent POC | Prove live triage in Teams (or PD web tab) on a **safe** incident | Cuts risk of waking the real on-call |
| Not a load test | One person, one test Service, a few asks | Enough to learn; not a performance study |

---

## 2) What you are proving (success criteria)

| Check | Pass if |
| --- | --- |
| Incident visible | Test incident card appears in the mapped Teams channel |
| Triage reply | `@pagerduty` answers with a grounded summary |
| Runbook | A later answer references your uploaded steps |
| Human control | No remediation ran without your explicit confirm |
| Memory path | You **Resolve** the test incident (memory can save) |

---

## 3) Prerequisites (before the POC story)

| Need | Ready when |
| --- | --- |
| PagerDuty Advance | AI Settings show Advance available; agent toggles work |
| SRE Agent Enabled | AI Agents → SRE = Enabled (Teams may be Early Access) |
| Teams Connected | Chat Integrations → Teams On; channel mapped to test Service |
| linkUser | You ran `@PagerDuty linkUser` in Teams |
| Test Service | e.g. `poc-pd-ai-agents-test` — escalation pages **only you** |
| Runbook file | `poc-checkout-latency.md` (or `.txt`), clear 5–10 steps, **≤ 100 KB** |

If Advance is off, stop — the POC will look like “bot does nothing.”

---

## 4) POC story — step by step (from the slide)

```
1. Prepare runbook poc-checkout-latency.md (5–10 steps)
2. Create TEST incident: "Checkout latency high"
   (UI Create incident on poc-pd-ai-agents-test — or Dynatrace test key only)
3. Open mapped Teams channel — confirm incident card
4. Ask: @pagerduty What are some likely root causes?
5. Upload / attach the runbook when offered (or use PD web SRE tab)
6. Ask: @pagerduty Analyze past incidents
7. Ask: @pagerduty What steps should I take first?
8. If remediation suggested → READ → approve or decline (never blind auto-run)
9. Optional: open PD web Incident → SRE Agent tab
10. Resolve the test incident
```

| Step | Why it is there |
| --- | --- |
| Test title “Checkout latency high” | Dynatrace-shaped story stakeholders recognize |
| First ask | Proves chat path + Actions spend |
| Upload runbook | Grounds answers in **your** process |
| Past incidents / first steps | Shows history + prioritization help |
| Confirm remediation | Proves human-in-the-loop |
| Resolve | Closes loop + memory save path |

---

## 5) Example runbook content (keep tiny)

Use short, numbered steps in `poc-checkout-latency.md`, for example:

1. Open Dynatrace problem URL from the incident custom details.
2. Check checkout service error rate and p95 latency for the last 15 minutes.
3. Check recent deploy / change window for checkout.
4. Check dependency health (payment API, DB, cache).
5. If bad deploy: prepare rollback plan — **do not execute without human confirm**.
6. Update incident notes with findings.
7. Resolve when latency returns to normal on the test path.

Do not put customer PII, passwords, or prod break-glass steps that auto-run.

---

## 6) Cost during POC

| Ask | Actions |
| --- | --- |
| Likely root causes | 4 |
| Analyze past incidents | 4 |
| What steps first | 4 |
| **Typical POC total** | about **12** Actions |

Virtual responder / workflow nudge also costs **4** per trigger — skip it on the first POC if you want to save budget.

---

## 7) Common POC fails

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| `@pagerduty` ignores you | Advance off or Teams not Connected | Finish §0 enablement |
| No incident card | Channel not mapped to Service | Remap channel ↔ test Service |
| Vague answers | No runbook / empty custom_details | Upload runbook; put `problem_url` early in custom_details |
| Wrong people paged | Prod escalation attached | Fix EP so only you notify |
| “It fixed prod by itself” | You should never allow that | Decline remediations; test Service only |

---

## Data flow map

```
Prereq: Advance + Teams map + linkUser + test Service
        │
        ▼
Create "Checkout latency high" (TEST)
        │
        ▼
Teams card → @pagerduty asks (4 Actions each)
        │
        ▼
Upload poc-checkout-latency.md
        │
        ▼
Read remediation → confirm/decline
        │
        ▼
Resolve → optional SRE memory
        │
        ▼
POC pass / fail checklist
```

---

## Related files

| File | Role |
| --- | --- |
| `11-sre-agent-live-triage-explain/` | Slide meaning |
| Whole pack slides 32–34 | Full §1 click path |
| `10-four-agents-ppt-each-page-explain/` | All 42 pages |
| `12.sh` | Optional open helpers (user runs) |

## Commands

See `12.sh`. Type Teams asks yourself on TEST only.
