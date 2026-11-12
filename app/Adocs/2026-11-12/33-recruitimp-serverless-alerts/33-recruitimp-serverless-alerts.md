# Recruitimp Serverless Alerts

```
recruitimp-serverless
  last 5 minutes
    word after the tab is ERROR
    title ALJ_ETOOL
    alj_jp_di_etool_maintenance@axa.co.jp
  daily at 8:00, window last 24 hours
    text after level: is ERROR
    title ALJ_EOPT
    that mailbox and chungyueh.chiu@axa.co.jp
```

| Alert | Mail |
|---|---|
| RI Monitoring Error | The E-Tool maintenance mailbox only |
| recruitimp AWS Serverless Error | That mailbox and `chungyueh.chiu@axa.co.jp` |

## Summary

Two detectors. No new profile and no new email. The titles start with `ALJ_ETOOL` and `ALJ_EOPT`, so the E-Tool profiles already written for those mailboxes send the mail. A second profile with the same prefix would send a second copy.

## Investigation

| Item | RI Monitoring Error | recruitimp AWS Serverless Error |
|---|---|---|
| Index | `recruitimp-serverless` | `recruitimp-serverless` |
| Time range | Last 5 minutes | No time range on the form |
| Schedule | Every 5 minutes | Every day at 8:00 |
| Expires | 24 hours | 24 hours |
| Trigger | Count greater than 0, once | Count greater than 0, once |
| Throttle | Off | Off |
| Priority | Normal | Normal |
| To | `alj_jp_di_etool_maintenance@axa.co.jp` | That address and `chungyueh.chiu@axa.co.jp` |

The first search runs three `rex` commands, then keeps `loglevel="ERROR"`. The session id and the user id are columns for the Splunk table. They do not change the trigger. `| table` does not filter.

The loglevel `rex` takes the word after a tab that follows four hyphenated words.

The second search reads the text after `level:`, turns it into uppercase, and keeps `ERROR`.

The gray "every day at 6PM" line under the first cron box is Splunk's example.

## Result

The file is [33-recruitimp-serverless-alerts.tf](33-recruitimp-serverless-alerts.tf). It has two detectors.

`ALJ_ETOOL` matches the profile that mails only `alj_jp_di_etool_maintenance@axa.co.jp`. `ALJ_EOPT` matches the profile that also mails `chungyueh.chiu@axa.co.jp`. Those profiles are in the E-Tool file. Apply that file as well, or these problems open and no mail goes out.

The daily form has no time range. The window is the last 24 hours because the search runs once a day. Davis still runs about once a minute. It does not wait until 8:00.

Both parses need one real log line before you trust them. The first looks for four words, hyphens, a tab, then the level word. The second takes the word after `level:` and compares the uppercase value with `ERROR`. A line that only contains the letters ERROR somewhere else does not match these parses.

`index` stays in both queries because `ERROR` is a short word. The field name may differ in Dynatrace.

Event severity stays `medium`. `pagerduty.enabled` is `0`. There is no PagerDuty action. Email priority Normal stays on the Splunk form. The 24-hour expiry has no detector field.

One `alert_key` keeps one open problem while the count stays above zero. Throttle is off on both forms. A new mail is not sent every minute. If the problem closes and the count is still above zero, Dynatrace can open a new problem.

## Data flow map

```
recruitimp-serverless
        |
        +--> level word after the tab is ERROR
        |      last 5 minutes
        |      ALJ_ETOOL
        |      etool maintenance
        |
        +--> text after level: is ERROR
               last 24 hours
               ALJ_EOPT
               etool maintenance and chungyueh.chiu
```

## Related files

| File | Purpose |
|---|---|
| `33-recruitimp-serverless-alerts.tf` | Two detectors. |
| `0-pic.md` | How the two alerts split. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | Why the E-Tool prefixes are reused. |
| `3-glossary.md` | The words. |
| `33-recruitimp-serverless-alerts-follow.txt` | The same notes for a phone. |
| `33.sh` | Copy commands. The E-Tool profiles are in the earlier E-Tool folder. |

Commands: [33.sh](33.sh)
