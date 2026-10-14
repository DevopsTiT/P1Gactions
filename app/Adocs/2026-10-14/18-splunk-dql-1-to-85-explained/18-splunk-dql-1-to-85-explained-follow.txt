# Splunk To DQL 1 To 85 Explained

## Decision tree

```
Look at a Splunk search → which pattern is it?
 host= / index= / sourcetype= + words or phrases  → Pattern A: source filter + text filter
 ... | eval matched_keywords=mvappend(if(match...))  → Pattern B: tag which keywords matched
 replace(_raw) | spath | search message.url=...      → Pattern C: JSON log fields
 rex / auto key=value + stats / dedup / where        → Pattern D: extract a value, then count
 [ subsearch ] AND ...                                → Pattern E: lookup on a shared ID
 metadata / _internal / openshift_stats / lookup     → Pattern F: Splunk-only data, rebuild
 strptime + relative_time                             → Pattern G: date math (expiry checks)

Then in Dynatrace:
 0 rows? → run the check query → name in pod / host / namespace?
   found → fix the source filter
   not found → logs not in Dynatrace (often S3-only) → onboarding request
```

## Short takeaway

| Question | Answer |
|---|---|
| How many SPLs were translated? | 80 of 85. #10, #56 to #65, and #77 never appeared in a screenshot. |
| What is the most common pattern? | Pattern A: pick the app, then search for words. |
| Biggest Splunk-to-Dynatrace difference | Dynatrace has no `index` or `sourcetype`. You filter on pod, host, namespace, or container instead. |
| Second biggest difference | Splunk bare words ignore case and match whole words. DQL `contains()` is case-sensitive and matches any substring. |
| Which SPLs cannot be copied directly? | #14, #17, #18, #21, #76, #81. They read Splunk's own data. |
| What to run first in Dynatrace | The check query, to confirm the app's logs exist and which field holds the name. |

## Summary

All 80 visible searches fall into seven patterns. Once you know the pattern, the DQL is almost mechanical: replace the Splunk source label with a pod or host filter, replace word search with `contains()` or `matchesPhrase()`, and replace Splunk commands one for one. The real risk is not syntax. It is whether the app's logs reach Dynatrace at all, because several apps (pc2, bc2, eopt) only send logs to S3 and Splunk.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| SPL | Splunk Processing Language, the Splunk query language. | The input you are translating. |
| DQL | Dynatrace Query Language. | The output you are writing. |
| Grail | Dynatrace storage for logs, metrics, and events. | `fetch logs` reads from here. |
| `_raw` / `content` | The full log line. Splunk calls it `_raw`, Dynatrace calls it `content`. | Most text filters run on this field. |
| `_time` / `timestamp` | When the log happened. | Used for sorting, binning, and time math. |
| `index` | Splunk storage area. | Does not exist in Dynatrace. |
| `sourcetype` | Splunk label for log format. | Does not exist in Dynatrace. |
| `host.name` | Host or pod name in Dynatrace. | App-only OneAgent pods show up here. |
| `k8s.pod.name` | Kubernetes pod name. | Often holds the app name for container apps. |
| Pipe `|` | Sends results to the next command. | Same idea in both languages. |

### Command map (Splunk to DQL)

| Splunk | DQL | Notes |
|---|---|---|
| `search` (start of query) | `fetch logs, from:now()-24h` | DQL always needs a time range. |
| `host="X"` | `lower(host.name) == "x"` | Splunk ignores case on `host=`. |
| `host="X*"` | `startsWith(host.name, "X")` | Prefix match. |
| `index=X*` | `startsWith(src, "x")` where `src = lower(coalesce(k8s.pod.name, host.name))` | Our standard replacement for index. |
| `sourcetype=X` | `contains(k8s.container.name, "X")` or pod or `log.source` | Confirm with a check query. |
| Bare word `error` | `matchesPhrase(content, "error")` | Whole word, case ignored. |
| Quoted phrase `"Failed to get lock"` | `contains(content, "Failed to get lock", caseSensitive:false)` | Splunk ignores case. |
| Quoted phrase with `*` inside | Split into several `contains()` | DQL `contains()` has no wildcard. |
| `match(_raw, "X")` | `contains(content, "X")` | `match()` is case-sensitive. So is plain `contains()`. |
| `A OR B` | `a or b` | |
| Implicit AND (space) | `and` | |
| `NOT X` | `not contains(content, "X")` | |
| `eval x = ...` | `fieldsAdd x = ...` | |
| `rex "(?<x>...)"` | `parse content, "..."` or `indexOf` + `substring` | DQL has no regex extract. |
| `spath` | `parse raw, "JSON:j"` then `j[message][url]` | |
| `replace(_raw, a, b)` | `replaceString(content, a, b)` | |
| `mvappend(if(...), null())` | `arrayRemoveNulls(array(if(...)))` | |
| `strftime(_time, ...)` | `formatTimestamp(timestamp, format:..., timezone:"Asia/Tokyo")` | |
| `strptime(x, ...)` | `parse x, "TIMESTAMP('...')"` | |
| `relative_time(now(), "+30d")` | `now() + 30d` | |
| `table a b c` | `fields a, b, c` | Put `sort` before `fields`. |
| `sort - x` | `sort x desc` | |
| `dedup x` | `dedup x` | |
| `stats count by x` | `summarize count = count(), by:{ x }` | |
| `stats values(x)` | `collectDistinct(x)` | |
| `stats dc(x)` | `countDistinctExact(x)` | |
| `where count > 1` | `filter count > 1` | |
| `bin _time span=1d` | `bin(timestamp, 1d)` | |
| `timechart span=1m count by x` | `makeTimeseries count(), by:{ x }, interval:1m` | |
| `earliest=-1d` | `from:now()-1d` | |
| `[ subsearch ]` | `lookup [ ... ], sourceField:, lookupField:` | |
| `metadata type=hosts` | `summarize max(timestamp) by host.name` | |

