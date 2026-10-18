# Dynatrace AI 30 Minute No Ack Incident

## Decision tree

```
Want: no one ack + still open after 30 min → create incident (PagerDuty / SILVA)
 Use AI Assistant for what?
   Design help / draft workflow / summarize problem text → YES (Davis Copilot / AI Assistant)
   Run the 30-minute rule every time by itself in chat → NO
 Lasting automation?
   → Dynatrace Workflow (Problem trigger + wait/filter + create incident)
 Simple rule (not closed 30 min)?
   → Problem trigger, Minimum duration = 30m, status still Active
     → then PagerDuty / SILVA action (preview then post if that is your standard)
 Also require "nobody acknowledged"?
   → after 30m, check problem still Active AND not acknowledged
     → if your tenant has no ack field in the trigger, use "still Active + no human comment/owner" or page only on severity filter first
 Optional AI in the workflow?
   → Prompt generative AI task: summarize problem → put summary into PD/SILVA body
 Slack PagerDuty AI still Not Connected?
   → Dynatrace can still open a PagerDuty incident via Events API
   → Slack card appears only after PD↔Slack is connected (seq 7)
```

## Short takeaway

| Question | Answer |
|---|---|
| Can the Dynatrace AI Assistant create the 30‑minute rule by chatting? | It can **help you design** it. The rule must live in a **Workflow**. |
| Best trigger | **Problem** trigger (one run per Davis problem, not per raw event). |
| “Not closed within 30 minutes” | Set **Minimum duration = 30 minutes**, or Problem open → **Wait 30m** → re-check Active. |
| “No one acknowledged” | Extra condition: still Active and not acked (field names vary by tenant). |
| Create incident where? | PagerDuty Events API and/or SILVA — follow your preview-then-post standard. |

## Summary

Use the Dynatrace AI Assistant to write the workflow idea and the incident text. Use a **Workflow** to enforce “open 30 minutes and still not handled → open an external incident.” Optionally add a generative-AI step to summarize the Davis problem into the PagerDuty/SILVA description.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Davis problem | Dynatrace groups related alerts into one problem. | What you wait on for 30 minutes. |
| AI Assistant / Davis Copilot | Chat helper in Dynatrace. | Helps design prompts and summaries. |
| Workflow | Saved automation: trigger → tasks. | Where the 30‑minute rule actually runs. |
| Problem trigger | Starts a workflow when a problem opens/updates/closes. | Correct trigger type for this use case. |
| Minimum duration | Wait until the problem has been open at least N minutes. | Built-in way to express “still open after 30 min.” |
| Acknowledge (ack) | A human marked the problem as seen / taken. | Your “no one acknowledged” condition. |
| Preview then post | Build payload, preview, then send if ready. | Your preferred SILVA/PagerDuty pattern. |

### What the AI Assistant is good for (and not)

| Use AI Assistant for | Do not expect AI Assistant alone to |
|---|---|
| Draft the workflow steps in plain English | Remember to page every problem forever from one chat |
| Write the Copilot prompt that summarizes a problem | Replace PagerDuty Slack connection |
| Suggest DQL filters for which problems qualify | Guarantee ack-field names without checking your tenant |
| Explain Minimum duration vs Wait task | Create SILVA secrets or PD routing keys |

### Recommended automation shape

```
Davis problem becomes Active
  → (optional) Wait for root cause analysis (~1–2 min)
  → Minimum duration 30 minutes   OR   Wait task 30 minutes
  → Condition: still Active
               AND not acknowledged (if available)
               AND your filters (severity / management zone / tags)
  → (optional) Dynatrace Intelligence: summarize problem
  → preview-silva / preview-pagerduty
  → post-silva / trigger-pagerduty   (only if preview ready)
```

This matches your house standard: preview then post, never send secrets in committed YAML.

### Two ways to express “30 minutes still open”

| Approach | How | Pros |
|---|---|---|
| A. Minimum duration on Problem trigger | Trigger option: wait until open ≥ 30m | Simple; problems that close early never fire |
| B. Fire on open, then Wait 30m task | Trigger on Active → Wait → query problem again | Easy to add “if acked, stop” in the middle |

For beginners, **Approach A** is enough for “not closed within 30 mins.” Add Approach B if you need a clear “if someone acked at minute 10, cancel” branch.

### “No one acknowledged” — be careful

