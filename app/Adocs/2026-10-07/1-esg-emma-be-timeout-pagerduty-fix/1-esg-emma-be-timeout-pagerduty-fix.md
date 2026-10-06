# ESG Emma BE Timeout PagerDuty Fix

## Decision Tree

```
Splunk Trigger Actions → Alert Status Manager present?
 PagerDuty Notification = Enable → pagerduty.enabled = "1"   ← this alert
 PagerDuty Notification = Disable, or no Alert Status Manager / PagerDuty action → "0"
 Only "Send email" → "0"
```

## Short Takeaway

| Question | Answer |
|---|---|
| 1 or 0? | `"1"` |
| Why | The second action, Alert Status Manager, has PagerDuty Notification set to Enable |
| What I missed before | The first screenshot showed only "Send email"; Alert Status Manager was further down the page |
| What changes | `pagerduty.enabled` goes from "0" to "1"; the header comment now lists both actions |
| Everything else | Same as 2026-10-06 seq 8 (query, threshold 20, severity high) |

## Summary

`pagerduty.enabled` should mirror whether the Splunk alert pages anyone. This alert has two actions: an email, and the Alert Status Manager with PagerDuty Notification set to Enable. So it pages, and the Dynatrace property must be "1" for the standard SILVA / PagerDuty flow to send the page.

## Splunk Actions On This Alert

| Splunk action | Setting | Dynatrace |
|---|---|---|
| Send email | Priority High, team mailing lists | `alert.severity high`, email through the standard flow |
| Alert Status Manager | Email Notification Mode: Production | Normal routing, not debug |
| Alert Status Manager | PagerDuty Notification: Enable | `pagerduty.enabled = "1"` |
| Alert Status Manager | PagerDuty URL events.pagerduty.com | Not copied; the standard flow owns the PagerDuty connection |

## How To Decide For Other Alerts

| What you see in Splunk | Value |
|---|---|
| A "PagerDuty" action in Trigger Actions | "1" |
| Alert Status Manager with PagerDuty Notification = Enable | "1" |
| Alert Status Manager with PagerDuty Notification = Disable | "0" |
| Only Send email or Triggered Alerts | "0" |

## Changed Lines

```hcl
property {
  key   = "pagerduty.enabled"
  value = "1"
}
```

## Data Flow

```
timeouts > 20 in 5 min → High problem (pagerduty.enabled = 1)
  → standard flow: preview-silva → post-silva
                   preview-pagerduty → trigger-pagerduty (now runs)
```

## Investigation

| Checked | Finding |
|---|---|
| New screenshot | Trigger Actions: Send email and Alert Status Manager |
| Alert Status Manager | Email mode Production, PagerDuty Enable, URL events.pagerduty.com |
| Seq 8 (2026-10-06) | Had "0" because only Send email was visible |

## Result

| Step | What to do |
|---|---|
| 1 | Use `1-esg-emma-be-timeout-pagerduty-fix.tf` instead of the seq 8 file |
| 2 | `terraform plan`: 1 to add (or 1 to change if seq 8 was already applied) |
| 3 | Recheck the OpenPaaS egress proxy alert (2026-10-06 seq 7) for an Alert Status Manager action too |

## Related Files

| File | Purpose |
|---|---|
| `1-esg-emma-be-timeout-pagerduty-fix.tf` | Corrected Terraform |
| `1-esg-emma-be-timeout-pagerduty-fix-check.dql` | Same check queries as seq 8 |
| `1.sh` | Commands |
