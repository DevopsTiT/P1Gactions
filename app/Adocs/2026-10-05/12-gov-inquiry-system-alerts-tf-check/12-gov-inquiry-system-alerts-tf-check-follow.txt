# Gov Inquiry System Alerts Terraform Check

## Decision tree

```
gov-inquiry-system.tf (7 alerts, all dynatrace_log_alert)   [eopt-serverless.tf: same as seq 11, unchanged]
 resource exists?                                → NO → plan fails
 is it a failure or a business notice?
   1 ND file summary, 2 answer file summary,
   3 request file summary, 7 MDM file summary   → notices (counts per file) → scheduled email workflow, no problem
   5 error file received, 6 system error file   → notices that an error FILE arrived → scheduled email workflow
                                                  (upgrade to a detector if the team wants tickets)
   4 General Error (level:ERROR)                 → real failure → detector + email workflow
 parse
   WORD:fileName                                 → stops at "." and "-" → "a-b.csv" becomes "a" → NSPACE
   'xxxCount:' INT                               → fails if there is a space → SPACE?
 case
   content "ParseErrorFileAndUpdateDB" vs log group "...parseErrorFileAndUpdateDb"
                                                  → different case → caseSensitive: false
 secrets?                                        → none
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the file OK? | No. All 7 use `dynatrace_log_alert`, which does not exist |
| Most of these alerts | Business notices (file summaries), not failures; email them, don't open problems |
| Only real failure | Alert 4 General Error → detector |
| Parse bug | `WORD:fileName` cuts file names at the first dot or hyphen |
| Case risk | Alert 5's search text has different case from its log group name |
| eopt-serverless.tf | Same file as last time; see seq 11 |
| Secrets | None |

## Summary

Six of the seven alerts tell the digital services team that a file was processed (with counts) or that an error file arrived. They're notices, so turning them into Davis problems would flood problems, and possibly SILVA and PagerDuty, with normal business activity. They become one `for_each` scheduled workflow that runs every 5 minutes and emails the matching lines. Alert 4 is the only real failure and gets a detector. Two small but real issues: `WORD:fileName` truncates file names, and case-sensitive matching would likely break Alert 5.

## Alert by alert

| # | Name | Log group suffix | Search | Type | Converted to |
|---|---|---|---|---|---|
| 1 | ND file detailed summary | `parseNdAndUpdateDb` | Biz file summary, ND_SEARCH_RESULT_FILE | Notice with counts | Scheduled email workflow |
| 2 | answer file detailed summary | `buildAnswerFile` | Biz file summary, ANSWER_FILE | Notice with counts | Scheduled email workflow |
| 3 | request file detailed summary | `validateAndComputeAnswer` | Biz file summary, REQUEST_FILE | Notice with counts | Scheduled email workflow |
| 4 | General Error | `logFailure` | level:ERROR | Failure | Detector + email workflow |
| 5 | Error File Processing | `parseErrorFileAndUpdateDb` | ParseErrorFileAndUpdateDB | Error file received from pipitLINQ | Scheduled email workflow |
| 6 | System Error File Processing | `parseSysErrorFileAndUpdateDb` | parseGatewaySysErrorFileAndUpdateDbEffect | System error file from the Kyoto gateway | Scheduled email workflow |
| 7 | MDM file summary | `parseMdmResponseAndUpdateDb` | Biz file summary | Notice | Scheduled email workflow |

All log groups start with `/aws/lambda/gov-inquiry-system-prod-`. All emails go to `aij_jp_dl_maintenance_operation_-_digitalservices@axa.co.jp` (check this address against the original; it is unusual).

## Problems found

| Problem | Where | Why it matters | Fix |
|---|---|---|---|
| Resource does not exist | All 7 | Plan fails | Workflows and one detector |
| Notices as alerts | 1, 2, 3, 5, 6, 7 | As problems they'd look like incidents and could reach SILVA and PagerDuty | Scheduled email workflows |
| `WORD:fileName` | 1, 2, 3 | `WORD` is letters, digits, underscore only; `ND_20261005.csv` becomes `ND_20261005`, `gov-req.csv` becomes `gov` | `NSPACE:fileName` (may keep a trailing comma; check a sample) |
| `'answerCount:' INT` with no space allowance | 1, 2, 3 | `answerCount: 12` would not parse | `SPACE?` before `INT` |
| Case mismatch | 5 | Text `ParseErrorFileAndUpdateDB` vs log group `parseErrorFileAndUpdateDb`; the real log may use the lower form; Splunk ignored case, DQL does not | `caseSensitive: false` (added to every filter) |
| `fields ... sort ... limit 100` | All | Fine for a list, not for an alert count | Kept for the notice emails; detector uses `makeTimeseries` |
| Every 5 minutes over last 5 minutes | All | Late logs can fall between runs | Query `[now-6m, now-1m]` |

## How the notice email looks

Each notice query builds one `line` per log line, for example Alert 1:

```
2026-10-05T01:05:12Z  ND_20261005.csv  searchResultCount=120  noContractCount=8  contractExistsCount=112
```

Email body:

```
{{ result("find_lines").records | length }} line(s) in the last 5 minutes.

