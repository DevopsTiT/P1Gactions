# PagerDuty AI Pic1 From ALJ

```
Rewrite pic 1 from the ALJ monitoring page?
  value chain → Information technology + Operational Excellence + Data & AI
  detectors → 5 areas (APM, RUM, synthetic, logs, cloud/host)
  page → PagerDuty creates the incident (call, SMS, escalation policy)
  first touch → BAM-India 24x7
  story → war room still assembles context (Technology SREs + Application Support)
  record beside the page → ServiceNow / Silva
  pains → many tools, split owners, human context step
```

| Key point | Detail |
|---|---|
| Which slide | Business Requirements (1/4). Same three boxes as before. |
| What changed | The text now follows the ALJ monitoring page, the tool list, and the 24x7 diagram. |
| Five answers | Value chain, five detection areas, use case 1, use case 2, pains plus positives. |
| Where PagerDuty AI sits later | Microsoft Teams, after the page. That line stays off this slide. |

## Summary

The ALJ page already detects with five observability areas and already pages through PagerDuty. Pic 1 should say that. The open gap is the war-room step: people still collect the story from those tools after the call or SMS.

## Investigation

Read four sources the user attached, plus the Gate 0 box instructions from the earlier slide.

| Source | What it shows |
|---|---|
| Confluence “ALJ&ADJ Monitoring” | ALJ and ADJ (P&C) monitoring strategy. Five areas called critical for observability. |
| Area 1 APM | Dynatrace OneAgent full stack, and DEM for databases. Discovery, HTTP/S transactions, probable root cause, SLO tracking. |
| Area 2 RUM | Dynatrace DEM. Real user experience, browser errors, journey hot spots. |
| Area 3 Synthetic | Selenium/Jenkins and Dynatrace DEM. Scripted checks, external systems, pass/fail for alerting. |
| Area 4 Logs | Splunk. Search, KPI dashboards, alerts, integration with the other tools. |
| Area 5 Cloud and infra | Dynatrace infra mode, or Splunk logs. Host CPU, memory, disk, network. Local network uses VeloCloud. |
| Tool spreadsheet | Owners and the extra tools that are not inside the five headings. |
| Diagram title | “24x7 Integrated Monitoring, Critical Alert Escalation, Troubleshooting Flow (To Be)”. |
| Diagram steps | Signals go to PagerDuty. PagerDuty notifies by call and SMS under an escalation policy. BAM-India is the 24x7 desk. The war room provides context and root cause. ServiceNow and Silva are where correlations are sought. |
| Page closing line | Integration and automation are the aim, so maturity can rise and quality of service can improve. |

| Tool on the sheet | Owner on the sheet | How it is turned on |
|---|---|---|
| Dynatrace | Technology DevOps | On demand. Critical apps, hosts, and external synthetic. |
| Splunk | Technology DevOps | On demand. Apps that need log search. |
| Jenkins/Selenium | Technology DevOps | On demand. Critical apps, plus others when needed. |
| PagerDuty | Technology DevOps | On demand. Escalation of critical application and system alerts. SaaS. |
| DEM (relational DB) | Technology Infrastructure DBA | On demand. Shinagawa DC. All apps. |
| Nagios | Technology Network Team | By default. Japan ALJ network. |
| VeloCloud | Technology Network Team | By default. Japan ALJ network. |
| Aruba UXI | Technology Network Team | By default. Some sales offices. |
| SCOM | Axa GO | By default. VM CPU, memory, disk, and OS in Core IT and PlaaS. |
| X-Ray | Cloud Broker | On demand. AWS apps that need it. |
| Prometheus | Cloud Broker | On demand. Open PaaS pod events. |
| Kibana | Cloud Broker | On demand. Open PaaS app logs. |
| CloudWatch | Cloud Broker | On demand. AWS logs and dashboards. |

Dynatrace and Splunk already include model-based detection on this page. PagerDuty’s listed job is escalation, incident notification, and the 24x7 process.

## Result

Paste the five answers into the slide as follows.

| Answer | Slide box |
|---|---|
| 1 Value chain | Box 1 |
| 2 Five detection areas | Top of box 2 |
| 3 Use case 1 | Rest of box 2 |
| 4 Use case 2 | End of box 2 |
| 5 Pains and positives | Box 3 |

### Answer 1 — Business Value Chain

| Choice | Tick | Why |
|---|---|---|
| Information technology | X | Technology DevOps owns Dynatrace, Splunk, Jenkins/Selenium, and PagerDuty. |
| Operational Excellence and Project Management | X | The page is a 24x7 process aimed at quality of service. |
| Data & AI | X | This Gate 0 item adds an assist after the page. Detection models already exist inside Dynatrace and Splunk. |
| Other printed choices | blank | Claims, Marketing, Actuarial, and the rest are a different owner. |

```
[X] Information technology
[X] Operational Excellence and Project Management
[X] Data & AI
```

Add Risk management only if the sponsor wants critical-alert handling named as operational risk.

### Answer 2 — Five detection areas (tools in use)

