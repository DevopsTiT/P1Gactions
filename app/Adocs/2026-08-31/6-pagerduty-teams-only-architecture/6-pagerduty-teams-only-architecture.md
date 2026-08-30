# PagerDuty Teams Only Architecture

## Decision tree

```
Need the whole Teams-only four-agent picture?
  What is this family?
    Product suite (what each agent is)     → seq 8 (detailed agents)
    Slack-primary runnable POC             → seq 9
    Graph / consent / least privilege      → seq 10 (permissions)
    Ordered Teams-only click path          → seq 11 (this source)
    Who can enable vs who can use          → seq 13
  Which agent to prove on Teams only?
    Active incident triage / RCA / runbook?     → 1) SRE Agent (Teams Early Access)
    Incident bridge notes / PIR draft?          → 2) Scribe Agent (Teams meeting + chat)
    On-call OOO / coverage / override?          → 3) Shift Agent
         Slack DMs required for full path?        → YES → skip full Shift; Path B (PD web + Calendar)
         Want best-effort Teams-only?             → Path A (Advance chat ask + manual override)
    Ops health / MTTR / trends?                 → 4) Insights Agent (conversational in Teams)
         Weekly proactive maturity DMs?           → Slack-only today → document gap
  Shared gate (do once)
    Have PagerDuty Advance?
      NO  → Sales / trial first
      YES → Have PD Admin/Owner + Microsoft Admin?
             NO  → stop; need both for Graph + AI Settings
             YES → §0 Shared Teams enablement
                   → then POC 1 → 2 → 3 (alt) → 4
    Always: TEST service / Level-1 TEST schedule — never prod pages
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this answer is | Full architecture, usage cases, and click path for the Teams-only four-agent POC (source: Daily Files 2026-08-25 seq 11) |
| What you prove | SRE Agent, Scribe Agent, and Insights conversational chat work without Slack |
| What you do not fully prove | Shift coverage DMs and Insights weekly maturity DMs stay Slack-first |
| Platform you need | PagerDuty Advance (paid AI add-on with AI Actions budget) |
| Chat surface | One standard Microsoft Teams team + channel mapped to a test Service |
| Who spends AI Actions | SRE and Scribe consume credits; Shift and Insights usually cost 0 |
| Safe demo rule | Dedicated test Service plus a Level-1 test schedule that pages only you |

---

## Summary

PagerDuty’s four named AI agents live under **PagerDuty Advance**. They are not four separate products. They are four jobs on one AI platform: live triage (SRE), meeting notes (Scribe), on-call coverage (Shift), and analytics (Insights). A Teams-only org can run a useful POC for SRE, Scribe, and Insights Q&A. Shift’s “request coverage → teammate accepts in DM” path still expects Slack, so you prove coverage with PagerDuty web plus Google Calendar instead. Enable Teams, Graph, and identity mapping once. Then walk each agent on a test Service in one afternoon.

---

## Main content

### What this is (beginner)

**PagerDuty** is the incident pager. When checkout is slow, something creates a PagerDuty **incident** and the on-call person gets a page.

**PagerDuty Advance** is the paid AI layer on top. It has a budget called **AI Actions**. The four agents live here. If Advance is off, the agent toggles do nothing.

**Microsoft Teams only** means the org never connects Slack. The PagerDuty bot lives in Teams. People ask `@pagerduty` questions there. That is enough for triage and meeting notes. It is a weaker fit for coverage DMs.

A **POC** (proof of concept) means you prove each agent with a visible, checkable outcome. You do not page production on-call.

### How the Daily Files family fits together

| Doc | What it designs | When you open it |
| --- | --- | --- |
| Seq 8 — AI agents detailed | Product architecture: what each agent is, what is not an agent, Dynatrace → PD story | You need the “why this exists” picture |
| Seq 9 — four agents POC | Slack-primary runnable steps for all four | You have Slack, or you want the original full Shift path |
| Seq 10 — Teams permissions | Graph scopes, Admin vs Delegated consent, least privilege | App install fails, or security asks “what did we grant?” |
| Seq 11 — Teams-only POC | One ordered Teams-only runbook: §0 then agents 1–4 | You will actually click through a Teams-only demo |
| Seq 13 — setup permissions | Who can enable vs who can only use | Someone says “I cannot see AI Settings” |

Seq 11 is the **runbook**. This answer expands it into **architecture + usage cases** and keeps the click path.

### What is not one of the four agents

| Name | What it is | Why you care |
| --- | --- | --- |
| PagerDuty Advance | Paid AI platform plus AI Actions budget plus the Assistant | Agents live here; without Advance they stay dark |
| Advance Assistant | Chat router in Teams or Slack | Entry point (`@PagerDuty advance …`). Not a fifth named agent |
| Event Intelligence / AIOps | Alert grouping and Event Orchestration | Noise reduction before a human or SRE Agent sees the page |
| Status updates, PIR drafts, Automation Digest | Extra Advance writing helpers | Useful, they spend AI Actions, they are not the named suite |
| Advance Side Panel | Slack paid-plan UI | Ignore it on Teams-only |

### Architecture layers (how the system is built)

Think of five layers. You enable them from the outside in. Agents sit on top of identity and chat.

```
Layer 5  Four AI agents (SRE / Scribe / Shift / Insights)
Layer 4  Advance Assistant (routes @pagerduty / @PagerDuty advance)
Layer 3  Identity map (linkUser, optional graphAuth)
Layer 2  Microsoft Graph + Teams bot (cards, chats, meetings, message read)
Layer 1  PagerDuty core (Service, Escalation, Schedule, Incident)
```

#### Layer 1 — PagerDuty core (always required)

| Object | What it is | POC object |
| --- | --- | --- |
| Service | Named thing that can have incidents | `poc-pd-ai-agents-test` |
| Escalation policy | Who gets paged, in what order | Test EP that notifies **only you** |
| Schedule | Who is on-call this hour | `poc-shift-agent` on **Level 1** of the test EP |
| Incident | One fire you acknowledge and resolve | Created in the UI, never via a prod routing key |
| Team (PagerDuty team) | Access boundary for Advance | Scope Advance to the team that owns the test Service |

Why Level 1 matters: Shift Agent only watches schedules on escalation **Level 1**. A Level 2 backup schedule will not show Shift conflicts. That is product design, not a bug.

#### Layer 2 — Teams bot + Microsoft Graph

The Teams app is a **bot**. It posts incident cards. It can create dedicated chats and meetings. For Advance to summarize a conversation, Microsoft must let the bot **read chat messages**. That is extra Graph permission, not the basic “post a card” install.

| Actor | What they grant | If missing |
| --- | --- | --- |
| Teams Admin | Allow the PagerDuty (or PagerDuty EU) third-party app | Users cannot install the bot |
| PD Admin | Authorize the PD ↔ Teams connection | Cards never appear |
| Microsoft Admin | Graph Admin consent (or bot `appconnect`) | Advance stays silent; “UPDATE AVAILABLE” on the tenant |

**Hard product limit:** the PagerDuty app does **not** support private or shared Teams channels. Use one **standard** team + channel. Dedicated incident chats created by Incident Workflows are still allowed.

#### Layer 3 — Identity

| Command (type in Teams) | What it does | Why you care |
| --- | --- | --- |
| `@PagerDuty linkUser` | Maps your PagerDuty user to your Teams user | Ack/resolve, auto-add to chats/meetings, personal agent actions |
| `graphAuth` | User consent for Delegated Graph scopes | Needed if the tenant is Delegated-heavy and Application scopes do not cover that feature |
| `appconnect` | Asks Microsoft Admin to finish Graph consent | Use when a non-admin hits a consent wall |

If Application permissions already cover a feature, users may not need `graphAuth` for that feature. If you later revoke Application scopes, every actor must have finished `graphAuth` first.

#### Layer 4 — Advance Assistant

Advance Assistant is the chat brain. In Teams you often type `@PagerDuty advance <question>`. For SRE and Insights, `@pagerduty <question>` in the mapped channel is the usual POC line. The Assistant routes the question to the right agent. It is not counted as a fifth named agent.

#### Layer 5 — The four agents

| Agent | Job | Teams-only honesty |
| --- | --- | --- |
| SRE Agent | Virtual responder: summarize, runbook, next steps, human-approved remediation | Full POC in Teams (Early Access) plus optional PD web tab |
| Scribe Agent | Join the meeting, transcript, post-meeting summary, PIR context | Strongest Teams-only fit |
| Shift Agent | Detect OOO vs on-call, request coverage, write override | Full DM path needs Slack; use Path B web + Calendar |
| Insights Agent | Answer MTTR/MTTA/volume questions; weekly maturity tips | Conversational Q&A in Teams; weekly DMs still Slack-first |

### Graph permission architecture (from seq 10)

PagerDuty supports **Application**, **Delegated**, or **hybrid**. If Application is granted for a feature, the bot uses that. Otherwise it falls back to Delegated (the user must have run `graphAuth`).

| Model | Consent | Best for |
| --- | --- | --- |
| Application | One-time Microsoft Admin Accept | Automation: create chat, add members, create meetings, read messages without every user signing Graph |
| Delegated | Each user runs `graphAuth` | Stricter “act as this user” security |
| Hybrid (common today) | Both present | Smooth migration; revoke Application only after all actors finished `graphAuth` |

#### Dedicated incident chat

| Scope type | Permission | Required | Least privileged |
| --- | --- | --- | --- |
| Delegated | `Chat.ReadWrite` | Yes | No |
| Delegated | `TeamsAppInstallation.ReadWriteForChat` | Yes | No |
| Delegated | `User.ReadBasic.All` | Yes | Yes |
| Application | `Chat.Create` | Yes | Yes |
| Application | `ChatMember.ReadWrite.All` | Yes | Yes |
| Application | `TeamsAppInstallation.ReadWriteSelfForChat.All` | Yes | Yes |
| Application | `User.ReadBasic.All` | Optional | Yes (prefer this) |
| Application | `User.Read.All` | Optional | No — revoke if present |

#### Dedicated channel

| Scope type | Permission | Required |
| --- | --- | --- |
| Delegated / Application | `Channel.Create` | Yes |

#### Conference bridge (Teams meeting)

| Scope type | Permission | Required | Notes |
| --- | --- | --- | --- |
| Delegated | `OnlineMeetings.ReadWrite` | Yes | User-created meetings |
| Application | `OnlineMeetings.ReadWrite.All` | Yes | May need `New-CsApplicationAccessPolicy` |
| Application | `Calendars.ReadWrite` | Optional unless meeting create falls back to a calendar event | Fallback does not need the PowerShell policy |

Scribe meeting AppIds for the access policy:

| Tenant | AppId |
| --- | --- |
| US | `05ffe668-5b27-45ff-a64d-b2ed6c475d7a` |
| EU | `8f79a561-d2f1-4a1e-8092-c2039043a40e` |

#### Advance message ingest (required for useful agents)

| Scope type | Permission | Required for Advance |
| --- | --- | --- |
| Delegated | `ChatMessage.Read` | Yes |
| Application | `ChatMessage.Read.All` | Yes |

Without these, the bot can still post cards. It cannot read the incident conversation that SRE and summaries need.

#### Org info + OIDC (delegated flow)

| Scope type | Permission | Required |
| --- | --- | --- |
| Delegated | `User.Read` | Yes |
| Application | `Organization.Read.All` | Yes |
| Delegated | `openid`, `profile`, `email` | Yes for any delegated feature |

Changelog note (2026-02-05): Advance message read is treated as **required** when using Advance. `offline_access` was removed from the required delegated list.

### Who does what (roles)

| Role | What they can do | Why you care for this POC |
| --- | --- | --- |
| PD Account Owner / Global Admin | Connect Teams, enable Advance, toggle agents, set team-level Advance access | Required to turn agents on |
| PD Admin | Authorize PD ↔ Teams; manage integrations | Usually enough to install |
| PD Manager | Map services ↔ Teams channels (in the Teams app; web mapping is Admin+) | Maps the test Service |
| PD Responder / any linked user | Ack/resolve in Teams after `linkUser`; ask agents if their PD team has Advance | Day-to-day POC users |
| Microsoft / Teams Admin | Consent Graph; allow the third-party app; optional meeting policy | Bot cannot read chats or create meetings without this |
| No PD Admin rights | Click **Request to Admin** on an agent card | Emails admins to enable that agent |

Team-level Advance access is enforced by **PagerDuty team membership**. Same rule for web, Teams, Slack, and API.

You do **not** mint a PagerDuty REST API token to turn these product agents on. Tokens belong to custom API POCs (seq 7), not this suite.

### Least privilege for the POC

| Do | Why |
| --- | --- |
| One standard Teams team + one channel | Limits Graph surface and blast radius |
| One PD test Service + escalation to you only | Fake incidents stay off prod rotations |
| Grant Application chat + meetings + `Organization.Read.All` | Fewer per-user Graph prompts |
| Grant Advance `ChatMessage.Read.All` and/or delegated `ChatMessage.Read` | Required for useful agent context |
| Prefer `User.ReadBasic.All`; revoke `User.Read.All` | Least profile data |
| Skip `Calendars.ReadWrite` unless meeting create fails | Optional fallback |
| Enable SRE + Scribe + Insights; Shift optional | Shift waits for Slack or stays web-only |
| Scope Advance to one PD team | Team-level access control |
| Use standard channels only | Private/shared channels are unsupported |

### Teams vs Slack command shape

| Job | Teams (this POC) | Slack (seq 9) |
| --- | --- | --- |
| Link identity | `@PagerDuty linkUser` | Slack link-accounts flow |
| Graph user consent | `graphAuth` | Not the Teams path |
| Ask SRE | `@pagerduty What are some likely root causes?` | **SRE Agent Triage** button or `@pagerduty …` |
| Add Scribe | `@PagerDuty advance scribe` | `/pd scribe` |
| Ask Insights | `@pagerduty How has MTTR changed …` | Same mention style in a public channel |
| Advance router | `@PagerDuty advance <question>` | `@PagerDuty` / Advance chat |

Do not expect the Slack **SRE Agent Triage** button or `/pd scribe` on a Teams-only tenant.

---

### 0) Shared Teams enablement (do once)

Reuse this for all four POCs. Graph tables live above and in seq 10. This is the click order.

#### Prerequisites

| Need | What it means | Why you care |
| --- | --- | --- |
| PagerDuty Advance | Paid AI platform with AI Actions budget | Without it, agent toggles do nothing |
| PD Account Owner / Global Admin / Admin | Can open AI Settings and authorize Teams | Turns agents and chat on |
| Microsoft / Teams Admin | Can consent Graph and allow third-party apps | Bot cannot read chats or create meetings without this |
| One standard Teams team + channel | Not private or shared | PD app does not support private/shared channels |
| Test Service | Example: `poc-pd-ai-agents-test` | Fake incidents stay off prod rotations |
| Linked users | Each POC person runs `linkUser` | Actions and auto-add need the identity map |

#### Numbered steps

1. **Teams Admin:** Allow the PagerDuty (or PagerDuty EU) third-party app so users can install it.
2. **Install:** In Teams, install **PagerDuty** → **Add to a team** → pick your one POC team.
3. **PD Admin Authorize:** Complete the PagerDuty Authorize flow for that team connection.
4. **Microsoft Admin Graph consent:** Accept Application and/or Delegated permissions (or have MS Admin DM the bot `appconnect`). For Advance, ensure message-read scopes exist (`ChatMessage.Read.All` and/or delegated `ChatMessage.Read`). Prefer `User.ReadBasic.All` over `User.Read.All`.
5. **Map service:** In the Teams PagerDuty app (or PD Integrations → Microsoft Teams), connect channel ↔ Service `poc-pd-ai-agents-test`. Escalation on that service must notify **only you**.
6. **Advance chat:** PD web → **AI → AI Settings → Assistant and AI Agents Configuration** → under Chat Integrations, Teams status **Connected** → enable optional Advance permissions if prompted → toggle Teams **On / Enabled**.
7. **Optional richer channel:** Under Teams **Configure**, turn on **Proactive Incident Insights** and/or **Proactive Incident Summarization**.
8. **Enable agents:** Under **AI Agents**, set **SRE**, **Scribe**, and **Insights** to **Enabled**. Enable **Shift** only if you still want the toggle on for Path A; full Shift DMs will not work without Slack.
9. **Scope Advance (optional but smart):** Limit Advance access to one PagerDuty team that owns the test Service.
10. **Each POC user in Teams:** Open a chat with the PagerDuty bot → type `@PagerDuty linkUser` and finish linking. If your tenant is Delegated-heavy for chat/meetings, also run `graphAuth`.
11. **Optional for Scribe meetings:** MS Admin may set `New-CsApplicationAccessPolicy` with the US or EU AppId above, and allow the Scribe bot past the Teams lobby.

#### Success criteria (§0)

| Check | Pass if |
| --- | --- |
| App present | PagerDuty bot responds in the POC team |
| Graph OK | No “UPDATE AVAILABLE” on the tenant for Advance features |
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

### 1) SRE Agent — architecture and usage

#### What this is

An AI site reliability helper tied to a PagerDuty **Service**. It reads incident context, past incidents, an uploaded runbook, and optional connectors (Grafana, Datadog, New Relic, CloudWatch, Confluence, GitHub). It suggests next steps. Humans still own blast radius.

It builds **memory** (playbook scratchpad, customer runbooks, summaries, service profile) each time you **resolve** incidents. That is why the last POC step is Resolve, not just close the chat.

#### Why it matters

The first 10 minutes of an incident are usually hunting docs and logs. The agent does that parallel work so humans decide, not dig.

#### Architecture surfaces

| Surface | How you start | Good first question |
| --- | --- | --- |
| MS Teams (Early Access) | Mapped channel or incident chat → `@pagerduty …` | What are some likely root causes? |
| Incident details | Open incident → right panel **SRE Agent** | Analyze past incidents |
| Operations Console | AIOps → Operations Console → incident → **SRE Agent** tab | What steps should I take first? |
| Virtual responder | Incident Workflow or Escalation Policy (Early Access) | Same cost as a chat ask (4 Actions) |

Ops Console needs **AIOps + Advance**. Dynatrace usually **creates** the incident. It is not the main item on the SRE connector list. Keep the Dynatrace problem URL in the PD event so humans and the agent can deep-link.

| Nudge / action | What it means |
| --- | --- |
| Upload / Update Runbook | Teach the agent your SOP for this service |
| Analyze Past / Related Incidents | Pull history and correlations |
| Generate a Playbook | Draft repeatable steps from this incident |
| Check Change Events | Look for recent deploys or config changes |
| Search Logs | Query connected observability tools |
| Update Memory | Save learnings after resolve |

#### Limits beginners hit

| Limit | What it means |
| --- | --- |
| Custom details cap | Only the first **~2,000 characters** of `custom_details` / notes are analyzed |
| Runbook size | `.md` / `.txt` / `.pdf` (and images `.jpg` / `.png`), max **100 KB** each |
| File count | **25** files per conversation |
| Fact-check | AI can be wrong; verify in monitoring and deploy tools |
| Human confirm | Do not auto-run remediations against prod |

#### Usage case A — checkout latency (classic)

**Story:** Dynatrace (or you, in the UI) opens “Checkout latency high” on `poc-pd-ai-agents-test`. You open the mapped Teams channel. You ask likely root causes. You upload `poc-checkout-latency.md` (check last deploy, open problem URL, named rollback workflow). You ask past incidents, then first steps. The agent points at a recent deploy and offers a rollback workflow. You **read it and decline** on the POC (or approve only a test-safe workflow). You resolve so memory saves.

**What you are proving:** grounded triage in Teams, runbook reuse, human control, memory after resolve.

#### Usage case B — web tab fallback

Teams Early Access may hide runbook upload. Same test incident, use PD Incident → **SRE Agent** tab to upload and ask. Still counts as a Teams-only org because chat is Teams; the web tab is a product surface, not Slack.

#### Numbered POC steps (Teams)

1. (Optional) PD web → **AI Settings → SRE Agent** → add **one** connector you actually use.
2. Prepare runbook `poc-checkout-latency.md` with 5–10 clear steps.
3. In PagerDuty web, create a **low-risk test incident** on `poc-pd-ai-agents-test` (UI “Create incident”). Do not use a prod routing key.
4. Open the mapped **Teams** channel (or the dedicated incident chat if your workflow creates one). Confirm the incident card appears.
5. Type: `@pagerduty What are some likely root causes?`
6. Upload or update the runbook when offered (or use the PD web **SRE Agent** tab if Teams upload UI is missing in EA).
7. Ask: `@pagerduty Analyze past incidents`.
8. Ask: `@pagerduty What steps should I take first?`
9. If the agent recommends a workflow or remediation: **read it**, then approve or decline. Do not auto-run against prod.
10. Optional: Incident details → **SRE Agent** tab; or AIOps → Operations Console → incident → **SRE Agent** tab.
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
| Fact-check log/change claims | AI can be wrong |
| Cap custom details noise | Only first ~2,000 characters are analyzed |
| No customer PII in the question | Teams channel members can see replies |

#### AI Actions cost

**4 AI Actions** per chat ask or nudge click (also when triggered via Incident Workflow / Escalation Policy virtual responder). Budget a handful of asks for the POC.

---

### 2) Scribe Agent — architecture and usage

#### What this is

A meeting bot that joins Zoom, Microsoft Teams, or Google Meet on an incident, streams an enhanced transcript, and posts a wrap-up (decisions, action items, attendees). Later, Advance can draft a **Post-Incident Review** that already includes bridge context.

As of July 23, 2026, Scribe can join bridges **without** a chat surface for internal SRE/PIR use. You still need Teams mapping if humans should **see** the transcript in the channel.

#### Why it matters

On a real bridge, people talk faster than anyone can type notes. Scribe is the note-taker so the commander can command.

#### Architecture path (Teams meeting)

```
Incident gets a Teams join URL (passcode in the URL if required)
  → auto-join  OR  @PagerDuty advance scribe
  → human joins within 15 minutes
  → Scribe admitted past lobby if needed
  → live transcript (optional: send to chat)
  → hang-up → post-meeting summary
  → optional PIR draft reuses bridge context
