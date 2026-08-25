# PagerDuty Teams Only Permissions

```
Teams-only POC for 4 AI Agents
  ├─ Have PD Admin/Owner + MS Admin?
  │    no → stop; need both to connect app + Graph consent
  │    yes → install PagerDuty Teams app → Authorize PD → Authorize Graph
  ├─ Want Advance / agents in Teams?
  │    yes → AI Settings → Teams Connected → enable optional Advance perms
  │         → ChatMessage.Read / ChatMessage.Read.All
  ├─ Which agent?
  │    SRE → Teams Early Access OK (@pagerduty)
  │    Scribe → Teams chat + Teams meetings OK
  │    Insights → conversational Teams OK; proactive DMs still Slack-first
  │    Shift → Slack-preferential; do not expect full Teams POC
  ├─ Permission model?
  │    POC ease → Application + one-time Admin consent
  │    Strict security → Delegated + each user runs graphAuth
  └─ Least privilege → one Team, one test Service, User.ReadBasic.All not User.Read.All
```

## Short takeaway

| Question | Answer |
|----------|--------|
| Can you run a Teams-only POC? | Yes for SRE (EA), Scribe, Insights chat. Shift is Slack-first. |
| Who enables it? | PD Account Owner / Global Admin / Admin + Microsoft Admin for Graph. |
| Who uses it? | Linked PD ↔ Teams users on teams that have Advance access. |
| Must-have Graph for Advance | `ChatMessage.Read` (delegated) and/or `ChatMessage.Read.All` (application). |
| Admin vs user consent | Application scopes = Admin consent once. Delegated = Admin may pre-approve; each user still runs `graphAuth`. |
| POC least privilege | One Teams team, one PD test service, Application baseline + Advance message read; skip `User.Read.All`. |

## Summary

If you only use Microsoft Teams (no Slack), you can still run a useful PagerDuty Advance POC for **SRE Agent**, **Scribe Agent**, and **Insights Agent** (on-demand chat). **Shift Agent** is documented and priced as Slack-native for conflict DMs and coverage requests, so treat Shift as out of scope or web-only for a Teams-only POC. Permissions split into three layers: PagerDuty roles, Microsoft Teams / Entra admin consent, and per-user account linking.

## Main content

### What this is (beginner)

PagerDuty’s Microsoft Teams app is a bot that posts incident cards and can create chats / meetings. **PagerDuty Advance** is the AI layer on top. For Advance to draft summaries and help agents, Microsoft must allow the app to **read chat messages** in incident conversations. That needs extra Graph permissions beyond basic incident notify.

### Layer 1 — PagerDuty roles

| Role | What they can do | Why you care for POC |
|------|------------------|----------------------|
| Account Owner / Global Admin | Connect Teams tenant, enable Advance chat integration, enable/disable AI agents, set team-level Advance access | Required to turn agents on |
| Admin | Authorize PD ↔ Teams connection; manage integrations | Usually enough to install |
| Manager (base or team) | Map services ↔ Teams channels (in Teams app; web mapping is Admin+) | Maps your test service |
| Responder / any linked user | Ack/resolve in Teams after `linkUser`; ask agents if their PD team has Advance access | Day-to-day POC users |
| No Admin rights | Click **Request to Admin** on an agent | Emails admins to enable that agent |

Team-level Advance access is enforced by **PagerDuty team membership**. It applies to web, Teams, Slack, and API the same way.

### Layer 2 — Microsoft / Teams admin

| Requirement | What it means |
|-------------|----------------|
| Teams Admin enables third-party apps | So users can install the **PagerDuty** (or **PagerDuty EU**) app from the store |
| Microsoft Admin authorizes Graph | Opens consent for Application and/or Delegated permissions |
| Optional: `appconnect` | Non-admin can ask MS Admin to DM the bot `appconnect`, or Admin uses Integrations → Microsoft Teams → Authorize |
| Optional: Online meeting app access policy | PowerShell `New-CsApplicationAccessPolicy` with AppId `05ffe668-5b27-45ff-a64d-b2ed6c475d7a` (US) or `8f79a561-d2f1-4a1e-8092-c2039043a40e` (EU) if application-token meeting create needs it |
| Scribe lobby | Optionally allow the Scribe bot past the Teams meeting lobby for auto-join |

**Hard limit:** PagerDuty cannot install into **private or shared** Teams channels. Dedicated **incident chats** via Incident Workflows are still supported.

