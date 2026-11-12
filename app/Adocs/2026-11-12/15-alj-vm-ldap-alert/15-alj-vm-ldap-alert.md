# ALJ VM LDAP Alert

```
last minute has more than 3 LDAP failures
  one CUSTOM_ALERT
  title starts with ALJ_VM
    profile matches ALJ_VM
      email uses that profile
```

| Name | Value |
|---|---|
| Title prefix | `ALJ_VM` |
| Profile | `ALJ_VM Alerting Profile` |
| Email | `ALJ_VM Cisco LDAP connections failing Email` |
| Search | Still the Cisco ASA LDAP failure search |

## Summary

Every `ALJ_VPN` name is now `ALJ_VM`. The profile filter is `BEGINS_WITH` `ALJ_VM`, so this mail does not use the OCP4 profile. The search is still the Cisco ASA LDAP failure lines.

## Investigation

The previous file used `ALJ_VPN` on the detector title, the event name, the profile, and the email name. The requested prefix is `ALJ_VM`, in the same style as `ALJ_OCP4`.

## Result

The full file is [15-alj-vm-ldap-alert.tf](15-alj-vm-ldap-alert.tf). The email `to` is still the placeholder. Expand Send email on the Splunk form and replace `paste-address-from-splunk-send-email`.

The Dynatrace title, profile, email subject, and `app.name` all use `ALJ_VM`.

## Data flow map

```
cisco:asa line
  Windows_LDAP
  FAILED
  count greater than 3 in 1 minute
        |
        v
CUSTOM_ALERT
  name starts with ALJ_VM
        |
        v
ALJ_VM profile
  severity level ERROR
        |
        +--> email
        |
        +--> pagerduty.enabled is 1
```

## Related files

| File | Purpose |
|---|---|
| `15-alj-vm-ldap-alert.tf` | Detector, profile, and email with the `ALJ_VM` prefix. |
| `0-pic.md` | Prefix and mail path. |
| `1-investigation.md` | What was renamed. |
| `2-result.md` | What to paste into `to`. |
| `3-glossary.md` | The words. |
| `15-alj-vm-ldap-alert-follow.txt` | The same notes for a phone. |
| `15.sh` | Copy commands. |

Commands: [15.sh](15.sh)
