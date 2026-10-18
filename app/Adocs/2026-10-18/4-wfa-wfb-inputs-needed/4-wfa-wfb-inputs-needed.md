# WFA WFB Inputs Needed

## Decision tree

```
Import WF-A / WF-B YAML
  Missing Slack/Teams connection?
    → Create Dynatrace Hub connection first; invite bot to channel
  Missing AI summary?
    → Add “Prompt generative AI” task; paste prompt from 12-ai-prompts.txt
  Missing PD page at 30m?
    → Set Minimum duration 30m + PD_ROUTING_KEY + DRY_RUN false (after test)
  Ready to go live?
    → Test channels/keys OK → set isActive true
```

## Short takeaway

| Workflow | You must input | Already filled by template |
|---|---|---|
| **WF-A** | Slack connection + channel; Teams connection + channel; optional AI prompt task | Problem extract script; message builder; trigger filter draft |
| **WF-B** | Minimum duration **30m**; `PD_ROUTING_KEY`; `DRY_RUN` flag | Preview + POST script; `dedup_key` pattern; categories draft |
| Both | Which problem categories; when to activate | `isActive: false` until you turn on |

## Summary

These YAML files are **templates with no secrets**. After import you bind chat connections (WF-A), set the 30-minute wait and PagerDuty routing key (WF-B), and optionally add the generative AI prompt. Dynatrace already fills problem id, title, description, and URL from the Davis event.

## Investigation

### What you do not type (auto from the event)

| Field | Where it comes from |
|---|---|
| `problem_id` | Davis problem display id |
| `title` | Problem name |
| `description` | Problem description |
| `severity` / category | Event category |
| `problem_url` | Built from your Dynatrace environment URL + problem id |

---

## WF-A — what you must input

**File:** `12-wfa-ai-notify-slack-teams.workflow.yaml`  
**Job:** Problem opens → build message → send to Slack and/or Teams.

### Required (or chat will not get posts)

| # | What to input | Where in UI | Example / notes |
|---|---|---|---|
| 1 | **Slack connection** | New task `notify-slack` → Connection | Dynatrace Slack Hub connection (bot token already stored there) |
| 2 | **Slack channel** | Same task → Channel | `#test-channel` first; invite the Dynatrace Slack app into the channel |
| 3 | **Teams connection** | New task `notify-teams` → Connection | Dynatrace Teams Hub connection |
| 4 | **Teams channel** | Same task → Channel / team | Your test Teams channel |
| 5 | **Message field** | Both notify tasks | Use `{{ result("build-chat-message").chat_message }}` or the `message` from `emit-chat-payload` |

The YAML only has a **placeholder** task (`emit-chat-payload`). You must **add** real Slack/Teams send tasks in the Workflows UI (commented hints are in the YAML).

### Strongly recommended (for real AI text)

| # | What to input | Where | Example / notes |
|---|---|---|---|
| 6 | **Prompt generative AI** task | Between `extract-problem` and `build-chat-message` | Hub action “Prompt generative AI” / Copilot |
| 7 | **Prompt text** | That task’s Prompt field | Copy from `12-ai-prompts.txt` (WF-A triage section) |
| 8 | **Map AI output → `ai_summary`** | Adjust `extract-problem` or insert a small JS step | If `ai_summary` stays empty, chat gets the non-AI template body |

### Optional / policy (edit before prod)

| # | What to input | Where | Notes |
|---|---|---|---|
| 9 | **Problem categories** | Trigger → categories | Template has error, resource, slowdown, availability = true; custom = false |
| 10 | **Entity tags filter** | Trigger → `entityTags` | Empty `{}` = all; narrow for prod if needed |
| 11 | **`filterQuery`** | Trigger | Default: `CREATED` + `ACTIVE` Davis problem |
| 12 | **Activate workflow** | Trigger `isActive` | Keep **false** until Slack/Teams test OK → then **true** |
| 13 | **Hourly execution limit** | Workflow settings | Default `200`; raise only if needed |

### WF-A checklist (copy)

```
[ ] Dynatrace Slack connection exists
[ ] Bot invited to #test-channel (or your channel)
[ ] Dynatrace Teams connection exists
[ ] Test Teams channel selected
[ ] notify-slack + notify-teams tasks added (message = chat_message)
[ ] Optional: Prompt generative AI + prompt from 12-ai-prompts.txt
[ ] Optional: ai_summary wired into build-chat-message
[ ] Categories / tags OK for your scope
[ ] Test run → then set isActive = true
```

---

## WF-B — what you must input

**File:** `12-wfb-30m-escalate-pagerduty.workflow.yaml`  
**Job:** Still Active after 30 minutes → one PagerDuty page.

