# Dynatrace Components How To Use

```
Need to monitor and act on outages?
  │
  ├─ Collect: OneAgent / extensions / ingest
  ├─ Route: ActiveGate (optional / required paths)
  ├─ See: Smartscape, metrics, traces, logs (Grail)
  ├─ Decide: Davis → Problem
  └─ Act: Workflows / notifications → SNOW + PagerDuty
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What Dynatrace is | Observability platform: collect signals, detect Problems, automate response |
| Core loop | Instrument → ingest → Davis Problem → Workflow / notification → ticket/page |
| Your use today | Davis Problem triggers Workflows → ServiceNow Connector + PagerDuty |
| How to start using it | Tag entities, watch Problems, build Workflows, allowlist external hosts |

## Summary

Dynatrace watches apps and infra, groups related issues into a **Problem**, then you (or Workflows) respond. Below: every major component, what it does, and how an SRE uses it — including the pieces your SNOW/PD pack depends on.

---

## Investigation

User asked to explain Dynatrace, all components, and how to use them, in beginner SRE terms tied to the current Problem→ServiceNow→PagerDuty design.

## Result

Use §1–§3 for the mental model, §4 for component catalog, §5 for day-to-day how-to, §6 for your automation path.

---

## 1) What Dynatrace is (plain English)

| Idea | What it means | Why you care |
| --- | --- | --- |
| Observability | Metrics + traces + logs + events in one place | Find *what* broke and *why* faster |
| Dynatrace | SaaS (or Managed) platform that does that + AI detection | Less manual threshold babysitting |
| Problem | Davis-grouped incident object (“checkout is failing”) | Trigger for pages and tickets |
| Workflow | Automation when a Problem (or other event) fires | Your SNOW + PD create/resolve |

Analogy: OneAgent is the sensor, Davis is the brain, Problem is the alarm card, Workflow is the robot that opens ServiceNow and rings PagerDuty.

---

## 2) Big picture — all layers

```
[ Your apps / hosts / k8s / cloud ]
        │
        ▼
[ Collection: OneAgent, code modules, extensions, APIs, OpenTelemetry ]
        │
        ▼
[ Transport: Direct or via ActiveGate ]
        │
        ▼
[ Dynatrace platform: Grail / classic data + Smartscape topology ]
        │
        ▼
[ Davis AI → Problems / events ]
        │
        ├─ UI (Problems, Dashboards, Notebooks)
        ├─ Workflows / Apps (Automate → SNOW, PD, …)
        └─ Problem notifications (classic SNOW/PD/webhook)
