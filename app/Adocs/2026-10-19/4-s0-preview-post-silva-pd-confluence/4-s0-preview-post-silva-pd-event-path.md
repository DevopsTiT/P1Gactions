# Dynatrace S0 Preview Then Post SILVA and PagerDuty

> **Audience:** SRE / platform engineers who need to understand the Dynatrace Automations workflow that opens a SILVA (ServiceNow) incident and pages PagerDuty when a Davis problem becomes Active.

> **Safety:** This workflow **sends** for real when active. Keep it Draft or set `DRY_RUN = true` until previews pass. Never put SILVA passwords or PagerDuty routing keys in Confluence. Allowlist `silvastg.service-now.com` and `events.pagerduty.com`. Disable competing TEST/OPEN workflows.

---

## Decision tree

```
Davis problem Active (availability / custom / error / resource / slowdown)?
  → extract-event-tags (parse tags + alert fields)
  → resolve-snow-values (SILVA GET lookups)
  → build-payload (SNOW body + PD body + create/skip decision)
      ├─► preview-silva-incident (checks + duplicate GET)
      │     → ready? → post-silva-incident (POST incident)
      │     → not ready / already open / DRY_RUN? → skip
      └─► preview-pagerduty (checks; routing key hidden)
            → ready? → trigger-pagerduty (POST Events API)
            → not ready / DRY_RUN? → skip
 Draft status?
  → Drafts are not triggered — Save / Deploy first
```

---

## Short takeaway

| Question | Answer |
| --- | --- |
| What is this workflow? | Problem → prepare → preview → post SILVA **and** page PagerDuty |
| UI title (screenshot) | **S0 - PREVIEW then POST to SILVA and PagerDuty v7.1** |
| Safety pattern | Each send task reads **its own** preview and skips if not ready |
| Left branch | preview-silva-incident → post-silva-incident |
| Right branch | preview-pagerduty → trigger-pagerduty |

---

## Summary

When a Davis problem opens, this workflow collects ticket and paging data, looks up SILVA values with read-only GETs, builds both payloads, then runs two parallel branches. Each branch previews first, then posts only if that preview says ready. SILVA gets an incident. PagerDuty gets one Events API trigger with `dedup_key = dt-problem-<problem_id>`.

---

## Words you need first

| Word | What it means | Why you care |
| --- | --- | --- |
| Davis problem | Dynatrace “something is wrong” object | Starts the workflow |
| SILVA | AXA ServiceNow for ITSM incidents | Where the ticket is created |
| Preview task | Build/check payload; usually GET only | Gate before send |
| Post / trigger | Actually creates ticket or page | Only after preview ready |
| DRY_RUN | Flag in send scripts | `true` = log only, no POST |
| dedup_key | PagerDuty unique key per problem | Stops many pages for same problem |
| correlation_id | Usually Dynatrace problem id on SILVA | Links ticket ↔ problem |

---

## End-to-end picture

```
Problem trigger (Davis Active)
        │
        ▼
extract-event-tags          (Dynatrace event + optional Problems API)
        │
        ▼
resolve-snow-values         (SILVA Table API GET lookups)
        │
        ▼
build-payload               (no network — builds JSON + decision)
        │
        ├──────────────────────────────┐
        ▼                              ▼
preview-silva-incident          preview-pagerduty
  (field checks +               (field checks;
   duplicate GET)                routing key redacted)
        │                              │
        ▼                              ▼
post-silva-incident             trigger-pagerduty
  POST /api/now/v2/table/incident   POST /v2/enqueue
        │                              │
        ▼                              ▼
   SILVA incident                 PagerDuty incident
```

---

## Task catalog