### Required

| # | What to input | Where in UI / script | Example / notes |
|---|---|---|---|
| 1 | **Minimum duration = 30 minutes** | Problem trigger settings (UI) | **Must set after import** — this is the “wait 30m” control |
| 2 | **`PD_ROUTING_KEY`** | In both `preview-pagerduty` and `trigger-pagerduty` scripts (or workflow secret) | PagerDuty Events API **integration / routing key** for a **test** service that pages only you |
| 3 | **`DRY_RUN`** | Same two scripts: `const DRY_RUN = true/false` | Keep **`true`** until preview looks good; then **`false`** to really POST |

Set the **same** `PD_ROUTING_KEY` and **same** `DRY_RUN` value in **both** script tasks (preview and trigger), or use one workflow secret and read it in both.

### Strongly recommended

| # | What to input | Where | Notes |
|---|---|---|---|
| 4 | **Network allowlist** | Tenant / outbound allowlist | Allow `events.pagerduty.com` if your Dynatrace env requires it |
| 5 | **Test PD service** | PagerDuty | Escalation policy → only you; not prod on-call |
| 6 | Optional **Slack/Teams “escalated” note** | New tasks after `trigger-pagerduty` | Reuse WF-A connections; short “paged after 30m” text |

### Optional AI blurb (not in YAML by default)

| # | What to input | Where | Notes |
|---|---|---|---|
| 7 | Escalate prompt | Optional generative AI task | Text from `12-ai-prompts.txt` (WF-B section); can go into PD `custom_details` or chat |

### Optional / policy

| # | What to input | Where | Notes |
|---|---|---|---|
| 8 | **Problem categories** | Trigger | Same idea as WF-A |
| 9 | **Entity tags** | Trigger | Narrow scope for prod |
| 10 | **`filterQuery`** | Trigger | Default: Davis problem `ACTIVE` (duration handled by Minimum duration) |
| 11 | **PD severity / summary prefix** | Script (`severity`, `[DT 30m]`) | Defaults are fine; change if your PD service expects different severity |
| 12 | **Activate workflow** | Trigger `isActive` | Keep **false** until `DRY_RUN` test OK → then **true** |

### WF-B checklist (copy)

```
[ ] Minimum duration = 30 minutes on trigger
[ ] PD_ROUTING_KEY set (test service only)
[ ] DRY_RUN = true → run once → check preview / would_post_dedup_key
[ ] events.pagerduty.com allowed if needed
[ ] DRY_RUN = false only after preview OK
[ ] Confirm one incident: dedup_key = dynatrace-<problem_id>
[ ] Optional: Slack/Teams escalate note
[ ] Set isActive = true
```

---

## Shared inputs (both workflows)

| Input | Why |
|---|---|
| Dynatrace environment with **Workflows** app | Templates use `dynatrace.automations` |
| **AI Units / Copilot** (if you add Prompt generative AI) | Without license, skip AI task; template message still works |
| Agreement: **one** PD path | Do not also create a second PD incident for the same problem |
| Test-first policy | Test channel + test routing key before prod |

## Result

| Done | Evidence |
|---|---|
| WF-A inputs complete | Test problem → message appears in Slack and/or Teams |
| WF-B inputs complete | After 30m (or test duration), preview ready; with DRY_RUN false, one PD incident |
| Safe | No prod routing key in git; DRY_RUN was true on first runs |

## Data flow map

```
You input (UI / secrets)
  WF-A: Slack conn+channel, Teams conn+channel, optional AI prompt
  WF-B: 30m duration, PD_ROUTING_KEY, DRY_RUN
        │
Davis problem event (auto fields)
  → extract-problem
  → WF-A: build message → Slack/Teams
  → WF-B @30m: preview → POST Events API (if DRY_RUN false)
```

## Related files

| File | Purpose |
|---|---|
| `4-wfa-wfb-inputs-needed.md` | This input guide |
| `../2-dt-ai-replace-pd-all-files/12-wfa-ai-notify-slack-teams.workflow.yaml` | WF-A template |
| `../2-dt-ai-replace-pd-all-files/12-wfb-30m-escalate-pagerduty.workflow.yaml` | WF-B template |
| `../2-dt-ai-replace-pd-all-files/12-ai-prompts.txt` | Prompt text to paste |
| `../2-dt-ai-replace-pd-all-files/12-pagerduty-trigger.payload.json` | PD body shape |
| `4.sh` | Git one-liners (not run) |

## Commands

See `4.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-18/4-wfa-wfb-inputs-needed
git commit -m "wfa wfb inputs needed checklist"
git push
```
