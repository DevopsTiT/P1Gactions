# PD AI Detailed Alert Example

```
Want a concrete story of PD AI on an alert?
 → Pick a realistic service (e.g. ebroker / payments API)
 → Walk: monitor fire → PD page → Teams/Slack → ask AI → act
 → Show sample AI replies (Catch me up / causes / status / Scribe)
 → End with what human still must do
```

| Key point | Detail |
|---|---|
| Question | Detailed example of how PagerDuty AI reacts to an alert |
| Story | Dynatrace problem on ebroker → PD incident → Teams → AI assist |
| AI role | Summarize, suggest, draft — not auto-fix |
| Use | Paste into Teams reply or walk the test yourself |

## Summary

This is one full story from alert to AI help. The numbers and names are realistic training data, not a live outage. Use it to answer Davesh or to script your own test incident.

---

## Scenario (what broke)

| Item | Example value |
|---|---|
| Service | `ebroker-api` (production) |
| Symptom | Address conversion / downstream 503 spike; error rate up |
| Detector | Dynatrace problem: high failure rate on ebroker calls |
| On-call | You (primary), Davesh (secondary) |
| Chat | Teams channel `monitoring-2026-prod` (PagerDuty app connected, AI On) |
| PD incident | `#INC-48291` — P2 — opened 16:05 JST |

---

## Minute-by-minute example

### T+0 — Alert becomes a PagerDuty incident

```
Dynatrace Problem P-88421
  title: High error rate on ebroker-api / address conversion path
  → WF-B / Events API (or existing PD integration)
  → PagerDuty incident INC-48291 created
  → Phone / push / SMS page to primary on-call
  → Teams: "Triggered: INC-48291 High error rate on ebroker-api …"
```

**What PD AI does here:** nothing automatic. The page is classic PagerDuty. AI waits until someone asks (or a workflow/agent you configured runs).

### T+2 — You ack and ask “Catch me up”

You open Teams on the incident thread and type something like:

```
@PagerDuty Catch me up on INC-48291
```

**Example AI reply (illustrative):**

```
Incident INC-48291 — High error rate on ebroker-api (P2)
• Opened: 16:05 JST · Status: Triggered → Acknowledged by you
• Source: Dynatrace problem P-88421
• Recent related: similar ebroker address-conversion noise last Tue (INC-47102, resolved after agrex dependency recovered)
• Timeline so far:
  - 16:05 Triggered from Dynatrace
  - 16:07 Ack by primary
  - Channel notes: none yet
• Suggested next checks (not confirmed):
  1) Downstream agrex / zipcode or ebroker dependency health
  2) Recent deploy or config change on ebroker in last 2h
  3) Whether failures match "Address conversion failed…" vs broader 5xx
```

**How this helps:** you did not scroll Dynatrace + PD + chat for ten minutes. You got a starter map in one message.

### T+8 — You paste a log hint and ask for likely causes

You reply in the thread:

```
Seeing many: Address conversion failed.Request to agrex Zipcode
@PagerDuty What are some likely root causes?
```

**Example AI reply (illustrative):**

```
Given the phrase + ebroker-api context, likely angles to verify:
1) agrex zipcode dependency slow / 5xx / timeout (most common pattern for this message)
2) Bad or unexpected zip input volume (data quality spike)
3) ebroker address service config / cert / URL change after deploy
4) Partial network path to intraxa host

I cannot confirm which one is true from chat alone.
Check: Dynatrace dependency chart for agrex, recent PD change events, last ebroker deploy.
```

**How this helps:** triage checklist, not a magic root cause. You still open Dynatrace / logs.

### T+15 — Stakeholder asks “what’s going on?” — status draft

```
@PagerDuty Draft an internal status update for INC-48291
```

**Example AI reply (illustrative):**

```
Draft — Internal status (edit before sending)

Title: Investigating elevated ebroker address-conversion errors
Impact: Increased failures on address lookup / conversion path; customer-facing flows that need zip→address may fail or retry
Started: 16:05 JST
Status: Investigating (acked)
What we know: Dynatrace shows elevated error rate; logs show "Address conversion failed.Request to agrex Zipcode"
Next: Validate agrex health and recent changes; will update in 30 minutes
Owner: On-call SRE
```

