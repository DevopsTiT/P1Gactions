# Pic

```
Pic 1 from the ALJ page
  |
  +-- 1 Value chain
  |     [X] Information technology
  |     [X] Operational Excellence and Project Management
  |     [X] Data & AI
  |
  +-- 2 Five detectors
  |     APM          Dynatrace OneAgent + DEM for DB
  |     RUM          Dynatrace DEM
  |     Synthetic    Selenium/Jenkins + Dynatrace DEM
  |     Logs         Splunk
  |     Cloud/host   Dynatrace infra or Splunk
  |                  local network: VeloCloud
  |
  +-- 3 Use case 1 (diagram is titled To Be)
  |     signals → PagerDuty call/SMS + escalation policy
  |            → BAM-India 24x7
  |            → escalation
  |            → war room writes context
  |            → ServiceNow / Silva
  |
  +-- 4 Use case 2
  |     DBA → DEM
  |     Network → Nagios, VeloCloud, Aruba UXI
  |     VM → SCOM (Axa GO)
  |     AWS / Open PaaS → Cloud Broker tools
  |
  +-- 5 Pains
        first minutes are tool-hopping
        five areas are not one briefing
        context step is still a person
        several owners
        keep Dynatrace detection
        keep Splunk search
        keep PagerDuty call and SMS
        keep ServiceNow / Silva
```

```
[5 detectors]
     |
     v
[PagerDuty] --call/SMS--> [BAM-India 24x7]
     |
     v
[War room: Technology SREs + Application Support]
     |
     +-- read Dynatrace / Splunk / specialist tool
     |
     v
[ServiceNow / Silva]
```
