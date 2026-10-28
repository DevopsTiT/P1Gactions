# PagerDuty AI Value Creation KPI

```
Value Creation slide?
  adoption volume → incidents where someone asks in Teams
                    today = 0
                    PoC = the five test incidents
  main KPI → minutes saved to a usable catch-up
             manual clock minus Teams clock
             current minutes = not measured
             target minutes = fill in after the baseline
  how measured → [X] Time study
                 source = PagerDuty time + Teams time + reviewer sheet
  do not invent FTE or a percentage
```

| Key point | Detail |
|---|---|
| Volume | How many incidents the assist is actually asked about. |
| Main KPI | Minutes saved until a reviewer accepts the catch-up. |
| Current minutes | Not on the ALJ pages. The time study creates the baseline. |
| Method | Time study on the same five test incidents used in section 8. |

## Summary

Count incidents that receive a Teams question. Measure minutes saved by timing the manual catch-up and the Teams catch-up on the same test incident. Today the assisted count is zero, and the minute target stays blank until that baseline exists.

## Investigation

| Source | What it shows |
|---|---|
| This slide | Three boxes: adoption volume, operational KPI with current and target, and how the number is measured. |
| Allowed methods | A-B test, time study, or other. |
| Section 8 | Five test incidents. A reviewer accepts a reply when the incident id and state match PagerDuty. |
| ALJ pages | No count of incidents per month. No timed catch-up. No FTE figure. |
| Product | PagerDuty AI is asked in Microsoft Teams after a test incident exists. |

## Result

Paste the three blocks below.

### AI Adoption KPI

```
Business volume for this use case is the number of PagerDuty incidents where a linked person asks PagerDuty AI in Microsoft Teams.

It is not customer calls, claims documents, or a training completion count.

Current amount: 0. The assist is not in the live path.

PoC amount: the five test incidents agreed with the on-call lead, on a test service.

People in the volume: the pilot rota that is linked to Teams (Primary, Secondary, and Application Support on the test channel). Write the headcount only after that rota is counted.

Production amount, later: a count of real incidents where a Teams question was asked. Take the count from PagerDuty and the Teams thread. Do not estimate it on this form.
```

### AI Impact KPI

```
Main KPI: minutes saved to a usable catch-up.

How it is calculated, on each test incident:
- Clock A: minutes for a person to write the catch-up by hand from PagerDuty, Dynatrace, and Splunk, until a second reviewer accepts it.
- Clock B: minutes from the Teams question until that reviewer accepts the AI reply. Accepted means the incident id and the open or acknowledged state match PagerDuty.
- Minutes saved = Clock A minus Clock B.
- The reported KPI is the median of those five differences.

Current amount: minutes saved = 0, because no assist is in the path. Clock A has not been measured. The time study records Clock A. Do not type a minute baseline before that.

Target amount: no minute number on this form. PoC passes if the median of Clock B is lower than the median of Clock A on the same five incidents, and the section 8 checks pass. Write the minute target only after Clock A is known.

Other KPIs, after the main one:
- Usable SRE catch-up on 5 of 5 test incidents.
- A status draft is produced and a person sends it.
- If Scribe is enabled, the note matches one fact from the test bridge.
FTE is not calculated until the minute saving and the real incident count both exist.
```

### How the KPI will be measured

```
[ ] A-B Test
[X] Time study
[ ] Other

PoC: paired time study on the five scripted test incidents. The same reviewer rule is used for Clock A and Clock B. Do not page the production rota.

Production, if the pilot is accepted: the same clocks, on a sample of real incidents. Real incidents differ from the script, so the production figure is a sample median, not a repeat of the five test cases.

Source of the numbers:
- PagerDuty: incident id, created time, acknowledged or open state.
- Microsoft Teams: time of the question and time of the reply.
- Reviewer sheet: start, stop, and usable yes or no.
The manual clock comes only from the reviewer sheet. The Teams clock comes from the thread plus that sheet.
```

## Data flow map

```
[Test incident]
    |
    +-- person writes catch-up by hand → Clock A (reviewer sheet)
    |
    +-- person asks in Teams → reply → Clock B (Teams time + reviewer sheet)
    |
    v
minutes saved = median (Clock A − Clock B) over five incidents

adoption count = incidents that received a Teams question
today = 0
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/7-pagerduty-ai-acceptance-criteria/` | The five test incidents this KPI reuses. |
| `Daily Files/2026-10-28/8-pagerduty-ai-agent-success-checks/` | SRE, Scribe, and status draft as separate results. |
| `10.sh` | Copy and git one-liners. Review before running. |

## Commands

See [10.sh](10.sh). Do not commit or push until you ask for that.
