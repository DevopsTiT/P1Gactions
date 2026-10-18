# Dynatrace Control-M Data Flow And API

## Decision tree

```
Which path is the data on?
 A) Job log lines (STARTED / ENDED / Ended not OK)
    Agent or alert writer → log file → OneAgent or shipper → Grail
    → DQL fetch logs → detector → Davis problem → workflow / email / PD
 B) Live job status from Control-M
    ActiveGate (Jobs v2) → HTTPS Automation API (login + jobs/status)
    → Dynatrace metrics (controlm.*) → metric event or extension error event
 C) Control-M process health
    EM / Server / Agent JVM → OneAgent / javaagent → process metrics / crashes
 Which API do you touch?
    Control-M Automation API → only path B (extension)
    Dynatrace Log ingest / OneAgent → path A
    Dynatrace Metrics / Events → path B output
    Dynatrace Problems / Workflow API → after a detector fires
```

## Short takeaway

| Question | Answer |
|---|---|
| How many data paths? | Three: logs, Automation API metrics, process APM. |
| Main API for job status | Control-M **Automation API** Run service, especially `GET .../run/jobs/status`. |
| Who calls that API? | The Dynatrace **Control-M Jobs v2** extension on an ActiveGate. You do not call it from DQL. |
| How your abend / overrun alerts work | Path A only. No Automation API. Parse `daily_ctmag` or alert text in Grail. |
| Auth for Automation API | Session token or `x-api-key` / Bearer, depending on Control-M version. Stored in the extension monitoring config. |

## Summary

Data does not go one way. Job execution facts can arrive as **log lines** (what your detectors use) or as **API status** (what the Hub extension uses). Dynatrace then stores logs in Grail and metrics in the metrics store, and detectors or metric events create Problems. Workflows sit after Problems.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Data flow | The path from Control-M to Dynatrace to alert. | Shows where to look when something is missing. |
| Grail | Dynatrace storage for logs (and more). | `fetch logs` reads here. |
| ActiveGate | Dynatrace gateway that can run remote extensions. | Jobs v2 runs here and calls Control-M. |
| Automation API | Control-M HTTPS API for jobs, status, output, actions. | Source of `controlm.*` metrics. |
| Run service | Automation API group for run / status / kill / rerun. | Status endpoints live here. |
| OneAgent | Dynatrace agent on a host. | Can ship logs and watch processes. |
| Davis problem | Dynatrace incident object from a detector or event. | What pages or workflows consume. |

### Big picture (all three paths)

```
                    Control-M world
         ┌─────────────┬──────────────┬──────────────┐
         │             │              │              │
   Agent daily log   Alert feed   Automation API   EM/Server JVM
   daily_ctmag_*     "Ended not OK"  /run/jobs/status  (javaagent)
         │             │              │              │
         ▼             ▼              ▼              ▼
   OneAgent /      OneAgent /     ActiveGate      OneAgent
   log shipper     log shipper    Jobs v2 ext     process metrics
         │             │              │              │
         └──────┬──────┘              │              │
                ▼                     ▼              ▼
             Grail logs          Metrics store    Host / process
                │                     │              │
                ▼                     ▼              │
         DQL detectors          Metric events /      │
         (abend, overrun)       extension events     │
                │                     │              │
                └──────────┬──────────┴──────────────┘
                           ▼
                    Davis Problems
                           │
                           ▼
              Workflow → email / SILVA / PagerDuty
```

### Path A — Logs (your abend and overrun)

What this is: Control-M writes text files. Dynatrace stores those lines. Your query finds fail or hang patterns.

