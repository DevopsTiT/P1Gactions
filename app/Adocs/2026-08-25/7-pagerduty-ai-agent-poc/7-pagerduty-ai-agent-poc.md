# PagerDuty AI Agent POC

## Decision tree

```
Want AI agent to help with PagerDuty in a POC?
        │
        ▼
Do you have a TEST Service only (not prod on-call)?
        │
   NO → stop. Create a dedicated poc-test service first.
   YES
        │
        ▼
Need to CREATE a test page?
        │
   YES → Events API v2 + routing key → trigger incident
   NO  → skip to manage open incidents
        │
        ▼
Agent needs list / ack / note / resolve?
        │
   YES → REST API + API user token (least privilege)
        │
        ▼
Resolve without a human?
        │
   NO  (POC default) → agent proposes; human clicks Resolve
   YES (later) → require explicit approval gate + audit log
        │
        ▼
Still paging real humans from POC?
        │
   YES → wrong. Point escalation at yourself or a silent test user.
   NO  → safe to iterate
```

If the agent “fails”: check token scope, wrong service ID, Events key vs REST token mix-up, and whether you hit the test Service — not “AI is broken.”

---

## Short takeaway

| Question | Answer |
|----------|--------|
| What does this POC prove? | An AI agent can safely create and help manage PagerDuty incidents on a test Service. |
| What must stay human? | Primary on-call for real prod pages. The agent is a helper, not the pager replacement. |
| Two keys you need | Events API routing key (create/update alerts) and a REST API token (ack/note/resolve/list). |
| Safe default | Test Service only. No prod schedule. Human approval before Resolve. |

## Summary

This guide wires a proof of concept so an AI agent (Cursor Agent, automation bot, or on-call assistant) can talk to PagerDuty. You prove create → list → acknowledge → annotate → (optional) resolve on a **test** Service. In your stack, Dynatrace already pages humans via PagerDuty; the agent sits beside that path as a secondary helper — never as the only owner of production incidents.

---

## 1. What this is (and why it matters)

**PagerDuty** is the tool that wakes a human when something may be hurting users.

An **AI agent** here means a program or chat agent that can call tools (HTTP APIs). In a POC you teach it a few PagerDuty tools so it can help with incident hygiene.

| Idea | What it means | Why you care |
|------|---------------|--------------|
| POC | Small, reversible demo — not production automation | You learn the wiring without paging the real rotation |
| Events API v2 | Simple HTTP API to open/update/resolve alerts with a routing key | Best way for monitors or agents to *create* a page |
| REST API | Full PagerDuty API with a user/API token | Needed to list incidents, ack, add notes |
| Agent as helper | Agent drafts notes, suggests ack, fetches context | Humans still own prod pages and customer impact |

Plain English: Dynatrace (or your agent) opens a test incident. A human still gets notified if you wire a schedule. The agent can say “I see incident X; here is a note; want me to ask you before resolve?”

---

## 2. What the POC must prove

| Capability | Success look | POC rule |
|------------|--------------|----------|
| Create | Test incident appears on the test Service | Use Events API only against test routing key |
| List | Agent returns open incidents for that Service | Filter by service id; ignore prod services |
| Acknowledge | Incident moves to Acknowledged | Prefer agent proposes + human confirms in early POC |
| Annotate | Timeline shows an agent note | Always include “source=ai-agent-poc” in the note |
| Resolve | Incident closes | Default: human resolves; agent only if approval gate exists |

Out of scope for v1 POC: replacing primary on-call, auto-mitigation in prod, or writing to production Services.

---

## 3. Prerequisites

| Need | What it is | Beginner tip |
|------|------------|--------------|
| PagerDuty account | Trial or existing org | Use a sandbox/dev subdomain if you have one |
| Permission to create a Service | Admin or service-owner rights | Ask a teammate if the UI is locked |
| Events API v2 integration | Per-Service routing key | This is *not* the same as the REST token |
| REST API token | User or API key with incident read/write | Prefer a dedicated “bot” user, least privilege |
| AI agent runtime | Cursor Agent, script, or webhook listener | Start with curl; then wrap as agent tools |
| Secret storage | `.env` local or Secrets Manager | Never commit keys to git |

---

## 4. Architecture (pic flow)

Happy path for the POC:

```
Monitor (Dynatrace)  OR  AI agent "trigger" tool
        │
        ▼
PagerDuty Events API v2  (routing key / integration key)
        │
        ▼
Alert → Incident on TEST Service
        │
        ▼
Escalation / Schedule  →  notify human (you, for POC)
        │
        ▼
Optional: PD webhook → agent listener (inbound)
        │
        ▼
Agent tools via REST API:
  list open  →  ack  →  add note  →  (human) resolve
```

