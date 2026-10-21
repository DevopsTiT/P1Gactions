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
