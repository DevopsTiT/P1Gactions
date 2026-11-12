# E-Tool Serverless Errors

```
index eopt-serverless
  extracted level is ERROR
    last 5 minutes, any line
      ALJ_ETOOL
      mail alj_jp_di_etool_maintenance@axa.co.jp

    last 24 hours, any line
      ALJ_EOPT
      same mailbox
      plus chungyueh.chiu@axa.co.jp
```

| Alert | Window | Mail |
|---|---|---|
| E-Tool Error Lambda | Last 5 minutes | The maintenance mailbox |
| eopt AWS Serverless Error | Last 24 hours | The maintenance mailbox and `chungyueh.chiu@axa.co.jp` |

## Summary

Both alerts look for level `ERROR` in `eopt-serverless`. The titles use different prefixes because the daily alert adds a second recipient. There is no PagerDuty action, so `pagerduty.enabled` is `0`.

## Investigation

| Item | E-Tool Error Lambda | eopt AWS Serverless Error |
|---|---|---|
| Name | E-Tool Error Lambda | eopt - AWS Serverless Error |
| Description | Optional | Optional |
| Index | `eopt-serverless` | `eopt-serverless` |
| Search | `rex` extracts `level`, then `where level="ERROR"` | The same `rex`, then `search level="ERROR"` |
| Schedule | Every 5 minutes | Every day at 10:00 |
| Time range | Last 5 minutes | Not shown |
| Expires | 24 hours | 24 hours |
| Trigger | Greater than 0, once | Greater than 0, once |
| Throttle | Off | Off |
| Priority | Normal | Normal |
| To | `alj_jp_di_etool_maintenance@axa.co.jp` | That address and `chungyueh.chiu@axa.co.jp` |

The `rex` finds a five-part hyphenated id in the message, then takes the next word as `level`. Splunk keeps the line only when that word is `ERROR`. `| table` only picks columns.

The maintenance address wraps after `@axa` on the form. The full address is `alj_jp_di_etool_maintenance@axa.co.jp`.

## Result

The file is [25-etool-serverless-errors.tf](25-etool-serverless-errors.tf).

The query keeps a line when `loglevel` is `ERROR` or the line contains `ERROR`. A line can contain the letters ERROR in the message body while the extracted level is a different word. Splunk would stay quiet on that line. Check one real message before apply.

The daily form has no Time Range. The query uses the last 24 hours. Davis runs about once a minute, so it does not wait until 10:00.

`index` stays in both queries. `ERROR` by itself would match other systems. There is no 24-hour expiry field on the detector.

## Data flow map

```
eopt-serverless
  level word is ERROR
        |
        +--> last 5 minutes
        |      ALJ_ETOOL
        |      maintenance mailbox
        |
        +--> last 24 hours
               ALJ_EOPT
               maintenance mailbox
               chungyueh.chiu@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `25-etool-serverless-errors.tf` | Both detectors, profiles, and emails. |
| `0-pic.md` | How the two triggers map. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | What to check before apply. |
| `3-glossary.md` | The words. |
| `25-etool-serverless-errors-follow.txt` | The same notes for a phone. |
| `25.sh` | Copy commands. |

Commands: [25.sh](25.sh)
