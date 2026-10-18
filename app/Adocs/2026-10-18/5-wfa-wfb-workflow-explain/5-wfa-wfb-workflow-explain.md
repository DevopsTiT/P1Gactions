# WFA WFB Workflow Explain

## Decision tree

```
What is this YAML?
  WF-A (12-wfa-…)?
    → Runs when a NEW Davis problem becomes Active
    → Builds a chat message (optional AI)
    → You send it to Slack and/or Teams
  WF-B (12-wfb-…)?
    → Runs when a problem is STILL Active after 30 minutes
    → Builds a PagerDuty “trigger” payload
    → Posts once (if DRY_RUN is false)
  Use both?
    → Yes: A = catch me up in chat; B = page humans if ignored
```

## Short takeaway

| File | Plain English job |
|---|---|
| `12-wfa-ai-notify-slack-teams.workflow.yaml` | “Problem just opened → write a summary → put it in Slack/Teams.” |
| `12-wfb-30m-escalate-pagerduty.workflow.yaml` | “Still broken after 30 minutes → create one PagerDuty incident so someone is paged.” |

## Summary

These are **Dynatrace Workflow** templates. A workflow is an automation: when something happens (a **Davis problem**), Dynatrace runs a list of **tasks** in order. WF-A helps humans in chat right away. WF-B pages on-call later if nobody fixed it. Both start **turned off** (`isActive: false`) so nothing fires until you finish setup.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Davis problem | Dynatrace’s “something is wrong” object | This is the event that starts both workflows |
| Workflow | Automation: trigger + ordered tasks | The YAML is that automation, exportable as a file |
| Trigger | “When do we run?” | WF-A: new Active problem; WF-B: still Active after 30m |
| Task | One step (JS script, send Slack, HTTP, …) | Each named block under `tasks:` |
| Connection | Saved Slack/Teams login in Dynatrace | Needed so WF-A can post to chat (you add those tasks in UI) |
| Routing key | PagerDuty Events API key for one service | WF-B uses it to open an incident |
| DRY_RUN | Practice mode | WF-B builds the payload but does not really page |
| dedup_key | Unique id for one PD incident | Stops many pages for the same problem (`dynatrace-<id>`) |

---

## Big picture (both together)

```
Something breaks in the app/host
        │
        ▼
Dynatrace opens a Davis problem
        │
        ├─► WF-A (soon after open)
        │     “Here is a summary for Slack/Teams”
        │
        └─► WF-B (only if still Active ≥ 30 minutes)
              “Page someone in PagerDuty once”
```

WF-A replaces a lot of **PagerDuty Paige-style** chat help.  
WF-B keeps **PagerDuty as the pager**, not as the AI.

---

## WF-A explained — AI notify Slack and Teams

### What it is for

When a **new** problem becomes **Active**, build a plain-text message so people in Slack/Teams can “catch up” without waiting for PagerDuty AI in chat.

### When it runs (trigger)

| Setting in YAML | Meaning |
|---|---|
| `event.kind == "DAVIS_PROBLEM"` | Only Davis problems |
| `event.status == "ACTIVE"` | Problem is open |
| `event.status_transition == "CREATED"` | This is the **create** moment (new problem), not every update |
| Categories error/resource/slowdown/availability | Which problem types are included |
| `isActive: false` | Workflow is **off** until you turn it on |

### Task chain (what each step does)

```
1) extract-problem
     Read id, title, description, severity, build problem URL
     Leave ai_summary empty (fill later if you add Copilot)

2) build-chat-message
     If ai_summary has text → format “[Dynatrace AI] …”
     Else → safe template with title, severity, URL, context
     Output: chat_message (max ~3500 chars)

3) emit-chat-payload
     Placeholder that shows the exact message ready to post
     Hints: #test-channel / Teams channel
     *** You replace this with real Slack Send + Teams Send tasks in the UI ***
```

### What is *not* inside the YAML yet

| Missing piece | Why |
|---|---|
| Real Slack / Teams send actions | Action IDs depend on your Hub apps; bind **connection + channel** after import |
| “Prompt generative AI” task | Optional; insert between extract and build; paste prompt from `12-ai-prompts.txt` |

### Happy path

1. Problem opens.  
2. Extract runs.  
3. Message is built (template or AI).  
4. Slack and/or Teams get the text.  
5. Humans fact-check and investigate.