Where this sits in your real stack:

```
Dynatrace Problem (prod path, unchanged)
        │
        ▼
PagerDuty Service (existing) → primary on-call human
        │
        └── AI agent (side path)
              reads incidents / drafts notes / helps triage
              does NOT replace primary paging
```

---

## 5. Step-by-step POC (minimal)

### A. Create a test Service + escalation + schedule

1. In PagerDuty UI: **Services → New Service**.
2. Name it clearly, e.g. `poc-ai-agent-test` (not a prod app name).
3. Attach an escalation policy that points at **you** (or a silent test user), not the production rotation.
4. Use a schedule only if you want to practice paging yourself. For quieter demos, use a policy that notifies email only.

### B. Add Events API v2 integration

1. On the test Service → **Integrations → Add integration → Events API V2**.
2. Copy the **Integration Key** (also called routing key).
3. Store it as `PD_ROUTING_KEY` outside git.

### C. Create an API token for the agent

1. Create or pick a dedicated user (example name: `ai-agent-poc`).
2. Generate an API access key / token with rights to **read and write incidents** on the test Service only if your plan supports scoping; otherwise restrict by process (agent only ever uses the test service id).
3. Store as `PD_API_TOKEN`. Never reuse a human password.

### D. Store secrets outside git

| Place | When to use |
|-------|-------------|
| Local `.env` (gitignored) | Laptop POC |
| AWS Secrets Manager / similar | Shared or cloud agent |
| CI secret store | Only if CI must trigger test pages |

Example variable names (placeholders only):

```
PD_ROUTING_KEY=REPLACE_ME_EVENTS_KEY
PD_API_TOKEN=REPLACE_ME_REST_TOKEN
PD_SERVICE_ID=REPLACE_ME_TEST_SERVICE_ID
PD_FROM_EMAIL=ai-agent-poc@example.com
```

`PD_FROM_EMAIL` is the email PagerDuty expects on many write calls (the “From” header for the acting user).

### E. Agent tool: trigger a test incident (Events API)

Wrap the Events API `trigger` call as one agent tool, e.g. `pagerduty_trigger_test`. Always send a unique `dedup_key` so retries do not spam new incidents.

### F. Agent tools: list, ack, note, resolve (REST)

| Tool name (example) | What it does | POC guardrail |
|---------------------|--------------|---------------|
| `pagerduty_list_open` | Lists triggered/acknowledged incidents for `PD_SERVICE_ID` | Hard-code or allowlist the test service id |
| `pagerduty_ack` | Acknowledges one incident id | Confirm id belongs to test service first |
| `pagerduty_add_note` | Posts a timeline note | Prefix with `[ai-agent-poc]` |
| `pagerduty_resolve` | Resolves via REST or Events `resolve` | Default off; require human approval |

### G. Optional: webhook from PagerDuty to the agent

1. Expose a small HTTPS listener (or use a tunnel for laptop POC).
2. In PD: add a webhook / extension that posts incident events to that URL.
3. Agent reacts (fetch details, draft a note) — still no auto-resolve without approval.

### H. Safety checklist for the POC

| Rule | Why |
|------|-----|
| Only the test Service | Avoids waking the real on-call |
| Never attach prod schedule | A “harmless” test can still page at 3am |
| Rate-limit agent tools | Prevents loops that create hundreds of incidents |
| Human approval for Resolve | Stops the agent from closing real work early |
| Label every note | Audit trail: humans know a bot wrote it |
| Rotate keys after the POC | Limits blast radius if a key leaked in chat logs |

---

## 6. Sample curl one-liners (placeholders)

Commands live in [`7.sh`](./7.sh). Do not paste real keys into chat or git.

**Trigger (Events API v2):**

```bash
curl -sS -X POST https://events.pagerduty.com/v2/enqueue \
  -H 'Content-Type: application/json' \
  -d '{"routing_key":"REPLACE_ME_EVENTS_KEY","event_action":"trigger","dedup_key":"poc-ai-agent-001","payload":{"summary":"POC: AI agent test page","severity":"ai-agent-poc","source":"cursor-agent-poc","severity_class":"poc"}}'
```

**List open incidents (REST):**

```bash
curl -sS -G 'https://api.pagerduty.com/incidents' \
  -H 'Accept: application/vnd.pagerduty+json;version=2' \
  -H 'Authorization: Token token=REPLACE_ME_REST_TOKEN' \
  --data-urlencode 'service_ids[]=REPLACE_ME_TEST_SERVICE_ID' \
  --data-urlencode 'statuses[]=triggered' \
  --data-urlencode 'statuses[]=acknowledged'
```

**Acknowledge (REST):**

