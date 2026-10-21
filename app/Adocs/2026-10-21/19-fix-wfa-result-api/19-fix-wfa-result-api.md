# Fix WFA Result API

```
Error: ex.result is not a function
 → Wrong: const ex = execution(); await ex.result("extract-problem")
 → Right: import { result } from '@dynatrace-sdk/automation-utils'
          const p = await result("extract-problem")
 → Paste fixed script into build-chat-message (and later tasks)
 → Re-run workflow
```

| Key point | Detail |
|---|---|
| What failed | Task `build-chat-message` |
| Why | `execution()` is async / has no `.result(taskName)` helper like that |
| Correct API | Standalone `result("task-name")` from `@dynatrace-sdk/automation-utils` |

## Summary

Dynatrace Run JavaScript must use `await result("extract-problem")` to read the previous task. Your template used `ex.result(...)`, which throws `TypeError: ex.result is not a function`.

## Paste this into `build-chat-message` now

Replace the whole script with:

```
import { result } from '@dynatrace-sdk/automation-utils';

export default async function () {
  const p = await result("extract-problem");
  const ai = (p.ai_summary || "").trim();
  const body = ai
    ? `[Dynatrace AI] ${p.problem_id}\n${p.title}\n${p.problem_url}\n\n${ai}`
    : `[Dynatrace] New problem ${p.problem_id}\n` +
      `Title: ${p.title}\n` +
      `Severity: ${p.severity}\n` +
      `URL: ${p.problem_url}\n\n` +
      `Context:\n${p.description}\n\n` +
      `(Insert Prompt generative AI task before this step for AI summary.)`;
  return {
    ...p,
    chat_message: body.slice(0, 3500)
  };
}
```

## Also fix later tasks (same bug)

| Task | Change |
|---|---|
| `preview-slack-webhook` | `const m = await result("build-chat-message");` |
| `post-slack-webhook` | `await result("preview-slack-webhook")` and `await result("build-chat-message")` |

Import line for those tasks:

```
import { result } from '@dynatrace-sdk/automation-utils';
```

(Keep `httpClient` import on the post task.)

## Optional: harden `extract-problem`

```
import { execution } from '@dynatrace-sdk/automation-utils';
import { getEnvironmentUrl } from '@dynatrace-sdk/app-environment';

export default async function () {
  const ex = await execution();
  const event = (typeof ex.event === "function" ? ex.event() : null) || {};
  // ... same field mapping as before using `event`
}
```

## Wrong vs right

| Wrong | Right |
|---|---|
| `const ex = execution();` | `const ex = await execution();` (only if you need event) |
| `await ex.result("extract-problem")` | `await result("extract-problem")` |
| `import { execution }` only | `import { result }` (or both) |

## Data flow map

```
extract-problem  → returns { problem_id, title, ... }
       ↓
build-chat-message
  await result("extract-problem")  ← fixed API
       ↓
preview-slack-webhook
  await result("build-chat-message")
       ↓
post-slack-webhook
```

## Related files

| File | Role |
|---|---|
| `19-wfa-ai-notify-slack-webhook.workflow.yaml` | Full fixed WF-A import |
| `19-wfb-30m-escalate-pagerduty.workflow.yaml` | Full fixed WF-B import |
| `19-build-chat-message-fixed.js` | Paste-only for UI |
| `19.sh` | Mirror |

## Commands

See [19.sh](./19.sh).