You edit two lines, post to the stakeholder channel. **AI saved writing time; you kept accuracy.**

### T+25 — Bridge call + Scribe

Someone starts a Teams meeting from the incident. Scribe (if enabled) joins / captures.

Later:

```
@PagerDuty Wrap me up / summarize with Scribe notes
```

**Example AI reply (illustrative):**

```
Summary including meeting notes:
• 16:18 Confirmed agrex latency spike on dependency view
• 16:22 Decision: wait for dependency recovery; no ebroker rollback yet
• 16:24 Comms: customer impact limited to address conversion; payments path separate
• Open action: vendor/infra follow-up on agrex; add runbook link to INC
```

### T+45 — Resolve + PIR draft

Incident resolves when errors drop. You ask:

```
@PagerDuty Draft a post-incident review outline for INC-48291
```

**Example AI output shape:**

| Section | Example content AI might draft |
|---|---|
| What happened | ebroker address conversion errors rose for ~40 minutes |
| Impact | Zip→address lookups failed / retried |
| Detection | Dynatrace problem → PD page in under 2 minutes |
| Response | Ack, dependency check, status update, no rollback |
| Root cause (draft) | Upstream agrex degradation (confirm with evidence) |
| Follow-ups | Runbook link; alert threshold review; dependency SLO chat |

You rewrite the root-cause line after you have proof.

---

## Side-by-side: without AI vs with AI

| Moment | Without PD AI | With PD AI |
|---|---|---|
| Just paged | Open PD + Dynatrace + scroll chat | Same pages, plus “Catch me up” for a starter brief |
| Mid-incident | Manually list theories in chat | Ask “likely causes” → checklist to verify |
| Stakeholder ping | Write status from scratch | Draft → edit → send |
| After bridge | Someone types notes from memory | Scribe + wrap-up pulls meeting + chat |
| After resolve | Blank PIR doc | Outline with timeline markers to edit |

---

## What to tell Davesh (short + example)

```
Example we can walk together:

1) Dynatrace (or a test) opens PD incident INC-xxxxx → we get paged → Teams shows the incident.
2) In the PD Teams thread: @PagerDuty Catch me up
   → AI returns timeline, related past incidents, starter checks.
3) We paste one real log line (e.g. Address conversion failed…) and ask likely causes
   → AI returns a short checklist (dependency / deploy / input) — we verify in Dynatrace.
4) @PagerDuty Draft status update → we edit and send.
5) Optional: Scribe on the bridge → Wrap me up for notes.
6) After resolve: draft PIR outline → we correct root cause with evidence.

So AI reacts after the alert is a PD incident: it assists in chat; it does not replace the page or the human decision.
```

---

## How to turn this into a real test (safe)

| Step | What you do | Pass |
|---|---|---|
| 1 | Confirm Chat Integrations = Connected + On | Bot responds |
| 2 | Create a **low priority test** incident on a non-prod or test service | Message in test channel |
| 3 | `@PagerDuty Catch me up` | Summary returns |
| 4 | Paste a fake symptom line; ask likely causes | Checklist returns |
| 5 | Ask for a status draft | Editable draft |
| 6 | Resolve test incident | Clean close |

Do not page the whole prod rotation for a demo — use a test service / low urgency if your PD policy allows.

## Data flow map

```
[Dynatrace Problem]
       |
       v
[PagerDuty INC-48291] ----page----> [On-call phone]
       |
       +----notify----> [Teams monitoring channel]
                              |
                              v
                    Human: @PagerDuty Catch me up
                              |
                              v
                    [PagerDuty AI] --> summary / causes / status / Scribe
                              |
                              v
                    Human fact-check --> fix / escalate / resolve in PD
                              |
                              v
                    Optional: AI PIR draft --> human edits
```

## Related files

| File | Role |
|---|---|
| `18-pd-ai-alert-reaction-capabilities-reply/` | Short Teams reply + capability list |
| `2026-10-21/10-pd-ai-slack-teams-data-flow/` | Setup wiring |
| `19.sh` | Dual-write |

## Commands

See [19.sh](19.sh). No CLI required.