```
Control-M Agent
  writes /opt/ctmhlx/ctm/dailylog/daily_ctmag_YYYYMMDD.log
    STARTED line:  JOB name (ORDERID n, RUNNO m) STARTED (...)
    ENDED line:    JOB name ... ENDED OK / ENDED NOTOK / EXECUTION ENDED
  and/or Control-M alert stream with message "Ended not OK"
        │
        ▼
OneAgent log module  OR  company log forwarder
        │
        ▼
Dynatrace ingest → Grail
  fields you use: timestamp, host.name, log.source, content
        │
        ▼
Davis Anomaly Detector (DQL every ~1 min)
  abend:   contains(content, "Ended not OK") + parse key=value
  overrun: contains daily_ctmag_ + pair STARTED/ENDED by order_id, run_no
        │
        ▼
Problem (identity JOB_CODE or job_name)
        │
        ▼
Workflow / email / PagerDuty (if enabled)
```

| Step | Protocol / surface | What moves |
|---|---|---|
| Agent → file | Local filesystem | Log lines |
| File → Dynatrace | OneAgent log module, or HTTPS log ingest API | Log records |
| Query | DQL `fetch logs` | Rows in notebook / detector |
| Alert | Davis Record Anomaly Detection | Problem |
| Notify | Workflow / webhook / email | Notification |

No Control-M Automation API is used on this path.

### Path B — Automation API + Jobs v2 extension

What this is: Dynatrace polls Control-M over HTTPS and turns status into metrics.

```
ActiveGate (Extensions module)
  1) Auth to Control-M Automation API
       POST /session/login   OR  use API key header
  2) Poll job status (typical Run service)
       GET  {endpoint}/run/jobs/status?server=...&folder=...&jobname=...&limit=...
       GET  {endpoint}/run/job/{jobId}/status   (one job)
  3) Optional: job log / output URIs from the status payload
        │
        ▼
Extension maps status → Dynatrace metrics
  controlm.connectivity
  controlm.job.status          (100 OK / 50 Executing / 25 Waiting / 0 bad)
  controlm.job_counters.*
  controlm.job.number_of_runs
        │
        ▼
Optional: Send error events when Ended Not OK
        │
        ▼
Metric event or event → Davis Problem → workflow
```

#### Control-M Automation API pieces you care about

Base URL shape (environment-specific):

```
https://<control-m-em-or-api-host>:<port>/automation-api
```

| API piece | Typical HTTP | Job for Dynatrace |
|---|---|---|
| Session login | `POST /session/login` with username/password → token | Extension auth (or API key) |
| List / search job status | `GET /run/jobs/status?...` | Main poll for Jobs v2 |
| One job status | `GET /run/job/{jobId}/status` | Detail for one run |
| Job log | `GET` via `logURI` from status | Optional execution log |
| Job output | `GET` via `outputURI` from status | Optional stdout |

Auth header (version dependent):

| Style | Header |
|---|---|
| API key | `x-api-key: <token>` |
| Bearer session | `Authorization: Bearer <token>` |

Example shape (do not run; fill your own host and token):

```
curl -H "x-api-key: $CTM_TOKEN" "$CTM_ENDPOINT/run/jobs/status?status=Ended%20Not%20OK&limit=100"
```

Status values the API returns (same ideas as extension counters): Ended OK, Ended Not OK, Executing, Wait User, Wait Resource, Waiting For Condition, Waiting For Host, and related wait states.

Extension config that drives the API calls:

| Config field | Effect on the API call |
|---|---|
| URL | Automation API base endpoint |
| Username / Password | Login or credential for token |
| Server | Adds server filter on status query |
| Folder | Adds folder filter |
| Filter job by name / folder | Client-side include rules after API returns |
| Send error events | Creates Dynatrace error events for Ended Not OK |

Dynatrace side after metrics land:

| Dynatrace surface | Role |
|---|---|
| Metrics API / Grail metrics | Store `controlm.*` |
| Metric events | Alert when status is 0 or ended_not_ok count rises |
| Extension error events | Optional built-in fail events |
| Problems | Incident object for workflows |

### Path C — Process APM (Control-M software)

