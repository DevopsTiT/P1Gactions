# Three IWFM Splunk Alerts

```
EIP006 failure
  more than 2 lines in 1 minute
  title ALJ_EIP
  mail alj_jp_di_infra_mwss@axa.co.jp

Compass IWFMReportException
  more than 15 lines in 5 minutes
  title ALJ_COMPASS
  mail axa.jp_di_compass_it_member@axa.co.jp
  second address is cut off on the photo

iWFM Caution or Fatal
  any matching line in 1 hour
  title ALJ_IWFM
  mail rajukolukuluri@axa.co.jp
  Splunk suppress is 1 hour
```

| Alert | Window | Fires when | Prefix |
|---|---|---|---|
| EIP006 service failure | Last 1 minute | Count is greater than 2 | `ALJ_EIP` |
| Compass IWFMReportException | Last 5 minutes | Count is greater than 15 | `ALJ_COMPASS` |
| iWFM Errors | Last 1 hour | Count is greater than 0 | `ALJ_IWFM` |

## Summary

Each Splunk alert becomes one detector, one profile, and one email. The prefixes are separate, so a Compass mail does not go to the EIP mailbox. None of these use `ALJ_VM`, `ALJ_EMMA`, or `ALJ_DATALAKE`. There is no PagerDuty action on these forms, so `pagerduty.enabled` is `0`.

## Investigation

| Item | EIP006 | Compass | iWFM Errors |
|---|---|---|---|
| Name | EIP - IWFM : EIP006 service Failure Alert | [Prod]ALJ-Compass-IWFMReportException発生 | iWFM_Errors |
| Search text | `jp-Distributing-Sell-GenerateFormImage-v2-vs` and `Status=FAILURE` | `IWFMReportException` | `LOGLEVEL` Caution or Fatal |
| Index | `eip1015` | `compass-prod-axa-11-jp` | `iwfm` |
| Sourcetype | `eip_mediator_serverlog` | Not on the form | `fmwagentlog` |
| Schedule | Every minute | Every 5 minutes | Every hour at minute 15 |
| Expires | 24 hours | 1500 days | 24 hours |
| Throttle | Off | Off | On, for 1 hour |
| Mail priority | High | Normal | Normal |
| To | `alj_jp_di_infra_mwss@axa.co.jp` | `axa.jp_di_compass_it_member@axa.co.jp` | `rajukolukuluri@axa.co.jp` |

The Compass To box has a second line. It is cut off, so it is not in the file. The EIP To box shows one address. If more lines sit below the fold, paste those too.

The iWFM search ends with `transaction host AGENTID maxspan=1s`. That groups lines before Splunk counts them. The threshold is greater than 0, so any matching line and any transaction both fire. The query counts matching lines.

## Result

The file is [18-three-iwfm-splunk-alerts.tf](18-three-iwfm-splunk-alerts.tf).

Index and sourcetype are not in the queries. The Dynatrace field names for those Splunk fields are not on these screens. The text filters are specific enough that the queries do not match every log in the tenant.

`alert.severity` stays `medium`. Each profile severity level stays `ERROR`. Splunk High and Normal are the email priorities on the forms.

Davis runs about once a minute. The iWFM alert does not wait until minute 15. The 1 hour suppress in Splunk is the throttle checkbox. The identity field keeps one Dynatrace problem open while the count stays above the threshold. A new mail is sent when that problem opens. If the problem closes and a new line arrives inside that same hour, Dynatrace can mail again. Splunk would still be inside the 1 hour suppress.

There is no expiry field on the detector. 24 hours and 1500 days are not copied.

## Data flow map

```
EIP006 line with FAILURE
  last 1 minute, count greater than 2
        |
        v
ALJ_EIP problem
        |
        v
alj_jp_di_infra_mwss@axa.co.jp

IWFMReportException
  last 5 minutes, count greater than 15
        |
        v
ALJ_COMPASS problem
        |
        v
axa.jp_di_compass_it_member@axa.co.jp

Caution or Fatal
  last 1 hour, count greater than 0
        |
        v
ALJ_IWFM problem
        |
        v
rajukolukuluri@axa.co.jp
```

## Related files

| File | Purpose |
|---|---|
| `18-three-iwfm-splunk-alerts.tf` | The three detectors, profiles, and emails. |
| `0-pic.md` | How each trigger maps. |
| `1-investigation.md` | The values read from the three forms. |
| `2-result.md` | What to paste before apply. |
| `3-glossary.md` | The words. |
| `18-three-iwfm-splunk-alerts-follow.txt` | The same notes for a phone. |
| `18.sh` | Copy commands. |

Commands: [18.sh](18.sh)
