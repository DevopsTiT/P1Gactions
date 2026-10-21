# Fix WFA Global Fetch

```
Error: httpClient.fetch is not a function
 → Remove import { httpClient } from '@dynatrace-sdk/http-client'
 → Use global fetch(url, { method, headers, body })
 → Settings → External requests → allow hooks.slack.com
 → DRY_RUN false + URL set → Run again → #test-channel
```

| Key point | Detail |
|---|---|
| What failed | `post-slack-webhook` |
| Why | Workflow JS runtime uses built-in `fetch`, not `httpClient.fetch` |
| Also needed | Outbound allowlist for `hooks.slack.com` |

## Summary

You cleared the `result()` bug and dry-run. The next failure is the HTTP call. Paste the fixed post script that uses `await fetch(...)`, allowlist Slack’s host, then re-run.

## Paste into `post-slack-webhook`

Use [21-post-slack-webhook-fixed.js](./21-post-slack-webhook-fixed.js) or:

```
import { result } from '@dynatrace-sdk/automation-utils';

const DRY_RUN = false;
const SLACK_WEBHOOK_URL = ""; // your webhook — Dynatrace UI only
const TEAMS_WEBHOOK_URL = "";

export default async function () {
  const prev = await result("preview-slack-webhook");
  const m = await result("build-chat-message");

  if (!prev.ready) {
    return { skipped: true, reason: "preview_not_ready", problems: prev.problems };
  }
  if (DRY_RUN) {
    return { skipped: true, reason: "DRY_RUN_true", would_post_slack: true };
  }
  if (!SLACK_WEBHOOK_URL) {
    return { skipped: true, reason: "missing_SLACK_WEBHOOK_URL" };
  }

  const slackRes = await fetch(SLACK_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text: m.chat_message })
  });
  const slackText = await slackRes.text();

  return {
    skipped: false,
    slack: {
      status: slackRes.status,
      ok: slackRes.ok || slackText.trim() === "ok",
      response: slackText.slice(0, 500)
    },
    problem_id: m.problem_id
  };
}
```

## External requests (required)

1. Dynatrace → **Settings** → **General** → **External requests**  
2. Add host pattern: `hooks.slack.com`  
3. Save, then re-run the workflow  

Without this, `fetch` to Slack can fail even with the correct code.

## Wrong vs right

| Wrong | Right |
|---|---|
| `import { httpClient } from '@dynatrace-sdk/http-client'` | (remove) |
| `await httpClient.fetch(url, …)` | `await fetch(url, …)` |

## Import full workflow

| File | Role |
|---|---|
| `21-wfa-ai-notify-slack-webhook.workflow.yaml` | Full WF-A with global `fetch` |
| `21-wfb-30m-escalate-pagerduty.workflow.yaml` | WF-B same HTTP fix |

## Data flow map

```
preview ready + DRY_RUN false
  → await fetch(hooks.slack.com …)
  → Slack returns ok
  → #test-channel shows problem text
```

## Related files

| File | Role |
|---|---|
| `21-post-slack-webhook-fixed.js` | Paste into UI |
| `../19-fix-wfa-result-api/` | Prior `result()` fix |
| `../20-wfa-dry-run-skipped-no-slack/` | Prior dry-run skip |
| `21.sh` | Mirror |

## Commands

See [21.sh](./21.sh).