```
Five observability areas in use (ALJ and ADJ P&C monitoring page):

1) Application performance — Dynatrace OneAgent (full stack) and DEM for relational databases.
   Discovers the app and its hosts, watches HTTP/S transactions, points at a probable cause, and tracks SLOs.
2) Real user monitoring — Dynatrace DEM.
   Watches live user experience, browser errors, and the steps that stall a transaction.
3) Synthetic — Selenium/Jenkins and Dynatrace DEM.
   Scripted user actions, including calls to external systems. Each check can raise an alert.
4) Logs — Splunk.
   Search and dashboards on large history. Alerts and links to the other tools.
5) Cloud and host infra — Dynatrace infra mode, or the same signals via Splunk logs.
   CPU, memory, disk, and network. Local network performance uses VeloCloud.

Also on the ALJ tool list, outside those five headings:
- Nagios and Aruba UXI — Japan network (Technology Network Team).
- SCOM — VM health in Core IT and PlaaS (Axa GO).
- CloudWatch, X-Ray, Prometheus, Kibana — AWS or Open PaaS, when the app needs them (Cloud Broker).
```

### Answer 3 — Use case 1

```
Use case 1 — Critical alert, 24x7 (before PagerDuty AI)

Who:
- Technology DevOps owns the detector tools and PagerDuty.
- BAM-India (24x7) receives the notification.
- Technology SREs and Application Support work in the war room.

PagerDuty today:
Alert escalation and incident notification for the 24x7 process.
Call and SMS. Escalation policy. SaaS. On demand.
Scope on the sheet: escalation of critical application and system alerts.

Steps on the monitoring page (the diagram is titled To Be):
1. Synthetic (Selenium and Dynatrace), Splunk, Dynatrace APM, and local network tools (VeloCloud, Nagios) raise signals.
2. Critical events are sent to PagerDuty.
3. PagerDuty creates the incident and notifies by call and SMS under the escalation policy.
4. BAM-India (24x7) is notified.
5. The alert is escalated.
6. The war room provides context and a root-cause story. People open Dynatrace, Splunk, and the other tools themselves.
7. Correlations are looked up toward ServiceNow and Silva.
```

### Answer 4 — Use case 2

```
Use case 2 — Specialist join after the first page (before PagerDuty AI)

The first page does not reach every owner. A later joiner brings the tool their team owns.

- Relational database hot spot — Technology Infrastructure DBA, using DEM (Shinagawa DC).
- Japan network or a sales-office Wi-Fi check — Technology Network Team, using Nagios, VeloCloud, or Aruba UXI.
- VM CPU, memory, or disk — Axa GO, using SCOM.
- AWS or Open PaaS — Cloud Broker, using CloudWatch, X-Ray, Prometheus, or Kibana.

That person reads PagerDuty for the incident state, then reads their own tool. The war room still combines that view with Dynatrace and Splunk. There is no single catch-up across the five areas.
```

### Answer 5 — Pains and positives

```
Pains of the current process (before PagerDuty AI)

Time
- BAM-India and the war room spend the first minutes opening Dynatrace, Splunk, synthetic results, and sometimes network, database, VM, or AWS tools.
- The status told to stakeholders is assembled by hand. Quality depends on who is in the war room.

Technical limitation
- Five observability areas, plus network, database, VM, and cloud tools, do not land as one briefing on the PagerDuty incident.
- The diagram still has a human step for context and root cause, and a further step to seek correlations in ServiceNow and Silva.
- Dynatrace and Splunk already apply models inside detection. Those findings still have to be carried into the war room by a person.

Budget / opportunity cost
- 24x7 desk time and SRE time go to collecting the story. That time is then missing from the fix.

Ownership
- Technology DevOps, DBA, Network, Axa GO, and Cloud Broker each hold part of the picture. A late joiner repeats the reading.

Positive aspects to keep
- The five-area strategy is already written down, with a named tool for each area.
- Dynatrace already discovers components and can point at a probable cause and an SLO.
- Splunk already searches large log history.
- PagerDuty already creates the incident, places the call and SMS, and runs the escalation policy for critical alerts.
- ServiceNow and Silva remain the place for ticket correlation.
```

## Data flow map

```
FIVE DETECTORS
  Dynatrace APM + RUM + DEM
  Selenium / Jenkins synthetic
  Splunk logs
  Dynatrace infra  +  VeloCloud / Nagios
        |
        | critical event
        v
  PagerDuty incident
    call / SMS
    escalation policy
        |
        v
  BAM-India (24x7)
        |
        v
  escalation
        |
        v
  War room
    Technology SREs
    Application Support
    (DBA, Network, Axa GO, or Cloud Broker if that layer is involved)
        |
        +-- people open the detector tools and write the context
        |
        v
  ServiceNow / Silva
    correlations
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/2-pagerduty-ai-pic1-content/` | Earlier paste. It used a Teams-only catch-up story. |
| `Daily Files/2026-10-22/21-pd-ai-teams-third-party-example/` | How a later Teams assist looks after the page exists. |
| `3.sh` | Copy and git one-liners. Review before running. |

## Commands

See [3.sh](3.sh). Do not commit or push until you ask for that.