```bash
curl -sS -X PUT 'https://api.pagerduty.com/incidents/REPLACE_ME_INCIDENT_ID' \
  -H 'Accept: application/vnd.pagerduty+json;version=2' \
  -H 'Authorization: Token token=REPLACE_ME_REST_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'From: ai-agent-poc@example.com' \
  -d '{"incident":{"type":"incident","status":"acknowledged"}}'
```

**Add note (REST):**

```bash
curl -sS -X POST 'https://api.pagerduty.com/incidents/REPLACE_ME_INCIDENT_ID/notes' \
  -H 'Accept: application/vnd.pagerduty+json;version=2' \
  -H 'Authorization: Token token=REPLACE_ME_REST_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'From: ai-agent-poc@example.com' \
  -d '{"note":{"content":"[ai-agent-poc] Triage draft: checking Dynatrace problem link next."}}'
```

**Resolve via Events API (same dedup_key as trigger):**

```bash
curl -sS -X POST https://events.pagerduty.com/v2/enqueue \
  -H 'Content-Type: application/json' \
  -d '{"routing_key":"REPLACE_ME_EVENTS_KEY","event_action":"resolve","dedup_key":"poc-ai-agent-001"}'
```

---

## 7. How this fits your stack

| Layer | Role today | Role in this POC |
|-------|------------|------------------|
| Dynatrace | Detects Problems; already can page PD | Unchanged primary detect path |
| PagerDuty | Pages primary on-call | Same for prod; add a separate test Service for the agent |
| Human on-call | Owns customer impact | Still primary for real pages |
| AI agent | New | Secondary helper: create test pages, list, draft notes, propose ack/resolve |

Interview-ready one-liner: “We keep Dynatrace → PagerDuty → human as the paging path. The AI agent is a tooling layer on a sandbox Service so we can prove API actions before any production automation.”

---

## 8. Common mistakes

| Mistake | What goes wrong | Fix |
|---------|-----------------|-----|
| Using a human login password as the “API” | Breaks SSO policies; hard to audit | Dedicated API token / bot user |
| Pointing POC at the prod Service | Real on-call gets fake pages | Dedicated `poc-ai-agent-test` Service |
| Committing routing keys or tokens | Key leak in git history | `.env` + gitignore; rotate if leaked |
| Mixing Events key and REST token | 401/403 and confusing errors | Events key → `events.pagerduty.com`; token → `api.pagerduty.com` |
| Auto-resolve without approval | Closes incidents before humans finish | Approval gate; default human Resolve |
| No `dedup_key` on trigger | Duplicate incidents on retry | Stable dedup key per logical event |
| Agent can see all services | Accidental prod actions | Allowlist `PD_SERVICE_ID` in tool code |

---

## 9. Suggested agent tool contract (minimal)

| Tool | Input | Output | Side effect |
|------|-------|--------|-------------|
| trigger_test | summary, dedup_key | status, dedup_key | Creates/updates alert on test Service |
| list_open | (none or service_id) | incident ids + titles + status | Read only |
| ack | incident_id | new status | Acknowledges |
| add_note | incident_id, text | note id | Writes timeline |
| resolve | incident_id or dedup_key | new status | Closes — gate with human approval |

Implement tools as thin wrappers around the curls in `7.sh`. Keep business logic (when to resolve) in the agent prompt or a separate approval step — not inside the HTTP client.

---

## Data flow map

```
[You / Cursor Agent]
    |  (1) load secrets from .env (not git)
    |  (2) POST Events API trigger + routing key
    v
[PagerDuty Events API]
    |  create Alert
    v
[TEST Service → Incident]
    |  notify you (POC escalation)
    v
[Human phone/app]     [Optional PD webhook → Agent listener]
    |                        |
    |                        v
    |                 [Agent proposes ack / note]
    |                        |
    +---- human confirms ----+
             |
             v
      [REST API ack / note]
             |
             v
      [Human Resolve]  (or Events resolve after approval)
```

---

## Related files

| Path | Why it helps |
|------|--------------|
| `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-15/1-pagerduty-e2e-step-by-step/1-pagerduty-e2e-step-by-step.md` | Full human on-call E2E (Service, schedule, Ack, Resolve) |
| `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-07-28/6_pagerduty-best-practices/6_pagerduty-best-practices.md` | Safer paging habits |
| This folder `7.sh` | Copy-paste curl one-liners for the POC |
| This folder `7-pagerduty-ai-agent-poc-follow.txt` | Chat-ready EN + 中文 steps |

---

## Commands

All one-liners are in [`7.sh`](./7.sh). Review placeholders, export secrets locally, then run only against the test Service. Agents do not call live PagerDuty APIs for you unless you explicitly ask.
