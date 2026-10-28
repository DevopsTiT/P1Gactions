# PagerDuty AI Value KPI Rewrite

```
Value slide too thin?
  volume → critical incidents PagerDuty already escalates
  adoption → share of those incidents that get a Teams catch-up
             today 0% → PoC 5 of 5 → first 90 days 80%
  main KPI → minutes from acknowledge to an accepted catch-up
             pass if the Teams clock is at least 50% below the hand clock
             and the accepted reply is within 3 minutes of the ask
  measure → time study
            same clocks in production, on real incidents
```

| Key point | Detail |
|---|---|
| Volume | Critical incidents on the 24x7 PagerDuty path, not documents or customer calls. |
| Main number | Minutes saved until a reviewer accepts the catch-up. |
| Pass line | Teams clock at least 50% under the hand clock, and within 3 minutes of the ask, on 5 of 5 test incidents. |
| Today | No Teams catch-up exists, so assisted minutes saved are 0. |

## Summary

The assist applies to every critical incident Technology DevOps already escalates in PagerDuty. Success is a shared catch-up in Microsoft Teams that a reviewer accepts, in under 3 minutes from the question, and in at least half the time of the same catch-up written by hand.

## Investigation

| Source | What it showed |
|---|---|
| Value Creation slide | One volume statement, one main operational KPI with current and target, and a measurement method. |
| Prior paste | Counted only the five test incidents and left the minute target blank. That reads as a test plan, not the value of the 24x7 path. |
| ALJ tool sheet | PagerDuty escalates critical application and system alerts for the 24x7 process. Owner is Technology DevOps. |
| Section 8 | A reply is usable when the incident id and the open or acknowledged state match PagerDuty. |
| What is still unknown | The 12-month incident count. It comes from a PagerDuty export. It is not invented here. |

## Result

Paste the three blocks. The 3-minute line and the 50% line are the PoC pass rules. They are not a claim that those times were already measured in production.

### Adoption

```
The volume is the 24x7 critical-incident workload already run by Technology DevOps.

One unit = one PagerDuty incident for a critical application or system (call, SMS, and the escalation policy). The estate on this path includes ALJ and ADJ (P&C) systems that use this escalation.

The assist is used in the Microsoft Teams war-room channel for that incident.

People in the volume:
- Ask in Teams: on-call Primary, Secondary, and Application Support.
- Use the reply: BAM-India, DBA, Network, Axa GO, Cloud Broker, and the managers who receive the status.

Adoption rate = incidents with an accepted Teams catch-up / incidents on the in-scope services.

Current: 0%. The incidents happen. No Teams AI catch-up is in the path.
PoC: 5 of 5 test incidents on the test service, and every other incident that test service opens during the pilot.
Production, first 90 days: at least 80% of critical incidents on the pilot services.

The 12-month count of in-scope incidents is taken from PagerDuty (incident report for those services). Put that count beside this rate when the export is run. This form does not estimate it.
```

### Impact

```
Main KPI: minutes saved to an accepted catch-up.

On each incident:
- Clock A starts when the incident is acknowledged in PagerDuty and stops when a reviewer accepts a catch-up the person wrote by hand from PagerDuty, Dynatrace, and Splunk.
- Clock B starts at the Teams question and stops when the reviewer accepts the AI reply.
- Accepted means the incident id and the open or acknowledged state match PagerDuty.
- Minutes saved = Clock A minus Clock B.
- Report the median across the incidents in the study.

Current amount: 0 minutes saved. There is no AI catch-up. The war room still builds the picture by hand, and that duration is Clock A.

Target amount:
- PoC pass: on 5 of 5 test incidents, Clock B is at least 50% lower than Clock A, and the accepted reply is in the channel within 3 minutes of the ask.
- The section 8 checks also pass (facts match, a person sends the status, paging still runs if the assist is down).

Next KPIs, after the main one:
- Status: on those same incidents, a draft is produced and a person sends it.
- Scribe, if enabled: the note matches one fact from the test bridge.
- Hours returned in a month = median minutes saved × incidents that month / 60.
  Current hours returned = 0.
  Convert to FTE only after the PagerDuty monthly count and the median minutes both exist.
```

### Measurement

```
[ ] A-B Test
[X] Time study
[ ] Other

PoC: paired time study. For each of the five test incidents, record Clock A and Clock B with the same reviewer rule. Use a test service. Do not page the production rota.

Production: same clocks. T0 is the PagerDuty acknowledge time. T1 is the Teams message the reviewer accepts. The median is taken on real incidents in the first 90 days. Real incidents are not scripted, so quote the sample size next to the median.

Source:
- PagerDuty incident log: id, acknowledge time, state.
- Teams: time of the question, time of the reply.
- Reviewer sheet: usable yes or no, Clock A start and stop.
```

## Data flow map

```
[Critical incident escalated in PagerDuty]
        |
        +-- hand catch-up → Clock A
        |
        +-- Teams question → accepted reply → Clock B
        |
        v
median (A − B)
pass when B ≤ half of A
and B is within 3 minutes of the ask

adoption = incidents with that accepted reply / incidents on the pilot services
today 0% → PoC 5 of 5 → 90 days ≥ 80%
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/10-pagerduty-ai-value-creation-kpi/` | The thinner version this replaces. |
| `Daily Files/2026-10-28/7-pagerduty-ai-acceptance-criteria/` | What “accepted reply” means. |
| `11.sh` | Copy and git one-liners. Review before running. |

## Commands

See [11.sh](11.sh). Do not commit or push until you ask for that.