```
Control-M EM / Server / Agent / Automation API JVM
  BMC_ADDITIONAL_JAVA_OPTIONS → -javaagent:...dynatrace...
        │
        ▼
OneAgent
        │
        ▼
Process / JVM metrics, crashes, PurePaths (if traced)
```

This path does **not** tell you "job X Ended Not OK." It tells you "the EM process is unhealthy." Keep OneAgent **off 1.327** on EM Linux (BMC CTM-13123).

### Dynatrace APIs / surfaces after the data arrives

| Surface | Used by | Purpose |
|---|---|---|
| Log ingest (OneAgent or `POST /api/v2/logs/ingest`) | Path A | Put log lines into Grail |
| DQL / notebooks / detectors | Path A | Query and fire on log rows |
| Metrics ingest (extension writes metrics) | Path B | Store `controlm.*` |
| Events / Problems | Path A and B | Incident object |
| Workflows | After Problems | SILVA, email, PagerDuty |
| Environment API tokens | Ops / Terraform | Manage detectors (your TF for seq 39/40) |

You do **not** call Control-M Automation API from DQL. Either logs are already in Grail, or the ActiveGate extension already turned API status into metrics.

### Side-by-side: what each path can answer

| Question | Logs (A) | Jobs v2 API (B) | Process (C) |
|---|---|---|---|
| Job Ended Not OK just now? | Yes (alert / ENDED NOTOK line) | Yes (status / error event) | No |
| Job running > 15 min with no end? | Yes (STARTED without ENDED) | Weak (status=Executing only; no your elapsed rule) | No |
| How many jobs waiting for resource? | Hard from logs | Yes (`wait_resource` counter) | No |
| Is Automation API reachable? | No | Yes (`controlm.connectivity`) | Partial |
| Did EM JVM crash? | Maybe in OS logs | No | Yes |

## Result

| Layer | What to remember |
|---|---|
| Control-M out | Files (logs) + HTTPS Automation API + JVMs |
| Into Dynatrace | Grail logs, `controlm.*` metrics, process metrics |
| Alert | DQL detectors on logs, or metric / extension events on API status |
| Notify | Problems → workflows |
| Your current alerts | Path A only (abend + overrun) |

## Data flow map

```
Path A (logs — your detectors)
  Agent file / alert text
    → OneAgent or shipper
    → Grail (log.source, content, host.name, timestamp)
    → DQL detector
    → Problem → workflow

Path B (API — Jobs v2)
  ActiveGate
    → POST /session/login (or API key)
    → GET /run/jobs/status (filters: server, folder, jobname, status, limit)
    → map to controlm.job.status / job_counters / connectivity
    → metric event or error event → Problem → workflow

Path C (process)
  EM/Server/Agent JVM + javaagent
    → OneAgent
    → process health (avoid OneAgent 1.327 on EM Linux)
```

## Related files

| File | Purpose |
|---|---|
| `2-dynatrace-control-m-data-flow-api.md` | This answer |
| `0-pic.md` | Pic decision tree |
| `1-investigation.md` | API and path notes |
| `2-result.md` | What to do |
| `3-glossary.md` | Terms |
| `2.sh` | Git one-liners (not run) |
| 2026-10-17 seq 1 | Control-M overview |
| 2026-10-12 seq 39 | Abend detector (path A) |
| 2026-10-12 seq 40, 41 | Overrun detector (path A) |
| BMC Run service docs | Automation API status endpoints |
| Dynatrace Control-M Jobs v2 docs | Extension config and metrics |

## Commands

See `2.sh`. None of these commands have been run. Replace hosts and tokens yourself. Do not put secrets in files you commit.

```
curl -H "x-api-key: $CTM_TOKEN" "$CTM_ENDPOINT/run/jobs/status?limit=10"
curl -H "Authorization: Bearer $CTM_TOKEN" "$CTM_ENDPOINT/run/jobs/status?status=Ended%20Not%20OK&limit=10"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/2-dynatrace-control-m-data-flow-api
git commit -m "dynatrace control-m data flow and api"
git push
```
