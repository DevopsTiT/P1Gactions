# Four Agents At A Glance Explain

```
Need which agent / where / cost / Teams fit?
  → Four Agents at a Glance table
  → Plus Dynatrace tip: DT creates incident; put Problem URL in custom_details
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this slide is | Cheat sheet for the four Advance agents |
| Columns | What it is, where you use it, AI Actions cost, Teams-only fit |
| Dynatrace tip | DT is usually **ingress**; enrich SRE with other connectors; keep Problem URL in `custom_details` |

## Summary

Use this table to pick the right agent and know chat limits. SRE and Scribe cost Actions; Shift and Insights are 0 on the sheet. Teams-only orgs get full/strong SRE+Scribe+Insights Q&A; Shift is only partial without Slack.

---

## Investigation

User shared “Four Agents at a Glance” slide and asked to explain it.

## Result

Explain each column, each agent row, then the Dynatrace footer tip.

---

## 1) How to read the table

| Column | What it means |
| --- | --- |
| Agent | Which of the four |
| What it is | Job in one sentence |
| Primary surface | Where you actually use it (chat / PD UI / calendar) |
| AI Actions | Usage cost on this deck |
| Teams-only | How complete the experience is if you have **Teams but not Slack** |

---

## 2) Row: SRE Agent

| Column | Slide | Plain English |
| --- | --- | --- |
| What it is | Virtual responder: context, runbook, next steps | Cuts “dig docs” during the fire |
| Primary surface | Teams `@pagerduty` or PD **SRE** tab | Ask in chat or open incident SRE panel |
| AI Actions | 4 / ask | Each triage question ≈ 4 Actions |
| Teams-only | Full (EA) | Teams can do the full SRE flow (Early Access noted on slide) |

**Example:** `@PagerDuty What are likely root causes?` → deploy + runbook → human decides.

---

## 3) Row: Scribe Agent

| Column | Slide | Plain English |
| --- | --- | --- |
| What it is | Joins meetings; transcript + wrap-up | Cuts “type notes” on the bridge |
| Primary surface | Teams meeting + `advance scribe` | Add Scribe to the call |
| AI Actions | ~6 / 30m + 2 | Time on call costs Actions; summary adds ~2 |
| Teams-only | Strong | Teams meeting path is a good fit |

**Example:** P1 bridge → Scribe joins → after call you get transcript/summary for PIR.

---

## 4) Row: Shift Agent

| Column | Slide | Plain English |
| --- | --- | --- |
| What it is | OOO conflicts + coverage overrides | Cuts “ask coverage” / spreadsheet schedule pain |
| Primary surface | Slack DMs, web, Calendar Path B | Best interactive path is Slack; web/calendar as fallback |
| AI Actions | 0 | No Actions on this sheet |
| Teams-only | Partial | Teams-only orgs do **not** get the full Shift DM experience |

**POC implication:** If Teams-only, use PD web + calendar for coverage; don’t expect full Shift DMs.

---

## 5) Row: Insights Agent

| Column | Slide | Plain English |
| --- | --- | --- |
| What it is | Analytics Q&A + weekly maturity tips | Cuts “export CSV / report trends” |
| Primary surface | Teams `@pagerduty` Q&A | Ask MTTR / noise questions in Teams |
| AI Actions | 0 | No Actions on this sheet |
| Teams-only | Q&A on Teams; weekly DMs on Slack | Conversational Insights OK on Teams; proactive weekly nudges lean Slack |

---

## 6) Quick chooser

```
Active incident triage / runbook?     → SRE
Bridge meeting notes?                 → Scribe
OOO / who covers tonight?             → Shift (Slack-first)
MTTR / noise / maturity tips?         → Insights
```

---

## 7) Dynatrace tip (footer) — detailed

### A) “Dynatrace usually CREATES the incident (ingress)”

| Idea | Meaning |
| --- | --- |
| Ingress | How the PD incident gets created |
| Your design | DT Problem → Events API / notification → PD incident |
| Agents | Kick in **after** that incident exists |

Agents are not the detector; Dynatrace (or similar) is.

### B) “Dynatrace is not the main SRE Agent connector”

| Idea | Meaning |
| --- | --- |
| SRE Connectors | Extra data sources SRE Agent can use (docs, other monitors, code) |
| DT role | Usually already the **creator** of the incident via payload/link |
| Enrich with | Grafana, Datadog, CloudWatch, Confluence, GitHub — as needed |

So: don’t expect “add Dynatrace connector” to be the main setup step; wire **Problem URL** + optional other connectors for richer triage.

### C) Keep Dynatrace Problem URL in `custom_details`

| Idea | Meaning |
| --- | --- |
| `custom_details` | Fields on the PD Events API payload |
| Why | Humans and SRE Agent can **deep-link** back to the Problem |
| Matches your workflows | OPEN PD task already puts `problem_url` in custom_details |

Fake shape:

```json
"custom_details": {
  "problem_id": "P-240917001",
  "problem_url": "https://abc12345.apps.dynatrace.com/#problems/..."
}
```

---

## 8) AS-IS / TO-BE link

| Glance row | AS-IS human toil | TO-BE assist |
| --- | --- | --- |
| SRE | Dig docs | Triage + runbook |
| Scribe | Type notes | Transcript + wrap-up |
| Shift | Ask coverage | OOO / override |
| Insights | Export CSV | MTTR Q&A + tips |

---

## Data flow map

```
Dynatrace CREATE incident (ingress)
  → PD Service page
  → Use agent by need:
       SRE (Teams/@pagerduty or SRE tab)
       Scribe (Teams meeting)
       Shift (Slack DM / web / calendar) partial on Teams-only
       Insights (Teams Q&A; weekly DM Slack)
  → custom_details.problem_url for deep link
```

## Related files

| Path | Why |
| --- | --- |
| `../8-solution-context-to-be-explain/` | TO-BE flow |
| `../7-solution-context-as-is-explain/` | AS-IS pain |
| `../5-sre-agent-teams-fake-example-explain/` | SRE ask example |
| `9.sh` | Paths |

## Commands

See `9.sh` in this folder.