```

| Limit | What it means |
| --- | --- |
| One Scribe per meeting | Do not double-add |
| 10 concurrent meetings | Account-wide cap |
| 15-minute human join | Auto-join skips if nobody shows |
| US vs EU toggle | US often needs a manual enable; EU may default on |
| Lobby | Optionally allow the Scribe bot past the Teams lobby |

#### Usage case A — short Teams war room (primary Teams-only demo)

**Story:** You create a test incident, paste a 10-minute Teams meeting URL onto the incident, type `@PagerDuty advance scribe`, join yourself, and say three sentences: symptom, suspected cause, decision (“rollback if error rate stays high”). You end the meeting. Teams shows transcript activity and a wrap-up. You optionally ask Advance for a PIR draft.

**What you are proving:** join, transcript, summary, PIR helper — all visible without Slack.

#### Usage case B — workflow auto-add

Add Incident Workflow step **Add Scribe Agent** on the test Service so every test incident can repeat the demo without typing the command.

#### Numbered POC steps (Teams)

1. Confirm **Scribe Agent** is **Enabled** in AI Settings.
2. (Optional) Add Incident Workflow step **Add Scribe Agent** on the test Service.
3. Create a test incident on `poc-pd-ai-agents-test`.
4. Create or open a short Teams meeting. Copy the join URL (with passcode if needed).
5. Paste the conference URL onto the incident conference / meeting field in PagerDuty.
6. Open the linked **Teams** incident channel or chat.
7. Either wait for **auto-join**, **or** type: `@PagerDuty advance scribe` → **Add Scribe Agent to meeting** → confirm the URL.
8. Join the meeting yourself within **15 minutes**. Admit Scribe if it sits in the lobby.
9. Speak 2–3 clear sentences: symptom, suspected cause, decision.
10. End the meeting.
11. Confirm live transcript activity during/after the call (if chat delivery is on).
12. Confirm the **post-meeting summary**.
13. Optional: ask Advance for a **Post-Incident Review** draft.
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
| One Scribe per meeting | Product limit |
| Cap concurrent meetings | Up to 10 account-wide |
| Keep POC under ~10 minutes | Limits AI Actions spend |

#### AI Actions cost

Roughly **~6 per 30 minutes** of bridge plus **~2** when the final summary posts. Keep the POC meeting under ~10 minutes.

---

### 3) Shift Agent — architecture and usage (honest Teams-only)

#### What this is

A scheduling assistant. It watches **Level-1** schedules, compares them to Google Calendar OOO, and (on Slack) DMs people to request coverage. When someone accepts, PagerDuty writes a schedule **override**. Coverage candidates get **24 hours** to reply. Weekends are excluded from that window. After timeout or all declines, you get a follow-up.

#### Why Teams-only is partial

| Fact | What it means |
| --- | --- |
| Slack-first product | Docs and pricing describe Shift as available with Slack |
| Notification wiring | Conflict and coverage rules auto-wire to Slack workspaces |
| Teams-only gap | Do not expect full “Request coverage → teammate accepts in Teams DM” |
| Still useful | You can still detect OOO vs on-call and write a manual override |

#### Architecture (intended Slack path vs Teams workaround)

```
Intended (seq 9, needs Slack)
  Level-1 schedule + Google Calendar OOO
    → Shift conflict DM
    → Request coverage
    → teammate Slack accept
    → schedule override written

