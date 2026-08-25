# Docs — review only; do not auto-run PowerShell without MS Admin approval
open "https://support.pagerduty.com/main/docs/microsoft-teams"
open "https://support.pagerduty.com/main/docs/microsoft-teams-permission-changelog"
open "https://support.pagerduty.com/main/docs/pagerduty-advance"
open "https://support.pagerduty.com/main/docs/sre-agent"
open "https://support.pagerduty.com/main/docs/scribe-agent"
open "https://support.pagerduty.com/main/docs/shift-agent"
open "https://support.pagerduty.com/main/docs/insights-agent"
open "https://support.pagerduty.com/main/changelog/insights-agent-now-generally-available-for-microsoft-teams"
# US tenant — OnlineMeetings application access policy (MS Admin only)
# Install-Module -Name MicrosoftTeams -Force -AllowClobber
# Import-Module MicrosoftTeams
# Connect-MicrosoftTeams
# New-CsApplicationAccessPolicy -Identity "PAGERDUTY_ACCESS_POLICY" -AppIds "05ffe668-5b27-45ff-a64d-b2ed6c475d7a" -Description "Policy for enabling online meetings with application token for PagerDuty"
# Grant-CsApplicationAccessPolicy -PolicyName "PAGERDUTY_ACCESS_POLICY" -Global
# EU tenant AppId: 8f79a561-d2f1-4a1e-8092-c2039043a40e
