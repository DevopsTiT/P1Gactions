# Open Advance AI Settings (replace subdomain)
open "https://REPLACE_ME.pagerduty.com/ai-settings"

# Official docs — review only; no live PD/MS API calls
open "https://support.pagerduty.com/main/docs/microsoft-teams"
open "https://support.pagerduty.com/main/docs/microsoft-teams-permission-changelog"
open "https://support.pagerduty.com/main/docs/pagerduty-advance"
open "https://support.pagerduty.com/main/docs/sre-agent"
open "https://support.pagerduty.com/main/docs/scribe-agent"
open "https://support.pagerduty.com/main/docs/shift-agent"
open "https://support.pagerduty.com/main/docs/insights-agent"
open "https://support.pagerduty.com/main/changelog/insights-agent-now-generally-available-for-microsoft-teams"

# Echo Teams-only ordered checklist (human UI; no APIs)
echo "0) Shared: Teams app + PD Authorize + Graph consent + Advance Teams On + linkUser + test Service"

echo "1) SRE: create test incident → Teams @pagerduty triage → upload runbook → resolve (4 Actions/ask)"

echo "2) Scribe: meeting URL on incident → @PagerDuty advance scribe → join within 15m → short meeting → summary"

echo "3) Shift: Teams-only → Path B PD web + Calendar override (or Path A best-effort Advance ask); Slack DMs deferred"

echo "4) Insights: Teams @pagerduty analytics Q&A; weekly maturity DMs still Slack-first"

echo "Cost: SRE 4/ask; Scribe ~6/30min +2 summary; Shift/Insights 0"