| Reality | What to do |
|---|---|
| Your UI shows Acknowledge on problems | Ask AI Assistant / docs which workflow field means acked on your version |
| No reliable ack in the trigger | First ship “still Active after 30m → create incident,” then harden with ack |
| People ack in PagerDuty, not Dynatrace | Dynatrace cannot see PD ack; use Dynatrace ack or “still open” only |

Practical starter condition:

```
Problem status = Active
Open duration >= 30 minutes
(optional) severity in {AVAILABILITY, ERROR, ...}
(optional) not acknowledged == true
```

### How to use the AI Assistant to help build it

In Dynatrace, open **Davis Copilot / AI Assistant** and paste a prompt like this:

```
I need a Dynatrace Workflow that:
1) Triggers on a Davis Problem (not raw Davis events).
2) Waits until the problem has been Active for 30 minutes (Minimum duration).
3) Continues only if the problem is still Active and not acknowledged.
4) Optionally uses generative AI to summarize the problem in plain text.
5) Creates a PagerDuty incident (and/or SILVA) using preview-then-post.
Please list: trigger settings, filter conditions, task order, and a sample AI prompt for the summary step.
```

Then build the workflow in the UI from that answer. Do not paste production routing keys or SILVA secrets into the chat if your policy forbids it — use placeholders.

### Sample generative-AI task prompt (inside the workflow)

Use after you have `problem_id` / description from earlier tasks:

```
A Davis problem has been Active for 30 minutes with no acknowledgement.
Problem id: {{ problem_id }}
Title: {{ problem_title }}
Status: {{ problem_status }}
Provide a short plain-text summary and the top 3 investigation steps for the on-call.
No markdown.
```

Needs AI Units / Conversational recommender permission on DPS if your tenant uses that model.

### Create the external incident

| Target | Typical workflow action | Note |
|---|---|---|
| PagerDuty | HTTP to Events API v2 `trigger`, or PD connector | Use a **test** routing key first |
| SILVA / ServiceNow | Your SILVA connector / HTTP | Preview task then post task |
| Slack only | Not enough for “create incident” | Slack shows the PD incident after PD is connected |

Your PagerDuty AI Slack card was **Not Connected** earlier. Dynatrace can still **create** the PagerDuty incident. Slack/Paige help starts only after an admin connects Slack (seq 7).

### Filters so you do not page on everything

| Filter idea | Why |
|---|---|
| Severity / category | Skip info noise |
| Management zone / tags | Only Tier‑1 apps |
| Wait for root cause analysis | Richer problem payload |
| Exclude maintenance windows | If your process supports it |

## Result

| Step | Action |
|---|---|
| 1 | Ask AI Assistant with the prompt above to draft the workflow |
| 2 | Create Workflow → Problem trigger → Minimum duration 30m → Active only |
| 3 | Add condition: still Active (+ not acked if available) |
| 4 | Optional: generative AI summarize task |
| 5 | Preview then post to PagerDuty and/or SILVA |
| 6 | Test with a low-severity test problem / test routing key |
| 7 | After PD↔Slack is Connected, verify the incident appears in `#test-channel` |

## Data flow map

```
Davis problem opens
  → AI Assistant (human): helps design workflow   [one-time]
  → Workflow runs automatically:
       wait 30m (min duration or Wait task)
       still Active? and not acked?
         NO  → stop
         YES → (optional) Copilot summary
             → preview PD/SILVA
             → post incident
  → PagerDuty incident
  → Slack (only if Slack integration Connected)
  → Paige / @PagerDuty can help responders
```

## Related files

| File | Purpose |
|---|---|
| `8-dynatrace-ai-30min-no-ack-incident.md` | This guide |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | AI vs Workflow split |
| `2-result.md` | Build checklist |
| `3-glossary.md` | Terms |
| `8.sh` | Git one-liners (not run) |
| 2026-10-17 seq 7 | Slack Not Connected blocker |
| Dynatrace docs | Problem trigger, Minimum duration, generative AI in workflows |
| House standard | Preview then post for SILVA / PagerDuty |

## Commands

No live Dynatrace/PagerDuty commands in this answer. After the workflow exists, verify in the UI with a **test** problem only.

See `8.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/8-dynatrace-ai-30min-no-ack-incident
git commit -m "dynatrace ai 30min no-ack create incident"
git push
```