Teams-only Path B (recommended)
  Same Level-1 + Calendar overlap
    → you see overlap in PD web / Calendar extension
    → you write override by hand
    → schedule history is the audit trail

Teams-only Path A (best-effort)
  Same setup
    → ask Advance in Teams: "I am OOO <date>. Any on-call conflict?"
    → if Request coverage appears, accept path may still need Slack
    → always close with a manual web override
```

#### Usage case A — Path B (recommended for Teams-only)

**Story:** You create `poc-shift-agent`, put yourself primary Friday 09:00–17:00, attach it to Level 1 of a **test** escalation policy. Admin enables Google Calendar Extension. You block Friday as OOO. In PD web you see the overlap. You write an override for a teammate. Schedule history shows who took the shift. You write in notes: “Full Shift Slack DM POC deferred — Teams-only org.”

**What you are proving:** coverage can still be handled with Calendar + web. You are **not** claiming Teams DM coverage worked.

#### Usage case B — Path A (best-effort chat)

Same setup. In Teams Advance chat you ask whether vacation conflicts with on-call. If the agent describes a conflict, that is a **partial** pass. You still write the override in the web UI.

#### Numbered steps — Path A

1. Enable **Shift Agent** in AI Settings if the toggle is off.
2. Create test schedule `poc-shift-agent` with you as primary for a known near-term window.
3. Put that schedule on **Level 1** of a **test** escalation policy.
4. Admin enables **Google Calendar Extension**; you authorize your calendar.
5. Block OOO on Google Calendar overlapping that window.
6. In Teams, ask: `I am on vacation <date>. Do I have a conflict?` (or `@PagerDuty advance I am OOO <date>. Any on-call conflict?`).
7. If **Request coverage** appears, click only if you understand the accept path may require Slack.
8. **Manual close:** PD web → Schedules → `poc-shift-agent` → create an **override** for the teammate. Confirm schedule history.
9. Mark result: **partial pass** if conflict was visible; **full Shift coverage chat = blocked without Slack**.

#### Numbered steps — Path B (recommended)

1. Document: “Full Shift Agent Slack DM POC deferred — Teams-only org.”
2. Create test schedule `poc-shift-agent` with you primary on a known window.
3. Attach it to **Level 1** of a test escalation policy (not prod).
4. Admin enables **Google Calendar Extension**; you authorize calendar.
5. Create an OOO block that overlaps the on-call window.
6. In PagerDuty web, confirm the conflict via Calendar extension / schedule UI.
7. Create a schedule **override** for the coverage person.
8. Confirm the override appears in schedule history.
9. Optional later: when Slack exists, re-run seq 9 Shift POC for Request coverage → accept DMs.

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
| Level-1 only by design | Lower levels will not show Shift conflicts |
| Do not claim Teams DM coverage worked | Keeps the POC honest for stakeholders |

#### AI Actions cost

**0** — Shift Agent does not consume AI Actions. Manual web overrides also cost 0 AI Actions.

---

### 4) Insights Agent — architecture and usage

#### What this is

Conversational analytics over Incidents / Services / Teams reports. You ask volume, MTTR, MTTA, or period-vs-period questions. Separately, on Slack, Account Owner / Admins / (Business+) Team Managers get **weekly** DMs with maturity tips (for example: turn on alert grouping). Unsubscribing from those DMs does **not** kill chat Q&A.

#### Why it matters

After the fire, leadership asks “are we getting slower?” Insights answers from PagerDuty Analytics so you do not export a CSV first.

#### Architecture split (important for Teams-only)

| Path | Surface | Teams-only? |
| --- | --- | --- |
| On-demand Q&A | `@pagerduty` in a Teams channel or Advance chat | **Yes** (GA for conversational Teams) |
| Weekly proactive DMs | Slack app DMs to owners/admins/managers | **No** — document the gap |
| Sanity check | PagerDuty web **Analytics** for the same window | Always do this |

Insights usually auto-enables with Advance. Brand-new test services have thin history. Prefer a non-sensitive service you own that already has weeks of data if the test Service is empty.

#### Usage case A — conversational Q&A in Teams (in scope)

**Story:** In the POC channel you ask last week’s high-urgency count, then 6-month MTTR trend, then MTTA this month vs last month. You open Analytics in the PD web UI for the same filters. Numbers roughly match. Channel members can see the replies.

**What you are proving:** Insights answers a checkable question inside Teams.

#### Usage case B — weekly DM (out of scope on Teams-only)

Do not wait a week for a Teams DM. Document that weekly tips are Slack-first. If a hybrid org later gets a Slack tip, open the link on the **test** service first. Maturity recommendations can change prod alert behavior.

#### Example prompts you can paste

| Prompt type | Example |
| --- | --- |
| Point in time | How many high urgency incidents were there last week on `<ServiceOrTeam>`? |
| Trend | How has the average time to resolve changed over the past 6 complete months for `<Team>`? |
| Period vs period | Was MTTA faster this month than last month for `<Service>`? |
| Vs baseline | Is aggregate MTTR this month better than the 2025 baseline for `<Service>`? |

#### Numbered POC steps

1. Confirm **Insights Agent** is Enabled.
2. Pick one Team and one Service you own (test service only if it has enough history).
3. Open the POC **Teams** channel (or Advance chat in Teams).
4. Ask: `@pagerduty How many high urgency incidents were there last week on <ServiceOrTeam>?`
5. Ask: `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?`
6. Ask: `@pagerduty Was MTTA faster this month than last month for <Service>?`
7. Compare each answer to **Analytics** in the PagerDuty web UI for the same window.
8. Optionally click **Rate AI Response** if shown.
9. Document that weekly proactive DMs are Slack-only today.
10. If you later get a Slack DM tip in a hybrid org: open the link on a **test** service first.

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
| Empty history | Brand-new test services may yield thin answers |

#### AI Actions cost

**0** — Insights Agent does not consume AI Actions.

---

### End-to-end usage story (how the four jobs fit one week)

This is the seq 8 Dynatrace story, rewritten for a Teams-only org.

| When | What happens | Agent |
| --- | --- | --- |
| Before the page | Someone’s Friday OOO overlaps Level-1 on-call | Shift Path B: Calendar + web override (Slack DM skipped) |
| Detect | Dynatrace (or UI) creates a PD incident on the test Service | None yet |
| Page | Test escalation notifies only you; card appears in the Teams channel | — |
| First 10 minutes | You ask root cause, upload runbook, ask first steps | **SRE Agent** |
| War room | You paste a Teams meeting URL; Scribe joins; you speak decisions | **Scribe Agent** |
| Resolve | You resolve so SRE memory updates | SRE memory |
| Next week | You ask MTTR/MTTA in Teams; you do **not** wait for a weekly Teams DM | **Insights** conversational only |

### Cost and surface cheat sheet

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

### Common mistakes

| Mistake | Fix |
| --- | --- |
| “UPDATE AVAILABLE” on tenant | MS Admin re-consent missing Graph scopes (especially ChatMessage read) |
| Agents silent in Teams | Advance Teams not Enabled; optional Advance perms missing; user not on an Advance-enabled PD team |
| Cannot create meeting or chat | Missing OnlineMeetings/Chat scopes, or user never ran `graphAuth` under Delegated |
| Scribe in lobby forever | Adjust Teams lobby / admit policy; optional CsApplicationAccessPolicy |
| Expect Shift DMs in Teams | Not documented; use Path B web + Calendar |
| Expect Insights weekly DMs in Teams | Docs still say Slack; use on-demand chat |
| Private channel mapping | Not supported; use a standard channel |
| Prod escalation on the test Service | Change EP to page only you |
| Claiming full four-agent Teams parity | Stakeholder-honest result is 3 full + 1 workaround |

---

## Data flow map

```
[§0 Shared]
  MS Admin Graph consent + PD Authorize
    → Teams app + standard channel ↔ test Service
    → Advance Teams Enabled + SRE/Scribe/Insights On
    → linkUser (each person) [+ graphAuth if Delegated]
         |
         +-- [1 SRE] test incident → Teams @pagerduty
         |     custom_details (~2k chars) + runbook + optional connectors
         |     triage / next steps (4 Actions each)
         |     human confirms remediation → resolve → service memory
         |
         +-- [2 Scribe] incident meeting URL → Teams meeting
         |     @PagerDuty advance scribe OR auto-join (human in 15 min)
         |     transcript + summary → Teams channel / PIR (~6/30m + 2)
         |
         +-- [3 Shift] Slack DMs missing on Teams-only
         |     Path A: Advance ask in Teams (partial)
         |     Path B: Calendar conflict → PD web override (recommended)
         |
         +-- [4 Insights] @pagerduty analytics in Teams (0 Actions)
               weekly proactive DMs ...... Slack-only (document gap)