---

## WF-B explained — 30m escalate to PagerDuty

### What it is for

If the problem is **still Active** after you wait **30 minutes**, open **one** PagerDuty incident so on-call gets a page. Dynatrace decided “this is worth escalating”; PagerDuty only rings the phone.

### When it runs (trigger)

| Setting | Meaning |
|---|---|
| Davis problem + `ACTIVE` | Still open |
| **Minimum duration = 30 minutes** (set in UI after import) | Do **not** run at T+0; wait half an hour |
| `isActive: false` | Off until you finish DRY_RUN tests |
| Categories | Same style as WF-A |

### Task chain

```
1) extract-problem
     Read id, title, description, URL
     Flag still_active

2) preview-pagerduty
     Build Events API v2 JSON (summary, severity, custom_details)
     dedup_key = dynatrace-<problem_id>
     Check: still active? have problem id? have PD_ROUTING_KEY?
     DRY_RUN = true by default
     Preview hides the real key as ***REDACTED***

3) trigger-pagerduty
     If preview not ready → skip
     If DRY_RUN true → skip POST; return “would_post_dedup_key”
     If DRY_RUN false → HTTP POST to https://events.pagerduty.com/v2/enqueue
```

### Important knobs you edit in the scripts

| Knob | Meaning | Safe first value |
|---|---|---|
| `PD_ROUTING_KEY` | Which PD service gets the incident | Test service key (pages only you) |
| `DRY_RUN` | Skip real page | `true` until preview looks right |
| Same values in **both** preview and trigger tasks | Avoid mismatch | Copy carefully or use one secret |

### Why `dedup_key` matters

If the same problem fires the workflow again, PagerDuty can treat `dynatrace-<problem_id>` as the **same** incident instead of opening many copies. That reduces double-pages.

### Happy path

1. Problem still open at 30m.  
2. Preview is ready.  
3. With `DRY_RUN false`, one PD incident is created.  
4. On-call is paged by PD schedule/escalation.  
5. Optional later: also post “escalated” to Slack/Teams.

---

## Side by side

| Topic | WF-A | WF-B |
|---|---|---|
| Timing | Right when problem is **created** Active | After **30 minutes** still Active |
| Main output | Chat message | PagerDuty incident |
| Replaces | Paige-style catch-up in chat | “Notice it’s still broken” → page |
| Needs | Slack/Teams connections + channels | Routing key + 30m duration + DRY_RUN |
| Default risk | Low (chat only, inactive) | Higher (can page) — keep DRY_RUN true first |
| AI | Optional Prompt generative AI | Optional escalate blurb; not required to page |

## Common mistakes

| Mistake | What goes wrong |
|---|---|
| Activate WF-A without Slack/Teams tasks | Only `emit-chat-payload` runs; nobody sees chat |
| Forget Minimum duration 30m on WF-B | May page too early or not wait as designed |
| Leave `PD_ROUTING_KEY` empty | Preview not ready; no page |
| Set `DRY_RUN false` with prod key on first try | Real page to prod on-call |
| Two different systems both create PD incidents | Double page for one problem |

## Result

| You understand | Meaning |
|---|---|
| WF-A | Auto “catch me up” text to Slack/Teams when a problem opens |
| WF-B | Auto one PD page if still open 30 minutes later |
| Together | Dynatrace AI/chat path + PagerDuty as pager only |

## Data flow map

```
Davis problem CREATED + ACTIVE
  → WF-A: extract → build chat_message → (UI) Slack + Teams

Same problem still ACTIVE after 30m
  → WF-B: extract → preview PD → (if not DRY_RUN) POST Events API
       dedup_key: dynatrace-<problem_id>
```

## Related files

| File | Purpose |
|---|---|
| `5-wfa-wfb-workflow-explain.md` | This explanation |
| `../2-dt-ai-replace-pd-all-files/12-wfa-…yaml` | WF-A template |
| `../2-dt-ai-replace-pd-all-files/12-wfb-…yaml` | WF-B template |
| `../4-wfa-wfb-inputs-needed/` | What to fill in after import |
| `5.sh` | Git one-liners (not run) |

## Commands

See `5.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-18/5-wfa-wfb-workflow-explain
git commit -m "wfa wfb workflow explain"
git push
```
