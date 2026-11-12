# Cisco VPN Email Notification

```
count greater than 3 in the last minute
  one CUSTOM_ALERT
  title starts with ALJ_VPN
    profile matches ALJ_VPN and severity ERROR
      email resource uses that profile
        to is still hidden in the Splunk Send email row
```

| Piece | What it does |
|---|---|
| Detector | Returns one row only when the last minute has more than 3 matches. |
| Profile | Matches titles that start with `ALJ_VPN`. |
| Email | Sends when that profile matches. Sends again when the problem closes. |

## Summary

The Splunk alert has a Send email action, so the Terraform now has `dynatrace_email_notification` on the `ALJ_VPN` profile. The address list is collapsed on the form, so `to` is a placeholder. Replace it with the addresses in that row before you apply.

## Investigation

The Trigger Actions list shows three actions: Add to Triggered Alerts at Critical, PagerDuty, and Send email. Send email is collapsed. No address is readable. The happy-future mail list is a different alert, so those addresses stay off this resource.

## Result

The full file is [14-cisco-vpn-ldap-alert.tf](14-cisco-vpn-ldap-alert.tf). The email resource uses `dynatrace_alerting.alj_vpn_alerting_profile.id`. The subject is `[Dynatrace] Cisco VPN - LDAP connections failing`. The body is `Alert detected: {ProblemDetailsHTML}`. `notify_closed_problems` is true, matching the working template.

Replace this line with the real addresses:

```
"paste-address-from-splunk-send-email"
```

## Data flow map

```
last 1 minute
  Windows_LDAP and FAILED
  count greater than 3
        |
        v
CUSTOM_ALERT
  name starts with ALJ_VPN
        |
        v
ALJ_VPN profile
  severity level ERROR
        |
        +--> email
        |      to comes from the Splunk Send email row
        |
        +--> pagerduty.enabled is 1
               the integration key is still inside the collapsed PagerDuty row
```

## Related files

| File | Purpose |
|---|---|
| `14-cisco-vpn-ldap-alert.tf` | Detector, profile, and email. |
| `0-pic.md` | How the email is attached. |
| `1-investigation.md` | What the form shows. |
| `2-result.md` | What to paste into `to`. |
| `3-glossary.md` | The words. |
| `14-cisco-vpn-email-notification-follow.txt` | The same notes for a phone. |
| `14.sh` | Copy commands. |

Commands: [14.sh](14.sh)
