# PagerDuty AI Agent On Slack

## Decision tree

```
Want PagerDuty AI in Slack?
 Have PagerDuty Advance / PD Reliability Platform AI?
   NO  → ask Sales / admin for Advance; agents stay dark
   YES → Admin maps Slack workspace (Integrations → Extensions → Slack)
        → Link your PD user to Slack
        → AI → AI Settings → Assistant and AI Agents Configuration
        → Chat Integrations: Slack Connected (or Update required → optional scopes)
        → Toggle Slack On
        → Enable agents: Paige/SRE, Scribe, Shift, Insights
        → Test in a TEST service channel — not prod on-call
 Slack shows Not Connected?
   → Install Slack | PagerDuty integration first
 Slack shows Update required?
   → Approve optional scopes (channel history) for better AI summaries
 Old "PagerDuty Advance" Slack app still installed?
   → Use the main PagerDuty Slack app; uninstall Advance app after scopes work
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it? | PagerDuty AI (also called **Advance**) chats and agents inside the **PagerDuty Slack app**. |
| Who can turn it on? | Admin, Global Admin, or Account Owner in PagerDuty; Slack workspace admin for app install. |
| Where do you enable it? | **AI → AI Settings → Assistant and AI Agents Configuration**. |
| How do you talk to it? | `@PagerDuty` in a channel, Slack side panel, or agent commands like `/pd scribe`. |
| Safe first test? | Dedicated test Service whose escalation pages only you. |

## Summary

PagerDuty AI on Slack is not a separate mystery bot. You connect the normal PagerDuty Slack app, turn Slack on under AI Settings, enable the agents you need, link your user, then ask questions in an incident channel. Fact-check every AI answer before you act on production.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| PagerDuty AI / Advance | Paid AI add-on (or included on Reliability Platform). | Without it, agent toggles do nothing. |
| Slack app | The official PagerDuty app in your Slack workspace. | Where `@PagerDuty` and `/pd` commands live. |
| AI Assistant | Chatbot that summarizes and answers incident questions. | Main "ask a question" surface. |
| AI Agent | Purpose-built helper (SRE/Paige, Scribe, Shift, Insights). | Each agent does a different job. |
| Optional scopes | Extra Slack permissions (channel history, etc.). | Makes summaries use Slack talk, not only PD notes. |
| Linked account | Your Slack user tied to your PagerDuty user. | Needed for DMs, Shift, and some agent actions. |
| Incident channel | Slack channel tied to a service or an open incident. | Best place to ask incident questions. |

### What you get in Slack

| Piece | What it does in Slack |
|---|---|
| AI Assistant | Answer `@PagerDuty …` about the incident or ops topics |
| Paige (SRE Agent) | Triage help, root-cause ideas, runbook-guided next steps |
| Scribe Agent | Join the bridge, transcript, meeting summary (`/pd scribe`) |
| Shift Agent | On-call coverage / OOO help (needs linked user) |
| Insights Agent | Ops analytics questions; some proactive DMs via Slack |
| Slack side panel | Private 1:1 chat with the Assistant (paid Slack plans) |
| Proactive messages | Optional auto insights / catch-up when people join |

### Roles needed

| Place | Role |
|---|---|
| PagerDuty | Admin, Global Admin, or Account Owner for first AI + Slack mapping |
| Slack | Workspace admin or owner to install / reauthorize the app |
| You | Linked PD ↔ Slack user to use agents fully |

---

## Part A — One-time setup (admin)

### Step 1 — Map Slack to PagerDuty

1. In PagerDuty: **Integrations → Extensions**.
2. Open the **Slack** tile.
3. Click **Add Workspace**, pick the correct Slack workspace, click **Allow**.
4. Confirm the PagerDuty bot is in the workspace and `/pd` commands work.

Official guide: [Slack integration](https://docs.pagerduty.com/integrations/slack-integration-guide)

### Step 2 — Link your personal accounts

1. In PagerDuty Slack config, if you see **Link Account**, click it.
2. Or in Slack run `/pd` flows that ask you to link.
3. Confirm your Slack identity matches the PagerDuty user you on-call as.

### Step 3 — Connect PagerDuty AI to Slack

1. PagerDuty web → **AI → AI Settings**.
2. Tab **Assistant and AI Agents Configuration**.
3. Under **Chat Integrations**, check Slack:

| Status | What to do |
|---|---|
| Not Connected | Install / finish the Slack \| PagerDuty integration (Step 1). |
| Update required | Enable **optional scopes** so AI can use channel conversation (not threads). |
| Connected | Good. |

4. Toggle **Slack** to **On**.
5. Optional: **Configure** proactive messages:

| Option | Effect |
|---|---|
| Proactive Incident Insights | Auto context / symptoms / investigation ideas when an incident triggers |
| Proactive Incident Summarization | Private catch-up for new channel members; PIR-style post after resolve |

Official guide: [PagerDuty AI](https://support.pagerduty.com/main/docs/pagerduty-advance)

### Step 4 — Enable each AI agent

Still under **Assistant and AI Agents Configuration** → **AI Agents**:

| Agent | Turn on for |
|---|---|
| Paige (SRE Agent) | Live triage in Slack / incident UI |
| Scribe Agent | Bridge notes and transcripts |
| Shift Agent | Coverage and schedule help |
| Insights Agent | Analytics questions |

If you lack permission, click **Request to Admin**.

Optional later: SRE connectors (Grafana, Datadog, GitHub, Confluence, …) under the SRE Agent settings. Dynatrace usually **creates** the PD incident; it is not always listed as an SRE "connector."

### Step 5 — Optional Slack side panel

1. Needs a **paid** Slack plan and extra scopes (admin may reauthorize).
2. In Slack: **Preferences → Navigation**.
3. Under **App agents & assistants**, check **PagerDuty**.
4. Or ask a Slack admin to enable it workspace-wide.

### Step 6 — Migrate off old Advance Slack app

The separate **PagerDuty Advance** Slack app is retired. Use the main **PagerDuty** Slack app, enable optional scopes for AI, then uninstall the old Advance app if it is still installed.

---

## Part B — Connect a channel (team / service)

1. In a Slack channel, run `/pd connect`.
2. Choose your PagerDuty account.
3. Connect a **service** or **team** to that channel.
4. Pick notification style:

| Style | Meaning |
|---|---|
| Responder | Full actions (ack, resolve, …) |
| Stakeholder | Updates without full responder controls |

Use a **test** service for first AI demos.

---

## Part C — How to use agents in Slack

### AI Assistant (general ask)

1. Open the Slack channel linked to the incident (or any channel for non-incident questions).
2. Mention the bot:

```
@PagerDuty What is the current status of this incident?
@PagerDuty Catch me up
@PagerDuty What are likely root causes?
```

3. Or open the **PagerDuty AI side panel** (top right) for a private chat that still understands the channel you are viewing.

### Paige / SRE Agent

| Action | How |
|---|---|
| Triage | Click **SRE Agent Triage** if shown, or ask `@PagerDuty …` |
| Runbook | Upload / update a small `.md` or `.txt` runbook when prompted |
| Past incidents | Ask `@PagerDuty Analyze past incidents` |
| Remediation | Read the suggestion; **approve or decline** — do not auto-run on prod |

### Scribe Agent

1. Be in an incident-linked channel.
2. Run `/pd scribe`, or click **Add Scribe Agent to meeting** when a conference URL exists.
3. Confirm the meeting URL (include passcode).
4. Click **Add**.
5. Or leave **auto-launch** on so Scribe joins incident meetings automatically (toggle under Scribe **Configure**).

### Shift Agent

Ask coverage questions in Slack after your accounts are linked (for example OOO conflict, who can cover). Prefer a test schedule first.

### Insights Agent

Ask analytics-style questions with `@PagerDuty …`. Some weekly / proactive nudges are Slack-app DMs and need a linked user.

---

## Part D — Safety and checks

| Rule | Why |
|---|---|
| Test Service first | Avoids paging real on-call |
| Fact-check AI output | Generative AI can be wrong |
| Confirm before remediations | Humans own blast radius |
| Optional scopes = Slack history | Improves summaries; know what you share with PD AI |
| Threads not included | Even with optional scopes, thread replies are not used |

### Quick health check

| Check | Pass if |
|---|---|
| `/pd` works | Slash commands respond |
| AI Settings Slack = On | Toggle is enabled |
| Agent Enabled | SRE / Scribe / … show Enabled |
| `@PagerDuty` reply | Bot answers in the test channel |
| Side panel (optional) | Private chat opens |

## Result

| Phase | Do |
|---|---|
| Admin once | Map Slack → link users → AI Settings Slack On → enable agents |
| Team | `/pd connect` test service to a channel |
| Daily use | `@PagerDuty` asks; `/pd scribe` for bridges; side panel for private help |
| Never skip | Test service + human confirm before production actions |

## Data flow map

```
PagerDuty incident / service
  → Slack channel (bot posts updates)
  → Human: @PagerDuty / /pd scribe / side panel
  → PagerDuty AI (Advance)
       uses: incident log, notes, optional Slack channel history,
             Scribe transcript, optional connectors
  → Answer / triage / summary posted in Slack (or private panel)
  → Human fact-checks → ack / resolve / runbook / remediation
```

## Related files

| File | Purpose |
|---|---|
| `4-pagerduty-ai-agent-slack-instructions.md` | This guide |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Doc sources |
| `2-result.md` | Checklist |
| `3-glossary.md` | Terms |
| `4.sh` | Git one-liners (not run) |
| 2026-08-25 seq 9 | Four-agent Slack POC examples |
| 2026-08-25 seq 10 | Teams-only variant |
| PagerDuty docs | AI settings, Slack integration, Scribe |

## Commands

Slack commands (you type these in Slack; not shell):

```
/pd connect
/pd scribe
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
@PagerDuty Analyze past incidents
```

See `4.sh` for git one-liners only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/4-pagerduty-ai-agent-slack-instructions
git commit -m "pagerduty ai agent slack instructions"
git push
```
