# Open Advance AI Settings (replace subdomain)
open "https://REPLACE_ME.pagerduty.com/ai-settings"

# Official AI agents overview
open "https://www.pagerduty.com/platform/ai-agents/"

# Support: PagerDuty Advance enablement
open "https://support.pagerduty.com/main/docs/pagerduty-advance"

# Support: SRE Agent
open "https://support.pagerduty.com/main/docs/sre-agent"

# Support: Scribe Agent
open "https://support.pagerduty.com/main/docs/scribe-agent"

# Support: Shift Agent
open "https://support.pagerduty.com/main/docs/shift-agent"

# Support: Insights Agent
open "https://support.pagerduty.com/main/docs/insights-agent"

# Echo shared enablement checklist (human UI; no PD API)
echo "1) Admin: AI > AI Settings > Assistant and AI Agents Configuration"

echo "2) Connect Slack and/or Teams; toggle chat integration on"

echo "3) Enable agents needed for POC: SRE, Scribe, Shift, Insights"

echo "4) Create test Service poc-pd-ai-agents-test; escalation pages only you"

echo "5) SRE POC: upload runbook; Slack SRE Agent Triage; resolve to save memory"

echo "6) Scribe POC: conference URL + passcode; join within 15 minutes; keep meeting short"

echo "7) Shift POC: Level-1 test schedule + Google Calendar; Request coverage"

echo "8) Insights POC: public @pagerduty analytics question; sanity-check Analytics UI"

echo "9) Cost: SRE 4 Actions/ask; Scribe ~6/30min +2 summary; Shift/Insights 0"
