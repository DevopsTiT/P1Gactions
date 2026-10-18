# Add Teams Along With Slack

## Decision tree

```
Want Microsoft Teams as well as Slack?
 Dynatrace AI summaries / problem posts?
   YES → OK: add Teams connector (or second notify task) next to Slack
   → same workflow, two deliver tasks (or branch by team tag)
 PagerDuty Advance AI (Paige / Scribe)?
   YES → OK: connect both Slack and Teams under AI Settings
   → each user links their own chat identity
   → Shift coverage DMs still weaker on Teams (Slack-oriented docs)
 Risk of double noise?
   Same alert to Slack AND Teams AND PagerDuty page?
     → OK for dual-chat visibility if teams expect it
     → BAD if two different escalate rules both page
 Rule of thumb
   Chat fan-out (Slack + Teams) = fine
   Page fan-out (two PD services / two escalations) = avoid
```

## Short takeaway

| Question | Answer |
|---|---|
| Is it OK to add Teams along with Slack? | **Yes.** |
| Best use | Same Dynatrace AI summary posted to **both** chats, or route by team. |
| PagerDuty AI | You may enable **both** chat integrations when admins connect them. |
| Main risk | Duplicate noise (two chats + a page) without a clear owner channel. |
| What not to duplicate | Two escalation paths that both page the same on-call. |

## Summary

Adding Teams beside Slack is normal. Use both as **notification surfaces**. Keep **one** paging path in PagerDuty. Decide which channel is primary for ack discussion so people do not split the incident conversation.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Slack Connector | Dynatrace posts to Slack. | Your current DT→chat path. |
| Teams (chat) | Microsoft Teams as a second chat surface. | Same idea for Teams users. |
| Fan-out | One event → many destinations. | Slack + Teams is fan-out. |
| Primary channel | Where the team is expected to talk. | Avoid split-brain incident chat. |

### Dynatrace side — yes, add Teams

| Pattern | How | When |
|---|---|---|
| Dual post | After generative AI task: Slack Send **and** Teams Send | Everyone must see the same AI summary |
| Route by tag | If problem has `team=payments` → Slack; `team=claims` → Teams | Different orgs prefer different chat |
| Primary + mirror | Post full card to primary; short link to the other | Cuts noise but keeps visibility |

Example task order (WF1 style):

```
Problem → generative AI summary
  → Slack message (#test-channel or ops Slack)
  → Teams message (ops Team / channel)
  → (optional 30m) one PagerDuty trigger only
```

### PagerDuty AI side — yes, both can be Connected

On `…/ai` you currently have Slack and Teams both **Not Connected**. An admin can install **both**. That is supported.

| After both Connected | Note |
|---|---|
| Paige / `@PagerDuty` style asks | Work in the chat where the incident channel lives |
| Scribe | Works with Slack or Teams commands (different syntax) |
| Shift proactive DMs | Historically Slack-oriented; treat Teams as weaker for coverage nudges |
| Side panel | Slack paid feature; not a Teams twin |

You do **not** need both PD chat apps to use Dynatrace→Teams. Dynatrace Teams/Slack connectors are independent of PagerDuty Advance Slack/Teams.

### What is OK vs not OK

| OK | Not OK |
|---|---|
| AI summary to Slack **and** Teams | Two PD services both paging the same person for one problem |
| Slack for eng, Teams for business stakeholders | Three different “30m escalate” workflows all creating PD incidents |
| PD Advance on both chats once admins connect | Assuming Shift/Insights behave identically on Teams |
| One primary incident thread (pick Slack **or** Teams) | Half the team talking in Slack, half in Teams with no rule |

### Suggested policy for your demo

| Surface | Role |
|---|---|
| Dynatrace | Detect + AI summarize |
| Slack `#test-channel` / `#pagerduty` | Eng primary thread (you already use this) |
| Teams (new) | Mirror summary for Teams-first colleagues, or stakeholder channel |
| PagerDuty | Single test service → single escalation (page only you) |
| PD Advance Slack/Teams | Optional later; not required for Dynatrace AI posts |

### Admin asks (short)

**Dynatrace admin:** enable Teams destination in Workflows (Teams connector / connection), pick a test Team channel.

**PagerDuty admin (optional):** on `/ai`, connect Teams as well as Slack when ready; enable agents once; users run link-user in each chat they use.

## Result

| Decision | Recommendation |
|---|---|
| Add Teams along with Slack? | **Yes** |
| How | Same workflow, second notify task (or tag-based route) |
| Paging | Still **one** PagerDuty path |
| Primary chat | Choose one home for live incident talk; other can be mirror |
| PD Advance both chats | Fine when admins connect; does not block Dynatrace dual-chat now |

## Data flow map

```
Davis problem
  → Dynatrace generative AI
  → Slack channel  ──┐
  → Teams channel  ──┼── same summary (OK)
                     │
  → (30m) one PD incident ──► one escalation (do not duplicate)
```

## Related files

| File | Purpose |
|---|---|
| `10-add-teams-along-with-slack.md` | This answer |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Dual-chat notes |
| `2-result.md` | Policy |
| `3-glossary.md` | Terms |
| `10.sh` | Git one-liners (not run) |
| 2026-10-17 seq 9 | Dynatrace AI replace PD AI |
| 2026-08-25 seq 10 | Teams-only PD AI limits |

## Commands

No live commands. After connectors exist, test with a **low-impact** problem to a **test** Slack channel and a **test** Teams channel only.

See `10.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/10-add-teams-along-with-slack
git commit -m "add teams along with slack for dynatrace ai"
git push
```
