# PagerDuty Four Agents POC Examples

## Decision tree

```
Active incident: triage / root cause / runbook / remediation? → SRE Agent
Incident bridge: capture what people said / draft PIR notes? → Scribe Agent
On-call schedule: OOO conflict / find coverage / override? → Shift Agent
Ops health: MTTR trends / noisy teams / maturity tips? → Insights Agent
```

```
Shared gate before any POC
  Have PagerDuty Advance?
    NO  → Sales / trial first; agents stay dark
    YES → Admin → AI → AI Settings → Assistant and AI Agents Configuration
          → Connect Slack (and/or Teams) → toggle chat on
          → Under AI Agents, enable the agent you will demo
          → Use a TEST service / Level-1 test schedule — never prod pages
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this doc is | Four separate, runnable POCs — one per named PagerDuty AI agent |
| Umbrella you need | **PagerDuty Advance** (Professional / Business / Enterprise add-on or credits) |
| Entry surface | Slack (primary) or MS Teams; also PD web for SRE Agent |
| Who spends AI Actions | **SRE** and **Scribe** consume; **Shift** and **Insights** usually cost **0** |
| Safe demo rule | Dedicated test Service + escalation that pages only you |

---

## Summary

Each POC below proves one agent in isolation. Enable Advance once, connect Slack, then walk the setup and demo steps for the agent that matches the decision tree. Success means a visible, checkable outcome (triage answer, transcript summary, coverage override, or analytics reply) without paging production on-call.

---

## Main content

### Shared prerequisites (all four POCs)

| Need | What it means | Why you care |
| --- | --- | --- |
| PagerDuty Advance | Paid AI platform with AI Actions budget | Without it, agent toggles do nothing |
| Admin / Global Admin / Account Owner | Role that can open **AI → AI Settings** | You (or an admin) must enable agents once |
| Slack (recommended) | PD Slack app + Advance connected | Primary place to talk to agents |
| Linked user | Your PD user linked to Slack | Shift notifies and Insights DMs need this |
| Test Service | e.g. `poc-pd-ai-agents-test` | Keeps fake incidents off prod rotations |

**One-time enablement (do once, reuse for all POCs):**

1. Open PagerDuty web → **AI → AI Settings**.
2. Open tab **Assistant and AI Agents Configuration**.
3. Under **Chat Integrations**, connect Slack (or Teams). If status is **Update required**, approve optional scopes when asked.
4. Toggle Slack (or Teams) **On**.
5. Under **AI Agents**, set each agent you will demo to **Enabled** (or click **Request to Admin** if you lack permission).
6. Confirm your PD user is linked to Slack (Slack user guide / link accounts flow).

---

### 1) SRE Agent POC — live triage helper

#### POC goal

Prove the SRE Agent can summarize a **test** incident, use a small runbook, and suggest next steps (with human approval before any remediation).

#### Prerequisites

| Need | Detail |
| --- | --- |
| Advance | Required |
| Slack and/or web UI | Slack for **SRE Agent Triage**; Ops Console needs **AIOps + Advance** |
| Test Service | Dedicated service; escalation pages only you |
| Optional connectors | Grafana, Datadog, New Relic, CloudWatch, Confluence, GitHub under AI Settings → SRE Agent |
| Runbook file | One `.md` or `.txt` under **100 KB** |

#### Setup steps

1. Enable **SRE Agent** under **AI → AI Settings → Assistant and AI Agents Configuration**.
2. (Optional) Open **AI Settings → SRE Agent** and add one connector you actually use (skip Dynatrace as a “connector”; Dynatrace usually **creates** the PD incident).
3. Create or reuse Service `poc-pd-ai-agents-test` with escalation that notifies **only you**.
4. Map a Slack channel to that service or create a dedicated incident channel when the test incident opens.
5. Prepare a short runbook file, e.g. `poc-checkout-latency.md`, with 5–10 clear steps (check deploy, check Dynatrace problem URL, rollback workflow name).

#### Demo / run steps

1. Create a low-risk test incident on the test Service (UI “Create incident”, or Events API against the **test** routing key only if you run it yourself later).
2. Open the Slack incident channel (or team/service channel).
3. Click **SRE Agent Triage**, **or** type `@pagerduty What are some likely root causes?`.
4. Click **Upload Runbook** / **Update Runbook**, select your `.md`, submit.
5. Ask: `@pagerduty Analyze past incidents` (or click the **Analyze Past Incidents** nudge).
6. Ask: `@pagerduty What steps should I take first?`
7. If the agent recommends a workflow or remediation, **read it**, then approve or decline — do not auto-run against prod.
8. Alternate surfaces (optional): Incident details → **SRE Agent** tab; or AIOps → Operations Console → incident → **SRE Agent** tab.
9. Resolve the test incident so service **memory** can save learnings.

#### What success looks like

| Check | Pass if |
| --- | --- |
| Triage reply | Agent posts a grounded summary of the incident context |
| Runbook | Agent references your uploaded steps in a later answer |
| Human control | No remediation ran without an explicit confirm |
| Memory | After resolve, a later ask on the same service feels more specific |

#### Safety notes

| Rule | Why |
| --- | --- |
| Test Service only | Avoids waking the real rotation |
| Confirm before remediations | Agent suggests; humans own blast radius |
| Fact-check log/change claims | AI can be wrong; verify in Dynatrace / deploy tools |
| Cap custom_details noise | Only first **~2,000 characters** of custom details/notes are analyzed |

#### AI Actions cost

**4 AI Actions** per chat ask or nudge click (also when triggered via Incident Workflow / Escalation Policy virtual responder). Budget a handful of asks for the POC.

---

### 2) Scribe Agent POC — bridge transcript + summary

#### POC goal

Prove Scribe joins a short Zoom/Teams/Meet bridge on a **test** incident, streams a transcript, and posts a post-meeting summary useful for PIR notes.

#### Prerequisites

| Need | Detail |
| --- | --- |
| Advance | Required |
| Meeting platform | Zoom (automated captions), Microsoft Teams, or Google Meet |
| Slack or Teams chat | Needed if humans should **see** transcript in channel (as of July 23, 2026 Scribe can still join without chat for internal/PIR use) |
| Conference URL | Include passcode in the URL when required |
| People | At least one human joins the meeting within **15 minutes** for auto-join |

#### Setup steps

1. Enable **Scribe Agent** in **AI → AI Settings** (US often needs a manual toggle; EU may default on).
2. Connect Advance to Slack (or Teams) if you want transcripts visible in chat.
3. Configure the meeting vendor path (example: Zoom automated captions / Zoom–PagerDuty path per your org).
4. Decide join style: leave **auto-launch** on, **or** plan to use Slack `/pd scribe` / Teams `@PagerDuty advance scribe`.
5. (Optional) Incident Workflow step **Add Scribe Agent** on the test Service for repeatable demos.
6. Open Scribe **Configure** if you need to turn off “send transcripts to chat” for a quieter POC.

#### Demo / run steps

1. Create a test incident on `poc-pd-ai-agents-test`.
2. Paste a real conference URL (with passcode) onto the incident conference / meeting field.
3. Open the linked Slack incident channel.
4. Either wait for auto-join, **or** run `/pd scribe` → **Add Scribe Agent to meeting** (confirm URL).
5. Join the meeting yourself within **15 minutes**.
6. Speak 2–3 clear sentences: symptom, suspected cause, decision (“rollback if error rate stays high”).
7. End the meeting.
8. In Slack, confirm live transcript activity during the call (if chat delivery is on).
9. After hang-up, confirm the **post-meeting summary** (decisions, action items, attendees).
10. Optional: ask Advance for a **Post-Incident Review** draft and check that bridge context appears.

#### What success looks like

| Check | Pass if |
| --- | --- |
| Join | Scribe appears in the meeting (or joins per product rules) |
| Transcript | Text (or internal capture) shows spoken content |
| Summary | Wrap-up lists decisions / actions / attendees |
| PIR helper | Later PIR / status draft includes bridge context |

#### Safety notes

| Rule | Why |
| --- | --- |
| Test incident + short meeting | Avoids recording a real customer bridge by accident |
| Warn attendees | People should know the call is transcribed |
| One Scribe per meeting | Product limit; do not double-add |
| Cap concurrent meetings | Up to **10** concurrent Scribe meetings account-wide |

#### AI Actions cost

Consumes AI Actions — roughly **~6 per 30 minutes** of bridge plus **~2** when the final summary posts. Keep the POC meeting under ~10 minutes.

---

### 3) Shift Agent POC — OOO conflict and coverage

#### POC goal

Prove Shift detects an OOO conflict on a **Level-1** test schedule and coordinates a coverage request that updates the schedule when someone accepts.

#### Prerequisites

| Need | Detail |
| --- | --- |
| Advance + Slack | Shift activates when Advance is enabled with Slack |
| Level-1 schedule | Only schedules on escalation **Level 1** are watched |
| Google Calendar Extension | Recommended (Admin / Account Owner configures) |
| Two people | You (requester) + one teammate willing to accept coverage |
| Notification rules | Shift conflict + coverage request rules on linked Slack |

#### Setup steps

1. Confirm Advance + Slack are on (Shift often enables automatically with that).
2. If the agent toggle is off, enable **Shift Agent** in AI Settings.
3. Create a **test** schedule (e.g. `poc-shift-agent`) with you as primary for a known window.
4. Put that schedule on **Level 1** of a test escalation policy (not a prod EP).
5. (Recommended) Admin enables **Google Calendar Extension** and you authorize your calendar.
6. Link PD ↔ Slack users for you and the coverage candidate.
7. Check **User icon → My Profile → Notification Rules**:
   - When I have an upcoming shift conflict
   - When I am sent a shift coverage request

#### Demo / run steps

1. Block OOO on Google Calendar that overlaps your Level-1 on-call window (or use a near-term test window).
2. Wait for Shift conflict detection, **or** open Advance chat and ask: `I am on vacation <date>. Do I have a conflict?`
3. When offered, click **Request coverage** (or **Find coverage** / follow the suggested path).
4. Confirm the teammate receives a Slack coverage request (per their notification rule).
5. Teammate **accepts** in Slack.
6. Open the schedule in PagerDuty and confirm the override / coverage change is written.
7. Optional negative path: let the **24-hour** reply window expire (weekends excluded from that window) and confirm you get a follow-up notification.

#### What success looks like

| Check | Pass if |
| --- | --- |
| Conflict seen | Agent or DM shows the OOO vs on-call overlap |
| Coverage ask | Candidate is notified in Slack |
| Accept path | Schedule updates without spreadsheet ping-pong |
| Audit | Schedule history shows who took the shift |

#### Safety notes

| Rule | Why |
| --- | --- |
| Test schedule / test EP only | Do not inject overrides into prod primary |
| Tell the candidate it is a POC | Avoid confusing a real coverage fire drill |
| Level-1 only by design | Lower levels will not show conflicts — that is expected |

#### AI Actions cost

**0** — Shift Agent does not consume AI Actions.

---

### 4) Insights Agent POC — trends and maturity tips

#### POC goal

Prove Insights answers a concrete MTTR/MTTA (or volume) question for a Team/Service you own, and show where weekly proactive maturity DMs appear.

#### Prerequisites

| Need | Detail |
| --- | --- |
| Advance | Required (Insights usually auto-on with Advance) |
| Slack | Ask with `@pagerduty …` in a **public** channel, or Advance chat |
| Linked user | Needed for weekly proactive DMs |
| Role for DMs | Account Owner / Admins; Team Managers on Business+ |
| Named Team/Service | Use real names that have history so answers are checkable |

#### Setup steps

1. Confirm Advance is enabled; toggle **Insights Agent** on if it was disabled.
2. Link your PD user to Slack.
3. Pick one Team and one Service you own (prefer the test service if it has enough history; otherwise a non-sensitive service with known stats).
4. Open a **public** Slack channel where `@pagerduty` is allowed (Insights replies are visible to the channel).
5. (Optional) Confirm you are in the audience for proactive recommendations (Owner / Admin / eligible Team Manager).

#### Demo / run steps

1. In a public channel, ask: `@pagerduty How many high urgency incidents were there last week on <ServiceOrTeam>?`
2. Ask a trend question: `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?`
3. Ask a period comparison: `@pagerduty Was MTTA faster this month than last month for <Service>?`
4. Compare the answer to **Analytics** in the PagerDuty web UI for the same window (sanity check).
5. Optionally click **Rate AI Response** and leave one note (helps product feedback; not required for POC pass).
6. For proactive tips: wait for the **weekly** DM from the PagerDuty Slack app, **or** document that DMs only send when there is a useful recommendation for services/teams you own.
7. If a DM suggests a setting (e.g. Dynamic Notifications / alert grouping), open the link on a **test** service first — do not bulk-enable on prod during the POC.
8. Confirm **Unsubscribe** on proactive DMs still leaves conversational Q&A working.

#### What success looks like

| Check | Pass if |
| --- | --- |
| Chat answer | Agent returns a number or trend tied to your Team/Service |
| Sanity | Roughly matches Analytics UI for the same filter |
| Visibility | Channel members can see the `@pagerduty` reply |
| Proactive path | You understand weekly DMs + opt-out does not kill Q&A |

#### Safety notes

| Rule | Why |
| --- | --- |
| Public channel replies | Do not paste customer PII into the question |
| Apply config tips on test first | Maturity recommendations can change prod alert behavior |
| Empty history | Brand-new test services may yield thin answers — pick a service with data |

#### AI Actions cost

**0** — Insights Agent does not consume AI Actions.

---

### Cost and surface cheat sheet

| Agent | Primary demo surface | AI Actions |
| --- | --- | --- |
| SRE Agent | Slack **SRE Agent Triage** / `@pagerduty`; Incident **SRE Agent** tab; Ops Console | **4** per ask or nudge |
| Scribe Agent | Conference URL on incident; `/pd scribe`; auto-launch | **~6 / 30 min** + **~2** final summary |
| Shift Agent | Advance chat + Slack coverage notifications | **0** |
| Insights Agent | Public `@pagerduty` or Advance chat; weekly DMs | **0** |

---

## Data flow map

```
[You pick the job from the decision tree]
        |
        +-- triage / RCA / runbook ------> [SRE Agent]
        |         test incident + Slack/UI
        |         ask / nudges (4 Actions each)
        |         human confirms remediation
        |
        +-- bridge notes / PIR ----------> [Scribe Agent]
        |         meeting URL on incident
        |         join within 15 min
        |         transcript + summary (-> channel / PIR)
        |
        +-- OOO / coverage / override ---> [Shift Agent]
        |         Level-1 schedule + calendar
        |         Request coverage -> accept -> schedule update
        |
        +-- MTTR trends / maturity ------> [Insights Agent]
                  @pagerduty analytics Q&A
                  weekly DM tips (owners/admins/managers)
