# PagerDuty AI Agents Teams Only

## Decision tree

```
Org chat = Microsoft Teams only (no Slack)?
  ├─ Shared gate
  │    Advance? NO → Sales / trial first
  │    YES → AI → AI Settings → Assistant and AI Agents Configuration
  │         → Connect Microsoft Teams → Optional Permissions → Connected
  │         → Toggle Microsoft Teams Enabled
  │         → Enable agents you will demo
  │         → Link PD user ↔ Teams (@PagerDuty linkUser)
  │         → Test Service only (never prod pages)
  ├─ Which agent?
  │    SRE → Teams Early Access OK (@pagerduty ask) + web SRE tab
  │    Scribe → Teams chat + Teams/Zoom/Meet bridge OK
  │    Insights → on-demand Q&A in Teams OK; weekly proactive DMs still Slack-first
  │    Shift → Slack-preferential; expect weak/no Teams coverage DMs
  └─ POC pass?
       SRE/Scribe/Insights chat → pass on Teams-only
       Shift full path / Insights weekly nudge → needs Slack (or mark out of scope)
```

```
Teams command shape (remember this delta vs Slack)
  Advance Assistant → @PagerDuty advance <question>
  SRE Agent         → @pagerduty <question>  (Teams EA; no Slack “Triage” button assumed)
  Scribe            → @PagerDuty advance scribe
  Insights ask      → @PagerDuty advance <analytics question>  (or public @pagerduty where supported)
  Slack equivalents → @PagerDuty / @pagerduty ; /pd scribe  (not available if Slack is off)
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Can you POC on Teams only? | Yes for **SRE** (Early Access), **Scribe**, and **Insights** conversational Q&A |
| What breaks without Slack? | **Shift** coverage/conflict DMs and **Insights weekly proactive nudges** are documented as Slack-first |
| One-time enablement | **AI → AI Settings → Assistant and AI Agents Configuration** → connect + enable **Microsoft Teams** |
| Mention style | Teams often needs `@PagerDuty advance …`; Slack often uses `@PagerDuty` / `/pd …` |
| Safe demo rule | Dedicated test Service + Level-1 test schedule that pages only you |

---

## Summary

If the org uses **Microsoft Teams only**, you still run three of the four Advance agents in chat: SRE (Teams Early Access), Scribe (transcript delivery to Teams), and Insights (on-demand questions). Shift Agent and Insights **weekly** maturity DMs are documented around Slack notification rules and Slack DMs, so treat those paths as out of scope or web-assisted for a Teams-only POC. Enable Advance once against Teams, link users, then walk each agent on a test Service.

Official references: [PagerDuty Advance](https://support.pagerduty.com/main/docs/pagerduty-advance), [SRE Agent](https://support.pagerduty.com/main/docs/sre-agent), [Scribe Agent](https://support.pagerduty.com/main/docs/scribe-agent), [Shift Agent](https://support.pagerduty.com/main/docs/shift-agent), [Insights Agent](https://support.pagerduty.com/main/docs/insights-agent), [Microsoft Teams User Guide](https://support.pagerduty.com/main/docs/microsoft-teams-user-guide).

---

## Main content

### What this is (beginner)

**PagerDuty Advance** is the paid AI add-on that powers the four agents. Agents talk to you in chat (Teams or Slack) and sometimes in the PagerDuty website. **Microsoft Teams only** means you never connect Slack. That is fine for triage and meeting notes. It is a weaker fit for on-call coverage DMs that PagerDuty still describes with Slack examples.

Related earlier notes on this date: seq **9** (four agents Slack-primary POCs), seq **10** sibling folder `10-pagerduty-teams-only-permissions` (Graph / consent scopes).

---

### Teams vs Slack support matrix

| Agent | Teams chat | Slack chat | Teams-only POC verdict |
| --- | --- | --- | --- |
| SRE Agent | Supported (**Early Access**) via `@pagerduty` asks | Supported (Triage button + `@pagerduty`) | **In scope** — use Teams mention + Incident **SRE Agent** tab |
| Scribe Agent | Transcript delivery **Supported**; command `@PagerDuty advance scribe` | Delivery Supported; `/pd scribe` | **In scope** — map Teams channel; use Teams meeting or Zoom/Meet |
| Shift Agent | Advance can be on Teams, but conflict/coverage **notification docs are Slack** | Default activation path with Slack; Slack workspace notification rules | **Limited / out of scope** for full DM coverage POC |
| Insights Agent | Enable Advance in **Slack or MS Teams**; ask analytics questions in chat | Public `@pagerduty` asks; **weekly proactive DMs via Slack app** | **Partial** — Q&A yes; weekly nudges expect Slack |

| Feature | Teams-only note |
| --- | --- |
| Advance Side Panel | Slack paid plans only — ignore in Teams-only |
| Proactive Incident Insights / Summarization | Available under Teams **Configure** after Advance is connected |
| Chat-first GA timeline | Vendor historically GA’d Slack chat-first earlier; Teams catch-up was projected later — verify EA badges in your tenant |

---

### Shared enablement (Teams only, do once)

| Need | What it means | Why you care |
| --- | --- | --- |
| PagerDuty Advance | AI add-on or AI Actions credits | Agent toggles stay dark without it |
| PD Admin / Global Admin / Account Owner | Can open **AI Settings** and enable agents | Someone with power must flip Teams + agents |
| Microsoft Admin | Allows third-party Teams apps + Graph consent | PD app cannot install without this |
| Linked user | `@PagerDuty linkUser` so PD identity maps to Teams | Incident actions, Scribe add, personal messages need this |
| Test Service | e.g. `poc-pd-ai-agents-test` | Fake incidents must not page prod on-call |

**Steps:**

1. PagerDuty web → **AI → AI Settings**.
2. Open **Assistant and AI Agents Configuration**.
3. Under **Chat Integrations**, if Microsoft Teams is **Not Connected**:
   - Install **Microsoft Teams \| PagerDuty**.
   - In Teams, accept **Optional Permissions** for PagerDuty Advance.
4. Confirm Teams shows **Connected**.
5. Toggle **Microsoft Teams** to **Enabled**.
6. Optional → **Configure**: turn on **Proactive Incident Insights** and/or **Proactive Incident Summarization** for richer incident channels.
7. Under **AI Agents**, enable **SRE**, **Scribe**, **Shift**, **Insights** as needed (or **Request to Admin**).
8. In a Teams channel with the bot: `@PagerDuty linkUser` and finish linking.
9. Map test Service → a POC Teams channel (`@PagerDuty connect <service-url>` if you have Admin/Manager rights).
10. Leave Slack **disconnected / off** for a true Teams-only proof.

Commands for install/check paths live in [`10.sh`](./10.sh).

---

### 1) SRE Agent — Teams-specific POC

#### What it is

A triage helper that reads incident context, runbooks, and (optional) logs, then suggests next steps. Humans still approve remediations.

#### Teams delta vs Slack

| Topic | Slack (seq 9) | Teams only |
| --- | --- | --- |
| Chat access | Slack channel + **SRE Agent Triage** button | **Early Access** in MS Teams; ask with `@pagerduty …` |
| Web fallback | Incident details / Ops Console | Same web tabs still work (best safety net) |
| Note analysis posts | Documented in Slack | Prefer web chat + Teams `@pagerduty` asks for POC |

#### Setup

1. Enable **SRE Agent** in AI Settings.
2. Confirm Teams Advance is **Connected** + **Enabled** (Teams EA prerequisite).
3. Optional: AI Settings → SRE Agent → one connector you really use (Grafana, Datadog, New Relic, CloudWatch, Confluence, GitHub).
4. Use Service `poc-pd-ai-agents-test` with escalation that notifies **only you**.
5. Map that service to a Teams channel or open a dedicated Teams incident chat when the test incident fires.
6. Prepare one short runbook `.md` / `.txt` under **100 KB**.

#### Demo steps

1. Create a low-urgency test incident on the test Service.
2. Open the Teams incident / service channel.
3. Type: `@pagerduty What are some likely root causes?`
4. Upload or update a runbook when the agent offers the nudge (or use the web **SRE Agent** tab if Teams UI lacks the button).
5. Ask: `@pagerduty Analyze past incidents`
6. Ask: `@pagerduty What steps should I take first?`
7. If a remediation/workflow is offered: **read it**, approve or decline — never auto-run on prod.
8. Optional parallel: Incident details → **SRE Agent** tab (works without Slack).
9. Resolve the test incident so service memory can save.

#### Success

| Check | Pass if |
| --- | --- |
| Reply | Agent answers in Teams (or web tab) with grounded context |
| Runbook | Later answers reference your uploaded steps |
| Human control | No remediation without explicit confirm |

#### AI Actions

**4** per ask or nudge.

---

### 2) Scribe Agent — Teams-specific POC

#### What it is

A meeting bot that joins Zoom / Microsoft Teams / Google Meet bridges, builds an enhanced transcript, and can post live text + a wrap-up summary into chat.

#### Teams delta vs Slack

| Topic | Slack | Teams only |
| --- | --- | --- |
| Delivery surface | Slack channel | Microsoft Teams channel (supported) |
| Manual add command | `/pd scribe` | `@PagerDuty advance scribe` |
| Meeting vendor | Zoom / Teams / Meet | Same; Teams meetings need lobby rules if you want auto-admit |
| Chat optional for capture | As of **2026-07-23**, Scribe can join without a chat surface for internal/PIR use | Still map a Teams channel if humans should **see** the transcript |

#### Setup

1. Enable **Scribe Agent** (US often manual; EU may default on).
2. Keep Teams Advance connected so transcripts can post to Teams.
3. For auto-join via workflows: ensure **Microsoft Teams \| PagerDuty** meeting path is installed; optionally allow lobby bypass for the bot.
4. Choose auto-launch **or** manual `@PagerDuty advance scribe`.
5. Optional: Incident Workflow step **Add PagerDuty Advance Scribe Agent** on the test Service.
6. Optional: Scribe **Configure** → turn off “send transcripts to chat” only if you want quieter demos (then humans will not see live text).

#### Demo steps

1. Create a test incident on `poc-pd-ai-agents-test`.
2. Attach a real conference URL (include passcode) — Teams meeting is ideal for a Teams-only story.
3. Open the mapped Teams channel.
4. Wait for auto-join, **or** run `@PagerDuty advance scribe` → **Add Scribe Agent to meeting**.
5. Join the meeting yourself within **15 minutes**.
6. Speak 2–3 clear sentences (symptom, cause guess, decision).
7. End the meeting.
8. Confirm live transcript activity in Teams (if chat delivery is on).
9. Confirm the **post-meeting summary** (decisions, actions, attendees).
10. Optional: generate a Post-Incident Review draft and check bridge context.

#### Success

| Check | Pass if |
| --- | --- |
| Join | Scribe appears in the meeting |
| Visibility | Teams channel shows transcript and/or summary |
| PIR helper | Later wrap-up / PIR draft includes bridge context |

#### AI Actions

Roughly **~6 per 30 minutes** of meeting + **~2** for the final summary. Keep the POC under ~10 minutes.

#### Teams meeting caveat

Scribe cannot join Teams meetings/webinars that require **registration** or **CAPTCHA**. “Unverified” label on the bot is cosmetic and does not block transcription.

---

### 3) Shift Agent — Teams-specific POC (limited)

#### What it is

An on-call helper that detects OOO vs shift conflicts, suggests coverage, and writes overrides when someone accepts.

#### Teams delta vs Slack

| Topic | Slack | Teams only |
| --- | --- | --- |
| Default activation language | “PagerDuty Advance with the **Slack** integration” | Docs still say “chat integration (for example, Slack)” |
| Conflict / coverage notify | Auto notification rules tied to **Slack workspace** when you link Slack | No equivalent Teams workspace rule documented |
| Coverage accept UX | Candidate gets Slack-oriented request | Do not expect a full Teams DM POC |

#### Honest POC stance

| Path | Recommendation |
| --- | --- |
| Full Shift POC (conflict DM → Request coverage → accept → schedule update) | **Needs Slack** today per published docs |
| Teams-only org | Mark Shift **out of scope**, or prove only the **web schedule / manual override** story |
| If Advance chat on Teams answers “Do I have a conflict?” | Treat as bonus signal only; still verify coverage DMs before claiming pass |

#### Setup (if you still try a partial demo)

1. Enable **Shift Agent** in AI Settings (may appear enabled with Advance).
2. Create test schedule `poc-shift-agent` on **Level 1** of a **test** escalation policy.
3. Admin enables **Google Calendar Extension**; authorize your calendar.
4. Link PD ↔ Teams users (required for chat identity; may not recreate Slack-style notify rules).
5. Check **My Profile → Notification Rules** for shift conflict / coverage request destinations — if only Slack destinations exist, document that gap.

#### Demo steps (partial)

1. Put OOO on Google Calendar overlapping your Level-1 window.
2. In Teams Advance chat, ask: `I am on vacation <date>. Do I have a conflict?`
3. If **Request coverage** appears, try it and watch whether the candidate gets a usable Teams notification.
4. If no Teams notification appears, stop and record: **Shift full path requires Slack** for this account.
5. Never write overrides onto a production primary schedule.

#### Success (Teams-only)

| Check | Pass if |
| --- | --- |
| Documented limitation | Team agrees Shift DM coverage is Slack-first |
| No prod damage | Test schedule only |
| Optional bonus | Conflict question returns a useful answer in Teams Advance chat |

#### AI Actions

**0**.

---

### 4) Insights Agent — Teams-specific POC

#### What it is

An analytics helper. You ask about incident volume, MTTA/MTTR, and trends. Separately, eligible managers can get **weekly** maturity tips.

#### Teams delta vs Slack

| Topic | Slack | Teams only |
| --- | --- | --- |
| Conversational insights | `@pagerduty …` in a public channel or Advance chat | Advance enabled for **MS Teams**; ask with `@PagerDuty advance …` (Teams command shape) |
| Weekly proactive nudges | DMs from the **PagerDuty Slack app**; link Slack accounts required | **Not documented for Teams** — treat weekly nudges as Slack-only |
| Opt-out | Unsubscribe in Slack DM | N/A if you never get Teams weekly DMs |

#### Setup

1. Confirm Advance + Teams are on; enable **Insights Agent** if it was toggled off.
2. Link your PD user to Teams.
3. Pick a Team/Service with real history (brand-new test services give thin answers).
4. Use a **public** Teams channel where the bot is allowed (replies are visible to the channel).
5. For weekly DMs: only claim them if your tenant actually delivers to Teams; otherwise mark “weekly nudge = Slack-only” in the POC report.

#### Demo steps

1. Ask: `@PagerDuty advance How many high urgency incidents were there last week on <ServiceOrTeam>?`
2. Ask a trend: `@PagerDuty advance How has the average time to resolve changed over the past 6 complete months for <Team>?`
3. Ask a comparison: `@PagerDuty advance Was MTTA faster this month than last month for <Service>?`
4. Sanity-check numbers in PagerDuty **Analytics** UI.
5. Optional: **Rate AI Response**.
6. For weekly nudges: wait one week **or** explicitly document that proactive DMs are Slack-documented only.
7. If a tip suggests changing alert settings, apply it on a **test** service first.

#### Success

| Check | Pass if |
| --- | --- |
| Chat answer | Number/trend matches Analytics roughly |
| Visibility | Channel members see the reply |
| Weekly path | You correctly labeled Slack-first if no Teams DM arrives |

#### AI Actions

**0**.

---

### Cost and surface cheat sheet (Teams-only)

| Agent | Primary Teams-only surface | AI Actions | Slack still required? |
| --- | --- | --- | --- |
| SRE | `@pagerduty` ask + Incident **SRE Agent** tab | **4** / ask or nudge | No (Teams EA + web) |
| Scribe | Teams channel + `@PagerDuty advance scribe` + bridge URL | **~6 / 30 min** + **~2** summary | No |
| Shift | Partial Advance chat only | **0** | **Yes** for full coverage DM POC |
| Insights | `@PagerDuty advance` analytics Q&A | **0** | **Yes** for documented weekly proactive DMs |

---

## Data flow map

```
[PagerDuty Advance]
        |
        v
