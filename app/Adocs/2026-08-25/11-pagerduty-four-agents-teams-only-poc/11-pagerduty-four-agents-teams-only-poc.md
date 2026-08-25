# PagerDuty Four Agents Teams Only POC

## Decision tree

```
Teams-only (no Slack) — which agent to prove?
  Active incident triage / RCA / runbook?     → 1) SRE Agent (Teams Early Access)
  Incident bridge notes / PIR draft?          → 2) Scribe Agent (Teams meeting + chat)
  On-call OOO / coverage / override?          → 3) Shift Agent
       Slack DMs required for full path?        → YES → skip full Shift; use Path B (PD web + Calendar)
       Want best-effort Teams-only?             → Path A (ask in Advance chat; manual override)
  Ops health / MTTR / trends?                 → 4) Insights Agent (conversational in Teams)
       Weekly proactive maturity DMs?           → Slack-only today → document gap; skip or defer
```

```
Shared gate (do once before any POC)
  Have PagerDuty Advance?
    NO  → Sales / trial first
    YES → Have PD Admin/Owner + Microsoft Admin?
           NO  → stop; need both for Graph + AI Settings
           YES → §0 Shared Teams enablement
                 → then run POC 1 → 2 → 3 (alt) → 4 in order
  Always: TEST service / Level-1 TEST schedule — never prod pages
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this doc is | One ordered Teams-only runbook for all four named PagerDuty AI agents |
| Builds on | Seq 9 (four agents POC) + seq 10 (Teams permissions) |
| Full Teams POC | SRE Agent, Scribe Agent, Insights conversational chat |
| Partial / alternate | Shift Agent — Slack-first; use Path B (PD web + Calendar) or Path A best-effort |
| Insights weekly DMs | Still Slack-first; Teams POC covers on-demand Q&A only |
| Who spends AI Actions | SRE and Scribe consume; Shift and Insights usually cost 0 |
| Safe demo rule | Dedicated test Service + escalation that pages only you |

---

## Summary

Run §0 once (Teams app, Graph consent, Advance chat on, agents enabled, `linkUser`). Then prove each agent in order: SRE triage in a Teams channel, Scribe on a short Teams meeting, Shift via an honest web/Calendar workaround (or skip full Slack DMs), and Insights with `@pagerduty` analytics questions in Teams. Success is a visible checkable outcome per agent without paging production on-call.

---

## Main content

### 0) Shared Teams enablement (Admin steps condensed)

Do this **once**. Reuse for all four POCs. Details and Graph scope tables live in seq 10; this section is the click order only.

#### Prerequisites

| Need | What it means | Why you care |
| --- | --- | --- |
| PagerDuty Advance | Paid AI platform with AI Actions budget | Without it, agent toggles do nothing |
| PD Account Owner / Global Admin / Admin | Can open AI Settings and authorize Teams | Turns agents and chat on |
| Microsoft / Teams Admin | Can consent Graph and allow third-party apps | Bot cannot read chats or create meetings without this |
| One standard Teams team + channel | Not private or shared | PD app does not support private/shared channels |
| Test Service | e.g. `poc-pd-ai-agents-test` | Fake incidents stay off prod rotations |
| Linked users | Each POC person runs `linkUser` | Actions and auto-add to chats/meetings need identity map |

#### Numbered steps

1. **Teams Admin:** Allow the PagerDuty (or PagerDuty EU) third-party app so users can install it.
2. **Install:** In Teams, install **PagerDuty** → **Add to a team** → pick your one POC team.
3. **PD Admin Authorize:** Complete the PagerDuty Authorize flow for that team connection.
4. **Microsoft Admin Graph consent:** Accept Application and/or Delegated permissions (or have MS Admin DM the bot `appconnect`). For Advance, ensure message-read scopes exist (`ChatMessage.Read.All` and/or delegated `ChatMessage.Read`). Prefer `User.ReadBasic.All` over `User.Read.All`.
5. **Map service:** In the Teams PagerDuty app (or PD Integrations → Microsoft Teams), connect channel ↔ Service `poc-pd-ai-agents-test`. Escalation on that service must notify **only you**.
6. **Advance chat:** PD web → **AI → AI Settings → Assistant and AI Agents Configuration** → under Chat Integrations, Teams status **Connected** → enable optional Advance permissions if prompted → toggle Teams **On / Enabled**.
7. **Enable agents:** Under **AI Agents**, set **SRE**, **Scribe**, and **Insights** to **Enabled**. Enable **Shift** only if you still want the toggle on for Path A; full Shift DMs will not work without Slack.
8. **Scope Advance (optional but smart):** Limit Advance access to one PagerDuty team that owns the test Service.
9. **Each POC user in Teams:** Open a chat with the PagerDuty bot → type `@PagerDuty linkUser` and finish linking. If your tenant is Delegated-heavy for chat/meetings, also run `graphAuth`.
10. **Optional for Scribe meetings:** MS Admin may set `New-CsApplicationAccessPolicy` with US AppId `05ffe668-5b27-45ff-a64d-b2ed6c475d7a` or EU AppId `8f79a561-d2f1-4a1e-8092-c2039043a40e`, and allow the Scribe bot past the Teams lobby.

#### Success criteria (§0)

| Check | Pass if |
| --- | --- |
| App present | PagerDuty bot responds in the POC team |
| Graph OK | No “UPDATE AVAILABLE” on tenant for Advance features |
| Advance Teams On | AI Settings shows Teams Connected / Enabled |
| Agents On | SRE, Scribe, Insights show Enabled |
| Identity | Your PD user is linked (`linkUser` done) |
| Safe target | Test Service maps to the POC channel; only you get pages |

#### Safety (§0)

| Rule | Why |
| --- | --- |
| One team, one channel, one test Service | Limits blast radius and Graph surface |
| Standard channel only | Private/shared channels are unsupported |
| No prod escalation | Prevents waking the real rotation |
| Do not grant `User.Read.All` for POC | Prefer least privilege profile scope |

#### AI Actions cost (§0)

**0** for enablement itself. Spend starts when you ask SRE or run Scribe.

---

### 1) SRE Agent POC — full click/say steps in Teams

#### POC goal

Prove the SRE Agent can summarize a **test** incident in Microsoft Teams, use a small runbook, and suggest next steps with human approval before any remediation.

#### Prerequisites

| Need | Detail |
| --- | --- |
| §0 complete | Advance Teams Enabled; SRE Agent Enabled; `linkUser` done |
| Teams Early Access | SRE Agent in MS Teams is Early Access — confirm your account has it |
| Test Service | `poc-pd-ai-agents-test` mapped to the POC channel |
| Runbook file | One `.md` or `.txt` under **100 KB** |
| Optional connectors | Grafana, Datadog, New Relic, CloudWatch, Confluence, GitHub under AI Settings → SRE Agent |
| Optional UI path | Incident **SRE Agent** tab in PD web; Ops Console needs **AIOps + Advance** |

#### Numbered steps

1. (Optional) PD web → **AI Settings → SRE Agent** → add **one** connector you actually use. Dynatrace usually **creates** the incident; it is not the main “SRE connector” list.
2. Prepare runbook `poc-checkout-latency.md` with 5–10 clear steps (check last deploy, open problem URL, named rollback workflow).
3. In PagerDuty web, create a **low-risk test incident** on `poc-pd-ai-agents-test` (UI “Create incident”). Do not use a prod routing key.
4. Open the mapped **Teams** channel (or the dedicated incident chat if your workflow creates one). Confirm the incident card appears.
5. In that Teams chat, type: `@pagerduty What are some likely root causes?` (or use the available SRE / Advance triage control if your tenant shows one).
6. Upload or update the runbook when the agent offers **Upload Runbook** / **Update Runbook** (or use the PD web Incident → **SRE Agent** tab if Teams upload UI is missing in EA). Submit the `.md`.
7. Ask: `@pagerduty Analyze past incidents`.
8. Ask: `@pagerduty What steps should I take first?`
9. If the agent recommends a workflow or remediation: **read it**, then approve or decline. Do not auto-run against prod.
10. Optional alternate surfaces: PD Incident details → **SRE Agent** tab; or AIOps → Operations Console → incident → **SRE Agent** tab.
11. **Resolve** the test incident so service memory can save learnings.

#### Success criteria

| Check | Pass if |
| --- | --- |
| Triage reply | Agent posts a grounded summary in Teams (or web tab) |
| Runbook | A later answer references your uploaded steps |
| Human control | No remediation ran without an explicit confirm |
| Memory | After resolve, a later ask on the same service feels more specific |

#### Safety

| Rule | Why |
| --- | --- |
| Test Service only | Avoids waking the real rotation |
| Confirm before remediations | Agent suggests; humans own blast radius |
| Fact-check log/change claims | AI can be wrong; verify in monitoring / deploy tools |
| Cap custom details noise | Only first **~2,000 characters** of custom details/notes are analyzed |
| No customer PII in the question | Teams channel members can see replies |

#### AI Actions cost

**4 AI Actions** per chat ask or nudge click (also when triggered via Incident Workflow / Escalation Policy virtual responder). Budget a handful of asks for the POC.

---

### 2) Scribe Agent POC — Teams meeting path

#### POC goal

Prove Scribe joins a short **Microsoft Teams** meeting on a test incident, streams a transcript, and posts a post-meeting summary useful for PIR notes — all visible in Teams (no Slack).

#### Prerequisites

| Need | Detail |
| --- | --- |
| §0 complete | Advance Teams on; Scribe Enabled; meeting Graph scopes OK |
| Teams meeting | Real conference URL; include passcode in the URL when required |
| Human join | At least one person joins within **15 minutes** for auto-join |
| Lobby | Optionally allow Scribe past the Teams lobby |
| Chat delivery | Leave “send transcripts to chat” on if you want channel visibility |

#### Numbered steps

1. Confirm **Scribe Agent** is **Enabled** in AI Settings (US often needs a manual toggle; EU may default on).
2. (Optional) Add Incident Workflow step **Add Scribe Agent** on the test Service for repeatable demos.
3. Create a test incident on `poc-pd-ai-agents-test`.
4. Create or open a short Teams meeting. Copy the join URL (with passcode if needed).
5. Paste the conference URL onto the incident conference / meeting field in PagerDuty.
6. Open the linked **Teams** incident channel or chat.
7. Either wait for **auto-join**, **or** in Teams type: `@PagerDuty advance scribe` → choose **Add Scribe Agent to meeting** → confirm the URL.
8. Join the meeting yourself within **15 minutes**. Admit Scribe if it sits in the lobby.
9. Speak 2–3 clear sentences: symptom, suspected cause, decision (example: “rollback if error rate stays high”).
10. End the meeting.
11. In Teams, confirm live transcript activity during/after the call (if chat delivery is on).
12. Confirm the **post-meeting summary** (decisions, action items, attendees).
13. Optional: ask Advance for a **Post-Incident Review** draft and check that bridge context appears.
14. Resolve the test incident when done.

#### Success criteria

| Check | Pass if |
| --- | --- |
| Join | Scribe appears in the Teams meeting (or joins per product rules) |
| Transcript | Teams chat or internal capture shows spoken content |
| Summary | Wrap-up lists decisions, actions, attendees |
| PIR helper | Later PIR / status draft can reuse bridge context |

#### Safety

| Rule | Why |
| --- | --- |
| Test incident + short meeting | Avoids recording a real customer bridge by accident |
| Warn attendees | People should know the call is transcribed |
| One Scribe per meeting | Product limit; do not double-add |
| Cap concurrent meetings | Up to **10** concurrent Scribe meetings account-wide |
| Keep POC under ~10 minutes | Limits AI Actions spend |

#### AI Actions cost

Consumes AI Actions — roughly **~6 per 30 minutes** of bridge plus **~2** when the final summary posts. Keep the POC meeting under ~10 minutes.

---

### 3) Shift Agent — honest Teams-only paths

#### Honest status

| Fact | What it means |
| --- | --- |
| Slack-first product | Docs and pricing describe Shift as available with Slack; conflict and coverage notifications wire to Slack |
| Teams-only gap | Do not expect full “Request coverage → teammate accepts in Teams DM” automation |
| Still give a step path | Use **Path A** (best-effort) or **Path B** (recommended skip-full / web + Calendar) below |

#### POC goal (Path B — recommended for Teams-only)

Prove you can still detect an OOO vs on-call conflict and apply a **manual** schedule override using PagerDuty web + Google Calendar, without Slack DMs. Document that full Shift Agent coverage chat is deferred until Slack exists.

#### Prerequisites (both paths)

| Need | Detail |
| --- | --- |
| Level-1 schedule | Only schedules on escalation **Level 1** are watched by Shift |
| Test schedule | e.g. `poc-shift-agent` — never prod primary |
| Google Calendar Extension | Recommended (Admin / Account Owner configures) |
| Two people (Path A only) | You + one teammate willing to take a manual override |
| Shift toggle | Optional; Path B works even if Shift DMs never fire |

#### Path A — best-effort Teams-only workaround

Use this only to see whether Advance chat in Teams answers schedule questions. Coverage accept in Slack will **not** run.

1. Enable **Shift Agent** in AI Settings if the toggle is off.
2. Create test schedule `poc-shift-agent` with you as primary for a known near-term window.
3. Put that schedule on **Level 1** of a **test** escalation policy.
4. (Recommended) Admin enables **Google Calendar Extension**; you authorize your calendar.
5. Block OOO on Google Calendar overlapping that window.
6. In Teams, open Advance chat and ask: `I am on vacation <date>. Do I have a conflict?` (or `@PagerDuty advance I am OOO <date>. Any on-call conflict?`).
7. If the agent describes a conflict, note it. If it offers **Request coverage**, click only if you understand the accept path may require Slack for the teammate.
8. **Manual close:** In PD web → Schedules → `poc-shift-agent` → create an **override** for the teammate for that window. Confirm schedule history.
9. Mark POC result: **partial pass** if conflict was visible in chat or Calendar; **full Shift coverage chat = blocked without Slack**.

#### Path B — clear skip / PD web + Calendar POC (recommended)

1. Document in your notes: “Full Shift Agent Slack DM POC deferred — Teams-only org.”
2. Create test schedule `poc-shift-agent` with you primary on a known window.
3. Attach it to **Level 1** of a test escalation policy (not prod).
4. Admin enables **Google Calendar Extension**; you authorize calendar.
5. Create an OOO block that overlaps the on-call window.
6. In PagerDuty web, open the schedule and confirm the conflict is visible via Calendar extension / schedule UI (or that you can see the overlap yourself).
7. Create a schedule **override** for the coverage person for that window.
8. Confirm the override appears in schedule history (who took the shift).
9. Optional later: when Slack is available, re-run seq 9 Shift POC for Request coverage → accept DMs.

#### Success criteria

| Path | Pass if |
| --- | --- |
| Path A | Advance in Teams surfaces conflict language **or** you documented that it did not; schedule override written manually |
| Path B | OOO vs on-call overlap handled with Calendar + web override; audit trail exists; full Shift Slack path explicitly deferred |
| Safety | No overrides written to a production primary schedule |

#### Safety

| Rule | Why |
| --- | --- |
| Test schedule / test EP only | Do not inject overrides into prod primary |
| Tell the candidate it is a POC | Avoid confusing a real coverage fire drill |
| Level-1 only by design | Lower levels will not show Shift conflicts — that is expected |
| Do not claim Teams DM coverage worked | Keeps the POC honest for stakeholders |

#### AI Actions cost

**0** — Shift Agent does not consume AI Actions. Manual web overrides also cost 0 AI Actions.

---

### 4) Insights Agent — conversational in Teams

#### POC goal

Prove Insights answers a concrete MTTR/MTTA (or volume) question for a Team/Service you own **inside Microsoft Teams**. Explicitly note that weekly proactive maturity DMs remain Slack-first.

#### Prerequisites

| Need | Detail |
| --- | --- |
| §0 complete | Advance Teams on; Insights usually auto-on with Advance |
| Conversational GA | Insights Agent generally available for MS Teams chat (product changelog) |
| Named Team/Service | Prefer a service with real history so answers are checkable |
| Channel | Ask in a channel where `@pagerduty` is allowed; replies are visible to members |
| Weekly DMs | Do **not** expect Teams DMs; those are still documented as Slack |

#### Numbered steps

1. Confirm **Insights Agent** is Enabled (toggle on if someone disabled it).
2. Pick one Team and one Service you own (test service only if it has enough history; otherwise a non-sensitive service with known stats).
3. Open the POC **Teams** channel (or Advance chat in Teams).
4. Ask: `@pagerduty How many high urgency incidents were there last week on <ServiceOrTeam>?`
5. Ask a trend question: `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?`
6. Ask a period comparison: `@pagerduty Was MTTA faster this month than last month for <Service>?`
7. Compare each answer to **Analytics** in the PagerDuty web UI for the same window (sanity check).
8. Optionally click **Rate AI Response** if shown.
9. **Weekly DM note:** Document that proactive recommendation DMs are Slack-only today. For Teams-only orgs, skip waiting for a weekly DM; treat maturity tips as out of scope or review Analytics / service settings manually on the **test** service.
10. If you later get a Slack DM tip in a hybrid org: open the link on a **test** service first — do not bulk-enable on prod during the POC.

#### Success criteria

| Check | Pass if |
| --- | --- |
| Chat answer | Agent returns a number or trend tied to your Team/Service in Teams |
| Sanity | Roughly matches Analytics UI for the same filter |
| Visibility | Channel members can see the `@pagerduty` reply |
| DM gap documented | Notes state weekly proactive DMs are Slack-first |

#### Safety

| Rule | Why |
| --- | --- |
| No customer PII in the question | Channel replies are visible |
| Apply config tips on test first | Maturity recommendations can change prod alert behavior |
| Empty history | Brand-new test services may yield thin answers — pick a service with data |

#### AI Actions cost

**0** — Insights Agent does not consume AI Actions.

---

### Cost and surface cheat sheet (Teams-only)

| Agent | Teams-only demo surface | AI Actions | Honest note |
| --- | --- | --- | --- |
| SRE Agent | Teams `@pagerduty` ask; optional PD web SRE tab | **4** per ask or nudge | Early Access in Teams |
| Scribe Agent | Teams meeting URL + `@PagerDuty advance scribe` | **~6 / 30 min** + **~2** final summary | Strongest Teams-only fit |
| Shift Agent | Path A Advance ask; Path B web + Calendar override | **0** | Full coverage DMs need Slack |
| Insights Agent | Teams `@pagerduty` analytics Q&A | **0** | Weekly maturity DMs still Slack-first |

### Suggested run order (single afternoon)

| Order | Block | Time box |
| --- | --- | --- |
| 0 | Shared Teams enablement | 30–60 min (Admins) |
| 1 | SRE Agent POC | 15–20 min |
| 2 | Scribe Agent POC | 15–20 min (meeting ≤10 min) |
| 3 | Shift Path B (or Path A) | 10–15 min |
| 4 | Insights conversational | 10–15 min |

---

## Data flow map

```
[§0 Shared]
  MS Admin Graph consent + PD Authorize
    → Teams app + channel ↔ test Service
    → Advance Teams Enabled + agents On
    → linkUser (each person)
         |
         +-- [1 SRE] test incident → Teams chat @pagerduty
         |     triage / runbook / next steps (4 Actions each)
         |     human confirms remediation → resolve → memory
         |
         +-- [2 Scribe] incident meeting URL → Teams meeting
         |     @PagerDuty advance scribe OR auto-join
         |     transcript + summary → Teams channel / PIR
         |
         +-- [3 Shift] Slack DMs missing on Teams-only
         |     Path A: Advance ask in Teams (partial)
         |     Path B: Calendar conflict → PD web override (recommended)
         |
         +-- [4 Insights] @pagerduty analytics in Teams
               weekly proactive DMs ...... Slack-only (document gap)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [11.sh](./11.sh) | Browser bookmarks and echo checklist (no live PD/MS API) |
