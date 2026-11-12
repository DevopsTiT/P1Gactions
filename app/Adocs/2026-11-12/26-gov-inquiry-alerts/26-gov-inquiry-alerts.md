# Gov Inquiry Alerts

```
Biz file summary in the last 5 minutes
  MDM_SEARCH_RESULT_FILE -> ALJ_GOV MDM file summary
  ND_SEARCH_RESULT_FILE -> ALJ_GOV ND file summary
  ANSWER_FILE -> ALJ_GOV Answer file summary
  REQUEST_FILE -> ALJ_GOV Request file summary

error lines in the last 5 minutes
  level:ERROR -> ALJ_GOV General error
  ParseErrorFileAndUpdateDb -> ALJ_GOV PipItLinq error file
  parseGatewaySysErrorFileAndUpdateDbEffect -> ALJ_GOV SYSERROR file

all titles start with ALJ_GOV
  one profile
  one email
  alj_jp_di_maintenance_operation_digital@axa.co.jp
```

| Alert | Fires when |
|---|---|
| MDM file summary | A Biz file summary for `MDM_SEARCH_RESULT_FILE` arrives |
| ND file summary | A Biz file summary for `ND_SEARCH_RESULT_FILE` arrives |
| Answer file summary | A Biz file summary for `ANSWER_FILE` arrives |
| Request file summary | A Biz file summary for `REQUEST_FILE` arrives |
| General error | The log failure function has `level:ERROR` |
| PipItLinq error file | The error-file function logs `ParseErrorFileAndUpdateDb` |
| SYSERROR file | The system-error function logs `parseGatewaySysErrorFileAndUpdateDbEffect` |

## Summary

Seven detectors share the prefix `ALJ_GOV`, one profile, and one email. The address is `alj_jp_di_maintenance_operation_digital@axa.co.jp`. There is no PagerDuty action, so `pagerduty.enabled` is `0`. The four summary alerts fire when the summary line exists. A normal file still sends the mail.

## Investigation

| Item | What the forms show |
|---|---|
| Index | `gov-inquiry-system` |
| Window | Last 5 minutes |
| Cron | Every 5 minutes |
| Expires | 24 hours |
| Trigger | Number of results is greater than 0, once |
| Throttle | Off |
| Priority | Normal |
| To | `alj_jp_di_maintenance_operation_digital@axa.co.jp` |

The `rex` and `rename` lines build the Splunk email table. They do not add another trigger. The Dynatrace mail body is `{ProblemDetailsHTML}`. It does not rebuild the Japanese count columns.

The E-Tool Lambda and eopt serverless screens are the pair already written with prefixes `ALJ_ETOOL` and `ALJ_EOPT`.

## Result

The file is [26-gov-inquiry-alerts.tf](26-gov-inquiry-alerts.tf).

`aws.log.group` is the same field used for the other Lambda log groups. Each summary query also requires `Biz file summary` and its file category, so a line from another file type does not open that alert.

The Splunk subjects differ. One Dynatrace email uses the problem name inside `{ProblemDetailsHTML}` to tell the four summaries and the three error files apart.

There is no 24-hour expiry field on the detector.

## Data flow map

```
gov-inquiry-system Lambda
        |
        +--> Biz file summary
        |      MDM, ND, answer, or request
        |
        +--> level:ERROR
        +--> ParseErrorFileAndUpdateDb
        +--> parseGatewaySysErrorFileAndUpdateDbEffect
        |
        v
ALJ_GOV profile
  alj_jp_di_maintenance_operation_digital@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `26-gov-inquiry-alerts.tf` | Seven detectors, one profile, and one email. |
| `0-pic.md` | How the triggers map. |
| `1-investigation.md` | The values read from the forms. |
| `2-result.md` | What the mail does and does not include. |
| `3-glossary.md` | The words. |
| `26-gov-inquiry-alerts-follow.txt` | The same notes for a phone. |
| `26.sh` | Copy commands. |

Commands: [26.sh](26.sh)