### Splunk rules that change the translation

| Rule | What it means | Example |
|---|---|---|
| Bare words ignore case | `error` matches `ERROR` and `Error`. | #11, #37 |
| Bare words match whole words | `connect` does not match `connection`. | #32 |
| `match()` and `regex` are case-sensitive | The tag column only matches exact case. | #1, #8 |
| `OR` binds tighter than implicit AND | `(a OR b) c` and `a OR b c` both mean (a or b) and c. | #32, #54 |
| `*` inside quotes is a wildcard | `"Record with ID * has ..."` needs to be split. | #35, #69 |
| `\[` is an escaped bracket | DQL `contains()` needs no escaping. | #51 |
| `field=value` is a field match | `errcode=E01` means the field equals E01, not a substring. | #50 |
| `#` at line start is a comment | `#OR "Operation started"` is ignored. | #32 |

### The seven patterns

| Pattern | What it does | SPLs |
|---|---|---|
| A. Source + text | Pick the app, then search words or phrases. | #2, #4, #5, #7, #11–#13, #15, #16, #19, #29–#31, #33–#40, #42–#46, #48, #49, #51–#55, #66, #68–#71, #73–#75 |
| B. Keyword tags | Same as A, plus a column listing which keywords matched. | #1, #6, #8, #9 |
| C. JSON fields | Unescape the line, parse JSON, filter on url, type, or level. | #20, #23–#28, #82–#85 |
| D. Extract and count | Pull a value out of text, then dedup, group, or count. | #3, #41, #47, #50, #67 |
| E. Subsearch to lookup | Find IDs in one set of lines, then show other lines with those IDs. | #72, #78–#80 |
| F. Splunk-only data | Rebuild from logs or metrics because Dynatrace lacks Splunk's internal data. | #14, #17, #18, #21, #76, #81 |
| G. Date math | Parse a date from the text and compare to now. | #22, #41, #47 |

## Result

### Every SPL, one row each

