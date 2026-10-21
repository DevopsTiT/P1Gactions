# WFA WFB Fill In Checklist

## Decision tree

```
Import WF-A / WF-B templates
  WF-A chat empty?
    → Add notify-slack / notify-teams; fill Connection + Channel + Message
  Want real AI text?
    → Add Prompt generative AI; paste prompt; map ai_summary
  WF-B never pages?
    → Set Minimum duration 30m + PD_ROUTING_KEY + DRY_RUN false (after test)
  Ready for prod?
    → Test OK → set trigger isActive true
```

## Short takeaway

| Workflow | Must fill | Optional | Already done by template |
|---|---|---|---|
| **WF-A** | Slack/Teams **Connection**, **Channel**, **Message** expression; add send tasks in UI | AI prompt task; categories/tags | Extract + build message; trigger draft off |
| **WF-B** | Trigger **Minimum duration = 30m**; **PD_ROUTING_KEY**; **DRY_RUN** | Escalate chat note; severity text | Preview/POST scripts; dedup_key pattern |

## Summary

These YAMLs are templates with **no secrets**. Dynatrace fills problem id/title/description/URL from the event. You bind chat connections (WF-A), set the 30-minute wait and PagerDuty routing key (WF-B), then activate after tests.

## Investigation

### Auto (do not type)

| Field | Source |
|---|---|
| problem_id, title, description, severity | Davis problem event |
| problem_url | Built from Dynatrace env URL |

---

## WF-A — fill these to complete

**File:** `12-wfa-ai-notify-slack-teams.workflow.yaml`  
**Job:** Problem opens → chat message → Slack and/or Teams.

### Required (or chat gets no posts)

| # | Fill in | Where | Example |
|---|---|---|---|
| 1 | **Slack connection** | New UI task `notify-slack` → Connection | Named Dynatrace Slack Hub connection |
| 2 | **Slack channel** | Same task → Channel | `#test-channel` (invite Dynatrace bot) |
| 3 | **Teams connection** | New UI task `notify-teams` → Connection | Named Dynatrace Teams Hub connection |
| 4 | **Teams channel** | Same task → Channel / team | Test Teams channel |
| 5 | **Message** | Both notify tasks | `{{ result("build-chat-message").chat_message }}` |

YAML only has placeholder `emit-chat-payload`. You **must add** real Slack/Teams send tasks after import.

Slack-only or Teams-only: fill that side; skip the other notify task.

### Recommended for AI summary

| # | Fill in | Where |
|---|---|---|
| 6 | **Prompt generative AI** task | Between `extract-problem` and `build-chat-message` |
| 7 | **Prompt text** | From `12-ai-prompts.txt` (WF-A section) |
| 8 | Map AI output → `ai_summary` | So chat uses AI text, not only the template |

### Before activate

| # | Fill / set | Notes |
|---|---|---|
| 9 | Categories / entity tags | Narrow for prod if needed |
| 10 | Trigger **isActive** | Keep **false** until test post works → then **true** |

### How to get Slack/Teams values

| Need | How |
|---|---|
| Connection | Dynatrace Hub / Settings → Connections → Slack or Teams → Add connection (OAuth). Token stays in Connection. |
| Channel | Create test channel; invite Dynatrace app; type `#name` or pick from dropdown |
| Message | Expression picker → previous task `build-chat-message` → `chat_message` |

See also: `2026-10-18/6-how-to-get-wfa-chat-inputs/`.

---

## WF-B — fill these to complete

**File:** `12-wfb-30m-escalate-pagerduty.workflow.yaml`  
**Job:** Still Active after 30 minutes → one PagerDuty page.

### Required

| # | Fill in | Where | First value |
|---|---|---|---|
| 1 | **Minimum duration = 30 minutes** | Problem trigger (UI) after import | **30m** |
| 2 | **PD_ROUTING_KEY** | In **both** scripts: `preview-pagerduty` and `trigger-pagerduty` (or workflow secret) | **Test** service routing key (pages only you) |
| 3 | **DRY_RUN** | Same two scripts (`const DRY_RUN = …`) | **`true`** until preview OK → then **`false`** |

Set the **same** key and **same** DRY_RUN in both script tasks.

### Recommended

| # | Fill / set | Why |
|---|---|---|
| 4 | Allow `events.pagerduty.com` | Outbound allowlist if tenant requires it |
| 5 | Optional Slack/Teams “escalated” note | After `trigger-pagerduty` |
| 6 | Trigger **isActive** | **false** until DRY_RUN test → then **true** |

### Already set (usually leave alone)

| Item | Value |
|---|---|
| dedup_key | `dynatrace-<problem_id>` |
| PD URL | `https://events.pagerduty.com/v2/enqueue` |
| event_action | `trigger` |

---

## Done checklist

```
WF-A
[ ] Slack and/or Teams Connection exists
[ ] Bot invited / app added to test channel
[ ] notify-slack / notify-teams added; Message = chat_message
[ ] Optional: AI prompt + ai_summary
[ ] Test problem → message in chat
[ ] isActive = true

WF-B
[ ] Minimum duration = 30m
[ ] PD_ROUTING_KEY set (test service)
[ ] DRY_RUN true → preview OK
[ ] DRY_RUN false → one PD incident
[ ] isActive = true
```

## Result

| Complete when | Evidence |
|---|---|
| WF-A | Test problem posts to Slack and/or Teams |
| WF-B | After 30m (or test), one PD page with `dedup_key dynatrace-<id>` |

## Data flow map

```
You fill
  WF-A: Connection + Channel + Message (+ optional AI prompt)
  WF-B: 30m + PD_ROUTING_KEY + DRY_RUN
        │
Event auto-fills problem fields
  → WF-A chat  /  WF-B page @30m
```

## Related files

| File | Purpose |
|---|---|
| `1-wfa-wfb-fill-in-checklist.md` | This checklist |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/12-wfa-*.yaml` | WF-A template |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/12-wfb-*.yaml` | WF-B template |
| `../2026-10-18/4-wfa-wfb-inputs-needed/` | Longer inputs guide |
| `../2026-10-18/6-how-to-get-wfa-chat-inputs/` | How to get Slack/Teams values |
| `1.sh` | Git one-liners (not run) |

## Commands

See `1.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/1-wfa-wfb-fill-in-checklist
git commit -m "wfa wfb fill in checklist"
git push
```