| [11-pagerduty-four-agents-teams-only-poc-follow.txt](./11-pagerduty-four-agents-teams-only-poc-follow.txt) | Full chat-ready steps (EN + 中文 brief) |
| Seq 9 four agents POC | Daily Files `2026-08-25/9-pagerduty-four-agents-poc-examples/` |
| Seq 10 Teams permissions | Daily Files `2026-08-25/10-pagerduty-teams-only-permissions/` |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-25/11-pagerduty-four-agents-teams-only-poc/` |

### Official docs

| Topic | URL |
| --- | --- |
| Microsoft Teams integration | https://support.pagerduty.com/main/docs/microsoft-teams |
| Teams permission changelog | https://support.pagerduty.com/main/docs/microsoft-teams-permission-changelog |
| PagerDuty Advance | https://support.pagerduty.com/main/docs/pagerduty-advance |
| SRE Agent | https://support.pagerduty.com/main/docs/sre-agent |
| Scribe Agent | https://support.pagerduty.com/main/docs/scribe-agent |
| Shift Agent | https://support.pagerduty.com/main/docs/shift-agent |
| Insights Agent | https://support.pagerduty.com/main/docs/insights-agent |
| Insights GA on Teams | https://support.pagerduty.com/main/changelog/insights-agent-now-generally-available-for-microsoft-teams |

---

## Commands

UI-first POCs. One-liners in [11.sh](./11.sh) open docs or print the checklist — **do not** call live PagerDuty or Microsoft APIs unless you explicitly ask later.

```bash
open "https://REPLACE_ME.pagerduty.com/ai-settings"
```

Teams bot lines (type in Teams; do not shell them):

```
@PagerDuty linkUser
graphAuth
@pagerduty What are some likely root causes?
@PagerDuty advance scribe
@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?
```
