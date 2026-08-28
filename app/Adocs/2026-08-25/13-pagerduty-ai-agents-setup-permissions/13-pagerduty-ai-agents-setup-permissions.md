# PagerDuty AI Agents Setup Permissions

```
Want to turn on all 4 AI Agents (SRE / Scribe / Shift / Insights)
  ├─ Have PagerDuty Advance (add-on or AI Actions)?
  │    no → Sales / trial first; agents stay unavailable
  │    yes → continue
  ├─ Your PD base role?
  │    Account Owner or Global Admin → AI → AI Settings → enable agents
  │    Admin → can connect Slack/Teams; agent toggle may need Owner/Global Admin
  │    Manager / Responder → cannot enable; click Request to Admin
  ├─ Team Advance access on?
  │    Access tab → your team toggled on (default: all teams on)
  ├─ Chat surface?
  │    Slack → workspace Admin/Owner install + optional Advance scopes
  │    Teams → MS Admin Graph consent (see seq 10) + PD Admin connect
  └─ Using agents day-to-day?
       any linked user on an Advance-enabled team → chat / Ops Console / incident UI
```

## Short takeaway

| Question | Answer |
|----------|--------|
| Who turns agents on? | **Account Owner** or **Global Admin** in **AI → AI Settings** (official Advance doc). |
| Who connects Slack/Teams for Advance? | **Admin**, **Global Admin**, or **Account Owner**. |
| Who uses agents after enable? | Any linked user on a team with Advance access (Responder is enough). |
| Need a REST API token? | **No** for product agents UI. Tokens are for custom API POCs (seq 7). |
| Same for all 4 agents? | Same enable role; each agent has small extras (Slack scopes, calendar, AIOps, etc.). |

## Summary

PagerDuty’s four product AI agents live under **PagerDuty Advance**. Turning them on is an admin job in the web UI. Day-to-day responders only need a linked chat account and membership on a team that has Advance access. You do **not** mint PagerDuty REST API tokens to enable SRE, Scribe, Shift, or Insights in the product.

## Main content

### What this is (beginner)

| Term | What it means | Why you care |
|------|---------------|--------------|
| PagerDuty Advance | Paid AI platform (add-on or AI Actions credits on Professional / Business / Enterprise) | Without Advance, the four agents are not available |
| AI Settings | Web page: **AI → AI Settings → Assistant and AI Agents Configuration** | Where you connect chat and toggle agents |
| Base role | Your account-wide role (Owner, Global Admin, Admin, Manager, Responder, …) | Decides who can **enable** vs only **use** |
| Team Advance access | Per-team on/off under **AI Settings → Access** | Even if agents are on, users outside allowed teams cannot invoke Advance |