[AI Settings] --connect--> [Microsoft Teams app + Optional Permissions]
        |
        +-- enable --> [SRE Agent] ----@pagerduty ask----> [Teams incident/service channel]
        |                      \---- web tab ------------> [Incident details / Ops Console]
        |
        +-- enable --> [Scribe Agent] --join bridge------> [Zoom / Teams / Meet]
        |                      \---- transcript/summary -> [Teams mapped channel]
        |                      \---- context -----------> [PIR / status / SRE memory]
        |
        +-- enable --> [Insights Agent] --Q&A-----------> [Teams public / Advance chat]
        |                      \---- weekly nudges -----> [Slack DMs (documented path)]
        |
        +-- enable --> [Shift Agent] --conflict detect--> [Level-1 schedules + optional Google Cal]
                               \---- coverage request --> [Slack notification rules (documented)]
                               \---- Teams-only? -------> [Expect gap; mark limited]
```

---

## Related files

| File | Role |
| --- | --- |
| [`10-pagerduty-ai-agents-teams-only.md`](./10-pagerduty-ai-agents-teams-only.md) | This answer |
| [`10.sh`](./10.sh) | One-liner checklist / open-doc links (you run manually) |
| [`10-pagerduty-ai-agents-teams-only-follow.txt`](./10-pagerduty-ai-agents-teams-only-follow.txt) | Full chat follow (EN + short 中文) |
| Daily Files `2026-08-25/9-pagerduty-four-agents-poc-examples/` | Slack-primary four-agent POCs |
| Daily Files `2026-08-25/10-pagerduty-teams-only-permissions/` | Teams Graph / consent permissions companion |
| [PagerDuty Advance](https://support.pagerduty.com/main/docs/pagerduty-advance) | Connect Teams + enable agents |
| [SRE Agent](https://support.pagerduty.com/main/docs/sre-agent) | Teams Early Access section |
| [Scribe Agent](https://support.pagerduty.com/main/docs/scribe-agent) | Teams delivery + `@PagerDuty advance scribe` |
| [Shift Agent](https://support.pagerduty.com/main/docs/shift-agent) | Slack notification model |
| [Insights Agent](https://support.pagerduty.com/main/docs/insights-agent) | Slack weekly DMs; Advance in Slack or Teams |
| [Microsoft Teams User Guide](https://support.pagerduty.com/main/docs/microsoft-teams-user-guide) | `@PagerDuty advance` commands |

---

## Commands

Inline one-liners only. Full list: [`10.sh`](./10.sh).

```bash
open "https://support.pagerduty.com/main/docs/pagerduty-advance"
open "https://support.pagerduty.com/main/docs/sre-agent"
open "https://support.pagerduty.com/main/docs/scribe-agent"
open "https://support.pagerduty.com/main/docs/shift-agent"
open "https://support.pagerduty.com/main/docs/insights-agent"
open "https://support.pagerduty.com/main/docs/microsoft-teams-user-guide"
```

In Microsoft Teams (type these yourself; not shell):

```
@PagerDuty linkUser
@PagerDuty help
@PagerDuty advance What is going on with this incident?
@pagerduty What are some likely root causes?
@PagerDuty advance scribe
@PagerDuty advance How many high urgency incidents were there last week on poc-pd-ai-agents-test?
@PagerDuty connect https://YOUR-SUBDOMAIN.pagerduty.com/services/YOUR-TEST-SERVICE-ID
```
