# PMT API Alerts

```
index pmt-api
  count greater than 0
    SFDC API error
      last 5 minutes
      ALJ_SFDC
      operations and applications
    process automation mailbox
      unexpected error, and the line does not contain sfdc
      Task timed out, last 6 minutes
      SendApprovalReminder handler failed
      Exception in myAxaMailSender
      Error occured during email sending process for this user
      ALJ_PMT
      alj_jp_di_processautomation@axa.co.jp
    Koichi plus process automation
      Max Memory Used, number after +Used: is over 480
      Exception in ExportData
      ALJ_STP
    Prod_Life_Emma mail sender
      same phrase, Send email box is collapsed
      ALJ_MAILSENDER
      no address copied
```

| Prefix | Who gets the mail |
|---|---|
| ALJ_SFDC | The two addresses on the SFDC form |
| ALJ_PMT | `alj_jp_di_processautomation@axa.co.jp` |
| ALJ_STP | `koichi.nagamine@axa.co.jp` and the process automation mailbox |
| ALJ_MAILSENDER | Nobody yet. The To box on that form is collapsed. |

## Summary

Nine detectors watch index `pmt-api`. Five share `ALJ_PMT`. Memory and ExportData share `ALJ_STP`, because those two forms also mail Koichi Nagamine. SFDC has its own prefix. The Emma-named mail-sender alert uses `ALJ_MAILSENDER` and has no email resource. The five onboarding-batch screens in this batch are already written. They are not repeated here.

## Investigation

| Item | What the forms show |
|---|---|
| Index | `pmt-api` on every search |
| Window | Last 5 minutes, except Transformation Timeout which is last 6 minutes |
| Cron | Every 5 minutes. The gray "every day at 6PM" line is Splunk's example. |
| Expires | 24 hours. There is no matching field on the detector. |
| Trigger | Number of results is greater than 0, once |
| Email priority | Normal |
| PagerDuty | No PagerDuty action on any form |

| Alert | Search line | Mail |
|---|---|---|
| pmt-api SFDC Error | `An error occurred while calling sfdc api` | Operations and applications |
| Unexpected Error | `Unexpected errors`, then drop lines whose message contains `sfdc` | Process automation |
| Transformation Timeout | `Task timed out` | Process automation |
| SendApprovalReminder handler failed | `SendApprovalReminder handler failed` | Process automation |
| STP APIs Memory Usage over 480MB | `Max Memory Used`, then the number after `+Used:` is greater than 480 | Koichi and process automation |
| Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal | `Exception in myAxaMailSender` | Send email is collapsed |
| Exception in myAxaMailSender | `Exception in myAxaMailSender` | Process automation |
| Exception in ExportData for Datalake | `Exception in ExportData` | Koichi and process automation |
| Error occured during email sending process for this user | The same sentence, including the spelling `occured` | Process automation |

The SFDC To box is small. The best read is `ALJ_JP_DI_operations@axa.co.jp` and `TS_JP_DI_applications@axa.co.jp`. Confirm both before apply. Koichi's address reads `koichi.nagamine@axa.co.jp`. Confirm that spelling too.

Splunk subject on the SFDC form is `[pmt-api] SFDC処理失敗のお知らせ`. The Dynatrace body stays `{ProblemDetailsHTML}`.

Four forms have throttle on for 60 seconds: the approval reminder, both mail-sender alerts, ExportData, and the email-sending error. The other four have throttle off.

The Emma form also has Add to Triggered Alerts at severity Medium. That is the Splunk triggered-alert severity. It is not a PagerDuty action.

`| table` on several searches only chooses columns. It does not change a greater-than-0 trigger.

## Result

The file is [32-pmt-api-alerts.tf](32-pmt-api-alerts.tf).

`index == "pmt-api"` stays in every query. Phrases such as `Task timed out` and `Unexpected errors` would match other apps without it. The field name `index` may differ in Dynatrace. Add the real field when you know it.

The unexpected-error query drops any line that contains `sfdc`. Splunk dropped that text from the `message` field only. The whole-line check is the stand-in until the Dynatrace field name is known.

The memory query looks for `Max Memory Used`, then reads the number after `+Used:`. Check that parse on one real log line before you trust it. Splunk's `rex` is not copied character for character.

`ALJ_STP` does not start with `ALJ_PMT`, so the process-automation profile does not also match the Koichi alerts. `ALJ_MAILSENDER` does not start with `ALJ_PMT`, so the collapsed form does not mail the process-automation list.

Event severity stays `medium`. Each profile severity level stays `ERROR`. Email priority Normal stays on the Splunk form. `pagerduty.enabled` is `0`.

Davis runs about once a minute. It does not follow the Splunk cron. One stable `alert_key` keeps one open problem while the count stays above zero. Splunk throttle of 60 seconds is shorter than that. If the problem closes and the same line is still in the window, Dynatrace can open a new problem.

## Data flow map

```
pmt-api logs
    |
    +--> sfdc api error
    |      ALJ_SFDC
    |      operations and applications
    |
    +--> five process-automation phrases
    |      ALJ_PMT
    |      alj_jp_di_processautomation@axa.co.jp
    |
    +--> memory over 480 and ExportData
    |      ALJ_STP
    |      koichi.nagamine and process automation
    |
    +--> Emma mail-sender name
           ALJ_MAILSENDER
           To box was collapsed
```

## Related files

| File | Purpose |
|---|---|
| `32-pmt-api-alerts.tf` | Nine detectors, three profiles, and three emails. |
| `0-pic.md` | How the mailboxes split. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | Why three prefixes are used. |
| `3-glossary.md` | The words. |
| `32-pmt-api-alerts-follow.txt` | The same notes for a phone. |
| `32.sh` | Copy commands. |

Commands: [32.sh](32.sh)
