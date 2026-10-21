import { result } from '@dynatrace-sdk/automation-utils';

// Use global fetch — NOT httpClient.fetch
// Settings → General → External requests → allow hooks.slack.com
const DRY_RUN = false;
const SLACK_WEBHOOK_URL = ""; // paste in Dynatrace UI only
const TEAMS_WEBHOOK_URL = "";

export default async function () {
  const prev = await result("preview-slack-webhook");
  const m = await result("build-chat-message");

  if (!prev.ready) {
    return { skipped: true, reason: "preview_not_ready", problems: prev.problems };
  }
  if (DRY_RUN) {
    return {
      skipped: true,
      reason: "DRY_RUN_true",
      would_post_slack: true,
      would_post_teams: Boolean(TEAMS_WEBHOOK_URL),
      preview_slack: prev.preview_slack
    };
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

  let teams = { skipped: true, reason: "TEAMS_WEBHOOK_URL_empty" };
  if (TEAMS_WEBHOOK_URL) {
    const teamsRes = await fetch(TEAMS_WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: m.chat_message })
    });
    teams = {
      skipped: false,
      status: teamsRes.status,
      response: (await teamsRes.text()).slice(0, 500)
    };
  }

  return {
    skipped: false,
    slack: {
      status: slackRes.status,
      ok: slackRes.ok || slackText.trim() === "ok",
      response: slackText.slice(0, 500)
    },
    teams,
    problem_id: m.problem_id
  };
}