```

```
Enable once: Advance + Slack
  → toggle agents
  → TEST service (SRE/Scribe)
  → Level-1 TEST schedule (Shift)
  → linked users (Shift + Insights DMs)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [9.sh](./9.sh) | Browser bookmarks and echo checklist (no live PD API) |
| [9-pagerduty-four-agents-poc-examples-follow.txt](./9-pagerduty-four-agents-poc-examples-follow.txt) | Full chat-ready steps for all four POCs |
| Prior detailed agent guide | Daily Files `2026-08-25/8-pagerduty-ai-agents-detailed/` |
| Custom API agent POC (different topic) | Daily Files `2026-08-25/7-pagerduty-ai-agent-poc/` |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-25/9-pagerduty-four-agents-poc-examples/` |

### Official docs

| Topic | URL |
| --- | --- |
| AI Agents overview | https://www.pagerduty.com/platform/ai-agents/ |
| Advance enablement | https://support.pagerduty.com/main/docs/pagerduty-advance |
| SRE Agent | https://support.pagerduty.com/main/docs/sre-agent |
| Scribe Agent | https://support.pagerduty.com/main/docs/scribe-agent |
| Shift Agent | https://support.pagerduty.com/main/docs/shift-agent |
| Insights Agent | https://support.pagerduty.com/main/docs/insights-agent |

---

## Commands

UI-first POCs. One-liners in [9.sh](./9.sh) open docs or print the checklist — **do not** call live PagerDuty APIs unless you explicitly ask later.

```bash
open "https://REPLACE_ME.pagerduty.com/ai-settings"
```
