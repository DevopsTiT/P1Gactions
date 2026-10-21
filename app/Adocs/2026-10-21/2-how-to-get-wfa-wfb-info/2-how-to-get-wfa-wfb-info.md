# How To Get WFA WFB Info

## Decision tree

```
Need values for WF-A or WF-B?
  WF-A (chat)?
    Connection missing → install Slack/Teams app → Dynatrace Connection
    Channel unknown → create test channel → invite bot → copy #name
    Message → expression from build-chat-message (not a secret)
  WF-B (page)?
    Minimum duration → set 30m on Problem trigger in UI
    PD_ROUTING_KEY → PagerDuty service → Integrations → Events API v2
    DRY_RUN → edit script const (true first)
  Dropdown empty / key unknown?
    → wrong tenant, app not installed, or no admin rights
```

## Short takeaway

| Workflow | Input | How you get it |
|---|---|---|
| WF-A | Slack/Teams **connection** | Dynatrace Hub/Connections after installing the chat app |
| WF-A | Slack/Teams **channel** | Create/invite bot; use `#name` or picker |
| WF-A | **Message** | `{{ result("build-chat-message").chat_message }}` |
| WF-B | **Minimum duration** | Problem trigger UI → 30 minutes |
| WF-B | **PD_ROUTING_KEY** | PagerDuty → Service → Events API v2 integration key |
| WF-B | **DRY_RUN** | Edit `const DRY_RUN` in both PD script tasks |

## Summary

For **WF-A**, get chat **connections** and **channels** from Dynatrace + Slack/Teams; the message is an expression, not something you look up. For **WF-B**, set **30 minutes** on the trigger, copy a **test** PagerDuty routing key from the service integration, and keep **DRY_RUN true** until a preview looks right. Never put bot tokens or prod routing keys in the YAML or git.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Connection | Dynatrace-stored login to Slack or Teams | Dropdown in notify tasks |
| Channel | Where the bot posts | Humans read the summary there |
| Routing key | PagerDuty Events API key for one service | WF-B uses it to create a page |
| Minimum duration | Wait time before the problem trigger fires WF-B | Set to 30m for “still open” escalate |
| DRY_RUN | Practice mode in the script | Builds payload but does not POST |
| Expression | `{{ result("task").field }}` | Reuses text the workflow already built |

---

# Part A — WF-A (Slack / Teams notify)

## A1 — Slack connection

### What it is

Named credential in Dynatrace. The workflow only picks the **name**.

### How to get it

1. **Slack** (admin may be required): Apps → install **Dynatrace** Slack app → Allow / OAuth.  
2. **Dynatrace**: Hub → **Slack** connector, or **Settings → Connections → Slack**.  
3. **Add connection** → finish Slack approve → name it (e.g. `slack-ops-test`).  
4. In WF-A task `notify-slack` → **Connection** → select that name.

| Do not put in YAML | Lives here |
|---|---|
| Bot token `xoxb-…` | Inside the Connection |

**Empty dropdown?** Hub Slack app missing, connection never created, or wrong Dynatrace tenant.

---

## A2 — Slack channel

### How to get it

1. Slack → create (or open) `#test-channel` / `#dt-ai-test`.  
2. Invite the **Dynatrace** bot (Add apps).  
3. In `notify-slack` → **Channel** → `#test-channel`.  

If the action wants a **Channel ID**: channel details → copy Channel ID.

**No message in channel?** Bot not invited.

---

## A3 — Teams connection

### How to get it

1. **M365 / Teams admin**: allow the **Dynatrace** Teams app.  
2. **Teams**: Apps → add Dynatrace to your **test team**.  
3. **Dynatrace**: Hub / Connections → **Teams** → Add connection → consent → name (e.g. `teams-ops-test`).  
4. `notify-teams` → **Connection** → pick that name.

---

## A4 — Teams channel

### How to get it

1. Create test team/channel (e.g. `dt-ai-test`).  
2. Dynatrace app must be on that **team**.  
3. In `notify-teams`: pick **Team** then **Channel** from dropdowns (filled via the connection).

Prefer the picker over hand-typed IDs.

---

## A5 — Message field

### How to get it

Not from Slack/Teams. The workflow already builds it.

1. Task `build-chat-message` outputs `chat_message`.  
2. In notify tasks → **Message** → insert:

```
{{ result("build-chat-message").chat_message }}
```

Or use the UI expression picker → previous task → `chat_message`.

---

## A6 — Optional AI prompt text

### How to get it

1. Open companion file `12-ai-prompts.txt` (same bundle as the YAMLs).  
2. Copy the **WF-A triage** prompt block.  
3. Paste into a **Prompt generative AI** Hub task between `extract-problem` and `build-chat-message`.  
4. Map the AI result into `ai_summary` so `build-chat-message` uses it.

Needs Davis Copilot / AI Units licensed.

---

# Part B — WF-B (30m PagerDuty escalate)

## B1 — Minimum duration = 30 minutes

### What it is

Trigger setting: “only run after the problem has been Active this long.”

### How to get / set it

