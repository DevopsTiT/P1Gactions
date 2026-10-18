# Dynatrace AI Assistant Steps

## Decision tree

```
Want Dynatrace AI Assistant (like PD AI in chat)?
 Have AI Units / Dynatrace Intelligence + Copilot permission?
   NO  → ask Dynatrace admin for AI license + davis-copilot permission
   YES → two ways to use it:
        A) Interactive: open Davis Copilot / AI Assistant in Dynatrace UI
           → ask about a problem, DQL, RCA ideas
        B) Automated: Workflow Problem trigger
           → Prompt generative AI
           → Slack and/or Teams (Dynatrace connectors)
           → optional 30m still Active → one PagerDuty page
 Post AI text to Slack/Teams without PagerDuty Advance?
   YES → use Dynatrace Slack/Teams Connector (does not need PD /ai Connected)
 Both Slack and Teams?
   YES → OK; same summary to both; one primary talk channel
```

## Short takeaway

| Step group | What you do |
|---|---|
| 0 | Confirm Dynatrace AI / Copilot is licensed and allowed for you |
| 1 | Admin: Slack and/or Teams **Dynatrace** connectors |
| 2 | You: use AI Assistant in the Dynatrace UI (interactive) |
| 3 | Admin/you: build WF-A (problem → AI → Slack + Teams) |
| 4 | Optional: WF-B (still open 30m → one PagerDuty page) |
| 5 | Test with a low-impact problem + test channels |
| 6 | Fact-check AI; do not auto-run prod remediations |

## Summary

Dynatrace AI Assistant (Davis Copilot / Dynatrace Intelligence) helps in two modes: **chat inside Dynatrace**, and **automated summaries** pushed to Slack/Teams by Workflows. It can replace much of PagerDuty Paige-style triage text. It does **not** replace PagerDuty Shift (schedules) or Scribe (meeting transcripts).

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Davis Copilot / AI Assistant | Dynatrace chat helper for problems, DQL, explanations |
| Prompt generative AI | Workflow task that asks Dynatrace Intelligence to write text |
| Slack / Teams Connector | Dynatrace posts to chat (not the PagerDuty bot) |
| Davis problem | Dynatrace grouped alert that triggers workflows |
| AI Units | License budget for generative AI on DPS |

### Dynatrace AI vs PagerDuty AI (quick)

| Job | Dynatrace AI Assistant | PagerDuty AI |
|---|---|---|
| Summarize / next steps | Yes (UI + Workflow) | Paige |
| Post to Slack/Teams | Yes (DT connectors) | Needs PD chat Connected |
| Page on-call | Via workflow → PD Events API | Native |
| Meeting transcript | No | Scribe |
| On-call coverage AI | No | Shift |

---

## Steps (do in order)

### Step 0 — License and permission check

1. Sign in to your Dynatrace environment (SaaS URL for your tenant).
2. Confirm you can open **Davis Copilot / AI Assistant** (name varies slightly by version).
3. If missing or errors on AI:
   - Ask admin for **AI Units** / Dynatrace Intelligence.
   - Ask for permission such as Conversational recommender  
     (`ALLOW davis-copilot:conversations:execute;` or current equivalent).
4. Confirm **Workflows** app is available if you want Slack/Teams automation.

### Step 1 — Admin: connect Slack and/or Teams to Dynatrace

These are **Dynatrace** connectors, not PagerDuty Advance.

**Slack**

1. Create/install the Dynatrace Slack app (per [Slack Connector setup](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/default-workflow-actions/actions/slack/automation-workflows-slack-setup)).
2. Dynatrace → **Settings → Connections** (or Connectors) → **Slack** → paste bot token.
3. Scopes typically include `chat:write`, `channels:read`, `groups:read` (and more if you upload files).
4. Invite the bot into `#test-channel` (private channels need an invite).

**Microsoft Teams**

1. Admin enables the Dynatrace Teams / Microsoft 365 path your tenant uses.
2. Create a Teams connection in Dynatrace Workflows.
3. Pick a **test** Team channel; ensure the bot/app can post.

You may use **both** Slack and Teams.

### Step 2 — You: use AI Assistant interactively (in Dynatrace)

1. Open a **Davis problem** (Problems app) or a Notebook.
2. Open **Davis Copilot / AI Assistant**.
3. Ask plain questions, for example:

```
Summarize this problem in five lines for on-call.
What are the top 3 investigation steps?
Write a short stakeholder status update.
Help me write DQL to count errors for this service in the last hour.
```

4. Paste or reference the problem id / description when the UI asks for context.
5. **Fact-check** before you act (AI can invent details not in the data).

This is the closest interactive twin to `@PagerDuty Catch me up`, but it lives **in Dynatrace**, not in the Slack PD bot.

### Step 3 — Build WF-A: auto AI summary to Slack and/or Teams

Goal: when a problem opens, chat gets an AI “catch me up” without waiting on PagerDuty AI.

1. Dynatrace → **Workflows** → Create (or import template from seq 12).
2. **Trigger:** Problem, state **Active**, **Wait for root cause analysis** On.
3. Optional filters: severity, management zone, tags (Tier-1 only).
4. **Task:** extract problem id, title, description, URL.
5. **Task:** **Prompt generative AI** (Dynatrace Intelligence), for example:

```
Davis problem {{problem_id}} is Active.
Title: {{title}}
Severity: {{severity}}
Context: {{description}}
Problem URL: {{problem_url}}

Plain text only:
1) Five-line summary for on-call
2) Top 3 investigation steps
3) What confirms recovery
Do not invent hosts or metrics not in the context.
```

6. **Task:** Slack **Send message** → test channel (e.g. `#test-channel`).
7. **Task:** Teams **Send message** → test channel (same text).
8. Save; keep inactive until a dry test looks good; then activate.

**Importable template:**  
`../12-dynatrace-ai-slack-teams-workflow-files/12-wfa-ai-notify-slack-teams.workflow.yaml`

### Step 4 — Optional WF-B: still open 30 minutes → one PagerDuty page

1. New workflow (or import WF-B template).
2. Problem trigger, **Minimum duration = 30 minutes**.
3. Condition: still Active (+ not acked if available).
4. Preview PagerDuty payload → post **one** Events API trigger (`dedup_key = dynatrace-{{problem_id}}`).
5. Notify Slack + Teams: “Escalated after 30m”.
6. Use a **test** routing key first; `DRY_RUN` until preview is OK.

**Importable template:**  
`../12-dynatrace-ai-slack-teams-workflow-files/12-wfb-30m-escalate-pagerduty.workflow.yaml`

### Step 5 — Test end-to-end

1. Trigger or wait for a **low-impact test problem**.
2. Check Dynatrace workflow run succeeded.
3. Confirm AI text in Slack and/or Teams.
4. For WF-B: problem still open 31+ min → exactly **one** PD incident; closed early → no page.

### Step 6 — Daily use patterns

| Goal | How |
|---|---|
| Ad-hoc RCA help | Step 2 — AI Assistant on the problem in Dynatrace |
| Auto catch-up in chat | Step 3 — WF-A |
| Escalate if ignored | Step 4 — WF-B |
| Stakeholder update draft | Ask Assistant, or add a generative AI task on problem update |
| Analytics / “why noisy” | Assistant + Notebooks / DQL (partial Insights replacement) |

### Step 7 — Safety

| Rule | Why |
|---|---|
| Test channels and test PD key first | Protects prod on-call |
| Fact-check AI | Can be wrong or incomplete |
| One PD escalation path | Avoid double-page |
| Primary chat for live talk | If Slack + Teams both get posts, pick one home thread |
| Do not expect Scribe/Shift here | Keep those in PagerDuty if needed |

### Step 8 — Health check

| Check | Pass if |
|---|---|
| Copilot / AI Assistant opens | You can ask and get a reply |
| Slack/Teams connection | Test message from a tiny workflow arrives |
| WF-A | AI summary appears on new test problem |
| WF-B (if used) | One PD incident after 30m still open |
| Permissions | No 403 on generative AI task |

---

## Slack vs Teams with Dynatrace AI

| Action | Slack | Teams |
|---|---|---|
| Connector | Dynatrace Slack Connector | Dynatrace Teams / M365 path |
| Where AI text lands | Channel you choose in WF-A | Channel you choose in WF-A |
| Interactive `@bot` like PD | Not the same; use Dynatrace UI Assistant | Same — UI Assistant for interactive ask |
| Invite bot | Needed for private channels | Needed for restricted teams |

PagerDuty `/ai` Slack or Teams **Not Connected** does **not** block this Dynatrace path.

---

## Example prompts (interactive Assistant)

```
Summarize problem P-xxxxxxxx for Slack in five lines.
What should I check first for this failure-rate problem?
Draft a status update for stakeholders (plain text).
Explain this DQL and suggest a safer filter.
```

Prompts file for workflows:  
`../12-dynatrace-ai-slack-teams-workflow-files/12-ai-prompts.txt`

## Result

| Phase | Done when |
|---|---|
| License | Assistant opens; generative AI task runs |
| Connectors | Test posts reach Slack and/or Teams |
| WF-A | Auto AI summary on problem open |
| WF-B (optional) | One PD page after 30m |
| Habit | Interactive asks in Dynatrace; chat gets automated catch-up |

## Data flow map

```
Interactive:
  You → Dynatrace AI Assistant → answer in UI

Automated:
  Davis problem
    → Prompt generative AI
    → Slack and/or Teams (Dynatrace connectors)
    → (optional @30m) one PagerDuty page
```

## Related files

| File | Purpose |
|---|---|
| `16-dynatrace-ai-assistant-steps.md` | This step list (PD seq 15 twin) |
| `../15-pagerduty-ai-slack-teams-steps/` | Matching PagerDuty AI steps |
| `../12-dynatrace-ai-slack-teams-workflow-files/` | WF-A / WF-B yaml + prompts |
| `../11-dynatrace-ai-slack-teams-solution/` | Full solution design |
| `../9-dynatrace-ai-replace-pagerduty-ai/` | What DT AI replaces vs keeps |
| `16.sh` | Git one-liners (not run) |

## Commands

No shell required for daily use. In Dynatrace UI: open Assistant; in Workflows: import/activate WF-A (and WF-B).

Example Assistant asks (copy into Dynatrace AI Assistant):

```
Summarize this problem in five lines for on-call.
What are the top 3 investigation steps?
Draft a plain-text stakeholder status update.
```

See `16.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/16-dynatrace-ai-assistant-steps
git commit -m "dynatrace ai assistant steps like pagerduty guide"
git push
```