### Layer 3 — Hybrid Graph permission model

PagerDuty supports **Application**, **Delegated**, or **hybrid**. For each feature, if Application is granted it uses that; otherwise it falls back to Delegated (user must have completed `graphAuth`).

| Model | Consent | Best for |
|-------|---------|----------|
| Application | One-time **Admin consent** | Automation: create chat, add members, create meetings, read messages for Advance without every user signing Graph |
| Delegated | User runs **`graphAuth`** in PagerDuty bot DM (Admin may still need to allow consent) | Stricter “act as user” security |
| Hybrid (default today) | Both present | Smooth migration; revoke Application only after all actors finished `graphAuth` |

### Graph permissions checklist (from PD docs)

**Dedicated incident chat**

| Scope type | Permission | Required | Least privileged |
|------------|------------|----------|------------------|
| Delegated | `Chat.ReadWrite` | Yes | No |
| Delegated | `TeamsAppInstallation.ReadWriteForChat` | Yes | No |
| Delegated | `User.ReadBasic.All` | Yes | Yes |
| Application | `Chat.Create` | Yes | Yes |
| Application | `ChatMember.ReadWrite.All` | Yes | Yes |
| Application | `TeamsAppInstallation.ReadWriteSelfForChat.All` | Yes | Yes |
| Application | `User.ReadBasic.All` | Optional | Yes (prefer over `User.Read.All`) |
| Application | `User.Read.All` | Optional | No — revoke if present |

**Dedicated channel**

| Scope type | Permission | Required |
|------------|------------|----------|
| Delegated / Application | `Channel.Create` | Yes |

**Conference bridge (Teams meeting)**

| Scope type | Permission | Required | Notes |
|------------|------------|----------|-------|
| Delegated | `OnlineMeetings.ReadWrite` | Yes | |
| Application | `OnlineMeetings.ReadWrite.All` | Yes | May need CsApplicationAccessPolicy |
| Application | `Calendars.ReadWrite` | Optional / required for calendar-event fallback | Fallback does not need the PowerShell policy |

**PagerDuty Advance (message ingest for summaries / agents)**

| Scope type | Permission | Required for Advance |
|------------|------------|----------------------|
| Delegated | `ChatMessage.Read` | Yes |
| Application | `ChatMessage.Read.All` | Yes |

**Org info + OIDC (delegated flow)**

| Scope type | Permission | Required |
|------------|------------|----------|
| Delegated | `User.Read` | Yes |
| Application | `Organization.Read.All` | Yes |
| Delegated | `openid`, `profile`, `email` | Yes for any delegated feature |

Changelog note (2026-02-05): Advance message read is treated as **required** when using Advance; `offline_access` removed from required delegated list.

### Per-agent Teams reality (honest)

| Agent | Teams support | Extra permission / setup | POC note |
|-------|---------------|---------------------------|----------|
| SRE Agent | **Early Access** in MS Teams | Advance Teams connected + agent Enabled; `@pagerduty` + question | Works Teams-only for triage POC; Ops Console path still needs AIOps |
| Scribe Agent | **Supported** for transcript delivery to Teams and joining Teams meetings | Teams integration for auto-add; lobby bypass optional; `@PagerDuty advance scribe` | Strong Teams-only candidate |
| Insights Agent | **GA for conversational** questions in Teams | Advance Teams enabled; agent on (often auto) | Ask `@pagerduty …` in channel or Advance chat. **Proactive recommendation DMs** are still documented as **Slack** DMs to Managers/Admins |
| Shift Agent | **Slack-preferential** | Docs: activates by default with Slack; pricing: “Available in Slack”; notification rules auto-wire to Slack workspaces | Do **not** plan a full Shift POC on Teams-only. Use PD web schedules / Google Calendar extension for conflict detection without Slack DMs, or accept Shift as deferred |

### Admin consent vs user consent (plain English)

```
Microsoft Admin clicks Accept on Graph
  → Application permissions: bot can act as itself (create chat, read messages.All)
  → Delegated permissions: tenant allows the app to ask users for those scopes

Each responder
  → linkUser (maps PD identity ↔ Teams identity) — required for actions
  → graphAuth — only if you rely on Delegated for chat/meeting/message features

If Application already covers that feature
  → users may not need graphAuth for that feature
If you later revoke Application
  → every assignee / workflow actor must have completed graphAuth first
```

### Least privilege for a Teams-only POC

