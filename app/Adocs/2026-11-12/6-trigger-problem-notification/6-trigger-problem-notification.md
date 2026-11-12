# Trigger Problem Notification

```
Preview shows CW test logs
  that is a query result
  a preview does not send a notification
Save the custom alert
  Problems list
    no problem → the alert did not open one
      query must return the bad rows, or the count must be above 0
    a problem is open
      Settings → Integration → Problem notifications
        integration disabled → turn it on
        alerting profile excludes this problem → include the severity
        problem already open → close it, then let a new match open it
        channel never tested → Send test notification
```

| Step | What it proves |
|---|---|
| Preview table | The query can see the CloudWatch test logs. |
| A row in Problems | The custom alert opened a problem. |
| Send test notification | The email, webhook, or PagerDuty channel can receive a message. |
| A new problem after the old one is closed | The real notification path runs again. |

## Summary

The preview did its job. A problem notification is sent when a Dynatrace problem opens and that problem matches an alerting profile on an enabled integration. Save the alert, confirm a problem exists, then use Send test notification if the channel itself has never delivered a message.

## Investigation

| Source | What it says |
|---|---|
| Your message at 9:33 | Two CloudWatch alerts work in the preview. The table status is Pending, and the text is CW test logs found. |
| Yasuda at 9:40 | Share the link, and try to trigger the problem notification. She is having trouble triggering the alert. |
| The draft reply | A Splunk config-explorer link. That link opens a Splunk page. It does not send the Dynatrace notification. |
| The alert form | It was still an unsaved Edit alert. Preview and Save are different buttons. |

## Result

Do these in order.

1. Press **Save** on the custom alert. The editor has to close.
2. Open **Problems**.
3. Look for a problem created by this alert.

| What Problems shows | What you do |
|---|---|
| No problem | The alert is not opening one. For Records, the query must return the bad rows. For Timeseries, the one-minute count must be above 0. |
| A problem is already open | A second matching log updates that problem. It does not send a second notification. Close the problem, then let a new matching line open a new one. |

4. Open **Settings**.
5. Open **Integration**, then **Problem notifications**.
6. Open the integration she expects. That may be email, a webhook, or PagerDuty.
7. Confirm the integration is turned on.
8. Open the alerting profile attached to it. The profile has to include the severity of this problem.
9. Select **Send test notification**.

A successful test means the channel works. The real notification still waits for a new problem that matches the profile.

The Splunk link answers "can you share the link?" Send the problem link from the Problems page when Yasuda asks for the alert. The Problems row has its own URL.

## Data flow map

```
Custom alert saved
        |
        v
Query matches, or the count is above 0
        |
        v
Dynatrace problem opens
        |
        v
Alerting profile includes that problem
        |
        v
Problem notification integration
        |
        v
Email, webhook, or PagerDuty
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Preview versus a sent notification. |
| `1-investigation.md` | What the chat asked for. |
| `2-result.md` | The order to follow. |
| `3-glossary.md` | The words. |
| `6-trigger-problem-notification-follow.txt` | The same steps for a phone. |
| `6.sh` | Copy commands. |

Commands: [6.sh](6.sh)