| # | What the Splunk search finds | How the DQL works | Pattern | Answer |
|---|---|---|---|---|
| 1 | Exceptions and ERROR lines from two envelope hosts, with a keyword tag column. | `in(host.name, ...)`, `contains()` per keyword, `arrayRemoveNulls` tags. | B | 1 |
| 2 | pc2-batch "Exception occured for job" during afterBind_Adj. | Pod prefix plus two `contains()`. | A | 2 |
| 3 | bc2 GMO order IDs that repeat with only the time part different. | Cut `orderid` with `indexOf` and `substring`, build a pattern, count > 1. | D | 3 |
| 4 | ERROR or FATAL from Camunda identity, zeebe, keycloak pods. | Pod prefixes plus case-sensitive `contains()`. | A | 4 |
| 5 | ERROR in Camunda Operate pods. | Pod prefix plus `contains("ERROR")`. | A | 5 |
| 6 | Seven error phrases from biloss-retrieve-files-cmx, tagged. | `lower(host.name) ==`, phrase filter, tag column. | B | 6 |
| 7 | "CMX Error" from biloss-retrieve-files-cmx. | One host, one phrase. | A | 7 |
| 8 | Seven error phrases from three BILoss hosts, tagged. | `in(lower(host.name), ...)`, tag column. | B | 8 |
| 9 | Three error phrases from biloss-upload-to-cmx, tagged. | One host, tag column. | B | 9 |
| 10 | Not shown in any screenshot. | Not translated. | n/a | n/a |
| 11 | error, failed, severe, or access log with 404, 500, 503. | `matchesPhrase()` per word, access source plus status codes. | A | 10 |
| 12 | Same as #11. | Same DQL. | A | 10 |
| 13 | pc2-ui lines calling the legacy claims ESB URL with FAIL. | Source filter, URL split into host and path, `matchesPhrase("FAIL")`. | A | 10 |
| 14 | Splunk license bytes per day by source, host, index. | Sum of `stringLength(content)` per day. Approximate. | F | 11 |
| 15 | mailservice AuthenticationFailedException. | mailservice source filter plus `contains()`. | A | 11 |
| 16 | mailservice Tomcat startup (restarts). | `matchesPhrase("Catalina.start Server startup")`. | A | 11 |
| 17 | Splunk throughput: events per minute, top 5 sources. | `makeTimeseries count()` by `log.source`, top 5. | F | 11 |
| 18 | Prod hosts silent for more than 1 hour. | `max(timestamp)` per host, seconds since, > 3600. | F | 11 |
| 19 | esbv4 cannot send HTTP request to NetSuite. | esbv4 source plus phrase. | A | 12 |
| 20 | Distinct account numbers per day, portals-amp-frontend. | JSON parse, first word, `countDistinctExact` per day. | C | 13 |
| 21 | pc-ui container CPU as % of limit, per pod. | `timeseries` on Kubernetes CPU usage and limit metrics. | F | 13 |
| 22 | esbv4 license expiring within 100 days. | Cut date, parse, `< now() + 100d`. | G | 13 |
| 23 | doCancel with CAUGHT_EXCEPTION_ON_BACKEND, 1 day. | JSON parse, filter url and type. | C | 13 |
| 24 | doCancel with EXECUTION_COMPLETED, 1 day. | Same as #23, other type. | C | 13 |
| 25 | doesRefundExist with EXECUTION_COMPLETED, 1 day. | Same as #23, other url. | C | 13 |
| 26 | isPolicyCancelAvailable with EXECUTION_COMPLETED, 1 week. | Same as #23, 7 days. | C | 13 |
| 27 | isPolicyCancelAvailable with EXECUTION_COMPLETED, 1 day. | Same as #23. | C | 13 |
| 28 | Error level on applySimplePayment, claim-customer apps. | JSON parse, `level` and `message.url`. | C | 13 |
| 29 | inssuite-prod BadInputException ContactName. | Host contains `-inssuite-prod-`, phrase. | A | 13 |
| 30 | pc2-ui Metaspace exhausted. | pc2-ui source, phrase. | A | 13 |
| 31 | alfrescoacr "Failed to get lock". | alfrescoacr source, phrase. | A | 13 |
| 32 | SSL, timeout, socket, connect across about 30 apps, count per app. | `matchesValue(src, [...])`, `matchesPhrase()`, count per namespace. | A | 14 |
| 33 | pc2-batch bcCancellationFinished_Adj and WaitForMidNight. | Prefix, two whole words. | A | 14 |
| 34 | bc2 GMO SEARCHTRADE exception. | Prefix, phrase (Japanese part unreadable). | A | 14 |
| 35 | bc2-batch DirectDebit rows with different PaymentDueDate. | Prefix, phrase split around `*`. | A | 14 |
| 36 | bc2 ConcurrentDataChangeException in PolicyDlnqProcess. | Prefix, two phrases. | A | 14 |
| 37 | bcsubledger Exception, ERROR, or WARN. | Prefix, three whole words. | A | 14 |
| 38 | bc2-ui GMO error code E01050004. | Prefix, phrase. | A | 14 |
| 39 | bc2 CVS offline payment notification exception. | Prefix, ERROR word plus two phrases. | A | 14 |
| 40 | bc2 MultipleMatchesException on ContactID_Adj. | Prefix, phrase plus two words. | A | 14 |
| 41 | bc2-batch CVS Offline quick records appearing more than once. | `parse` key=value, count > 1, sort by parsed date. | D | 14 |
| 42 | "API - Exception when executing" in bc2-ui, bc2-batch, bcsubledger. | Three prefixes, phrase. | A | 14 |
| 43 | GMO EXECTRAN exception in the same three apps. | Three prefixes, phrase. | A | 14 |
| 44 | Same as #38. | Same DQL. | A | 14 |
| 45 | Same as #39. | Same DQL. | A | 14 |
| 46 | Same as #40. | Same DQL. | A | 14 |
| 47 | Same as #41. | Same DQL. | D | 14 |
| 48 | Same as #42. | Same DQL. | A | 14 |
| 49 | Same as #43. | Same DQL. | A | 14 |
| 50 | bc2-ui errcode E01, minus three known errinfo codes. | `parse` errcode, `== "E01"`, three `not contains()`. | D | 15 |
| 51 | bc2-batch saveCardWithOrderID errors on MW-Writer-[54]. | Prefix, two phrases, brackets literal. | A | 15 |
| 52 | GMO SearchTrade used to confirm ExecTran status. | Three prefixes, phrase. | A | 15 |
| 53 | Same as #43. | Same DQL. | A | 15 |
| 54 | pc2-ui or bc2-ui "Operation failed" about a Producer. | Two prefixes, phrase, Producer phrase (Japanese unreadable). | A | 15 |
| 55 | bc2 "Producer Contact is missing for Producer". | Prefix, phrase. | A | 15 |
| 56–65 | Not shown in any screenshot. | Not translated. | n/a | n/a |
| 66 | cc apps NoUpdatePaymentError. | Prefix, phrase. | A | 16 |
| 67 | ERROR lines from sonpov and temp-receipt-accounting, grouped by time. | `parse` level at line start, `== "ERROR"`, `collectDistinct`. | D | 16 |
| 68 | cc-ui removeDocument called. | Prefix, phrase. | A | 16 |
| 69 | esbv4 call to ebroker failed with 503. | Prefix, phrase split around `*`. | A | 16 |
| 70 | ebroker address conversion failures. | Prefix, two phrases with OR. | A | 16 |
| 71 | ebroker startup (restarts). | Prefix, phrase. | A | 16 |
| 72 | esbv4 ebroker requests whose ID hit an Interceptor exception. | `lookup` on request ID. | E | 16 |
| 73 | ebroker POST /request/ottif started. | Prefix, phrase. | A | 16 |
| 74 | esbv4 call to pc quote endpoint failed. | Prefix, phrase up to the `*`. | A | 16 |
| 75 | esbv4 cannot reach localhost:8082. | Prefix, phrase. | A | 16 |
| 76 | Apps (sourcetypes) silent for more than 1 hour. | App name from workload, `max(timestamp)`, > 3600 s. | F | 16 |
| 77 | Not shown in any screenshot. | Not translated. | n/a | n/a |
| 78 | inswebauto quote requests that hit the pc quote timeout. | `lookup` on request ID. | E | 17 |
| 79 | inswebbike quote requests that hit the pc quote timeout. | `lookup` on request ID. | E | 17 |
| 80 | kakakucomauto quote requests that hit the pc quote timeout. | `lookup` on request ID. | E | 17 |
| 81 | ebroker SSL certificate expiring within 30 days. | Grail lookup file, or Synthetic monitor certificate check. | F | 17 |
| 82 | Error level on save, ampupdateCoverages, quote, bind. | JSON parse, `in(msg_url, ...)`, level error. | C | 17 |
| 83 | payWithCreditCard_Adj CAUGHT_EXCEPTION_ON_BACKEND, 1 day. | JSON parse, url and type. | C | 17 |
| 84 | payWithCreditCard_Adj EXECUTION_COMPLETED, 1 day. | Same as #83, other type. | C | 17 |
| 85 | payWithCreditCard_Adj EXECUTION_COMPLETED, 1 hour. | Same as #84, 1 hour. | C | 17 |