| Do | Why |
|----|-----|
| One standard Teams team + one channel | Avoid org-wide sprawl |
| One PD test Service + escalation to you only | Safe pages |
| Grant Application set for chat + meetings + `Organization.Read.All` | Fewer per-user Graph prompts |
| Grant Advance `ChatMessage.Read.All` (and/or delegated `ChatMessage.Read`) | Required for useful Advance / agent context |
| Prefer `User.ReadBasic.All`; revoke `User.Read.All` | Least profile data |
| Skip `Calendars.ReadWrite` unless meeting create fails | Optional fallback |
| Enable only SRE + Scribe + Insights | Shift waits for Slack or is web-only |
| Scope Advance to one PD team | Team-level access control |
| Use standard channels only | Private/shared unsupported |
| Link POC users with `linkUser` | Actions and auto-add to chats/meetings |

### Enablement steps (order)

1. Teams Admin: allow third-party / PagerDuty app.
2. Install PagerDuty app → Add to a Team → PD Admin **Authorize**.
3. Microsoft Admin **Authorize** Graph (or `appconnect`).
4. PD: Integrations → Microsoft Teams → connect channel ↔ test Service.
5. AI → AI Settings → Assistant and AI Agents → Teams **Connected** → enable optional Advance permissions → toggle Teams **Enabled**.
6. Enable SRE / Scribe / Insights (and Shift only if you later add Slack).
7. Each POC user: `linkUser` (and `graphAuth` if Delegated-only).
8. Optional: PowerShell app access policy for meetings; Scribe lobby bypass.

### Common mistakes

| Mistake | Fix |
|---------|-----|
| “UPDATE AVAILABLE” on tenant | MS Admin re-consent missing Graph scopes |
| Agents silent in Teams | Advance Teams not Enabled; optional Advance perms missing; wrong PD team access |
| Cannot create meeting/chat | Missing OnlineMeetings/Chat scopes or user never ran `graphAuth` under Delegated |
| Scribe in lobby forever | Adjust Teams lobby / admit policy |
| Expect Shift DMs in Teams | Not documented; use Slack or web |
| Expect Insights proactive DMs in Teams | Docs still say Slack DMs; use on-demand chat in Teams |
| Private channel mapping | Not supported |

## Data flow map

```
[Microsoft Admin] --Admin consent--> [Entra / Graph permissions]
[PD Admin] --Authorize--> [PagerDuty Teams app] --Bot Kit--> [Teams channel / DM]
[Responder] --linkUser--> [PD user ↔ Teams user]
[Incident] --> [PD webhook] --> [PD Teams service] --> [Incident card in channel]
[Advance / Agents] --ChatMessage.Read(.All)--> [incident chat history]
                + PD log entries / Scribe transcript
                --> [SRE triage | Insights answer | status / wrap-up]
[Scribe bot] --> [Teams meeting] --> transcript --> [Teams channel + PIR context]
[Shift] ...... Slack DMs / Slack Advance (limited on Teams-only path)
```

## Related files

| File | Purpose |
|------|---------|
| [10.sh](10.sh) | One-liner references (docs URLs + PowerShell policy stubs) |
| [10-pagerduty-teams-only-permissions-follow.txt](10-pagerduty-teams-only-permissions-follow.txt) | Full EN/中文 checklist for parent chat |
| Official: [Microsoft Teams Integration](https://support.pagerduty.com/main/docs/microsoft-teams) | Graph permission table |
| Official: [Permission Changelog](https://support.pagerduty.com/main/docs/microsoft-teams-permission-changelog) | Scope changes |
| Official: [PagerDuty Advance](https://support.pagerduty.com/main/docs/pagerduty-advance) | Connect Advance to Teams |
| Official: [SRE](https://support.pagerduty.com/main/docs/sre-agent) / [Scribe](https://support.pagerduty.com/main/docs/scribe-agent) / [Shift](https://support.pagerduty.com/main/docs/shift-agent) / [Insights](https://support.pagerduty.com/main/docs/insights-agent) | Per-agent Teams notes |

## Commands

See [10.sh](/Users/k/Learnings/AIProject/CursorFiles/Daily%20Files/2026-08-25/10-pagerduty-teams-only-permissions/10.sh). Do not auto-run; review and run yourself.

Teams bot commands (type in Teams):

```
@PagerDuty linkUser
graphAuth
appconnect
@PagerDuty advance <question>
@PagerDuty advance scribe
@pagerduty <Insights or SRE question>
```