1. Open imported **WF-B** in Dynatrace → **Workflows**.  
2. Click the **Problem trigger** (top node).  
3. Find **Minimum duration** (or equivalent wait / duration on davis-problem trigger).  
4. Set **30 minutes**.  
5. Save.

This is **not** a secret and is **not** fully guaranteed in the YAML alone — set it in the UI after import.

---

## B2 — PD_ROUTING_KEY (PagerDuty routing key)

### What it is

Events API v2 integration key for **one** PagerDuty service. WF-B POSTs to `events.pagerduty.com` with this key.

### How to get it (test first)

1. Open **PagerDuty** → **Services**.  
2. Open (or create) a **test** service whose escalation pages **only you**.  
3. **Integrations** → **Add integration** → **Events API v2** (or “PagerDuty Events API”).  
4. Copy the **Integration Key** / **Routing Key** (long hex string).  
5. In WF-B, paste into **both** script tasks (same value):

| Task | What to edit |
|---|---|
| `preview-pagerduty` | `const PD_ROUTING_KEY = "…";` |
| `trigger-pagerduty` | `const PD_ROUTING_KEY = "…";` |

Better: store as a **workflow secret** named `PD_ROUTING_KEY` and read it in both scripts (if your tenant pattern supports that) — still never commit the value.

| Use | Key from |
|---|---|
| First tests | Test service (pages only you) |
| Prod later | Real on-call service — only after DRY_RUN tests pass |

**Wrong key symptoms:** preview `missing_PD_ROUTING_KEY`, or HTTP 400/403 from Events API.

---

## B3 — DRY_RUN

### What it is

Script flag. `true` = build/preview only, **no** real page. `false` = POST for real.

### How to get / set it

1. Open tasks `preview-pagerduty` and `trigger-pagerduty`.  
2. Find:

```
const DRY_RUN = true;
```

3. Keep **`true`** for first runs.  
4. After preview shows `ready: true` and `would_post_dedup_key` looks right, set **both** tasks to `false`.  
5. Save.

You “get” this by editing the script — it is not looked up in PagerDuty.

---

## B4 — Network allowlist (if needed)

### How to get / set it

1. Ask Dynatrace / network admin whether outbound HTTPS is restricted.  
2. If yes, allowlist host: **`events.pagerduty.com`**.  
3. Confirm in tenant settings / support process for your company.

No value to paste into the workflow — just ensure the POST is allowed.

---

## B5 — Optional: confirm dedup_key (no fill-in)

Already computed as `dynatrace-<problem_id>`. After a test run, check the task result for `dedup_key` / `would_post_dedup_key`. You do not invent this.

---

# Part C — Shared: when you are done

| Step | Action |
|---|---|
| 1 | WF-A: Connections + channels + Message expression |
| 2 | WF-A: test problem → message in Slack/Teams |
| 3 | WF-B: Minimum duration 30m + test routing key + DRY_RUN true |
| 4 | WF-B: preview ready → DRY_RUN false → one PD incident |
| 5 | Both: set trigger **isActive = true** |

---

## Quick map (input → where you get it)

| Input | App / place you open | What you copy / pick |
|---|---|---|
| Slack connection | Dynatrace Connections / Hub | Connection **name** in dropdown |
| Slack channel | Slack | `#channel` or Channel ID |
| Teams connection | Dynatrace Connections / Hub | Connection **name** |
| Teams channel | Teams + workflow picker | Team + channel |
| Message | Dynatrace workflow expression | `build-chat-message.chat_message` |
| AI prompt | File `12-ai-prompts.txt` | Prompt text |
| Minimum duration | WF-B Problem trigger UI | `30` minutes |
| PD_ROUTING_KEY | PagerDuty → Service → Events API v2 | Integration / routing key |
| DRY_RUN | WF-B script tasks | `true` then `false` |

## Result

| Done | Evidence |
|---|---|
| WF-A info complete | Named connections in dropdown; test post in channel |
| WF-B info complete | Preview ready with test key; one PD incident when DRY_RUN false |

## Data flow map

```
Slack/Teams admin → install Dynatrace app
  → Dynatrace Connection (token stored)
  → Channel invite
  → WF-A notify: Connection + Channel + Message expression

PagerDuty → test Service → Events API v2 key
  → WF-B scripts: PD_ROUTING_KEY
  → Trigger UI: Minimum duration 30m
  → Scripts: DRY_RUN true → false
```

## Related files

| File | Purpose |
|---|---|
| `2-how-to-get-wfa-wfb-info.md` | This guide (both workflows) |
| `../1-wfa-wfb-fill-in-checklist/` | What must be filled |
| `../2026-10-18/6-how-to-get-wfa-chat-inputs/` | WF-A-only deep dive |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/` | YAML + prompts |
| `2.sh` | Git one-liners (not run) |

## Commands

See `2.sh`. None have been run. All values are obtained in Slack / Teams / PagerDuty / Dynatrace UI.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/2-how-to-get-wfa-wfb-info
git commit -m "how to get wfa wfb relative info"
git push
```