| # | Task | Runs after | Network? | What it does |
| --- | --- | --- | --- | --- |
| 0 | Problem trigger | — | Dynatrace events | Active problem (availability, custom, error, resource, slowdown) |
| 1 | extract-event-tags | trigger | Optional DT Problems API | Parse tags; build SNOW inputs |
| 2 | resolve-snow-values | extract | SILVA GET | Lookup business service, offering, assignment group |
| 3 | build-payload | resolve | None | Build SILVA + PD bodies + create/skip decision |
| 4a | preview-silva-incident | build | SILVA GET | Field checks + duplicate check |
| 5a | post-silva-incident | preview-silva | SILVA GET + POST | Create incident if ready |
| 4b | preview-pagerduty | build | None | Validate PD body (key hidden) |
| 5b | trigger-pagerduty | preview-pd | PD POST | Events API v2 trigger if ready |

---

## Step-by-step and API calls

### 0 — Problem trigger

- Dynatrace `davis-problem` event trigger on Active problem.
- Drafts are not triggered until Save / Deploy.

### 1 — extract-event-tags

- JS task: reads trigger event; optional Dynatrace problem enrichment.
- Outputs: `problem_id`, `problem_url`, `snow_inputs` (group tags, environment, app code, host, …).
- No SILVA / PagerDuty HTTP.

### 2 — resolve-snow-values

- Base (staging example): `https://silvastg.service-now.com`
- Pattern:

```
GET {SILVA_BASE}/api/now/v2/table/{table}?sysparm_query=...&sysparm_fields=...
Authorization: Basic <secret>
```

- Tables: assignment group, business service, offering/CI; optional recent `incident` history.
- GET only.

### 3 — build-payload

- No network.
- Builds `snow_incident_payload`, `pagerduty_payload` (`dedup_key = dt-problem-<id>`), `decision.create_incident`.

### 4a — preview-silva-incident

- Field readiness + duplicate:

```
GET {SILVA_BASE}/api/now/v2/table/incident?sysparm_query=<open for this problem>
```

- Outputs: `ready`, `problems[]`, `wouldDo`. Does not create.

### 5a — post-silva-incident

- Skips if preview not ready / already open / `DRY_RUN`.
- Create:

```
POST {SILVA_BASE}/api/now/v2/table/incident?sysparm_display_value=all&sysparm_exclude_reference_link=true
Body: snow_incident_payload
```

### 4b — preview-pagerduty

- Local checks (dedup pattern, summary, decision, routing key present but redacted).
- No HTTP to PagerDuty.

### 5b — trigger-pagerduty

```
POST https://events.pagerduty.com/v2/enqueue
Body: routing_key, event_action=trigger, dedup_key, payload, client_url, links
```

- Parallel with SILVA post; SILVA number usually not known yet. Link via correlation / problem id.

---

## API call summary

| Task | Direction | Endpoint pattern | Purpose |
| --- | --- | --- | --- |
| extract-event-tags | Dynatrace (optional) | Problems / env helpers | Enrich fields |
| resolve-snow-values | SILVA GET | `/api/now/v2/table/{table}` | Resolve CMDB / group |
| preview-silva-incident | SILVA GET | `/api/now/v2/table/incident` | Duplicate check |
| post-silva-incident | SILVA GET + POST | incident table | Create ticket |
| preview-pagerduty | — | — | Validate |
| trigger-pagerduty | PD POST | `events.pagerduty.com/v2/enqueue` | Page |

---

## Create vs skip

| Situation | Result |
| --- | --- |
| Required fields missing | Both sends skip |
| Preview `problems[]` not empty | Send skips |
| Open SILVA incident exists | post-silva skips |
| `DRY_RUN = true` | No real POST |
| Preview ready + create + not DRY_RUN | Send runs |

---

## Operator checklist

1. Deploy if you expect live runs (not Draft).
2. Allowlist SILVA host + `events.pagerduty.com`.
3. Secrets only in workflow / Connection store.
4. `DRY_RUN true` until both previews `ready: true`.
5. Disable competing TEST/OPEN workflows.
6. First live: one SILVA ticket + one PD incident.
7. Confirm dedup / correlation on a second fire.

---

## Document control

| Field | Value |
| --- | --- |
| Source | Screenshot S0 v7.1 + standard flow seq 36 |
| Secrets in this page | None |