### One worked example per pattern

**Pattern A (source + text), #31**

```
Splunk:  index="alfrescoacr" "Failed to get lock"

DQL:
fetch logs, from:now()-24h
| filter contains(k8s.pod.name, "alfrescoacr", caseSensitive:false)
| filter contains(content, "Failed to get lock", caseSensitive:false)
| sort timestamp desc
```

Read it as: get logs from the last day, keep the alfrescoacr pods, keep lines with the phrase, newest first.

**Pattern B (keyword tags), #9**

```
Splunk:  ... | eval matched_keywords=mvappend(if(match(_raw,"CMX Error"),"CMX Error",null()), ...)

DQL:
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CMX Error"), "CMX Error"),
    if(contains(content, "RuntimeException"), "RuntimeException")))
```

Each `if()` returns the keyword or nothing. `arrayRemoveNulls` drops the nothings. You get a list of keywords found on that line.

**Pattern C (JSON fields), #23**

```
Splunk:  ... | eval _raw=replace(...) | spath | search message.url="doCancel" message.type="CAUGHT_EXCEPTION_ON_BACKEND"

DQL:
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter msg_url == "doCancel" and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
```

The app writes JSON with escaped quotes. Unescape, parse, then read nested fields.

**Pattern D (extract and count), #50**

