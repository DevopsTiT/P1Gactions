# Problem Notifications Vs Workflow Slack Teams

## Decision tree

```
Settings → Integration → Problem notifications (this screen)?
  Want classic “problem opened → ping Slack/Teams”?
    → YES: Add notification → Slack or Teams (if listed) or Custom webhook
    → Good for simple alerts; NOT the same as WF-A AI workflow Connection

  Want WF-A / WF-B Automations (AI summary, 30m PD page)?
    → Use Workflows (purple banner “Try Workflows”)
    → Slack/Teams via Hub Connection or webhook inside the workflow
    → Problem notifications screen alone does NOT complete WF-A YAML

  Already have Custom → SILVA / Email here?
    → Keep for those alerting profiles; do not confuse with WF-A Connections
```

## Short takeaway

| Question | Answer |
|---|---|
| Can this page talk to Slack/Teams? | **Sometimes yes** — if **Add notification** offers Slack / Microsoft Teams (or you use a webhook Custom Integration) |
| Is that enough for WF-A YAML? | **No** — WF-A needs a **Workflows** Slack/Teams **Connection** (or HTTP webhook task), not only Problem notifications |
| What is this page for? | Classic **Problem notifications** tied to an **Alerting profile** |
| What should you click for your AI workflows? | Purple banner → **Try Workflows** / Automations |
| Your current rows (SILVA Custom + Email)? | Separate path — ServiceNow event / email, not Slack connector for WF-A |

## Summary

**Problem notifications** can send problem alerts to Slack or Teams on some tenants, but that is a different feature from **Workflows** connections used by `12-wfa-ai-notify-slack-teams.workflow.yaml`. For WF-A/WF-B, use Automations/Workflows. Use this screen only if you want classic profile-based Slack/Teams pings in addition to (or instead of) workflows.

## Investigation

### What the screen you opened is

| Item | Meaning |
|---|---|
| Path | Settings → Integration → **Problem notifications** |
| Job | When a problem matches an **Alerting profile**, Dynatrace calls a notification target |
| Your examples | Custom Integration → `silva.service-now.com/.../em_event`; Email → mailboxes |
| Firewall note | Dynatrace egress IPs listed for inbound allow on the receiver side |

### Two different “connect to Slack/Teams” paths

| Path | Where | What you get | Fits WF-A template? |
|---|---|---|---|
| **A. Problem notifications** | This Settings page → Add notification | Problem card / text to Slack or Teams when profile fires | **No** (different plumbing) |
| **B. Workflows Hub Connection** | Hub → Slack/Teams → Connection; used inside a Workflow | WF-A `notify-slack` / `notify-teams` tasks | **Yes** |
| **C. Webhook** | Slack/Teams Incoming Webhook URL | HTTP POST from either Problem notification (Custom) **or** Workflow HTTP task | WF-A: yes if you add HTTP task |

### Can you use *this* page for Slack and Teams?

| If Add notification shows… | You can… |
|---|---|
| **Slack** or **Microsoft Teams** | Create a classic problem → Slack/Teams notification + pick Alerting profile |
| Only **Custom Integration** / Email (common on locked tenants) | Point Custom URL at a Slack/Teams **Incoming Webhook** (JSON payload you design) |
| Nothing for Slack/Teams | Use **Workflows** (recommended for your YAML) or ask admin |

So: **yes for classic alerts (if the type exists or via webhook); no as a substitute for the WF-A connector Connection.**

### What to do for your WF-A / WF-B goals

| Goal | Use |
|---|---|
| AI summary → Slack/Teams (WF-A) | **Workflows** + Hub Slack/Teams Connection **or** workflow webhook |
| Still Active 30m → PagerDuty (WF-B) | **Workflows** + PD routing key (not this Problem notifications page) |
| Extra: also email / SILVA em_event on profile | Keep using **this** Problem notifications page as you already do |

Click **Try Workflows** on the purple banner — that is the product family for your YAML files.

### If you still want Slack from Problem notifications

1. **Add notification**.  
2. Choose **Slack** / **Teams** if listed → finish auth → set Alerting profile + test.  
3. Or choose **Custom Integration** → Slack Incoming Webhook URL → craft payload (often needs a small formatter; not identical to WF-A `chat_message`).  
4. Do **not** expect that to fill WF-A’s Connection dropdown.

## Result

| Use case | This page OK? |
|---|---|
| Classic problem → Slack/Teams ping | Yes, if Slack/Teams/webhook available under Add notification |
| Complete WF-A / WF-B templates | No — use Workflows |
| Existing SILVA Custom + Email | Keep; unrelated to WF-A Connection |

## Data flow map

```
Problem notifications (this screen)
  Alerting profile matches
    → Email / Custom SILVA em_event / (optional) Slack|Teams|webhook
    → Simple notify — NOT WF-A AI pipeline

Workflows (Try Workflows)
  Problem trigger → extract → (AI) → Slack/Teams Connection or webhook
  WF-B → PagerDuty Events API
```

## Related files

| File | Purpose |
|---|---|
| `5-problem-notifications-vs-workflow-slack-teams.md` | This comparison |
| `../3-no-dynatrace-app-in-slack-marketplace/` | Hub / webhook when Marketplace empty |
| `../2-how-to-get-wfa-wfb-info/` | How to get WF-A/WF-B values |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/` | WF-A / WF-B YAML |
| `5.sh` | Git one-liners (not run) |

## Commands

See `5.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/5-problem-notifications-vs-workflow-slack-teams
git commit -m "problem notifications vs workflow slack teams"
git push
```