{% for r in result("find_lines").records %}{{ r.line }}
{% endfor %}
```

The email is skipped when there are no lines.

## Alert 1 query (pattern for 2 and 3)

```dql
fetch logs, from:now()-6m, to:now()-1m
| filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb"
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "fileCategory:ND_SEARCH_RESULT_FILE", caseSensitive: false)
| parse content, "LD 'fileName:' SPACE? NSPACE:fileName"
| parse content, "LD 'searchResultCount:' SPACE? INT:searchResultCount"
| parse content, "LD 'noContractCount:' SPACE? INT:noContractCount"
| parse content, "LD 'contractExistsCount:' SPACE? INT:contractExistsCount"
| fieldsAdd line = concat(toString(timestamp), "  ", coalesce(fileName, "-"),
    "  searchResultCount=", coalesce(toString(searchResultCount), "-"),
    "  noContractCount=", coalesce(toString(noContractCount), "-"),
    "  contractExistsCount=", coalesce(toString(contractExistsCount), "-"))
| fields timestamp, line
| sort timestamp desc
| limit 100
```

## Alert 4 detector query

```dql
fetch logs
| filter aws.log_group == "/aws/lambda/gov-inquiry-system-prod-logFailure"
| filter contains(content, "level:ERROR", caseSensitive: false)
| makeTimeseries count = count(default: 0), interval:1m
```

Window 5, threshold 0, ABOVE, violating 1, dealerting 5. The email workflow fetches the last 10 minutes of `level:ERROR` lines and emails them.

## Check the parse on real lines

```dql
fetch logs, from:-1d
| filter startsWith(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-")
| filter contains(content, "Biz file summary", caseSensitive: false)
| parse content, "LD 'fileName:' SPACE? NSPACE:fileName"
| fields timestamp, aws.log_group, fileName, content
| limit 20
```

| What you see | Fix |
|---|---|
| `fileName` complete | Good |
| `fileName` ends with `,` or `"` | Share a sample line; I'll switch to a pattern that stops at that character |
| `fileName` empty | The text may be `"fileName":`; share a sample |

## Routing

| Alert | Opens a problem? | Email |
|---|---|---|
| 1, 2, 3, 5, 6, 7 | No | digitalservices maintenance, every 5 minutes when lines exist |
| 4 | Yes | digitalservices maintenance via the problem email workflow; check your SILVA workflow handles it as the team expects |

## Data flow

```
gov-inquiry-system-prod-* Lambdas → CloudWatch → Dynatrace AWS log forwarding → Grail

NOTICES (1,2,3,5,6,7)
  every 5 min → DQL [now-6m, now-1m] → build "line" per log → lines > 0 ? → email digitalservices

FAILURE (4)
  detector every minute → level:ERROR count > 0 → problem "gov-inquiry-system General Error"
  → email workflow → last 10 min ERROR lines → digitalservices
```

## Investigation

| Checked | Finding |
|---|---|
| 9 screenshots | First two are `eopt-serverless.tf` (already checked in seq 11); seven show `gov-inquiry-system.tf` |
| Alerts 1, 2, 3, 7 | "Biz file summary" notices with counts parsed from the line |
| Alerts 5, 6 | Notices that error files arrived from pipitLINQ and the Kyoto gateway |
| Alert 4 | `level:ERROR` from the logFailure Lambda |
| Parse | `WORD:fileName` and no `SPACE?` before `INT` |
| Case | Alert 5 search text and log group differ in case |
| Secrets | None |

## Result

Not OK as is. Convert alerts 1, 2, 3, 5, 6 and 7 to one `for_each` scheduled email workflow, alert 4 to a detector plus email workflow, use `NSPACE` and `SPACE?` in the parse patterns, and keep `caseSensitive: false`. Check one real "Biz file summary" line before applying.

## Related files

| File | Purpose |
|---|---|
| `12-gov-inquiry-system-alerts-tf-check-main.tf` | All 7 alerts |
| `12.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/11-eopt-serverless-alerts-tf-check/` | eopt-serverless.tf check |
| `2026-10-05/9-customer-process-api-alerts-tf-check/` | Same "notice, not a problem" pattern |

## Commands

See `12.sh` (not run).