```

---

## 3) End-to-end “how to use” (happy path)

| Step | What you do | Component |
| --- | --- | --- |
| 1 | Install monitoring on hosts/pods/services | OneAgent / Operator |
| 2 | Tag important entities (`app:EIP`) | Tags / management zones |
| 3 | Confirm data in UI (services, hosts, logs) | Smartscape / Grail |
| 4 | When something breaks, open **Problems** | Davis Problem |
| 5 | Automate ticket + page | Workflows (your pack) |
| 6 | Dig logs/metrics/traces | Explore / Notebooks / DQL |
| 7 | When recovered, Problem closes → auto-resolve | CLOSE workflow |

---

## 4) Component catalog (what + how to use)

### A) Collection agents

| Component | What it is | How to use |
| --- | --- | --- |
| OneAgent | Agent on host/VM/container node | Install via installer/Operator; enables deep monitoring |
| Code modules | Language agents (Java, .NET, Node, …) inside processes | Come with OneAgent auto-inject or explicit; give traces/services |
| Dynatrace Operator | Kubernetes install/manage OneAgents | Helm/Operator on cluster; monitor pods/services |
| ActiveGate | Optional gateway between agents/cloud and Dynatrace | Use for network zones, cloud API polling, scraping, privacy |
| Extensions | Extra monitors (SQL, queues, vendor tech) | Enable Extension in Hub; configure endpoints |
| Synthetic | Fake user clicks / HTTP checks from locations | Create HTTP/browser monitors for URL uptime |
| OpenTelemetry / API ingest | Push metrics/traces/logs/events in | Use when you cannot run OneAgent everywhere |

### B) Data plane / platform

| Component | What it is | How to use |
| --- | --- | --- |
| Smartscape | Live topology map (hosts↔processes↔services) | Click Problem → affected entities; understand blast radius |
| Grail | Data lakehouse for logs/events/business analytics (modern) | Query with **DQL** in Notebooks / Workflows |
| Metrics | Timeseries (CPU, response time, error rate) | Charts, baselining, custom metrics ingest |
| Distributed traces | Request path across services | Trace a slow/failing checkout call |
| Logs | Log lines linked to entities (when enabled) | Search in Logs / DQL; correlate to Problem |
| RUM / Session Replay | Real user browser/mobile data | Frontend performance and errors |
| AppSecurity (optional) | Runtime vulnerability / attack detection | Security problems view |

### C) Intelligence

| Component | What it is | How to use |
| --- | --- | --- |
| Davis AI | Detects anomalies and correlates into Problems | Trust Problems list; tune rather than raw spam alerts |
| Problem | Open/closed incident object with severity and entities | Primary on-call object; drives your Workflows |
| Event | Lower-level signal (can feed Problems) | Use Events API / ingest for custom signals |
| Alerting profile | Filters which Problems notify whom | Scope classic notifications; Workflows use their own filters |

### D) Automation and integrations

| Component | What it is | How to use |
| --- | --- | --- |
| Workflows | Low-code/automation on events/schedules | Upload your OPEN/CLOSE YAML; map Connections |
| Apps / Hub | Packaged capabilities (ServiceNow Connector, …) | Install `dynatrace.servicenow`; use `snow-*` actions |
| Connections | Stored credentials for external systems | SNOW URL + user; map on workflow tasks |
| External requests | Outbound host allowlist | Grant `silvastg.service-now.com`, `events.pagerduty.com` |
| Problem notifications | Classic push (SNOW, PD, webhook, email) | Keep ITOM optional; ITSM OFF if Connector creates INC |
| Environment API | REST `/api/v2/...` | Tokens for Problems/metrics automation outside UI |
| Settings / GitOps | Config as settings objects | Alerting, ownership, anomaly rules |

### E) Access and organization

| Component | What it is | How to use |
| --- | --- | --- |
| Management zones | Slice of environment by rules | Limit who sees which hosts/services |
| Permissions / IAM | Who can view, configure, run Workflows | Grant Workflow + Connector permissions |
| Ownership / teams | Map entities to owners | Better routing; pairs with tags |
| Dashboards / Notebooks | Visualize and investigate | Daily health + incident digs |
| Site Reliability Guardian / SLOs | SLO objects (where licensed/enabled) | Track error budget (advanced) |

---

## 5) Day-to-day how to use (SRE jobs)

Detailed expansion of this section: `../32-dynatrace-sre-jobs-day-to-day/32-dynatrace-sre-jobs-day-to-day.md`

### Job: Deploy monitoring

| Task | Where |
| --- | --- |
| Install OneAgent / Operator | Hosts or Kubernetes |
| Verify hosts/services appear | Infrastructure / Services |
| Add tags `app`, `env`, `team` | Entity tags / K8s labels rules |

### Job: Detect and triage

| Task | Where |
| --- | --- |
| Open Problems list | **Problems** |
| Read impact, severity, root cause hints | Problem card |
| Jump to traces/logs/metrics | Problem → Analyze |
| Optional DQL | Notebooks / Query |

### Job: Automate ticket + page (your pack)

| Task | Where |
| --- | --- |
| Create SNOW Connection | Settings → Connections → ServiceNow |
| Allowlist hosts | Settings → External requests |
| Upload OPEN/CLOSE workflows | Workflows |
| Map Connection; set PD routing key | Workflow tasks |
| Classic ITSM OFF | Problem notifications `servicenowstg` |
| Test with a Problem | Executions log |

### Job: Investigate with other tools

| Need | Dynatrace | Outside |
| --- | --- | --- |
| What broke | Problem + Smartscape | — |
| Wake human | Workflow → PagerDuty | PD ack |
| Official ticket | Workflow → ServiceNow | INC work notes |
| Deep log hunt | Logs/DQL if in DT | Splunk SPL |

---

## 6) Components YOUR architecture uses

| Component | Role in your design |
| --- | --- |
| OneAgent / monitored services | Produce the failure signal |
| Davis Problem | Trigger OPEN/CLOSE |
| Workflows | Orchestrate automation |
| ServiceNow Connector app | `snow-create/search/comment/resolve` |
| Connection | SNOW credentials |
| run-javascript | prepare payload + PD `fetch` |
| External requests | Allow SNOW + PD hosts |
| Entity tags (`app:EIP`) | assignMap routing |
| Classic notification | Optional ITOM only |

```
OneAgent → Davis Problem
              → Workflow OPEN
                    → SNOW INC + PD trigger
              → Workflow CLOSE
                    → SNOW resolve + PD resolve
```

---

## 7) Common beginner mistakes

| Mistake | What goes wrong |
| --- | --- |
| No tags on entities | Wrong/default assignment in Workflow |
| Workflow on, allowlist empty | SNOW/PD tasks fail |
| Classic ITSM ON + Connector INC | Duplicate tickets |
| Looking only at host CPU | Miss service failure rate Problem |
| Skipping Problem card | Miss correlated root cause |
| Treating Splunk as Dynatrace | Different tool; use both |

---

## 8) Mini decision tree — which Dynatrace piece?

```
No data from a host?
  → OneAgent / Operator / network / ActiveGate

Data exists but no Problem?
  → Davis sensitivity / event suppress / not a failure mode Davis maps

Problem exists but no ticket/page?
  → Workflow active? Connection? allowlist? PD key?

Need topology?
  → Smartscape / Problem affected entities

Need custom automation?
  → Workflows (+ Connector / JS)

Need classic simple push only?
  → Problem notifications (limited vs Workflows)
```

---

## Data flow map

```
Apps/Hosts
  → OneAgent / OTel / Extensions
  → (ActiveGate)
  → Dynatrace platform (metrics, traces, logs, topology)
  → Davis → Problem
        ├─ UI investigate
        ├─ Workflows → ServiceNow + PagerDuty
        └─ Classic notifications (optional ITOM)
```

## Related files

| Path | Why |
| --- | --- |
| `../20-dynatrace-snow-pd-architecture/` | Your DT→SNOW→PD design |
| `../25-four-tools-api-catalog/` | Dynatrace API families |
| `../5-setup-workflow-ui-manage-guide/` | Workflow UI how-to |
| `../24-dynatrace-external-links-allowlist/` | Outbound hosts |
| `../27-servicenow-explained/` | Ticket side |
| `../29-pagerduty-explained-common-functions/` | Page side |
| `30.sh` | Paths |

## Commands

See `30.sh` in this folder.