Official: [PagerDuty Advance](https://support.pagerduty.com/main/docs/pagerduty-advance)

### 1) PagerDuty account roles — who can enable AI agents

| Base role | Connect Slack / Teams for Advance | Enable / disable the 4 AI agents | Manage Advance account settings | Use agents after they are on |
|-----------|-----------------------------------|----------------------------------|---------------------------------|------------------------------|
| Account Owner | Yes | Yes | Yes | Yes |
| Global Admin | Yes | Yes | Yes | Yes |
| Admin | Yes (required for initial chat connect) | Often listed on individual agent pages; Advance “enable agents” section names Owner / Global Admin | View; may need Owner / Global Admin for full settings | Yes |
| Manager | Map channels / services after workspace is linked | No — use **Request to Admin** | View only | Yes (if team has Advance access) |
| Responder | No | No — use **Request to Admin** | View only | Yes (if team has Advance access) |
| Stakeholder / limited roles | No | No | Usually no | Limited; not the setup path |

**Practical rule for beginners**

| Goal | Ask for this person |
|------|---------------------|
| Turn on all four agents | Account Owner or Global Admin |
| First-time Slack or Teams ↔ PagerDuty map | Admin or higher |
| Just use agents on-call | Responder (or higher) + linked chat user + Advance team access |

If you lack enable rights: open the agent card and click **Request to Admin** (emails admins).

### 2) PagerDuty Advance entitlement and team access

| Check | What it means | Why you care |
|-------|---------------|--------------|
| Advance on the account | Add-on or AI Actions credits / trial | Agents will not work without it |
| Plans | Professional, Business, Enterprise for Incident Management | Confirm with Sales if AI Settings is empty |
| AI Actions budget | SRE and Scribe consume Actions; Shift and Insights do not (per PD Advance pricing table) | Empty credits block Scribe / SRE usage |
| Team Access tab | Toggle Advance per PagerDuty team | Default is **all teams on**; turn teams off for gradual rollout |
| Enforcement | Based on the user’s **team membership** | Same rule for web, Slack, Teams, and API |

Path: **AI → AI Settings → Access** → toggle teams.

### 3) Per-agent needs (same enable role; different extras)

| Agent | Who enables in AI Settings | Extra setup beyond the shared toggle | Who can use it |
|-------|----------------------------|--------------------------------------|----------------|
| SRE Agent | Owner / Global Admin (same AI Settings) | Connectors optional; Ops Console needs **AIOps + Advance**; Slack may need reauthorize for extra scopes; Teams is Early Access | Linked users on Advance-enabled teams |
| Scribe Agent | Admin or Account Owner (Scribe doc); same AI Settings toggle | Zoom captions / Teams lobby / Google Workspace as needed; optional auto-launch; needs available **AI Actions** | Any user with linked PD ↔ chat can add Scribe to a meeting |
| Shift Agent | Same AI Settings (often on with Advance + Slack) | Schedules on **escalation Level 1**; Google Calendar Extension = Admin or Account Owner | Any Advance user after permissions accepted |
| Insights Agent | Same AI Settings (often auto-on with Advance) | Link Slack for proactive DMs; Managers / Admins / Owner get weekly tips (Business+ for Team Managers) | Any linked user can ask in public chat |

Shared enable path for all four:

1. **AI → AI Settings → Assistant and AI Agents Configuration**
2. Under **AI Agents**, toggle each agent to **Enabled**
3. Follow that agent’s guide for connectors / calendar / meeting platforms

Docs: [SRE](https://support.pagerduty.com/main/docs/sre-agent) · [Scribe](https://support.pagerduty.com/main/docs/scribe-agent) · [Shift](https://support.pagerduty.com/main/docs/shift-agent) · [Insights](https://support.pagerduty.com/main/docs/insights-agent)

### 4) Slack permissions / scopes (if using Slack)

| Layer | Who | What they must do |
|-------|-----|-------------------|
| Slack workspace | Workspace **Admin** or **Owner** | Approve PagerDuty app install / updates |
| PagerDuty | Admin / Global Admin / Account Owner | Map PD account → Slack; toggle Slack Connected in AI Settings |
| Optional Advance scopes | PD Admin reauthorize when Slack shows **Update required** | Improves catch-me-up / wrap-me-up / proactive messages from channel history |
| Side panel | Slack Admin may enable App agents & assistants for everyone | Needs extra scopes; PD Admin may reauthorize |

**Core bot scopes that matter for Advance / agents (examples from Slack Integration Guide)**

| Scope | What it is for |
|-------|----------------|
| `app_mentions:read` | Respond when someone `@pagerduty` |
| `assistant:write` | Act as Slack AI / Advance assistant |
| `chat:write` | Post as `@pagerduty` |
| `commands` | Slash commands (for example `/pd scribe`) |
| `im:history` | Read DMs to the PagerDuty app |
| Optional: `channels:history`, `groups:history`, `files:read`, `reactions:read`, `reactions:write` | Richer summaries from channel history / files (opt-in / Update required) |

Full table: [Slack Integration Guide](https://support.pagerduty.com/main/docs/slack-integration-guide) · changelog: [Slack Permission Changelog](https://support.pagerduty.com/main/docs/slack-permission-changelog)

**User linking:** each responder should link PagerDuty ↔ Slack so Shift / Insights DMs and Scribe add work correctly.

### 5) Microsoft Teams / Graph (if using Teams) — PD-side focus

Do **not** reinvent the full Graph matrix here. Use seq **10** for Application vs Delegated scopes.

| PD-side need | Detail |
|--------------|--------|
| Who connects Teams in AI Settings | Admin / Global Admin / Account Owner |
| Who consents Graph | Microsoft Admin (tenant) |
| Advance message read (must-have for richer Advance) | `ChatMessage.Read` (delegated) and/or `ChatMessage.Read.All` (application) |
| Full Graph checklist | See Daily File **10-pagerduty-teams-only-permissions** |
| Teams-only agent reality | SRE (EA), Scribe, Insights chat OK; Shift is Slack-first |

Pointer: `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-25/10-pagerduty-teams-only-permissions/10-pagerduty-teams-only-permissions.md`

### 6) API tokens — product agents vs custom POC

| Path | Need REST API token? | Why |
|------|----------------------|-----|
| Enable SRE / Scribe / Shift / Insights in AI Settings | **No** | Product UI + OAuth chat apps |
| Use agents in Slack / Teams / Ops Console | **No** | Logged-in user + Advance entitlement |
| Custom “AI agent” that calls Events/REST yourself (seq 7) | **Yes** | Your code talks to `api.pagerduty.com` / Events API |

Contrast: seq **7** (`7-pagerduty-ai-agent-poc`) is a DIY API sandbox. That is **not** how you turn on the four product agents.

### 7) Checklists

#### A) To turn on all 4 (setup)

| # | Check | Done when |
|---|-------|-----------|
| 1 | Account has PagerDuty Advance (or trial / AI Actions) | AI Settings shows agents |
| 2 | You are Account Owner or Global Admin (preferred) | Agent toggles are editable |
| 3 | Slack and/or Teams Connected under Chat Integrations | Status shows Connected (not Not Connected) |
| 4 | Slack workspace Admin approved app / optional scopes if Update required | Mentions and Advance features work |
| 5 | Teams: MS Admin Graph consent if using Teams | See seq 10 |
| 6 | Toggle **SRE**, **Scribe**, **Shift**, **Insights** to Enabled | All four switches on |
| 7 | Access tab: POC teams left enabled | Test users are on those teams |
| 8 | Agent extras: Level-1 schedules (Shift), meeting platform (Scribe), optional SRE connectors | Happy-path POC works |

#### B) To use as a responder (day-to-day)

| # | Check | Done when |
|---|-------|-----------|
| 1 | Agents already enabled by admin | You do not need Owner rights |
| 2 | You are on a team with Advance access | Chat / UI does not refuse Advance |
| 3 | PagerDuty ↔ Slack or Teams account linked | Bot recognizes you |
| 4 | You can open the incident channel or Ops Console | Ask `@pagerduty` / use agent buttons |
| 5 | No REST API token created for this | Expected for product agents |

## Data flow map

```
[Account Owner / Global Admin]
        |
        v
[AI Settings: Chat Connected + Agents Enabled + Team Access]
        |
        +-- Slack workspace Admin (scopes) ----+
        |                                      |
        +-- MS Admin (Graph — see seq 10) -----+
                                               |
                                               v
                         [Responder on Advance-enabled team]
                                               |
                    +--------------------------+--------------------------+
                    |                          |                          |
                    v                          v                          v
             [SRE triage]              [Scribe on bridge]           [Shift / Insights]
             Slack/Teams/UI              Zoom/Teams/Meet              Slack (Shift-first)

Custom API POC (seq 7): Events key + REST token → YOUR code
Product agents: NO REST token required for enable/use in UI
```

## Related files

| File | Role |
|------|------|
| [13-pagerduty-ai-agents-setup-permissions.md](./13-pagerduty-ai-agents-setup-permissions.md) | This answer |
| [13-pagerduty-ai-agents-setup-permissions-follow.txt](./13-pagerduty-ai-agents-setup-permissions-follow.txt) | Chat-ready EN + 中文 checklist |
| [13.sh](./13.sh) | Doc / path one-liners (no live API) |
| Seq 7 | Custom API POC (tokens required) |
| Seq 8 | Four agents detailed behavior |
| Seq 10 | Teams-only Graph permissions |

## Commands

See [`13.sh`](./13.sh). These only open docs or list local paths. They do **not** call PagerDuty APIs. Review and run yourself if useful.