[Incident card path]
  PD incident → PD webhook → PD Teams service → card in mapped channel
  Advance reads chat via ChatMessage.Read(.All)
```

---

## Related files

| File | Purpose |
| --- | --- |
| This folder [6.sh](./6.sh) | Browser bookmarks and echo checklist (no live PD/MS API) |
| [6-pagerduty-teams-only-architecture-follow.txt](./6-pagerduty-teams-only-architecture-follow.txt) | Chat-ready full steps |
| Source runbook | Daily Files `2026-08-25/11-pagerduty-four-agents-teams-only-poc/` |
| Product architecture | Daily Files `2026-08-25/8-pagerduty-ai-agents-detailed/` |
| Slack-primary POCs | Daily Files `2026-08-25/9-pagerduty-four-agents-poc-examples/` |
| Graph permissions | Daily Files `2026-08-25/10-pagerduty-teams-only-permissions/` |
| Teams-only matrix | Daily Files `2026-08-25/10-pagerduty-ai-agents-teams-only/` |
| Who can enable | Daily Files `2026-08-25/13-pagerduty-ai-agents-setup-permissions/` |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/6-pagerduty-teams-only-architecture/` |

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
| AI Agents overview | https://www.pagerduty.com/platform/ai-agents/ |

---

## Commands

UI-first topic. One-liners in [6.sh](./6.sh) open docs or print the checklist. **Do not** call live PagerDuty or Microsoft APIs unless you explicitly ask later.

```bash
open "https://REPLACE_ME.pagerduty.com/ai-settings"
```

Teams bot lines (type in Teams; do not shell them):

```
@PagerDuty linkUser
graphAuth
appconnect
@pagerduty What are some likely root causes?
@PagerDuty advance scribe
@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?
```