```
Splunk:  index=bc2-ui* "Map returned by method call" AND errcode=E01 AND NOT E01130002 ...

DQL:
| parse content, "LD 'errcode=' ALNUM:errcode"
| filter errcode == "E01"
| filter not contains(content, "E01130002")
```

Splunk pulls `errcode` automatically. DQL must parse it first.

**Pattern E (subsearch to lookup), #79**

```
Splunk:  index=esbv4 [ search "...Timeout exceeded." | rex "(?<query>uuid)" | fields query | format ]
         AND "Sending request to /esb/ebroker/inswebbike/online/_quote"

DQL:
fetch logs | filter "Sending request ... inswebbike" | parse uuid as query
| lookup [ fetch logs | filter "Timeout exceeded." | parse uuid as query | fields query ],
         sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
```

Step 1 finds IDs of timed-out calls. Step 2 keeps request lines with those IDs.

**Pattern F (Splunk-only data), #18**

```
Splunk:  | metadata type=hosts | eval Last_Seen=now()-recentTime | where Last_Seen > 3600

DQL:
fetch logs, from:now()-7d
| summarize last_event = max(timestamp), by:{ host.name }
| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000
| filter last_seen_sec > 3600
```

Splunk keeps a host list. Dynatrace does not, so we compute the last log time ourselves.

**Pattern G (date math), #22**

```
Splunk:  | rex "Expiration Date = (?<expiration_date>...)" | eval e=strptime(...) | where e < relative_time(now(), "+100d")

DQL:
| fieldsAdd expiration_date = trim(substring(content, from:indexOf(content, "Expiration Date = ") + 18))
| parse replaceString(expiration_date, " JST ", " "), "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):exp_as_utc"
| filter exp_as_utc - 9h < now() + 100d
```

Cut out the date, parse it, adjust JST to UTC, compare.

### Common mistakes to avoid

| Mistake | What happens | Fix |
|---|---|---|
| Forgetting `caseSensitive:false` on phrases | Misses lines Splunk would find. | Add it whenever Splunk would ignore case. |
| Using `contains()` for Splunk bare words | Finds extra lines (`errors`, `terror`). | Use `matchesPhrase()`. |
| `fields` before `sort timestamp` | Sort fails because `timestamp` was dropped. | Sort first, then `fields`. |
| Trusting `host.name` for pods | Some apps put the name in `k8s.pod.name`. | Use `coalesce(k8s.pod.name, host.name)`. |
| Assuming the logs exist | 0 rows looks like "no errors". | Run the check query. 0 lines total means not onboarded. |
| Copying `*` inside a phrase | `contains()` looks for a literal star. | Split the phrase. |
| Forgetting a time range | DQL uses the default window, which may be too short or too costly. | Always set `from:`. |

### Things still open

| Item | What to do |
|---|---|
| #10, #56–#65, #77 | Send screenshots to translate them. |
| Japanese text in #29, #34, #54 | Unreadable in screenshots. Paste the text to complete the filters. |
| Source field per app | Run the check queries once and lock the filter to the matching field. |
| S3-only apps (pc2, bc2, eopt and others) | If check queries return nothing, raise an onboarding request. |
| #21 metric names | Confirm they exist in the tenant. |
| #81 certificate check | Prefer a Synthetic HTTP monitor with certificate expiry check. |

## Data flow map

```
Splunk search
  -> identify pattern (A to G)
  -> source:  index / host / sourcetype  ->  src = lower(coalesce(k8s.pod.name, host.name))
  -> text:    bare word -> matchesPhrase   |  quoted phrase -> contains(caseSensitive:false)
  -> shape:   eval -> fieldsAdd  |  rex -> parse  |  spath -> parse JSON
  -> result:  stats -> summarize  |  table -> fields  |  timechart -> makeTimeseries
  -> special: subsearch -> lookup  |  metadata / _internal -> rebuild from logs or metrics

Dynatrace run
  fetch logs -> source filter -> text filter -> shape -> result
  0 rows? -> check query -> fix field  or  onboarding request
```

## Related files

| File | What it holds |
|---|---|
| `0-pic.md` | Pattern decision tree and data flow |
| `1-investigation.md` | Command map and Splunk rules |
| `2-result.md` | The 1 to 85 table |
| `3-glossary.md` | Glossary |
| `18.sh` | Git one-liners |
| Answers 1 to 17 (same date) | Full DQL for each SPL, with check queries |

## Commands

See `18.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/18-splunk-dql-1-to-85-explained
git commit -m "Splunk to DQL 1 to 85 explained"
git push
```
