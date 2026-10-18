# PagerDuty AI Slack Not Connected

## Decision tree

```
Screen: axa-life-japan.pagerduty.com/ai
 Paige / Scribe / Shift = Enabled?
   YES → agents are on (good)
 Slack card = Not Connected + Requested to Admin?
   YES → blocker: Slack integration not installed/mapped for this PD account
   → @PagerDuty AI in Slack will NOT work until an admin connects Slack
 What to do
   You (non-admin): send admin the request below; wait until Slack shows Connected
   Admin: Integrations → Extensions → Slack → Add Workspace
        → then this page: Slack Connected → toggle Slack On (if shown)
        → optional scopes if Update required
 After Connected: /pd connect in #test-channel → create test incident → @PagerDuty
 Teams also Not Connected? → same story; pick Slack first for your demo
```

## Short takeaway

| Question | Answer |
|---|---|
| What does this screen say? | AI agents are **Enabled**, but Slack is **Not Connected**. |
| Can you use Paige in Slack now? | **No.** Chat integration must be connected first. |
| What does "Requested to Admin" mean? | You already asked; a PagerDuty/Slack admin must finish the install. |
| Account | `axa-life-japan.pagerduty.com` |
| Next owner | Workspace / PagerDuty admin who can install the Slack app |

## Summary

Your AI Agents toggles are already on. The red state on Slack is the gate: until Slack shows **Connected**, PagerDuty Advance Assistance cannot run in Slack. Ask an admin to install and map the Slack app for AXA Life Japan PagerDuty, then come back to this page and confirm Slack is Connected before `/pd connect` and `@PagerDuty` tests.

## Investigation

### What the screenshot shows

| Section | State | Meaning |
|---|---|---|
| Getting Started step 1 | Connect a chat integration | Not done yet for Slack |
| Slack | Not Connected + Requested to Admin | Your request is pending; app not usable |
| Microsoft Teams | Not Connected + Requested to Admin | Same for Teams |
| Paige, SRE Agent | Enabled | Agent license/toggle OK |
| Scribe Agent | Enabled | OK |
| Shift Agent | Enabled | OK |

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Chat integration | Slack or Teams bridge to PagerDuty AI | Required before AI works in chat |
| Not Connected | Integration not installed or not mapped | AI in Slack stays dark |
| Requested to Admin | You clicked request; waiting on admin | You cannot finish this alone |
| Enabled (agent) | Agent is turned on in PD | Necessary but not enough without Slack |

## Result

### What you should do (you)

1. Do **not** keep toggling agents — they are already Enabled.
2. Message a PagerDuty **Admin / Global Admin / Account Owner** (and Slack workspace admin if different) with the text below.
3. After they finish, refresh `https://axa-life-japan.pagerduty.com/ai` and confirm Slack shows **Connected** (not Not Connected).
4. Then continue seq 6 steps: invite bot to `#test-channel` → `/pd connect` → test incident → `@PagerDuty`.

### Copy-paste for your admin

```
Please connect Slack to PagerDuty AI for axa-life-japan.pagerduty.com.

I am blocked on https://axa-life-japan.pagerduty.com/ai
Slack shows: Not Connected / Requested to Admin
AI Agents (Paige, Scribe, Shift) are already Enabled.

Need:
1) PagerDuty: Integrations → Extensions → Slack → Add Workspace
   (map to our Slack workspace; authorize the PagerDuty Slack app)
2) On AI → AI Settings /ai page: Slack status = Connected, Slack assistance On
3) If status is Update required: approve optional scopes for AI summaries
4) Confirm I can Link Account (Slack user ↔ PagerDuty user)

Goal: use Paige / @PagerDuty in our demo Slack channels (#test-channel / #pagerduty).
```

### What the admin should do

| Step | Where | Action |
|---|---|---|
| 1 | PagerDuty → Integrations → Extensions → Slack | Add Workspace → Allow |
| 2 | Same Slack mapping screen | Confirm correct workspace |
| 3 | `…/ai` or AI Settings | Slack = Connected; toggle assistance On if present |
| 4 | If Update required | Enable optional scopes |
| 5 | Tell you | Refresh `/ai` and link your user |

### After Slack is Connected — quick verify

| Check | Pass |
|---|---|
| `/ai` Slack card | Connected (green), not Not Connected |
| Slack `/pd` | Slash command responds |
| Link Account | Your user linked |
| `#test-channel` | Bot invited + `/pd connect` to test service |
| `@PagerDuty Catch me up` | Reply on a test incident |

## Data flow map

```
Now (blocked)
  AI Agents Enabled ──✘── Slack Not Connected ──► no @PagerDuty AI in Slack

After admin
  Slack Connected → /pd connect channel → incident → @PagerDuty / Paige / Scribe
```

## Related files

| File | Purpose |
|---|---|
| `7-pagerduty-ai-slack-not-connected.md` | This reading of your `/ai` screen |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Screenshot evidence |
| `2-result.md` | Admin ask + verify |
| `3-glossary.md` | Terms |
| `7.sh` | Git one-liners (not run) |
| 2026-10-17 seq 4 | Full Slack AI setup |
| 2026-10-17 seq 6 | Create alert in `#test-channel` after Connected |

## Commands

No shell needed for this blocker. After admin connects Slack, in Slack:

```
/pd connect
@PagerDuty Catch me up
```

See `7.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/7-pagerduty-ai-slack-not-connected
git commit -m "pagerduty ai slack not connected next steps"
git push
```
