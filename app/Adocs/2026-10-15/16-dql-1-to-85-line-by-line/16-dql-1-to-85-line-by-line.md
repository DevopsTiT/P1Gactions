# DQL 1 To 85 Line By Line

## Decision tree

```
Reading any DQL line → which job does it do?
 fetch logs, from: → which data and how far back
 fieldsAdd src = lower(coalesce(k8s.pod.name, host.name)) → stand-in for Splunk index
 filter startsWith / contains / matchesPhrase / in → keep rows
 parse / indexOf + substring / replaceString → pull values out of text
 fieldsAdd → make a new column
 summarize / makeTimeseries → group, count, chart
 lookup [ ... ] → join a second query (Splunk subsearch)
 sort / fields / dedup / limit → order and choose columns
Query returns 0 rows?
 → run only the fetch + source filter lines
   0 rows → logs not in Dynatrace (portals-amp) or wrong source field
   rows → a text filter is wrong (case, == on a full URL, wildcard copied)
```

## Short takeaway

| Question | Answer |
|---|---|
| How many queries are explained? | All 85 numbers. #10 has no DQL because the Splunk query was never shown. |
| Which are repeats? | #12, #44 to #49, #53, #56, and the channel variants #79 and #80. |
| Which were corrected? | The portals-amp JSON queries (#23 to #28, #82 to #85) now use `contains` or `endsWith` on the URL instead of `==`. |
| Which return 0 today for a known reason? | #20, #23 to #28 and #82 to #85, because portals-amp logs are not in Dynatrace yet. |
| Most common shape | `fetch logs`, then a source filter, then one or more text filters, then `sort` and `fields`. |

## Summary

Each entry shows the main DQL query, a table that explains every line and names the Splunk part it replaces, and a "Watch out" line on the most likely silent failure. Helper queries (check, count, chart) are listed by purpose under each entry. Read the basics table at the top of each part first.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| DQL | Dynatrace Query Language. Each line takes rows from the line above and passes them down. |
| Grail | The Dynatrace storage that `fetch logs` reads from. |
| `content` | The full log line. Splunk calls it `_raw`. |
| `timestamp` | The event time. Splunk calls it `_time`. |
| `src` | Our helper field: the pod name, or the host name when there is no pod. It replaces Splunk `index`. |
| `contains` | Substring match. Case-sensitive unless `caseSensitive:false` is added. Used for Splunk quoted phrases. |
| `matchesPhrase` | Whole word or phrase match that ignores case. Used for Splunk bare words. |
| `parse` | Pulls values out of text with DPL patterns such as `LD`, `DIGIT` and `JSON`. Replaces Splunk `rex` and `spath`. |
| `lookup` | Joins rows from a second query on a shared field. Replaces a Splunk subsearch. |

### Where each DQL came from

| Queries | Source answer |
|---|---|
| #1 to #31 | 2026-10-14 answers 1 to 13 (#7 from 2026-10-15 answer 7) |
| #32 to #43 | 2026-10-14 answer 14 |
| #44 to #60 | 2026-10-15 answers 4, 5 and 6 |
| #61 to #65 | 2026-10-15 answer 6 |
| #66 to #76 | 2026-10-14 answer 16 |
| #77 to #80 | 2026-10-15 answers 1 and 3 |
| #81 | 2026-10-15 answer 11 |
| #82 to #85 | 2026-10-14 answers 17, 19 and 24, and 2026-10-15 answer 8 |

## Result

The full line-by-line explanation follows in three parts.

## Part 1: DQL 1 to 30

This part walks through the Dynatrace DQL translations of Splunk queries #1 to #30, one line at a time. DQL (Dynatrace Query Language) works like a pipeline. The first line reads records. Each `|` line then takes the rows from the line above, changes them, and passes them down.

These are the basic ideas used again and again in this part:

| Term | What it means |
|---|---|
| Record | One stored item. For logs, one record is one log line. |
| Field | One named value on a record, such as `host.name` or `timestamp`. |
| `content` | The field that holds the full text of the log line. It is the DQL version of Splunk `_raw`. |
| `host.name` | The field that holds the host or service name. It is the closest match to Splunk `host`. |
| `k8s.pod.name` | The Kubernetes pod name. A pod is one running copy of an app in Kubernetes. |
| `log.source` | Where the log came from, such as a file path or stream name. It is the usual stand-in for Splunk `sourcetype`. |
| Pipe `\|` | Passes the rows from one command to the next. |
| `//` | Starts a comment. DQL ignores the rest of that line. |
| Case-sensitive | `ERROR` and `error` count as different text. Most DQL text checks are case-sensitive unless you say otherwise. |
| Main query | The query that does the same job as the Splunk search. |
| Check query | A helper query that finds where the data lives in Dynatrace. Run it when the main query returns 0 rows. |

---

### #1 Envelope Exceptions With Keyword Tags

**What it finds:** Exception and ERROR lines from two envelope services, with a column listing which exception names appear in each line.

```
fetch logs, from:now()-24h
| filter in(host.name, array("biloss-envelope-list-prod", "start-envelope-executions-prod"))
| filter contains(content, "Exception", caseSensitive:false)
    or contains(content, "ERROR", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "CmxApiException"), "CmxApiException"),
    if(contains(content, "NetworkException"), "NetworkException"),
    if(contains(content, "PSQLException"), "PSQLException"),
    if(contains(content, "NullPointerException"), "NullPointerException"),
    if(contains(content, "IllegalArgumentException"), "IllegalArgumentException"),
    if(contains(content, "Exception"), "Exception"),
    if(contains(content, "ERROR"), "ERROR")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | `fetch` reads records from a data type. `logs` is the log data. `from:` sets the start of the time range. `now()-24h` means 24 hours ago. | The Splunk time picker. The search had no index. |
| `\| filter in(host.name, array("biloss-envelope-list-prod", "start-envelope-executions-prod"))` | `filter` keeps only rows where the condition is true. `array(...)` builds a list. `in(x, list)` is true when x is exactly one of the list values. The match is case-sensitive. | `(host="biloss-envelope-list-prod" OR host="start-envelope-executions-prod")` |
| `\| filter contains(content, "Exception", caseSensitive:false)` | `contains(text, word)` is true when the word appears anywhere in the text. `caseSensitive:false` makes it ignore case. | `\| search ("Exception" ...` |
| `or contains(content, "ERROR", caseSensitive:false)` | A second check joined with `or`, so either word is enough. | `... OR "ERROR")` |
| `\| fieldsAdd matched_keywords = arrayRemoveNulls(array( ... ))` | `fieldsAdd` creates a new field on each row. `array(...)` holds one result per keyword. `arrayRemoveNulls` throws away the empty results, so only the found keywords stay. | `\| eval matched_keywords=mvappend(...)` |
| `if(contains(content, "RuntimeException"), "RuntimeException")` and the seven lines like it | `if(condition, value)` returns the value when the condition is true. With no else value, it returns null, which means empty. This `contains` has no `caseSensitive` option, so it is case-sensitive. | `if(match(_raw,"RuntimeException"),"RuntimeException",null())` |
| `\| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` | `formatTimestamp` turns a time value into readable text. `timezone:` shows it in Japan time. | `\| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S %Z")` |
| `\| sort timestamp desc` | `sort` orders the rows. `desc` puts the newest first. | (none) Splunk shows newest first by default. |
| `\| fields time, host.name, matched_keywords, content` | `fields` keeps only the listed columns, in this order. | `\| table time host matched_keywords _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: where do these names live | Searches `host.name`, `log.source`, and `content` for "envelope" and counts lines per field value. Use it to find the real field name if the main query is empty. |
| Extra: lines per keyword and host | Same filters, then `expand` turns each keyword in the list into its own row, and `summarize` counts rows per host and keyword. |

**Watch out:** `in(host.name, ...)` is an exact, case-sensitive match, so if Dynatrace stores the name with different case or in `k8s.pod.name` instead, the query returns 0 rows.

---

### #2 PC2 Batch AfterBind Exception

**What it finds:** Lines from the pc2 batch pods that say a job threw an exception during the afterBind_Adj step.

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "pc2-batch-inssuite-prod-")
    or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")
| filter contains(content, "Exception occured for job", caseSensitive:false)
    and contains(content, "during afterBind_Adj process", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter startsWith(host.name, "pc2-batch-inssuite-prod-")` | `startsWith(text, prefix)` is true when the text begins with the prefix. It is case-sensitive. | `index="pc2-batch" host="pc*"` |
| `or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")` | Also accepts the name in the pod field, in case Dynatrace stores it there. | (none) Splunk only had `host`. |
| `\| filter contains(content, "Exception occured for job", caseSensitive:false)` | Keeps lines with the first phrase, any case. The spelling "occured" matches the app's own log. | `\| search "Exception occured for job"` |
| `and contains(content, "during afterBind_Adj process", caseSensitive:false)` | `and` means the second phrase must also be present. | `AND "during afterBind_Adj process"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, k8s.pod.name, content` | Shows these four columns. | `\| fields + _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check 1: are pc2-batch logs in Dynatrace | Looks for "pc2-batch" or "pc2" in host, pod, namespace, and source fields, and counts lines per value. |
| Check 2: phrase only, no host filter | Searches 7 days for the afterBind phrase alone. `takeFirst` keeps one sample line per group. It finds the lines even if the host field is different. |
| Extra: how often per day and pod | Same filters over 7 days, counted per day with `bin(timestamp, 1d)` and per host. |

**Watch out:** Splunk gets pc2-batch logs from an S3 bucket, so if that path is not onboarded into Dynatrace the query quietly returns 0 rows; run Check 1 first.

---

### #3 BC2 GMO Duplicate Order IDs

**What it finds:** GMO payment order IDs that appear more than once when you ignore the 6-character time part, which can point to duplicate payments.

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "bc2-") or startsWith(k8s.pod.name, "bc2-")
| filter contains(content, "Integration.GMO")
    and contains(content, "Map returned by method call", caseSensitive:false)
    and contains(content, "[acs=0&paytimes=&tranid=")
    and contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")
    and contains(content, "&orderid=")
    and contains(content, "&trandate=")
| fieldsAdd after_orderid = substring(content, from: indexOf(content, "&orderid=") + 9)
| fieldsAdd orderid = substring(after_orderid, from:0, to: indexOf(after_orderid, "&"))
| dedup orderid
| filter stringLength(orderid) >= 24
| fieldsAdd OrderID_noTime = substring(orderid, from:0, to:18),
            Time = substring(orderid, from:18, to:24),
            Rest = substring(orderid, from:24)
| fieldsAdd OrderIDPattern = concat(OrderID_noTime, "*", Rest)
| summarize count = count(), orderids = collectDistinct(orderid), by:{ OrderIDPattern }
| filter count > 1
| sort count desc
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter startsWith(host.name, "bc2-") or startsWith(k8s.pod.name, "bc2-")` | Keeps rows whose host or pod name begins with "bc2-". | `index=bc2*` |
| `\| filter contains(content, "Integration.GMO")` | Keeps lines with the GMO logger name. Case-sensitive. | `Integration.GMO` |
| `and contains(content, "Map returned by method call", caseSensitive:false)` | The line must also have this phrase, any case. | `AND "Map returned by method call"` |
| `and contains(content, "[acs=0&paytimes=&tranid=")` | First fixed piece of the GMO parameter string. | The start of the `"[acs=0&...]"` phrase. |
| `and contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")` | Second fixed piece of the parameter string. | The middle of the `"[acs=0&...]"` phrase. |
| `and contains(content, "&orderid=")` | Makes sure an order ID is present. | The `&orderid=*` part. |
| `and contains(content, "&trandate=")` | Makes sure a transaction date is present. | The `&trandate=*` part. |
| `\| fieldsAdd after_orderid = substring(content, from: indexOf(content, "&orderid=") + 9)` | `indexOf(text, word)` gives the position where the word starts. `substring(text, from:, to:)` cuts out part of the text. Adding 9 skips the 9 characters of "&orderid=", so this keeps everything after it. | Splunk's automatic `orderid=` field extraction. |
| `\| fieldsAdd orderid = substring(after_orderid, from:0, to: indexOf(after_orderid, "&"))` | Cuts from the start up to the next "&". The result is just the order ID value. `to:` is not included in the result. | Splunk's automatic `orderid=` field extraction. |
| `\| dedup orderid` | `dedup` keeps only one row for each order ID value. | `\| dedup orderid` |
| `\| filter stringLength(orderid) >= 24` | `stringLength` counts characters. IDs shorter than 24 cannot be split into the three parts, so they are dropped. | (none) Splunk's `rex` silently skips short IDs. |
| `\| fieldsAdd OrderID_noTime = substring(orderid, from:0, to:18),` | The first 18 characters. | `(?<OrderID_noTime>.{18})` in `rex` |
| `Time = substring(orderid, from:18, to:24),` | The next 6 characters, which hold the time part. | `(?<Time>.{6})` in `rex` |
| `Rest = substring(orderid, from:24)` | Everything after character 24. | `(?<Rest>.*)` in `rex` |
| `\| fieldsAdd OrderIDPattern = concat(OrderID_noTime, "*", Rest)` | `concat` joins text. This builds the ID with the time part replaced by a star. | `\| eval OrderIDPattern=OrderID_noTime."*".Rest` |
| `\| summarize count = count(), orderids = collectDistinct(orderid), by:{ OrderIDPattern }` | `summarize` groups rows and calculates per group. `count()` counts rows. `collectDistinct` lists the different order IDs in the group, so you can see the real duplicates. `by:` sets the grouping field. | `\| stats count by OrderIDPattern` |
| `\| filter count > 1` | Keeps only patterns seen more than once. | `\| where count > 1` |
| `\| sort count desc` | Biggest groups first. | `\| sort - count` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check 1: are bc2 logs in Dynatrace | Looks for "bc2" in host, pod, and namespace fields, and counts lines per value. |
| Check 2: does the orderid cut work | Runs the same cutting steps without grouping and shows 20 rows with `limit 20`, so you can eyeball the three parts. |

**Watch out:** the `Integration.GMO` and parameter-string checks are case-sensitive, and bc2 logs come to Splunk from S3, so either a case difference or missing onboarding gives 0 rows.

---

### #4 Camunda Error And Fatal

**What it finds:** Lines with uppercase ERROR or FATAL from Camunda 8 identity, Zeebe, Zeebe gateway, and Keycloak pods.

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "camunda8-prod-identity-")
    or startsWith(host.name, "camunda8-prod-zeebe-")
    or startsWith(host.name, "camunda8-prod-keycloak-")
    or startsWith(k8s.pod.name, "camunda8-prod-identity-")
    or startsWith(k8s.pod.name, "camunda8-prod-zeebe-")
    or startsWith(k8s.pod.name, "camunda8-prod-keycloak-")
| filter contains(content, "ERROR") or contains(content, "FATAL")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "ERROR"), "ERROR"),
    if(contains(content, "FATAL"), "FATAL")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, k8s.pod.name, matched_keywords, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter startsWith(host.name, "camunda8-prod-identity-")` | Keeps the identity component by host prefix. | `host="camunda8-prod-identity-*"` |
| `or startsWith(host.name, "camunda8-prod-zeebe-")` | Keeps Zeebe. This prefix also covers the Zeebe gateway. | `host="camunda8-prod-zeebe-*" OR host="camunda8-prod-zeebe-gateway-*"` |
| `or startsWith(host.name, "camunda8-prod-keycloak-")` | Keeps Keycloak, the login service. | `host="camunda8-prod-keycloak-*"` |
| The three `or startsWith(k8s.pod.name, ...)` lines | The same three prefixes, checked on the pod name field. | (none) Splunk only had `host`. |
| `\| filter contains(content, "ERROR") or contains(content, "FATAL")` | Keeps lines with uppercase ERROR or FATAL. No `caseSensitive:false`, so lowercase is not matched. | `\| search ("ERROR" OR "FATAL")` plus `\| where isnotnull(matched_keywords)` |
| `\| fieldsAdd matched_keywords = arrayRemoveNulls(array( ... ))` | Builds the list of keywords found on each line. | `\| eval matched_keywords=mvappend(...)` |
| `if(contains(content, "ERROR"), "ERROR")` and the FATAL line | Each returns the keyword when present, or empty when not. | `if(match(_raw,"ERROR"),"ERROR",null())` |
| `\| fieldsAdd time = formatTimestamp(...)` | Readable Japan time column. | `\| eval time=strftime(...)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields time, host.name, k8s.pod.name, matched_keywords, content` | Shows five columns. | `\| table time host matched_keywords _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check 1: are camunda8 logs in Dynatrace | Looks for "camunda8" or "camunda" in host, pod, namespace, and source fields, and counts lines per value. |
| Extra: count per component and keyword | Uses `coalesce` to pick the pod name or host name, nested `if(..., else: ...)` to label each component, then counts rows per component and keyword. |

**Watch out:** the `sourcetype="camunda-platform"` part of the Splunk search has no DQL line, so if other apps use host names starting with these prefixes they would slip in, and if Camunda logs use a different pod naming the query returns 0 rows.

---

### #5 Camunda Operate Error

**What it finds:** Lines with uppercase ERROR from the Camunda 8 Operate pods.

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "camunda8-prod-operate-")
    or startsWith(k8s.pod.name, "camunda8-prod-operate-")
| filter contains(content, "ERROR")
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, k8s.pod.name, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter startsWith(host.name, "camunda8-prod-operate-")` | Keeps the Operate pods by host prefix. Operate is Camunda's web tool for watching processes. | `sourcetype="camunda-platform" host="camunda8-prod-operate-*"` |
| `or startsWith(k8s.pod.name, "camunda8-prod-operate-")` | Same prefix on the pod name field. | (none) |
| `\| filter contains(content, "ERROR")` | Keeps lines with uppercase ERROR only. One case-sensitive check replaces two Splunk stages. | `\| search "ERROR"` plus `\| regex _raw="ERROR"` |
| `\| fieldsAdd time = formatTimestamp(...)` | Readable Japan time column. | `\| eval time=strftime(...)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields time, host.name, k8s.pod.name, content` | Shows four columns. | `\| table time host _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: are Operate logs in Dynatrace | Finds rows where a host or pod name contains both "operate" and "camunda", and counts lines per field value. |

**Watch out:** this is case-sensitive on purpose, so lines that only say "Error" or "error" are not shown, which matches Splunk but can surprise you.

---

### #6 BILoss Retrieve Files CMX Seven Phrases

**What it finds:** Error lines from BILoss-retrieve-files-cmx-prod with any of seven error phrases, tagged with the phrases found.

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"
| filter contains(content, "CC Error", caseSensitive:false)
    or contains(content, "CmxApiException", caseSensitive:false)
    or contains(content, "NetworkException", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
    or contains(content, "Failed getCCInformations", caseSensitive:false)
    or contains(content, "NullPointerException", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CC Error"), "CC Error"),
    if(contains(content, "CmxApiException"), "CmxApiException"),
    if(contains(content, "NetworkException"), "NetworkException"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients"),
    if(contains(content, "Failed getCCInformations"), "Failed getCCInformations"),
    if(contains(content, "NullPointerException"), "NullPointerException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` | `lower` turns text into lowercase. Comparing the lowercase name to a lowercase value makes the host match ignore case. `==` means exactly equal. | `host="BILoss-retrieve-files-cmx-prod"` |
| `\| filter contains(content, "CC Error", caseSensitive:false)` | Keeps lines with "CC Error", any case. | `\| search ("CC Error" ...` |
| The six `or contains(..., caseSensitive:false)` lines | Each adds one more phrase. Any one of the seven is enough. | `OR "CmxApiException" OR ... OR "NullPointerException")` |
| `\| fieldsAdd matched_keywords = arrayRemoveNulls(array( ... ))` | Builds the list of phrases found on each line. | `\| eval matched_keywords=mvappend(...)` |
| `if(contains(content, "CC Error"), "CC Error")` and the six lines like it | Each returns the phrase when it appears with exact case. Lines that only have a lowercase phrase still show, with an empty list. | `if(match(_raw,"CC Error"),"CC Error",null())` |
| `\| fieldsAdd time = formatTimestamp(...)` | Readable Japan time column. | `\| eval time=strftime(...)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields time, host.name, matched_keywords, content` | Shows four columns. | `\| table time host matched_keywords _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: where does the name live | Looks for "retrieve-files-cmx" in host, source, and pod fields, and counts lines per value. |
| Extra: count per keyword | Builds the keyword list, uses `expand` to give each keyword its own row, drops empties with `isNotNull`, and counts rows per keyword. |

**Watch out:** if the service name is stored in `k8s.pod.name` with a pod suffix rather than in `host.name`, the exact `==` match returns 0 rows.

---

### #7 BILoss Retrieve Files CMX Error

**What it finds:** Lines that contain exactly "CMX Error" from BILoss-retrieve-files-cmx-prod.

This uses the corrected version from 2026-10-15.

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"
| filter contains(content, "CMX Error")
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` | Keeps one host, ignoring case. | `host="BILoss-retrieve-files-cmx-prod"` |
| `\| filter contains(content, "CMX Error")` | Keeps lines with exact-case "CMX Error". | `\| search "CMX Error"` plus `\| regex _raw="CMX Error"` |
| `\| fieldsAdd time = formatTimestamp(...)` | Readable Japan time column. | `\| eval time=strftime(...)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields time, host.name, content` | Shows three columns. | `\| table time host _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: does the host send logs at all | Lists every host with "biloss" in its name, with line counts and `max(timestamp)` as the last time seen. |

**Watch out:** "CMX Error" is not the same phrase as "CC Error" in #6, so do not swap them, and a lowercase "cmx error" line will not match.

---

### #8 BILoss Processing Three Hosts

**What it finds:** Error lines from three BILoss services with any of seven phrases, tagged with the phrases found.

```
fetch logs, from:now()-24h
| filter in(lower(host.name), array("biloss-processing-prod", "biloss-pre-processing-prod", "biloss-link-data-to-cc-prod"))
| filter contains(content, "CC Error", caseSensitive:false)
    or contains(content, "Camunda Error", caseSensitive:false)
    or contains(content, "callCamundaProcess error", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
    or contains(content, "PSQLException", caseSensitive:false)
    or contains(content, "IllegalArgumentException", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CC Error"), "CC Error"),
    if(contains(content, "Camunda Error"), "Camunda Error"),
    if(contains(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients"),
    if(contains(content, "PSQLException"), "PSQLException"),
    if(contains(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter in(lower(host.name), array(...three names...))` | Lowercases the host name, then keeps it if it is one of the three names. | `(host="BILoss-processing-prod" OR host="BILoss-pre-processing-prod" OR host="BILoss-link-data-to-cc-prod")` |
| `\| filter contains(content, "CC Error", caseSensitive:false)` | Keeps lines with "CC Error", any case. | `\| search ("CC Error" ...` |
| The six `or contains(..., caseSensitive:false)` lines | Each adds one more phrase. | `OR "Camunda Error" OR ... OR "IllegalArgumentException")` |
| `\| fieldsAdd matched_keywords = arrayRemoveNulls(array( ... ))` | Builds the list of phrases found. | `\| eval matched_keywords=mvappend(...)` |
| `if(contains(content, "CC Error"), "CC Error")` and the six lines like it | Case-sensitive tag for each phrase. | `if(match(_raw,...),...,null())` |
| `\| fieldsAdd time = formatTimestamp(...)` | Readable Japan time column. | `\| eval time=strftime(...)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields time, host.name, matched_keywords, content` | Shows four columns. | `\| table time host matched_keywords _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: where do the three names live | Looks for "biloss" in host, source, and pod fields, and counts lines per value. |
| Extra: count per host and keyword | Expands the keyword list into rows and counts per host and keyword. |

**Watch out:** the array values must be all lowercase, because the host name is lowercased before the compare; a capital letter in the list would never match.

---

### #9 BILoss Upload To CMX

**What it finds:** Lines from BILoss-upload-to-cmx-prod with any of three error phrases, tagged with the phrases found.

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-upload-to-cmx-prod"
| filter contains(content, "CMX Error", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CMX Error"), "CMX Error"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter lower(host.name) == "biloss-upload-to-cmx-prod"` | Keeps one host, ignoring case. | `host="BILoss-upload-to-cmx-prod"` |
| `\| filter contains(content, "CMX Error", caseSensitive:false)` | Keeps lines with "CMX Error", any case. | `\| search ("CMX Error" ...` |
| `or contains(content, "RuntimeException", caseSensitive:false)` | Or a RuntimeException. | `OR "RuntimeException"` |
| `or contains(content, "Failed to initialize clients", caseSensitive:false)` | Or a client startup failure. | `OR "Failed to initialize clients")` |
| `\| fieldsAdd matched_keywords = arrayRemoveNulls(array( ... ))` | Builds the list of phrases found. | `\| eval matched_keywords=mvappend(...)` |
| `if(contains(content, "CMX Error"), "CMX Error")` and the two lines like it | Case-sensitive tag for each phrase. | `if(match(_raw,...),...,null())` |
| `\| fieldsAdd time = formatTimestamp(...)` | Readable Japan time column. | `\| eval time=strftime(...)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields time, host.name, matched_keywords, content` | Shows four columns. | `\| table time host matched_keywords _raw` |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: where does the name live | Looks for "upload-to-cmx" in host, source, and pod fields, and counts lines per value. |
| Extra: count per keyword | Expands the keyword list into rows and counts per keyword. |

**Watch out:** same as #6, the exact `==` host match returns 0 rows if Dynatrace keeps the name somewhere other than `host.name`.

---

### #10 Not Shown

**What it finds:** Unknown. Query #10 was never shown, so no DQL exists for it.

---

### #11 Error Words Or Access Log Failures

**What it finds:** Any line with the word error, failed, or severe, or any access log line with 404, 500, or 503.

```
fetch logs, from:now()-1h
| filter matchesPhrase(content, "error")
    or matchesPhrase(content, "failed")
    or matchesPhrase(content, "severe")
    or (
         startsWith(log.source, "access_")
         and (matchesPhrase(content, "404") or matchesPhrase(content, "500") or matchesPhrase(content, "503"))
       )
| sort timestamp desc
| fields timestamp, host.name, log.source, loglevel, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1h` | Reads the last hour. The window is short because this search has no host filter and can be huge. | The Splunk time picker. |
| `\| filter matchesPhrase(content, "error")` | `matchesPhrase` looks for a whole word or phrase and ignores case. "error" matches "ERROR" but not "errors". | `error` (bare word) |
| `or matchesPhrase(content, "failed")` | Or the whole word "failed". | `OR failed` |
| `or matchesPhrase(content, "severe")` | Or the whole word "severe". | `OR severe` |
| `or (` | Opens a group. The two checks inside must both be true. | `OR (` |
| `startsWith(log.source, "access_")` | Keeps access logs. This field is a guess for Splunk's sourcetype and must be confirmed with the check query. | `sourcetype=access_*` |
| `and (matchesPhrase(content, "404") or matchesPhrase(content, "500") or matchesPhrase(content, "503"))` | The access line must also contain one of the three status codes as a whole word. | `( 404 OR 500 OR 503 )` |
| `)` | Closes the group. | `)` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, log.source, loglevel, content` | Shows five columns. `loglevel` is the log level Dynatrace detected. | (none) Splunk shows the raw events. |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Variant: parsed HTTP status field | Same query, but checks `http.response.status_code` with `toString` and `in(...)` instead of searching the text for the numbers. Use it if access logs are already parsed. |
| Check: which field holds the access sourcetype | Looks for "access" in `log.source` and `dt.openpipeline.source`, and counts lines per value. |

**Watch out:** `log.source` may not start with "access_" in Dynatrace, so the access-log half silently finds nothing until you confirm the field with the check query.

---

### #12 Error Words Or Access Log Failures (Repeat)

**What it finds:** Same as #11.

Same DQL as #11.

---

### #13 PC2 UI Legacy Claims FAIL

**What it finds:** pc2-ui lines that call the legacy claims ESB URL and contain the word FAIL.

```
fetch logs, from:now()-24h
| filter contains(log.source, "pc2-ui", caseSensitive:false)
    or contains(k8s.container.name, "pc2-ui", caseSensitive:false)
    or startsWith(k8s.pod.name, "pc2-ui")
| filter contains(content, "esbv4-inssuite-prod", caseSensitive:false)
    and contains(content, "/esb/legacyclaims/services/legacydata/claims", caseSensitive:false)
| filter matchesPhrase(content, "FAIL")
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, log.source, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(log.source, "pc2-ui", caseSensitive:false)` | Keeps rows whose source mentions pc2-ui. | `sourcetype="pc2-ui"` |
| `or contains(k8s.container.name, "pc2-ui", caseSensitive:false)` | Or the container name mentions pc2-ui. A container is the app process inside a pod. | `sourcetype="pc2-ui"` |
| `or startsWith(k8s.pod.name, "pc2-ui")` | Or the pod name starts with pc2-ui. | `sourcetype="pc2-ui"` |
| `\| filter contains(content, "esbv4-inssuite-prod", caseSensitive:false)` | The line must mention the ESB host part of the URL. | The host part of the quoted URL. |
| `and contains(content, "/esb/legacyclaims/services/legacydata/claims", caseSensitive:false)` | And the claims path part of the URL. Splitting the URL avoids a miss if the domain text differs slightly. | The path part of the quoted URL. |
| `\| filter matchesPhrase(content, "FAIL")` | The whole word FAIL, any case. | `FAIL` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, k8s.pod.name, log.source, content` | Shows five columns. | (none) |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: which field holds the pc2-ui sourcetype | Looks for "pc2-ui" in host, pod, container, and source fields, and counts lines per value. |

**Watch out:** `matchesPhrase` needs FAIL as a whole word, so a line that only says "FAILED" or "FAILURE" will not match, the same as Splunk.

---

### #14 Splunk License Usage Per Day

**What it finds:** About how much log text was ingested per day, split by source, pipeline source, host, and bucket.

```
fetch logs, from:now()-7d
| fieldsAdd b = stringLength(content)
| fieldsAdd s   = coalesce(log.source, "(SQUASHED)"),
            st  = coalesce(dt.openpipeline.source, "(SQUASHED)"),
            h   = coalesce(host.name, "(SQUASHED)"),
            idx = coalesce(dt.system.bucket, "(UNKNOWN)")
| summarize b = sum(b), by:{ day = bin(timestamp, 1d), s, st, h, idx }
| fieldsAdd gb = round(toDouble(b) / 1073741824, decimals:3)
| sort day desc, b desc
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-7d` | Reads the last 7 days of logs. | `index=_internal source=*license_usage.log* type="Usage"` |
| `\| fieldsAdd b = stringLength(content)` | Counts the characters in each log line. This stands in for bytes. | The `b` field in the license log. |
| `\| fieldsAdd s = coalesce(log.source, "(SQUASHED)"),` | `coalesce` returns the first value that is not empty. Empty sources become "(SQUASHED)". | `\| eval s=if(len(s)=0 OR isnull(s),"(SQUASHED)",s)` |
| `st = coalesce(dt.openpipeline.source, "(SQUASHED)"),` | Same fill-in for the pipeline source, the closest thing to sourcetype. | The `st` field. |
| `h = coalesce(host.name, "(SQUASHED)"),` | Same fill-in for the host. | `\| eval h=if(...,"(SQUASHED)",h)` |
| `idx = coalesce(dt.system.bucket, "(UNKNOWN)")` | Same fill-in for the storage bucket, the closest thing to a Splunk index. | `\| eval idx=if(...,"(UNKNOWN)",idx)` |
| `\| summarize b = sum(b), by:{ day = bin(timestamp, 1d), s, st, h, idx }` | `bin(timestamp, 1d)` rounds each time down to its day. `sum` adds up the sizes. One row per day and group. | `\| bin _time span=1d` plus `\| stats sum(b) as b by _time, pool, s, st, h, idx` |
| `\| fieldsAdd gb = round(toDouble(b) / 1073741824, decimals:3)` | `toDouble` turns the number into a decimal number so division keeps the fraction. Dividing by 1073741824 converts to gigabytes. `round` keeps 3 decimals. | (none) |
| `\| sort day desc, b desc` | Newest day first, biggest groups first within each day. | (none) |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: billing usage events | Reads `dt.system.events` for `BILLING_USAGE_EVENT` records, which hold the exact billed volume if your tenant exposes them. |

**Watch out:** this counts only the text of each line and not its attributes, so it is lower than real billed volume and should not be compared one-to-one with Splunk license numbers.

---

### #15 Mailservice Authentication Failure

**What it finds:** mailservice lines with `AuthenticationFailedException`, which means a login to the mail server failed.

```
fetch logs, from:now()-24h
| filter contains(host.name, "mailservice", caseSensitive:false)
    or contains(k8s.namespace.name, "mailservice", caseSensitive:false)
    or contains(dt.system.bucket, "mailservice", caseSensitive:false)
| filter contains(content, "AuthenticationFailedException", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, log.source, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(host.name, "mailservice", caseSensitive:false)` | Keeps rows whose host name mentions mailservice. | `index=mailservice` |
| `or contains(k8s.namespace.name, "mailservice", caseSensitive:false)` | Or the Kubernetes namespace mentions it. A namespace is a folder that groups related apps in a cluster. | `index=mailservice` |
| `or contains(dt.system.bucket, "mailservice", caseSensitive:false)` | Or the storage bucket name mentions it. | `index=mailservice` |
| `\| filter contains(content, "AuthenticationFailedException", caseSensitive:false)` | Keeps the failed login lines. `contains` already matches the word inside longer text. | `"*AuthenticationFailedException*"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, log.source, content` | Shows four columns. | (none) |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check for #15 and #16: where does mailservice live | Looks for "mailservice" in host, namespace, source, and bucket fields, and counts lines per value. |

**Watch out:** if mailservice logs are stored under a name that does not contain "mailservice", none of the three source checks hit and you get 0 rows.

---

### #16 Mailservice Tomcat Startup

**What it finds:** Tomcat "server started" lines in mailservice, which show each restart.

```
fetch logs, from:now()-24h
| filter contains(host.name, "mailservice", caseSensitive:false)
    or contains(k8s.namespace.name, "mailservice", caseSensitive:false)
    or contains(dt.system.bucket, "mailservice", caseSensitive:false)
| filter matchesPhrase(content, "Catalina.start Server startup")
| sort timestamp desc
| fields timestamp, host.name, log.source, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(host.name, "mailservice", caseSensitive:false)` | Same source filter as #15. | `index=mailservice` |
| `or contains(k8s.namespace.name, "mailservice", caseSensitive:false)` | Same as #15. | `index=mailservice` |
| `or contains(dt.system.bucket, "mailservice", caseSensitive:false)` | Same as #15. | `index=mailservice` |
| `\| filter matchesPhrase(content, "Catalina.start Server startup")` | Keeps the Tomcat startup message as a phrase, any case. | `"Catalina.start Server startup"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, log.source, content` | Shows four columns. | (none) |

Extra queries in the file: uses the shared check from #15.

**Watch out:** if the log parser moves the logger name ("Catalina.start") out of `content` into its own attribute, the full phrase is no longer in the text and the query returns 0 rows; test with `matchesPhrase(content, "Server startup")` to confirm.

---

### #17 Throughput Top Five Sources

**What it finds:** Log lines per minute for the five busiest log sources in the last hour.

```
fetch logs, from:now()-1h
| makeTimeseries events = count(), by:{ log.source }, interval:1m
| fieldsAdd total = arraySum(events)
| sort total desc
| limit 5
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1h` | Reads the last hour of logs. | `index=_internal source=*metrics.log group=per_source_thruput NOT filetracker` |
| `\| makeTimeseries events = count(), by:{ log.source }, interval:1m` | `makeTimeseries` turns log rows into a chart series. It counts lines in each 1-minute slot, with one series per source. `events` becomes a list of numbers. | `\| timechart span=1m sum(events) by series` |
| `\| fieldsAdd total = arraySum(events)` | `arraySum` adds up all numbers in the list. This gives the hour's total per source. | `\| eval events=eps*kb/kbps` (Splunk works out counts differently) |
| `\| sort total desc` | Busiest source first. | (none) |
| `\| limit 5` | `limit` keeps only the first N rows. | `limit=5` in `timechart` |

**Watch out:** this counts lines in Dynatrace, not Splunk's own throughput log, so the numbers describe Dynatrace data and will not match Splunk.

---

### #18 Silent Production Hosts

**What it finds:** Production hosts that have not sent any log for more than one hour.

```
fetch logs, from:now()-7d
| filter contains(host.name, "-prod-") and not contains(host.name, "amazonaws")
| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ host.name }
| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000
| filter last_seen_sec > 3600
| fieldsAdd minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0),
            hours_behind   = round(toDouble(last_seen_sec) / 3600, decimals:1),
            days_behind    = round(toDouble(last_seen_sec) / 86400, decimals:1),
            last_event_jst = formatTimestamp(last_event, format:"EEE MMM dd HH:mm:ss yyyy", timezone:"Asia/Tokyo")
| sort last_seen_sec desc
| fields host.name, last_event_jst, minutes_behind, hours_behind, days_behind
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-7d` | Reads 7 days of logs. Hosts silent for longer than 7 days will not appear at all. | `\| metadata type=hosts` |
| `\| filter contains(host.name, "-prod-") and not contains(host.name, "amazonaws")` | Keeps production hosts. `not` flips the check, so raw AWS host names are dropped. | `\| where like(host, "%-prod-%") AND NOT like(host, "%amazonaws%")` |
| `\| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ host.name }` | One row per host. `min` gives the earliest time. `max` gives the latest time. | The `firstTime` and `recentTime` columns from `metadata`. |
| `\| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000` | `now()` is the current time. `toLong` turns a time into a whole number of nanoseconds. Dividing by one billion gives seconds since the last log. | `\| eval Last_Seen=now()-recentTime` |
| `\| filter last_seen_sec > 3600` | Keeps hosts silent for more than one hour. | `\| where Last_Seen > 3600` |
| `\| fieldsAdd minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0),` | Silence in whole minutes. | `\| eval Minutes_Behind=round(Last_Seen/60, 0)` |
| `hours_behind = round(toDouble(last_seen_sec) / 3600, decimals:1),` | Silence in hours, one decimal. | `\| eval Hours_Behind=...` |
| `days_behind = round(toDouble(last_seen_sec) / 86400, decimals:1),` | Silence in days, one decimal. | `\| eval Days_Behind=...` |
| `last_event_jst = formatTimestamp(last_event, format:"EEE MMM dd HH:mm:ss yyyy", timezone:"Asia/Tokyo")` | Shows the last log time as text like "Thu Oct 15 22:00:00 2026" in Japan time. | `\| eval recentTime=strftime(recentTime, "%c")` |
| `\| sort last_seen_sec desc` | Longest silence first. | `\| sort - Last_Seen` |
| `\| fields host.name, last_event_jst, minutes_behind, hours_behind, days_behind` | Shows five columns. | `\| table host recentTime Minutes_Behind Hours_Behind Days_Behind` |

**Watch out:** a host that stopped sending more than 7 days ago is not in the fetched data, so it vanishes from the list instead of showing as the worst offender.

---

### #19 ESBv4 NetSuite HTTP Error

**What it finds:** ESBv4 lines saying it could not send an HTTP request to NetSuite.

```
fetch logs, from:now()-24h
| filter contains(host.name, "esbv4", caseSensitive:false)
    or contains(k8s.namespace.name, "esbv4", caseSensitive:false)
    or contains(k8s.pod.name, "esbv4", caseSensitive:false)
    or contains(dt.system.bucket, "esbv4", caseSensitive:false)
| filter contains(content, "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, log.source, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(host.name, "esbv4", caseSensitive:false)` | Keeps rows whose host mentions esbv4. | `index=esbv4` |
| `or contains(k8s.namespace.name, "esbv4", caseSensitive:false)` | Or the namespace mentions it. | `index=esbv4` |
| `or contains(k8s.pod.name, "esbv4", caseSensitive:false)` | Or the pod name mentions it. | `index=esbv4` |
| `or contains(dt.system.bucket, "esbv4", caseSensitive:false)` | Or the bucket name mentions it. | `index=esbv4` |
| `\| filter contains(content, "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443", caseSensitive:false)` | Keeps the NetSuite send failure lines, any case. | `"Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, k8s.pod.name, log.source, content` | Shows five columns. | (none) |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| Check: where does esbv4 live | Looks for "esbv4" in host, namespace, pod, source, and bucket fields, and counts lines per value. |
| Extra: error count per 5 minutes | Uses `makeTimeseries` with `interval:5m` on the error phrase alone, to spot outage windows. |

**Watch out:** the phrase is long and exact, so if the log writes the URL without `:443` or with a different account number the query returns 0 rows; try a shorter phrase like "restlets.api.netsuite.com" to confirm.

---

### #20 Portals AMP Distinct Accounts Per Day

**What it finds:** How many different account numbers used the portals-amp-frontend app each day.

```
fetch logs, from:now()-30d
| filter contains(k8s.container.name, "portals-amp-frontend") or contains(k8s.pod.name, "portals-amp-frontend") or contains(log.source, "portals-amp-frontend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd acct = toString(j[message][account_number])
| filter isNotNull(acct) and contains(acct, " ")
| fieldsAdd accountNo = substring(acct, from:0, to:indexOf(acct, " "))
| summarize count = countDistinctExact(accountNo), by:{ day = bin(timestamp, 1d) }
| fieldsAdd date = formatTimestamp(day, format:"yyyy-MM-dd", timezone:"Asia/Tokyo")
| sort day asc
| fields date, count
```

Note on the URL fix: this query does not filter on the `url` field, so the `==` to `contains()` correction used in #23 to #28 does not change any line here.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-30d` | Reads the last 30 days of logs. | The Splunk time picker. |
| `\| filter contains(k8s.container.name, "portals-amp-frontend") or contains(k8s.pod.name, ...) or contains(log.source, ...)` | Keeps rows where the container, pod, or source mentions the AMP frontend. Case-sensitive. | `sourcetype="portals-amp-frontend"` |
| `\| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | `replaceString(text, old, new)` swaps every copy of old for new. The inner call turns each escaped quote back into a plain quote. The outer call removes leftover backslashes. The result is clean JSON. | The two `\| eval _raw=replace(...)` lines. |
| `\| parse raw, "JSON:j"` | `parse` reads text with a pattern. The `JSON` pattern reads the whole text as JSON and stores it in a field named `j`. | `\| spath` |
| `\| fieldsAdd acct = toString(j[message][account_number])` | `j[message][account_number]` reaches into the JSON. `toString` turns the value into text. | The `message.account_number` field from `spath`. |
| `\| filter isNotNull(acct) and contains(acct, " ")` | `isNotNull` is true when the field has a value. The space check keeps only values that have a second part, like Splunk's regex does. | The `rex` only matches when a space follows. |
| `\| fieldsAdd accountNo = substring(acct, from:0, to:indexOf(acct, " "))` | Keeps the text before the first space. That is the account number. | `\| rex field=message.account_number "(?<accountNo>\w+)(?<accountNo2>\s.+)"` |
| `\| summarize count = countDistinctExact(accountNo), by:{ day = bin(timestamp, 1d) }` | `countDistinctExact` counts how many different values there are, exactly. One row per day. | `\| dedup accountNo date` plus `\| timechart span=1day count` |
| `\| fieldsAdd date = formatTimestamp(day, format:"yyyy-MM-dd", timezone:"Asia/Tokyo")` | Turns the day into a label like 2026-10-15. | `\| eval date=strftime(_time, "%Y-%m-%d")` |
| `\| sort day asc` | Oldest day first, like a chart. | (none) `timechart` is already in time order. |
| `\| fields date, count` | Shows two columns. | (none) |

**Watch out:** portals-amp logs are confirmed NOT in Dynatrace today, so this returns 0 rows until they are onboarded; also `bin(timestamp, 1d)` cuts days at UTC midnight, not Japan midnight.

---

### #21 PC UI CPU Percent Of Limit

**What it finds:** For each pc-ui pod, how much CPU it uses as a percent of its CPU limit.

```
timeseries { usage = avg(dt.kubernetes.container.cpu_usage), cpu_limit = avg(dt.kubernetes.container.limits_cpu) },
  by:{ k8s.pod.name },
  filter: k8s.workload.name == "pc-ui",
  from:now()-24h
| fieldsAdd percent = round(arrayAvg(usage) / arrayAvg(cpu_limit) * 100, decimals:2)
| sort percent desc
| fields k8s.pod.name, percent
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `timeseries { usage = avg(dt.kubernetes.container.cpu_usage), cpu_limit = avg(dt.kubernetes.container.limits_cpu) },` | `timeseries` reads metrics, which are numbers measured over time, instead of logs. `avg` takes the average. This reads CPU used and CPU limit. Each becomes a list of numbers over time. | `index=openshift_stats` and the `openshift_stats_cpu_percent_of_limit` field. |
| `by:{ k8s.pod.name },` | One series per pod. | `by openshift_pod_name` |
| `filter: k8s.workload.name == "pc-ui",` | Keeps only the pc-ui workload. A workload is the Kubernetes object that runs the pods, such as a Deployment. | `openshift_deploymentconfig_name=pc-ui` |
| `from:now()-24h` | Looks at the last 24 hours. | The Splunk time picker. |
| `\| fieldsAdd percent = round(arrayAvg(usage) / arrayAvg(cpu_limit) * 100, decimals:2)` | `arrayAvg` averages the numbers in a list. Used divided by limit, times 100, gives the percent. Rounded to 2 decimals. | `avg(openshift_stats_cpu_percent_of_limit)` |
| `\| sort percent desc` | Busiest pod first. | (none) |
| `\| fields k8s.pod.name, percent` | Shows two columns. | `stats ... by openshift_pod_name` output. |

**Watch out:** Splunk's `host=ljpiosa*` cluster filter has no line here, and if pc-ui runs as an OpenShift DeploymentConfig the workload name may differ, so check `k8s.workload.name` values first if you get no rows.

---

### #22 ESBv4 License Expiring Soon

**What it finds:** ESBv4 license lines whose expiry date is less than 100 days away.

```
fetch logs, from:now()-7d
| filter contains(host.name, "esbv4", caseSensitive:false) or contains(k8s.namespace.name, "esbv4", caseSensitive:false) or contains(k8s.pod.name, "esbv4", caseSensitive:false)
| filter contains(content, "Valid license key --> Evaluation = false, Expiration Date = ")
| fieldsAdd expiration_date = trim(substring(content, from:indexOf(content, "Expiration Date = ") + 18))
| fieldsAdd exp_clean = replaceString(expiration_date, " JST ", " ")
| parse exp_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):exp_as_utc"
| fieldsAdd expiration_epoch = exp_as_utc - 9h
| filter expiration_epoch < now() + 100d
| sort expiration_epoch asc
| fields timestamp, host.name, expiration_date, expiration_epoch, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-7d` | Reads the last 7 days of logs. | The Splunk time picker. |
| `\| filter contains(host.name, "esbv4", ...) or contains(k8s.namespace.name, ...) or contains(k8s.pod.name, ...)` | Keeps esbv4 rows by host, namespace, or pod name. | `index=esbv4` |
| `\| filter contains(content, "Valid license key --> Evaluation = false, Expiration Date = ")` | Keeps the license check lines. Case-sensitive. | `"Valid license key --> Evaluation = false, Expiration Date = "` |
| `\| fieldsAdd expiration_date = trim(substring(content, from:indexOf(content, "Expiration Date = ") + 18))` | Cuts out the text after "Expiration Date = ", which is 18 characters long. `trim` removes spaces at both ends. | `\| rex "Expiration Date = (?<expiration_date>.+)"` |
| `\| fieldsAdd exp_clean = replaceString(expiration_date, " JST ", " ")` | Removes the "JST" word so the date can be read by a time pattern. | The `JST` literal inside the `strptime` format. |
| `\| parse exp_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):exp_as_utc"` | The `TIMESTAMP` pattern reads date text in the given format and makes a real time value. With no zone given, it is read as UTC. | `\| eval expiration_epoch=strptime(expiration_date, "%a %b %d %T JST %Y")` |
| `\| fieldsAdd expiration_epoch = exp_as_utc - 9h` | Japan time is 9 hours ahead of UTC, so subtracting 9 hours gives the correct moment. | (none) Splunk handled JST in the format. |
| `\| filter expiration_epoch < now() + 100d` | Keeps licenses that expire within 100 days from now. | `\| where expiration_epoch < relative_time(now(), "+100d")` |
| `\| sort expiration_epoch asc` | Soonest expiry first. | (none) |
| `\| fields timestamp, host.name, expiration_date, expiration_epoch, content` | Shows five columns. | `\| table _time host expiration_date` |

**Watch out:** if the log has any extra text after the year, the `TIMESTAMP` parse fails and gives an empty value, and the row is quietly dropped by the filter.

---

### #23 AMP Backend doCancel Backend Exception

**What it finds:** doCancel calls in the last day that ended with CAUGHT_EXCEPTION_ON_BACKEND.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "doCancel") and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

The original file used `msg_url == "doCancel"`. The `url` field holds the full URL, such as `https://portals-api-gateway-.../doCancel`, so an exact match never hits and `contains()` is used instead.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1d` | Reads the last day of logs. | `earliest=-1d` |
| `\| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, ...) or contains(log.source, ...)` | Keeps the AMP backend by container, pod, or source name. | `sourcetype="portals-amp-backend"` |
| `\| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | Unescapes the JSON, the same as #20. | The two `\| eval _raw=replace(...)` lines. |
| `\| parse raw, "JSON:j"` | Reads the JSON into the field `j`. | `\| spath` |
| `\| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])` | Pulls out the called URL and the call result type as text. | `message.url` and `message.type` from `spath`. |
| `\| filter contains(msg_url, "doCancel") and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` | Keeps doCancel calls that ended in a backend exception. The URL check looks for the name anywhere in the full URL. The type check is exact. | `\| search message.url="doCancel" message.type="CAUGHT_EXCEPTION_ON_BACKEND"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, msg_url, msg_type, raw` | Shows four columns. | (none) |

Extra queries in the file:

| Extra query | Purpose |
|---|---|
| #23 to #27 in one table | Reads 7 days, keeps the three URL names and two types, and counts per pair. `countIf(condition)` counts only rows where the condition is true, so it gives a last-1-day column next to the 7-day total. Its `in(msg_url, array(...))` line is also an exact match and needs the same `contains()` fix. |

**Watch out:** portals-amp logs are confirmed NOT in Dynatrace today, so this returns 0 rows until they are onboarded, even with the corrected filter.

---

### #24 AMP Backend doCancel Completed

**What it finds:** doCancel calls in the last day that finished normally.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "doCancel") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

The original file used `msg_url == "doCancel"`, which never matches because the field holds the full URL, so it now uses `contains()`.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1d` | Same as #23. | `earliest=-1d` |
| `\| filter contains(k8s.container.name, "portals-amp-backend") or ...` | Same as #23. | `sourcetype="portals-amp-backend"` |
| `\| fieldsAdd raw = replaceString(...)` | Same as #23. | The two `replace` lines. |
| `\| parse raw, "JSON:j"` | Same as #23. | `\| spath` |
| `\| fieldsAdd msg_url = ..., msg_type = ...` | Same as #23. | `message.url` and `message.type` |
| `\| filter contains(msg_url, "doCancel") and msg_type == "EXECUTION_COMPLETED"` | Keeps doCancel calls that completed normally. This is the only line that differs from #23. | `\| search message.url="doCancel" message.type="EXECUTION_COMPLETED"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, msg_url, msg_type, raw` | Shows four columns. | (none) |

**Watch out:** portals-amp logs are not in Dynatrace yet, so this returns 0 rows until onboarding.

---

### #25 AMP Backend doesRefundExist Completed

**What it finds:** doesRefundExist calls in the last day that finished normally.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "doesRefundExist") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

The original file used `msg_url == "doesRefundExist"`, which never matches the full URL, so it now uses `contains()`.

| Line | What it does | Splunk equivalent |
|---|---|---|
| The first five lines | Same as #23. | `sourcetype="portals-amp-backend" earliest=-1d` plus the `replace` and `spath` lines. |
| `\| filter contains(msg_url, "doesRefundExist") and msg_type == "EXECUTION_COMPLETED"` | Keeps completed refund lookup calls. | `\| search message.url="doesRefundExist" message.type="EXECUTION_COMPLETED"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, msg_url, msg_type, raw` | Shows four columns. | (none) |

**Watch out:** portals-amp logs are not in Dynatrace yet, so this returns 0 rows until onboarding.

---

### #26 AMP Backend isPolicyCancelAvailable Completed One Week

**What it finds:** isPolicyCancelAvailable calls in the last week that finished normally.

```
fetch logs, from:now()-7d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "isPolicyCancelAvailable") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

The original file used `msg_url == "isPolicyCancelAvailable"`, which never matches the full URL, so it now uses `contains()`.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-7d` | Reads one week instead of one day. | `earliest=-1w` |
| The next four lines | Same as #23. | `sourcetype="portals-amp-backend"` plus the `replace` and `spath` lines. |
| `\| filter contains(msg_url, "isPolicyCancelAvailable") and msg_type == "EXECUTION_COMPLETED"` | Keeps completed "can this policy be cancelled" calls. | `\| search message.url="isPolicyCancelAvailable" message.type="EXECUTION_COMPLETED"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, msg_url, msg_type, raw` | Shows four columns. | (none) |

**Watch out:** portals-amp logs are not in Dynatrace yet, so this returns 0 rows until onboarding.

---

### #27 AMP Backend isPolicyCancelAvailable Completed One Day

**What it finds:** Same as #26, but for the last day only.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "isPolicyCancelAvailable") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

The original file used `msg_url == "isPolicyCancelAvailable"`, which never matches the full URL, so it now uses `contains()`.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1d` | One day instead of one week. This is the only difference from #26. | `earliest=-1d` |
| All other lines | Same as #26. | Same as #26. |

**Watch out:** portals-amp logs are not in Dynatrace yet, so this returns 0 rows until onboarding.

---

### #28 Claim Customer applySimplePayment Errors

**What it finds:** Error-level JSON lines from the claim-customer frontend or backend on the applySimplePayment call.

```
fetch logs, from:now()-24h
| filter contains(k8s.container.name, "portals-claim-customer-frontend") or contains(k8s.pod.name, "portals-claim-customer-frontend") or contains(log.source, "portals-claim-customer-frontend")
    or contains(k8s.container.name, "portals-claim-customer-backend") or contains(k8s.pod.name, "portals-claim-customer-backend") or contains(log.source, "portals-claim-customer-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd level = toString(j[level]), msg_url = toString(j[message][url])
| filter lower(level) == "error" and contains(msg_url, "/customer/exposure/applySimplePayment")
| sort timestamp desc
| fields timestamp, k8s.pod.name, level, msg_url, raw
```

The original file used `msg_url == "/customer/exposure/applySimplePayment"`. If the url field holds the full URL with the gateway host in front, an exact match never hits, so it now uses `contains()`.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(k8s.container.name, "portals-claim-customer-frontend") or ...` | Keeps the frontend app by container, pod, or source name. | `sourcetype="portals-claim-customer-frontend"` |
| `or contains(k8s.container.name, "portals-claim-customer-backend") or ...` | Or the backend app by the same three fields. | `OR sourcetype="portals-claim-customer-backend"` |
| `\| fieldsAdd raw = replaceString(...)` | Unescapes the JSON, the same as #20. | The two `replace` lines. |
| `\| parse raw, "JSON:j"` | Reads the JSON into the field `j`. | `\| spath` |
| `\| fieldsAdd level = toString(j[level]), msg_url = toString(j[message][url])` | Pulls out the log level and the called URL as text. | `level` and `message.url` from `spath`. |
| `\| filter lower(level) == "error" and contains(msg_url, "/customer/exposure/applySimplePayment")` | Keeps error-level lines, any case, on the simple payment endpoint. | `\| search level="error" message.url="/customer/exposure/applySimplePayment"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, k8s.pod.name, level, msg_url, raw` | Shows five columns. | (none) |

**Watch out:** the portals logs are not in Dynatrace yet (#28 is on the same blocked list as #20 and #23 to #27), so this returns 0 rows until onboarding.

---

### #29 Inssuite BadInputException ContactName

**What it finds:** Lines from inssuite-prod hosts where an API rejected a request because of a bad ContactName.

```
fetch logs, from:now()-24h
| filter contains(host.name, "-inssuite-prod-", caseSensitive:false) or contains(k8s.pod.name, "-inssuite-prod-", caseSensitive:false)
| filter contains(content, "gw.api.rest.exceptions.BadInputException: ContactName:", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(host.name, "-inssuite-prod-", caseSensitive:false) or contains(k8s.pod.name, ...)` | Keeps any host or pod whose name contains "-inssuite-prod-". | `host="*-inssuite-prod-*"` |
| `\| filter contains(content, "gw.api.rest.exceptions.BadInputException: ContactName:", caseSensitive:false)` | Keeps the bad ContactName exception lines. | `"gw.api.rest.exceptions.BadInputException: ContactName:"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, k8s.pod.name, content` | Shows four columns. | (none) |

The Japanese message after "ContactName:" was unreadable in the screenshot. Add it as a second `contains()` line if you need the exact message.

**Watch out:** without the Japanese text this finds every ContactName error, not only the one Splunk searched, so it can return more rows than Splunk.

---

### #30 PC2 UI Metaspace Exhausted

**What it finds:** pc2-ui lines saying Java ran out of Metaspace, the memory area that holds class data. This often comes before a crash.

```
fetch logs, from:now()-24h
| filter contains(k8s.container.name, "pc2-ui") or contains(k8s.pod.name, "pc2-ui") or contains(log.source, "pc2-ui")
| filter contains(content, "Posting Resource Exhausted event: Metaspace", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The Splunk time picker. |
| `\| filter contains(k8s.container.name, "pc2-ui") or contains(k8s.pod.name, "pc2-ui") or contains(log.source, "pc2-ui")` | Keeps pc2-ui by container, pod, or source name. Case-sensitive. | `sourcetype="pc2-ui"` |
| `\| filter contains(content, "Posting Resource Exhausted event: Metaspace", caseSensitive:false)` | Keeps the Metaspace exhaustion message, any case. | `"Posting Resource Exhausted event: Metaspace"` |
| `\| sort timestamp desc` | Newest first. | (none) |
| `\| fields timestamp, host.name, k8s.pod.name, content` | Shows four columns. | (none) |

**Watch out:** the pc2-ui name checks are case-sensitive here, unlike #13, so a source stored as "PC2-UI" would be missed; run the #13 check query to confirm the field and case.


---

## Part 2: DQL 31 to 60

This part explains the Dynatrace DQL versions of Splunk queries #31 to #60, one line at a time. DQL (Dynatrace Query Language) works like Splunk SPL: each line does one step, and the pipe `|` hands the results to the next line.

Basics used in this part:

| Term | What it means |
|---|---|
| Record | One row of data. For logs, one record is one log line. |
| `content` | The field that holds the full text of a log line. It is the DQL version of Splunk `_raw`. |
| `fetch` | The first command of a query. It says which kind of data to read, such as `logs`. |
| `from:` | An option of `fetch` that sets the time window. `from:now()-24h` means "the last 24 hours". |
| `filter` | Keeps only records where the test is true. Like Splunk `search` or `where`. |
| `fieldsAdd` | Adds a new field to every record. Like Splunk `eval`. |
| `lower()` | Turns text into lowercase so later checks do not depend on case. |
| `coalesce()` | Returns the first value in its list that is not empty. |
| `startsWith()` | True when a text value begins with the given text. |
| `contains()` | True when the given text appears anywhere inside a value. |
| `caseSensitive:false` | An option for `contains()` that makes it ignore upper and lower case. |
| `matchesPhrase()` | True when a word or phrase appears as whole words. It ignores case. |
| `and`, `or`, `not` | Join or flip tests. `not` throws away records where the test is true. |
| `sort` | Orders the rows. `desc` means newest or largest first. |
| `fields` | Keeps only the listed columns in the output. Like Splunk `table` or `fields`. |
| `summarize` | Groups records and calculates numbers per group. Like Splunk `stats`. |
| `parse` | Pulls a new field out of text by using a pattern. Like Splunk `rex`. |

### The standard source line

Splunk picks the app with `index=bc2*`. Dynatrace has no `index` field. So most queries in this part add a helper field first:

```
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
```

| Piece | What it means | Why you care |
|---|---|---|
| `k8s.pod.name` | The name of the Kubernetes pod that wrote the log. A pod is one running copy of an app. | This is where the app name usually lives. |
| `host.name` | The name of the machine or container host. | Some apps are monitored without pod details, so their name shows up here instead. |
| `coalesce(k8s.pod.name, host.name)` | Use the pod name. If it is empty, use the host name. | Every record gets a name to filter on. |
| `lower(...)` | Make that name lowercase. | Splunk index names ignore case, so the DQL version should too. |
| `src = ...` | Save the result in a new field called `src`. | Later lines can say `startsWith(src, "bc2")`. |

Why `startsWith` and not `==`: pod names end with a random suffix, such as `bc2-ui-7f9c6d-x2kqp`. An exact match on `bc2-ui` would find nothing. `startsWith(src, "bc2-ui")` behaves like Splunk `index=bc2-ui*`.

### matchesPhrase versus contains

| Function | How it matches | Used for |
|---|---|---|
| `matchesPhrase(content, "ERROR")` | Whole words only. Ignores case. `connect` does not match `connection`. | Splunk bare words without quotes, like `ERROR` or `ready`. |
| `contains(content, "Failed to get lock")` | Any substring. Case-sensitive by default. | Splunk quoted phrases. |
| `contains(..., caseSensitive:false)` | Any substring, ignoring case. | Splunk quoted phrases, because Splunk ignores case there too. |

---

### #31 Alfrescoacr Failed To Get Lock

**What it finds:** Log lines from the alfrescoacr app that say a lock could not be taken.

```
fetch logs, from:now()-24h
| filter contains(host.name, "alfrescoacr", caseSensitive:false) or contains(k8s.namespace.name, "alfrescoacr", caseSensitive:false) or contains(k8s.pod.name, "alfrescoacr", caseSensitive:false) or contains(dt.system.bucket, "alfrescoacr", caseSensitive:false)
| filter contains(content, "Failed to get lock", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | `fetch` reads log records. `from:now()-24h` limits them to the last 24 hours. | The time picker set to "Last 24 hours". It is not written in the Splunk text. |
| `\| filter contains(host.name, "alfrescoacr", caseSensitive:false) or ...` | Keeps a record if `alfrescoacr` appears in the host name, the namespace, the pod name, or the storage bucket name. `or` means any one of the four is enough. This query is older than the `src` line, so it checks four fields directly. | `index="alfrescoacr"` |
| `\| filter contains(content, "Failed to get lock", caseSensitive:false)` | Keeps lines whose text includes the phrase, ignoring case. | `"Failed to get lock"` |
| `\| sort timestamp desc` | Puts the newest lines first. | Splunk shows newest first by default. |
| `\| fields timestamp, host.name, k8s.pod.name, content` | Shows only the time, host, pod, and log text. | Closest is `\| table _time, host, _raw`. |

Extra query in the same source file: a "check" query that counts lines per namespace, container, log source, and bucket. Its purpose is to find which field really holds the app name before you trust the main query.

**Watch out:** `contains` is a substring test, so this also catches `alfrescoacr-batch` pods, which the exact Splunk `index="alfrescoacr"` would not.

---

### #32 Network Errors Counted Per App

**What it finds:** Lines with SSL, timeout, socket, or connect across about 29 apps, counted per app.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter matchesValue(src, array(
    "accounting*", "agrex*", "alfrescoaca*", "alfrescoacr*", "alfrescoacr-batch*", "alfrescoaev*",
    "alfrescocollabsrv*", "batch_server*", "bc-batch*", "bc-ui*", "bc2-batch*", "bc2-ui*",
    "bcsubledger*", "cc-batch*", "cc-ui*", "cm-ui*", "cm2-ui*", "ebroker*", "esb*", "hulft*",
    "legacybridge*", "mailservice*", "pc-batch*", "pc-ui*", "portals*", "sonpovan*", "staging*",
    "temp-receipt-accounting*", "tts*"))
| filter matchesPhrase(content, "SSL")
    or matchesPhrase(content, "timeout")
    or matchesPhrase(content, "socket")
    or matchesPhrase(content, "connect")
| summarize record_count = count(), by:{ index = coalesce(k8s.namespace.name, k8s.workload.name, src) }
| sort record_count desc
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the lowercase app name `src`, as explained at the top of this part. | No line. It prepares a stand-in for `index`. |
| `\| filter matchesValue(src, array(` | `matchesValue()` checks the whole value against a pattern, ignoring case. A `*` at the end means "anything after this". `array()` builds a list, so `src` may match any pattern in the list. | The opening of `(index=accounting* OR ...` |
| `"accounting*", "agrex*", ... "alfrescoaev*",` | First six app name patterns. | `index=accounting* OR index=agrex* OR ...` |
| `"alfrescocollabsrv*", ... "bc2-ui*",` | Next six app name patterns. | The matching `index=...*` terms. |
| `"bcsubledger*", ... "hulft*",` | Next eight app name patterns. | The matching `index=...*` terms. |
| `"legacybridge*", ... "staging*",` | Next seven app name patterns. | The matching `index=...*` terms. |
| `"temp-receipt-accounting*", "tts*"))` | Last two patterns. The two `)` close the list and the function. | `... OR index=tts*)` |
| `\| filter matchesPhrase(content, "SSL")` | Keeps lines with the whole word `SSL`. | `SSL` |
| `or matchesPhrase(content, "timeout")` | Or the whole word `timeout`. | `OR timeout` |
| `or matchesPhrase(content, "socket")` | Or the whole word `socket`. | `OR socket` |
| `or matchesPhrase(content, "connect")` | Or the whole word `connect`. It does not match `connection`. | `OR connect` |
| `\| summarize record_count = count(), by:{ index = ... }` | `summarize` groups records. `count()` counts records per group. `by:` names the grouping field. Here the group is the namespace, or the workload, or `src`, whichever exists first, and it is named `index`. | `\| stats count as record_count by index` |
| `\| sort record_count desc` | Biggest counts first. | `\| sort - record_count` |

The Splunk line `#OR "Operation started"` has no DQL line. It was treated as switched off.

**Watch out:** the count is grouped by namespace first, so if several apps share one namespace they collapse into a single row and the per-app view is lost.

---

### #33 PC2 Batch Cancellation Waiting For Midnight

**What it finds:** pc2-batch lines that mention both the cancellation step and the wait-for-midnight step.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "pc2-batch")
| filter matchesPhrase(content, "bcCancellationFinished_Adj") and matchesPhrase(content, "WaitForMidNight")
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "pc2-batch")` | Keeps records from pods whose name begins with `pc2-batch`. | `index=pc2-batch*` |
| `\| filter matchesPhrase(...) and matchesPhrase(...)` | Both whole words must be on the same line. `and` means both tests must pass. | `bcCancellationFinished_Adj AND WaitForMidNight` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** if the two step names are logged on separate lines, no single line holds both, and the query returns 0 rows.

---

### #34 BC2 GMO SEARCHTRADE Exception

**What it finds:** bc2 lines where a call to the GMO payment gateway's SEARCHTRADE action threw an exception.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2")
| filter contains(content, "Exception during GMO call SEARCHTRADE", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2")` | Keeps all bc2 apps, such as bc2-ui and bc2-batch. | `index=bc2*` |
| `\| filter contains(content, "Exception during GMO call SEARCHTRADE", caseSensitive:false)` | Keeps lines with the English part of the error. The Japanese part was unreadable, so it is left out. | `"Exception during GMO call SEARCHTRADE:<JP_TEXT>"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** without the Japanese text this returns every SEARCHTRADE exception, not just the one message the Splunk search targets, so expect more rows than Splunk.

---

### #35 BC2 Batch DirectDebit PaymentDueDate Mismatch

**What it finds:** DirectDebit batch lines saying a record has a different payment due date than earlier rows.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-batch")
| filter contains(content, "Server.BatchProcess.DirectDebitBatchProcess", caseSensitive:false)
| filter contains(content, "Record with ID ", caseSensitive:false)
    and contains(content, " has different PaymentDueDate value ", caseSensitive:false)
    and contains(content, " than previous rows", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-batch")` | Keeps bc2-batch pods. | `index=bc2-batch*` |
| `\| filter contains(content, "Server.BatchProcess.DirectDebitBatchProcess", caseSensitive:false)` | Keeps lines from the DirectDebit batch class. | `"Server.BatchProcess.DirectDebitBatchProcess"` |
| `\| filter contains(content, "Record with ID ", caseSensitive:false)` | First piece of the phrase, before the first wildcard. | `"Record with ID *` |
| `and contains(content, " has different PaymentDueDate value ", caseSensitive:false)` | Middle piece, between the two wildcards. | `* has different PaymentDueDate value *` |
| `and contains(content, " than previous rows", caseSensitive:false)` | Last piece, after the second wildcard. | `* than previous rows"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

DQL `contains()` has no wildcard, so the Splunk phrase is cut into three pieces at each `*`.

**Watch out:** the three pieces are checked separately, so they may match in any order or in different parts of a long line, which can let in a few wrong rows.

---

### #36 BC2 Concurrent Data Change In Delinquency Process

**What it finds:** bc2 lines where two processes changed the same data at once during the policy delinquency (late payment) process.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-")
| filter contains(content, "com.guidewire.pl.system.exception.ConcurrentDataChangeException", caseSensitive:false)
    and contains(content, "PolicyDlnqProcess:bc", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-")` | Keeps pods whose name begins with `bc2-`. | `index=bc2-*` |
| `\| filter contains(content, "com.guidewire...ConcurrentDataChangeException", caseSensitive:false)` | Keeps lines with the Guidewire "data changed under you" error. | `"com.guidewire.pl.system.exception.ConcurrentDataChangeException"` |
| `and contains(content, "PolicyDlnqProcess:bc", caseSensitive:false)` | The same line must also name the delinquency process. | `AND "PolicyDlnqProcess:bc"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** Java stack traces often put the exception name and the process name on different lines, and if Dynatrace stored them as separate records the query returns 0 rows.

---

### #37 Bcsubledger Exception Error Or Warn

**What it finds:** bcsubledger lines that contain Exception, ERROR, or WARN.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bcsubledger")
| filter matchesPhrase(content, "Exception")
    or matchesPhrase(content, "ERROR")
    or matchesPhrase(content, "WARN")
| sort timestamp desc
| fields timestamp, src, loglevel, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bcsubledger")` | Keeps bcsubledger pods. | `index=bcsubledger*` |
| `\| filter matchesPhrase(content, "Exception")` | Keeps lines with the whole word `Exception`. | `Exception` |
| `or matchesPhrase(content, "ERROR")` | Or the whole word `ERROR`. | `OR " ERROR "` |
| `or matchesPhrase(content, "WARN")` | Or the whole word `WARN`. | `OR WARN` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, loglevel, content` | Shows time, app name, log level, and log text. | Closest is `\| table _time, host, loglevel, _raw`. |

**Watch out:** `matchesPhrase` needs whole words, so lines that say `WARNING` or `NullPointerException` (one long word) are not caught.

---

### #38 BC2 UI GMO Error Code E01050004

**What it finds:** bc2-ui lines that carry the GMO error code E01 with detail code E01050004.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui")
| filter contains(content, "errcode=E01&errinfo=E01050004", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-ui")` | Keeps bc2-ui pods. | `index=bc2-ui*` |
| `\| filter contains(content, "errcode=E01&errinfo=E01050004", caseSensitive:false)` | Keeps lines with this exact text. | `"errcode=E01&errinfo=E01050004"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** if the app logs the two codes in a different order or with a space, such as `errinfo=E01050004&errcode=E01`, the exact substring is not found and you get 0 rows.

---

### #39 BC2 CVS Offline Payment Notification Exception

**What it finds:** bc2 ERROR lines where processing a convenience store (CVS) payment notice failed.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2")
| filter matchesPhrase(content, "ERROR")
    and contains(content, "Integration.CVS", caseSensitive:false)
    and contains(content, "Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2")` | Keeps all bc2 apps. | `index=bc2*` |
| `\| filter matchesPhrase(content, "ERROR")` | The line must contain the whole word `ERROR`. | `ERROR` |
| `and contains(content, "Integration.CVS", caseSensitive:false)` | The line must also contain the CVS logger name. | `AND Integration.CVS` |
| `and contains(content, "Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:", caseSensitive:false)` | The line must also contain the exact error phrase. The `[` is plain text and needs no escaping. | `AND "Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** `contains` for `Integration.CVS` also matches longer names like `Integration.CVSRetry`, so you may see a few extra rows that Splunk's whole-word match would skip.

---

### #40 BC2 Multiple Matches On ContactID

**What it finds:** bc2 lines where a lookup by ContactID_Adj found more than one record.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2")
| filter contains(content, "gw.api.database.MultipleMatchesException", caseSensitive:false)
    and matchesPhrase(content, "ContactID_Adj")
    and matchesPhrase(content, "Values")
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2")` | Keeps all bc2 apps. | `index=bc2*` |
| `\| filter contains(content, "gw.api.database.MultipleMatchesException", caseSensitive:false)` | Keeps lines with the Guidewire "expected one row, got several" error. | `gw.api.database.MultipleMatchesException` |
| `and matchesPhrase(content, "ContactID_Adj")` | The line must also contain the whole word `ContactID_Adj`. | `AND ContactID_Adj` |
| `and matchesPhrase(content, "Values")` | The line must also contain the whole word `Values`. | `AND Values` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** if the field is written as `ContactID_Adj=123` with no space, whole-word matching still works, but if it is glued into a longer word like `byContactID_Adj` the line is dropped.

---

### #41 BC2 Batch Duplicate CVS Offline Quick Records

**What it finds:** CVS Offline quick payment records that appear more than once with the same ID, amount, and date.

```
fetch logs, from:now()-7d
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-batch")
| filter contains(content, "PaymentRecordType=Quick record for CVS Offline", caseSensitive:false)
| dedup content
| parse content, "LD 'Identifier=' LD:Identifier ','"
| parse content, "LD 'Amount=' LD:Amount ','"
| parse content, "LD 'PaymentDate=' LD:PaymentDate ','"
| summarize count = count(), by:{ Identifier, Amount, PaymentDate }
| filter count > 1
| fieldsAdd pd_clean = replaceString(PaymentDate, " JST ", " ")
| parse pd_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):PaymentDateForSort"
| sort PaymentDateForSort asc
| fields Identifier, Amount, PaymentDate
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-7d` | Reads logs from the last 7 days. Duplicates are easier to spot over a week. | Time picker "Last 7 days". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-batch")` | Keeps bc2-batch pods. | `index=bc2-batch*` |
| `\| filter contains(content, "PaymentRecordType=Quick record for CVS Offline", caseSensitive:false)` | Keeps only CVS Offline quick record lines. | `"PaymentRecordType=Quick record for CVS Offline"` |
| `\| dedup content` | `dedup` keeps only the first record for each distinct value. Here identical log lines are kept once. | `\| dedup _raw` |
| `\| parse content, "LD 'Identifier=' LD:Identifier ','"` | `parse` uses a DPL pattern (Dynatrace Pattern Language). `LD` means "any characters". The quoted part is literal text. `LD:Identifier` captures the text up to the next `,` into a field named `Identifier`. | No line. Splunk pulls `key=value` fields out automatically. |
| `\| parse content, "LD 'Amount=' LD:Amount ','"` | Same idea. Captures the amount into `Amount`. | No line. Automatic field extraction. |
| `\| parse content, "LD 'PaymentDate=' LD:PaymentDate ','"` | Same idea. Captures the date text into `PaymentDate`. | No line. Automatic field extraction. |
| `\| summarize count = count(), by:{ Identifier, Amount, PaymentDate }` | Counts lines for each combination of ID, amount, and date. | `\| stats count by Identifier, Amount, PaymentDate` |
| `\| filter count > 1` | Keeps combinations seen more than once. These are the duplicates. | `\| where count > 1` |
| `\| fieldsAdd pd_clean = replaceString(PaymentDate, " JST ", " ")` | `replaceString()` swaps text. Here it removes ` JST ` because the time pattern below cannot read that zone name. | No line. Splunk `%Z` reads `JST` directly. |
| `\| parse pd_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):PaymentDateForSort"` | The `TIMESTAMP` pattern turns date text like `Wed Oct 14 10:00:00 2026` into a real time value named `PaymentDateForSort`. | `\| eval PaymentDateForSort=strptime(PaymentDate, "%a %b %d %H:%M:%S %Z %Y")` |
| `\| sort PaymentDateForSort asc` | Oldest payment date first. | `\| sort PaymentDateForSort` |
| `\| fields Identifier, Amount, PaymentDate` | Shows only the three duplicate keys. | `\| fields Identifier, Amount, PaymentDate` |

**Watch out:** if the real delimiter after each value is not a comma, all three `parse` lines return empty fields, and you get one wrong row with blank keys instead of the real duplicates.

---

### #42 API Exception When Executing In Three BC2 Apps

**What it finds:** "API - Exception when executing" lines in bc2-ui, bc2-batch, or bcsubledger.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")
| filter contains(content, "API - Exception when executing", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` | Keeps any of the three apps. | `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` |
| `\| filter contains(content, "API - Exception when executing", caseSensitive:false)` | Keeps lines with the exact error phrase. | `AND "API - Exception when executing"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** the Splunk index names are exact, but `startsWith` is a prefix, so a pod like `bc2-ui-canary` is also included and can add rows Splunk never showed.

---

### #43 GMO EXECTRAN Exception In Three BC2 Apps

**What it finds:** Lines where the GMO EXECTRAN call (the step that actually charges the card) threw an exception.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")
| filter contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` | Keeps any of the three apps. | `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` |
| `\| filter contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)` | Keeps lines with the exact error phrase. EXECTRAN means "execute transaction". | `AND "Exception during GMO call EXECTRAN"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** if the bcsubledger app is monitored without pod details and its host name is something generic like an IP-based node name, `src` never starts with `bcsubledger` and that app silently drops out.

---

### #44 BC2 UI GMO Error Code E01050004

**What it finds:** Same as #38.

Same DQL as #38.

---

### #45 BC2 CVS Offline Payment Notification Exception

**What it finds:** Same as #39.

Same DQL as #39. Today's source file writes each test on its own `filter` line and uses `matchesPhrase(content, "Integration.CVS")` instead of `contains()`, which is a closer copy of the Splunk bare term.

---

### #46 BC2 Multiple Matches On ContactID

**What it finds:** Same as #40.

Same DQL as #40. Today's source file writes each test on its own `filter` line and uses `matchesPhrase()` for the exception name too.

---

### #47 BC2 Batch Duplicate CVS Offline Quick Records

**What it finds:** Same as #41.

Same DQL as #41.

---

### #48 API Exception When Executing In Three BC2 Apps

**What it finds:** Same as #42.

Same DQL as #42.

---

### #49 GMO EXECTRAN Exception In Three BC2 Apps

**What it finds:** Same as #43.

Same DQL as #43.

---

### #50 BC2 UI Error Code E01 Minus Known Codes

**What it finds:** bc2-ui "Map returned by method call" lines with error code E01, leaving out three detail codes that are already known.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui")
| filter contains(content, "Map returned by method call", caseSensitive:false)
| parse content, "LD 'errcode=' ALNUM:errcode"
| filter errcode == "E01"
| filter not matchesPhrase(content, "E01390002")
| filter not matchesPhrase(content, "E01260010")
| filter not matchesPhrase(content, "E01110002")
| sort timestamp desc
| fields timestamp, src, errcode, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-ui")` | Keeps bc2-ui pods. | `index=bc2-ui*` |
| `\| filter contains(content, "Map returned by method call", caseSensitive:false)` | Keeps the log lines that print the GMO response. | `"Map returned by method call"` |
| `\| parse content, "LD 'errcode=' ALNUM:errcode"` | Skips text up to `errcode=`, then captures the letters and digits after it. `ALNUM` means letters and digits only, so it stops at `&`. The result goes into a field named `errcode`. | No line. Splunk extracts `errcode` automatically. |
| `\| filter errcode == "E01"` | Keeps lines where the code is exactly `E01`. `==` is an exact comparison. | `AND errcode=E01` |
| `\| filter not matchesPhrase(content, "E01390002")` | `not` drops lines that contain this detail code. | `AND NOT E01390002` |
| `\| filter not matchesPhrase(content, "E01260010")` | Drops lines with this detail code. | `AND NOT E01260010` |
| `\| filter not matchesPhrase(content, "E01110002")` | Drops lines with this detail code. | `AND NOT E01110002` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, errcode, content` | Shows time, app name, the parsed code, and log text. | Closest is `\| table _time, host, errcode, _raw`. |

**Watch out:** if the response is printed as JSON, such as `"errcode":"E01"`, the pattern `errcode=` never matches, `errcode` stays empty, and every line is filtered out.

---

### #51 BC2 Batch SaveCardWithOrderID Errors On Writer 54

**What it finds:** bc2-batch lines from worker thread MW-Writer-[54] where saving a card with an order ID failed.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-batch")
| filter contains(content, "Errors in saveCardWithOrderID call", caseSensitive:false)
| filter contains(content, "MW-Writer-[54]", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-batch")` | Keeps bc2-batch pods. | `index="bc2-batch"` |
| `\| filter contains(content, "Errors in saveCardWithOrderID call", caseSensitive:false)` | Keeps lines with the card save error. | `"Errors in saveCardWithOrderID call"` |
| `\| filter contains(content, "MW-Writer-[54]", caseSensitive:false)` | Keeps lines from thread 54. DQL `contains()` treats `[` and `]` as plain text, so no backslashes are needed. | `"MW-Writer-\[54\]"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** if someone copies the Splunk text with backslashes, `MW-Writer-\[54\]` is searched literally and never matches.

---

### #52 GMO SearchTrade Used To Confirm ExecTran

**What it finds:** Lines where the app used GMO SearchTrade to double-check the result of an ExecTran charge.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")
| filter contains(content, "GMO SearchTrade used to confirm ExecTran status with OrderID", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` | Keeps any of the three apps. | `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` |
| `\| filter contains(content, "GMO SearchTrade used to confirm ExecTran status with OrderID", caseSensitive:false)` | Keeps lines with the exact phrase. It usually means the first charge reply was unclear. | `AND "GMO SearchTrade used to confirm ExecTran status with OrderID"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** the phrase is long, so a single extra space or a changed word in a newer app version (for example `OrderId` with a small d is fine, but `Order ID` is not) gives 0 rows.

---

### #53 GMO EXECTRAN Exception In Three BC2 Apps

**What it finds:** Same as #49 (and #43).

Same DQL as #49, which is the same as #43.

Extra query in the standalone #53 source file:

| Extra query | Purpose |
|---|---|
| Count per app per hour | Uses `if()` with `else:` to label each record as bc2-ui, bc2-batch, or bcsubledger, then `makeTimeseries errors = count(), by:{ app }, interval:1h` to draw one hourly error line per app. `if(test, A, else: B)` returns A when the test is true and B when it is not. `makeTimeseries` turns records into a chart over time. |

---

### #54 Operation Failed For A Producer

**What it finds:** pc2-ui or bc2-ui lines where an operation failed and the message is about a producer (sales agent) or producer code.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "pc2-ui") or startsWith(src, "bc2-ui")
| filter contains(content, "Operation failed", caseSensitive:false)
| filter contains(content, "ProducerCode <JP_TEXT_1>", caseSensitive:false)
    or contains(content, "Producer <JP_TEXT_2>", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "pc2-ui") or startsWith(src, "bc2-ui")` | Keeps pc2-ui or bc2-ui pods. | `index=pc2-ui* OR index=bc2-ui*` |
| `\| filter contains(content, "Operation failed", caseSensitive:false)` | Keeps lines saying an operation failed. | `"Operation failed"` |
| `\| filter contains(content, "ProducerCode <JP_TEXT_1>", caseSensitive:false)` | First possible message, about the producer code. The Japanese text is a placeholder. | `AND ("ProducerCode <JP_TEXT>"` |
| `or contains(content, "Producer <JP_TEXT_2>", caseSensitive:false)` | Second possible message, about the producer. Either one is enough. | `OR "Producer <JP_TEXT>")` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

Each test sits on its own `filter` line, so the two producer checks are grouped together just like the brackets in Splunk.

**Watch out:** until `<JP_TEXT_1>` and `<JP_TEXT_2>` are replaced with the real Japanese words, no log line contains them and the query always returns 0 rows.

---

### #55 BC2 Producer Contact Missing

**What it finds:** bc2 lines saying a producer has no contact record.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2")
| filter contains(content, "Producer Contact is missing for Producer", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2")` | Keeps all bc2 apps. | `index=bc2*` |
| `\| filter contains(content, "Producer Contact is missing for Producer", caseSensitive:false)` | Keeps lines with the exact phrase. | `"Producer Contact is missing for Producer"` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** this is a data problem that repeats for the same producer, so one bad record can flood the results and hide other producers; add a count by producer if the list is long.

---

### #56 BC2 Producer Contact Missing

**What it finds:** Same as #55.

Same DQL as #55.

---

### #57 BC2 Server RunLevel Ready

**What it finds:** bc2 lines saying the server reached a run level and is ready. These show when a bc2 server started or restarted.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-")
| filter matchesPhrase(content, "Server.RunLevel")
| filter matchesPhrase(content, "ready")
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bc2-")` | Keeps pods whose name begins with `bc2-`. | `index=bc2-*` |
| `\| filter matchesPhrase(content, "Server.RunLevel")` | Keeps lines from the Guidewire logger that reports start-up stages. | `Server.RunLevel` |
| `\| filter matchesPhrase(content, "ready")` | The line must also contain the whole word `ready`. | `AND ready` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** a line such as `Server.RunLevel ... not ready` also contains the word `ready`, so some rows may be failed start-ups rather than successful ones.

---

### #58 Bcsubledger Japanese Text Search

**What it finds:** bcsubledger lines that contain a Japanese error message.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bcsubledger")
| filter contains(content, "<JP_TEXT>", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "bcsubledger")` | Keeps bcsubledger pods. | `index=bcsubledger` |
| `\| filter contains(content, "<JP_TEXT>", caseSensitive:false)` | Keeps lines with the Japanese text. `<JP_TEXT>` is a placeholder for words that were unreadable in the screenshot. | `<JP_TEXT>` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** the placeholder must be replaced with the real Japanese text, and if the logs store Japanese in a different encoding (for example escaped as `\u` codes) even the right text will not match.

---

### #59 PC2 Batch Payment Request Creation Failure

**What it finds:** pc2-batch lines where creating a payment request for a transaction failed.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "pc2-batch")
| filter contains(content, "Creation of a payment request for transaction", caseSensitive:false)
| filter matchesPhrase(content, "failure")
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "pc2-batch")` | Keeps pc2-batch pods. | `index=pc2-batch` |
| `\| filter contains(content, "Creation of a payment request for transaction", caseSensitive:false)` | Keeps lines about the payment request step. | `"Creation of a payment request for transaction"` |
| `\| filter matchesPhrase(content, "failure")` | The line must also contain the whole word `failure`. | `failure` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** lines that say `failed` or `failures` are not matched, because `matchesPhrase` only accepts the exact whole word `failure`.

---

### #60 CC RemoveDocumentChain Execution Duration

**What it finds:** cc-ui or cc-batch lines that report how long the RemoveDocumentChain step took.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "cc-ui") or startsWith(src, "cc-batch")
| filter contains(src, "cc-")
| filter matchesPhrase(content, "RemoveDocumentChain")
| filter matchesPhrase(content, "Execution")
| filter matchesPhrase(content, "Duration")
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds the app name `src`. | No line. Stand-in for `index`. |
| `\| filter startsWith(src, "cc-ui") or startsWith(src, "cc-batch")` | Keeps cc-ui or cc-batch pods. | `(index=cc-ui OR index=cc-batch)` |
| `\| filter contains(src, "cc-")` | Keeps names that contain `cc-`. It copies the Splunk host check. It removes nothing extra here, because both prefixes already contain `cc-`. | `AND host="*cc-*"` |
| `\| filter matchesPhrase(content, "RemoveDocumentChain")` | The line must contain the step name as a whole word. | `RemoveDocumentChain` |
| `\| filter matchesPhrase(content, "Execution")` | The line must also contain the whole word `Execution`. | `Execution` |
| `\| filter matchesPhrase(content, "Duration")` | The line must also contain the whole word `Duration`. | `Duration` |
| `\| sort timestamp desc` | Newest first. | Splunk default order. |
| `\| fields timestamp, src, content` | Shows time, app name, and log text. | Closest is `\| table _time, host, _raw`. |

**Watch out:** if the log writes the label as one word, such as `ExecutionDuration=1234ms`, neither `Execution` nor `Duration` is a whole word on its own and the query returns 0 rows.

---

### Helper Queries In The Source Files

These are extra queries found next to the main ones. They are not part of the Splunk list.

| Source file | Purpose |
|---|---|
| File for #31 (2026-10-14 answer 13) | Check query. Counts log lines per namespace, container, log source, and bucket so you can see which field really holds each Splunk sourcetype or index name. |
| File for #32 to #43 (2026-10-14 answer 14) | Check query. Counts log lines per namespace, workload, and host for names starting with bc, pc, cc, cm, alfresco, esb, or portals, so you can confirm the `startsWith` prefixes are right. |
| File for #53 (2026-10-15 answer 5) | Hourly chart of EXECTRAN exceptions per app, explained under #53 above. |


---

## Part 3: DQL 61 to 85

This part covers the DQL versions of the cc-batch and sonpovan batch searches, the esbv4 and ebroker integration searches, the "which apps went silent" report, the ebroker SSL certificate check, and the portals-amp-backend JSON searches.

| Term | What it means |
|---|---|
| DQL | Dynatrace Query Language. You write steps, and each step is joined to the next with a pipe `\|`. |
| Grail | The Dynatrace storage where logs live. `fetch logs` reads from it. |
| `fetch logs` | The first step. It reads log records. Think of it as Splunk's `index=...` search. |
| `from:now()-24h` | The time range. `now()` is the current time, and `-24h` means "start 24 hours ago". |
| `content` | The raw text of one log line. It is the same idea as Splunk `_raw`. |
| `timestamp` | The time of the log line. It is the same idea as Splunk `_time`. |
| `fieldsAdd` | Creates a new field (a new column) on every row. Like Splunk `eval`. |
| `coalesce(a, b)` | Returns the first value that is not empty. |
| `lower(x)` | Turns text into lower case, so later checks do not depend on case. |
| `src` | A field we create in almost every query: the pod name, or the host name when there is no pod. It replaces Splunk's index. |
| `filter` | Keeps only the rows where the condition is true. Like Splunk `search` or `where`. |
| `startsWith(x, "abc")` | True when the text in `x` begins with `abc`. |
| `contains(x, "abc")` | True when `abc` appears anywhere in `x`. It has no wildcards. |
| `caseSensitive:false` | An option for `contains`. It ignores upper and lower case. Without it, `contains` is case-sensitive. |
| `sort timestamp desc` | Puts the newest rows first. |
| `fields a, b, c` | Keeps only these columns, in this order. Like Splunk `table`. |
| `parse` | Reads a text field with a DPL pattern and saves named pieces as new fields. Like Splunk `rex`. |
| DPL | Dynatrace Pattern Language. The pattern language used by `parse`. It uses named building blocks instead of regex symbols. |

Every query in this part is a translation. Splunk has indexes and sourcetypes. Dynatrace does not, so every query starts by building `src` (or `app`) and filtering on the pod or container name.

---

### #61 Cc-Batch ERROR Lines For EnqueteWorkItem

**What it finds:** ERROR-level log lines from cc-batch that mention the `EnqueteWorkItem_Adj` work item.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "cc-batch")
| parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"
| filter loglevel == "ERROR"
| filter contains(content, "EnqueteWorkItem_Adj", caseSensitive:false)
| summarize loglevel = collectDistinct(loglevel), log = collectDistinct(content), by:{ timestamp }
| sort timestamp desc
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads all log records from the last 24 hours. | The time picker set to "Last 24 hours". |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod name, or the host name if there is no pod name, in lower case. | No line. Splunk already knows the app from the index. |
| `\| filter startsWith(src, "cc-batch")` | Keeps only logs from pods whose name begins with `cc-batch`. | `index="cc-batch"` |
| `\| parse content, "LD DIGIT+ ... WORD:loglevel"` | Reads the date and time at the start of the line and saves the next word as `loglevel`. The pattern pieces are explained in the small table below. | `rex field=_raw "\d+-\d+-\d+\s\d+:\d+:\d+,\d+\s+(?<loglevel>\w+)"` |
| `\| filter loglevel == "ERROR"` | Keeps rows whose level is exactly `ERROR`. `==` means "is exactly equal to". | `search loglevel="ERROR"` |
| `\| filter contains(content, "EnqueteWorkItem_Adj", caseSensitive:false)` | Keeps lines that mention the work item, in any case. | `search log="*EnqueteWorkItem_Adj*"` |
| `\| summarize loglevel = collectDistinct(loglevel), log = collectDistinct(content), by:{ timestamp }` | `summarize` groups rows. `by:{ timestamp }` makes one group per timestamp. `collectDistinct` builds a list of the unique values in each group. | `stats values(loglevel) as loglevel, values(_raw) as log by _time` |
| `\| sort timestamp desc` | Newest group first. | No line. Splunk shows newest first by default. |

The DPL pattern pieces used in the `parse` line:

| Pattern piece | What it matches |
|---|---|
| `LD` | "Line data". Any characters up to the end of the line. Here it skips anything before the date. |
| `DIGIT+` | One or more digits, such as `2026` or `09`. |
| `'-'` | A literal dash. Text in single quotes must appear exactly. |
| `' '` | A literal single space between the date and the time. |
| `','` | The literal comma before the milliseconds. |
| `SPACE+` | One or more spaces or tabs. |
| `WORD:loglevel` | One word made of letters, digits, or underscores, saved into a field named `loglevel`. |

Small difference: DQL filters on `ERROR` before grouping, while Splunk grouped first and filtered after. For normal logs the result is the same.

**Watch out:** if the line's time uses a dot instead of a comma before the milliseconds (for example `09:12:33.123`), `parse` leaves `loglevel` empty and the ERROR filter silently drops every row.

### #62 Cc-Batch MessageQueueMonitor ERROR With Detail Lines

**What it finds:** ERROR lines from `MessageQueueMonitor_Adj` that list stuck queue messages, with the "Found ..." summary and every 10-digit detail line.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter contains(src, "cc-batch")
| parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"
| filter loglevel == "ERROR"
| filter contains(content, "MessageQueueMonitor_Adj", caseSensitive:false)
| filter not contains(content, "Sonpovan <JP_TEXT>", caseSensitive:false)
| filter contains(content, "Found ")
| fieldsAdd queueMessage = substring(content, from: indexOf(content, "Found "))
| fieldsAdd line = splitString(content, "\n")
| expand line
| parse line, "(DIGIT{10} SPACE LD):detail"
| filter isNotNull(detail)
| summarize details = collectArray(detail), by:{ timestamp, src, queueMessage }
| sort timestamp desc
| fields timestamp, src, queueMessage, details
```

`<JP_TEXT>` is a placeholder. Paste the real Japanese words from the Splunk `log!=` line.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter contains(src, "cc-batch")` | Keeps pods with `cc-batch` anywhere in the name. | `index="*cc-batch*"` |
| `\| parse content, "LD DIGIT+ ... WORD:loglevel"` | Same pattern as #61. Saves the log level. The logger name from the Splunk regex is not needed, so DQL skips it. | `rex field=_raw "...(?<loglevel>\w+)\s\[.+\]\s(?<logger>.+)\s-\s\["` |
| `\| filter loglevel == "ERROR"` | Keeps ERROR lines only. | `search loglevel="ERROR"` |
| `\| filter contains(content, "MessageQueueMonitor_Adj", caseSensitive:false)` | Keeps lines from the message queue monitor. | `search log="*MessageQueueMonitor_Adj*"` |
| `\| filter not contains(content, "Sonpovan <JP_TEXT>", caseSensitive:false)` | `not` flips the result. This drops the one Sonpovan message the team does not want. | `search log!="*Sonpovan <JP_TEXT>*"` |
| `\| filter contains(content, "Found ")` | Keeps only lines that have a "Found ..." summary. This protects the next line from a missing position. | No line. In Splunk the `rex` simply finds nothing. |
| `\| fieldsAdd queueMessage = substring(content, from: indexOf(content, "Found "))` | `indexOf` returns the position of "Found " in the text, counting from 0. `substring` cuts the text from that position to the end. | `rex field=log "(?<queueMessage>Found .*$)"` |
| `\| fieldsAdd line = splitString(content, "\n")` | `splitString` cuts the text at every newline and returns a list (an array) of lines. | First half of `rex max_match=0`. |
| `\| expand line` | `expand` turns one row with a list into many rows, one row per list item. | Second half of `rex max_match=0`. |
| `\| parse line, "(DIGIT{10} SPACE LD):detail"` | Checks if the line starts with exactly 10 digits and a space. If yes, the whole line is saved as `detail`. The parentheses group the pieces so they are saved together. | `rex field=log max_match=0 "((?<details>[0-9]{10}\s.*)$)"` |
| `\| filter isNotNull(detail)` | `isNotNull` is true when a field has a value. Lines that did not match are dropped. | `search details="*"` |
| `\| summarize details = collectArray(detail), by:{ timestamp, src, queueMessage }` | Puts the detail lines back together. `collectArray` keeps every value in order, including repeats. | The multivalue `details` field that `max_match=0` built. |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, queueMessage, details` | Shows the summary and the list of detail lines. Dynatrace displays the list one item per line. | `eval prettyPrint = queueMessage."<newline>".mvjoin(details,"<newline>")` |

**Watch out:** if Dynatrace stores each line of a multi-line log as its own record, the 10-digit lines are not inside `content` of the ERROR line, so the query returns 0 rows even when Splunk shows results.

### #63 Cc-Batch DocNotif Work Item Failed

**What it finds:** cc-batch lines where the `DocNotif_Adj` work item finished with `failed=true`.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "cc-batch")
| filter contains(content, "Work item processed \"DocNotif_Adj\"", caseSensitive:false)
| filter contains(content, "failed=true", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "cc-batch")` | Keeps cc-batch pods. | `index=cc-batch` |
| `\| filter contains(content, "Work item processed \"DocNotif_Adj\"", caseSensitive:false)` | Keeps the "work item processed" line for DocNotif_Adj. `\"` is a real double quote inside the DQL string. | `search _raw="*Work item processed \"DocNotif_Adj\"*"` |
| `\| filter contains(content, "failed=true", caseSensitive:false)` | Keeps only failed runs. One text check replaces the Splunk extract-then-search pair. | `rex field=_raw "failed=(?<failed>(true\|false))"` followed by `search failed = true` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. DQL keeps one row per line instead of grouping by time. | `stats values(_raw) as log, values(failed) as failed by _time` |

**Watch out:** if the log writes the name with single quotes or adds spaces around the equals sign (`failed = true`), the exact text checks miss it and the query returns 0 rows.

### #64 Cc-Batch FinancialsEsc Work Item Failed

**What it finds:** cc-batch lines where a `FinancialsEsc...` work item finished with `failed=true`.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "cc-batch")
| filter contains(content, "Work item processed \"FinancialsEsc", caseSensitive:false)
| filter contains(content, "failed=true", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

Same as #63 except the work item text is `Work item processed "FinancialsEsc` with no closing quote. Leaving the quote open makes it match any work item whose name starts with FinancialsEsc, just like the Splunk `*`.

**Watch out:** same risk as #63: a different quote style or spacing in the log line gives 0 rows.

### #65 Sonpovan Account Statement Tasklet Warnings

**What it finds:** WARN lines from the sonpovan account statement API tasklet, with the claim number, the message, and a 17-character slice of the message.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter contains(src, "sonpov")
| filter matchesPhrase(content, "WARN")
| filter contains(content, "VanTRecvAccountStatementCallApiTasklet", caseSensitive:false)
| filter contains(content, "Message")
| parse content, "LD (DIGIT+ '/' DIGIT+):claimNumber"
| parse content, "LD 'Message : ' LD:message"
| fieldsAdd suffix = if(stringLength(message) > 400, substring(message, from:400, to:417))
| sort timestamp desc
| fields timestamp, src, claimNumber, message, suffix, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter contains(src, "sonpov")` | Keeps pods with `sonpov` in the name. | `index="*sonpov*"` |
| `\| filter matchesPhrase(content, "WARN")` | `matchesPhrase` looks for a whole word or phrase, ignoring case. It will not match `WARNING` by accident. | The bare word `WARN`. |
| `\| filter contains(content, "VanTRecvAccountStatementCallApiTasklet", caseSensitive:false)` | Keeps lines from the account statement tasklet class. | `<class>.VanTRecvAccountStatementCallApiTasklet` |
| `\| filter contains(content, "Message")` | Keeps lines with `Message` in exactly this case. `contains` is case-sensitive by default. | `CASE(Message)` |
| `\| parse content, "LD (DIGIT+ '/' DIGIT+):claimNumber"` | Skips text until it finds digits, a slash, and digits, and saves them as `claimNumber`. | `rex field=_raw "(?<claimNb>[0-9]+/[0-9]+)"` |
| `\| parse content, "LD 'Message : ' LD:message"` | Skips to the literal text `Message : ` and saves the rest of the line as `message`. | `rex field=_raw "Message : (?<message>.*)"` |
| `\| fieldsAdd suffix = if(stringLength(message) > 400, substring(message, from:400, to:417))` | `stringLength` counts the characters. `if` returns the slice only when the message is longer than 400 characters, otherwise it returns nothing. `substring` counts from 0 and stops before `to`, so this is 17 characters. | `values(eval(substr(message,401,17))) as suffix` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, claimNumber, message, suffix, content` | Shows one row per line. | `stats values(...) ... by _time` |

**Watch out:** the class name was hard to read in the screenshot, so one wrong letter in `VanTRecvAccountStatementCallApiTasklet` makes the query return 0 rows.

### #66 Cc Apps NoUpdatePaymentError

**What it finds:** any cc app log line that contains `NoUpdatePaymentError`.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "cc-")
| filter contains(content, "NoUpdatePaymentError", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "cc-")` | Keeps every pod whose name starts with `cc-`, such as cc-ui and cc-batch. | `index="cc-*"` |
| `\| filter contains(content, "NoUpdatePaymentError", caseSensitive:false)` | Keeps lines with the error name anywhere. | `"*NoUpdatePaymentError*"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. Splunk shows the events list. |

**Watch out:** the Splunk query was rebuilt from a cut-off screenshot, so confirm the error name before trusting a result of 0 rows.

### #67 Sonpov And Temp Receipt ERROR Lines

**What it finds:** ERROR lines from the sonpov and temp-receipt-accounting apps, grouped by time with the pod name.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter contains(src, "sonpov") or contains(src, "temp-receipt-accounting")
| parse content, "INT '-' INT '-' INT SPACE INT ':' INT ':' INT SPACE ALPHA:loglevel_parsed"
| filter loglevel_parsed == "ERROR"
| summarize loglevel = collectDistinct(loglevel_parsed), log = collectDistinct(content), podname = collectDistinct(src), by:{ timestamp }
| sort timestamp desc
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter contains(src, "sonpov") or contains(src, "temp-receipt-accounting")` | Keeps pods from either app. `or` means either check may be true. | `index="*sonpov*" OR index="*temp-receipt-accounting*"` |
| `\| parse content, "INT '-' INT ... SPACE ALPHA:loglevel_parsed"` | `INT` is a whole number. `ALPHA` is a run of letters. The pattern reads `yyyy-mm-dd hh:mm:ss` and saves the next word as the level. | `rex field=_raw "^\d+-\d+-\d+\s\d+:\d+:\d+\S*\s+(?<loglevel>[A-Z]+)"` |
| `\| filter loglevel_parsed == "ERROR"` | Keeps ERROR lines only. | `search loglevel="ERROR"` |
| `\| summarize loglevel = collectDistinct(loglevel_parsed), log = collectDistinct(content), podname = collectDistinct(src), by:{ timestamp }` | One row per timestamp, listing the levels, the raw lines, and which pods wrote them. | `stats values(loglevel) as loglevel, values(_raw) as log, values(host) as podname by _time` |
| `\| sort timestamp desc` | Newest first. | No line. |

**Watch out:** the Splunk regex allows extra characters after the seconds (`\S*`, such as `,123`) and several spaces, but this DQL pattern expects exactly one space right after the seconds, so lines with milliseconds silently fail to parse and give 0 rows.

### #68 Cc-Ui RemoveDocument Called

**What it finds:** cc-ui lines saying a document was removed.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "cc-ui")
| filter contains(content, "removeDocument called for document with DocUID", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "cc-ui")` | Keeps cc-ui pods. | `index="cc-ui*"` |
| `\| filter contains(content, "removeDocument called for document with DocUID", caseSensitive:false)` | Keeps the remove-document line. | `"removeDocument called for document with DocUID"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** Splunk phrase search tolerates extra spaces between words, but `contains` needs the exact spacing, so a double space in the log gives 0 rows.

### #69 Esbv4 Call To Ebroker Failed With 503

**What it finds:** esbv4 errors where a POST to any ebroker URL got "service unavailable (503)".

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/", caseSensitive:false)
    and contains(content, "' failed: service unavailable (503).", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "esbv4")` | Keeps esbv4 pods. | `index="esbv4*"` |
| `\| filter contains(content, "Error(esb.xml) ... :443/", caseSensitive:false)` | Checks the part of the error text before the wildcard: the error header and the ebroker base URL. | The part of the phrase before `*`. |
| `and contains(content, "' failed: service unavailable (503).", caseSensitive:false)` | Checks the part after the wildcard. Both parts must be present. This is how DQL copies a `*` in the middle of a phrase. | The part of the phrase after `*`. |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** the base URL must match the log character for character, so if the log omits `:443` the first check fails and the query returns 0 rows.

### #70 Ebroker Address Conversion Failures

**What it finds:** ebroker lines where converting a zip code to an address failed.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "ebroker")
| filter contains(content, "Address conversion failed.Request to agrex Zipcode:", caseSensitive:false)
    or contains(content, "Address conversion failed.Status code", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "ebroker")` | Keeps ebroker pods. | `index="ebroker*"` |
| `\| filter contains(content, "Address conversion failed.Request to agrex Zipcode:", caseSensitive:false)` | First failure type: the call to the agrex zip code service failed. | `"Address conversion failed.Request to agrex Zipcode:"` |
| `or contains(content, "Address conversion failed.Status code", caseSensitive:false)` | Second failure type: agrex answered with a bad status code. | `OR "Address conversion failed.Status code"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** this filter also matches the ebroker batch pods (`ebroker_batch` style names start with `ebroker` too), so you may see more rows than Splunk if Splunk's index excluded them.

### #71 Ebroker Startup Lines

**What it finds:** each time ebroker started, which shows restarts.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "ebroker")
| filter contains(content, "Starting ApiMain on ebroker", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "ebroker")` | Keeps ebroker pods. | `index="ebroker*"` |
| `\| filter contains(content, "Starting ApiMain on ebroker", caseSensitive:false)` | Keeps the Spring Boot startup line. One line means one start. | `"Starting ApiMain on ebroker"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** 0 rows is normal when nothing restarted in the last 24 hours, so widen the time range before deciding the query is broken.

### #72 Esbv4 Ebroker Requests That Hit An Interceptor Exception

**What it finds:** Interceptor exception lines in esbv4 whose request ID belongs to a request that esbv4 sent to ebroker.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Interceptor for", caseSensitive:false)
    and contains(content, "has thrown exception", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Sending request to /esb/ebroker", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"req."
| filter isNotNull(req.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

How it works: the outer query finds exception lines. The inner query (inside `lookup [ ... ]`) finds request IDs of calls sent to ebroker. `lookup` joins the two on the ID.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Outer query. Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "esbv4")` | Keeps esbv4 pods. | `index=esbv4` |
| `\| filter contains(content, "Interceptor for", caseSensitive:false)` | First half of the exception text, before the wildcard. | `"Interceptor for*` |
| `and contains(content, "has thrown exception", caseSensitive:false)` | Second half of the exception text, after the wildcard. | `*has thrown exception"` |
| `\| parse content, "LD ([0-9a-z]{8} ... [0-9a-z]{12}):query"` | Pulls the request ID (a UUID, 36 characters) out of the exception line into `query`. | No line. Splunk matches the ID as a plain word anywhere in the text. |
| `\| lookup [` | `lookup` runs the query inside the brackets first. Then, for each outer row, it looks for an inner row with the same key and copies its fields onto the outer row. | The subsearch `[ ... ]`. |
| `fetch logs, from:now()-24h` (inner) | Inner query. Reads the same 24 hours. | The subsearch time range. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` (inner) | Builds `src` for the inner query. | No line. |
| `\| filter startsWith(src, "esbv4")` (inner) | Inner query also reads esbv4 only. | `index=esbv4` applies to the subsearch too. |
| `\| filter contains(content, "Sending request to /esb/ebroker", caseSensitive:false)` (inner) | Keeps the lines where esbv4 sends a request to ebroker. | `search "Sending request to /esb/ebroker"` |
| `\| parse content, "LD (...UUID...):query"` (inner) | Pulls the request ID out of the request line. | `rex field=_raw "(?<query>[0-9a-z]{8}-...-[0-9a-z]{12})"` |
| `\| filter isNotNull(query)` (inner) | Drops request lines where no ID was found. | No line. |
| `\| dedup query` (inner) | `dedup` keeps only the first row for each value of `query`, so each ID appears once. | No line. `format` lists each ID. |
| `\| fields query` (inner) | Keeps only the ID column. | `fields query` |
| `], sourceField:query` | Closes the inner query. `sourceField` is the outer field to match on: the ID from the exception line. | `format]` closes the subsearch. |
| `lookupField:query` | The inner field to compare it with: the ID from the request line. | The words written by `format`. |
| `prefix:"req."` | Copied inner fields get this prefix, so the inner `query` arrives as `req.query` and does not overwrite the outer `query`. | No line. |
| `\| filter isNotNull(req.query)` | Keeps only exception lines that found a matching request. Rows with no match have an empty `req.query` and are dropped. This makes the join behave like Splunk's AND. | `AND` between the subsearch and the exception phrase. |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, query, content` | Shows time, pod, ID, and the exception line. | No line. |

The UUID pattern pieces:

| Pattern piece | What it matches |
|---|---|
| `[0-9a-z]{8}` | Exactly 8 characters, each a digit or a lower-case letter. |
| `'-'` | A literal dash between the groups. |
| `[0-9a-z]{4}` | Exactly 4 such characters. Used three times. |
| `[0-9a-z]{12}` | The last group of 12 characters. |
| `( ... ):query` | The parentheses group all the pieces, and `:query` saves the whole UUID into `query`. |

**Watch out:** if a line carries more than one UUID, the outer and inner `parse` may each pick a different one, so the IDs never match and `filter isNotNull(req.query)` silently drops every row.

### #73 Ebroker POST Request Ottif Started

**What it finds:** ebroker lines showing a `POST /request/ottif` call started.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "ebroker")
| filter contains(content, "Started: POST /request/ottif", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "ebroker")` | Keeps ebroker pods. | `index="ebroker*"` |
| `\| filter contains(content, "Started: POST /request/ottif", caseSensitive:false)` | Keeps the request-started line for this endpoint. | `"Started: POST /request/ottif"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** the word `ottif` was blurry in the screenshot, so a wrong spelling returns 0 rows.

### #74 Esbv4 Call To Pc Quote Failed

**What it finds:** any esbv4 failure when calling the policy center quote API, whatever the reason.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: ", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "esbv4")` | Keeps esbv4 pods. | `index="esbv4*"` |
| `\| filter contains(content, "Error(esb-ebroker.xml) ... /quote' failed: ", caseSensitive:false)` | Keeps the failure lines. The text stops where Splunk had its trailing `*`, so any reason (timeout, 500, and so on) matches. | `"Error(esb-ebroker.xml) ... /quote' failed: *"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** the search text ends with a space after `failed:`, so if the log puts a newline there instead of a space, nothing matches.

### #75 Esbv4 Cannot Reach Localhost 8082

**What it finds:** esbv4 errors when it cannot send an HTTP request to a local service on port 8082.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Error sending HTTP request to http://localhost:8082", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads the last 24 hours of logs. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "esbv4")` | Keeps esbv4 pods. | `index="esbv4*"` |
| `\| filter contains(content, "Error sending HTTP request to http://localhost:8082", caseSensitive:false)` | Keeps the connection error lines. Usually a sidecar or local agent on that port is down. | `"Error sending HTTP request to http://localhost:8082"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, content` | Shows time, pod, and the raw line. | No line. |

**Watch out:** `localhost:8082` was blurry in the screenshot, so a wrong port number returns 0 rows.

### #76 Apps That Stopped Logging

**What it finds:** a list of apps whose last log was more than an hour ago, with how far behind each one is.

```
fetch logs, from:now()-7d
| fieldsAdd app = lower(coalesce(k8s.workload.name, k8s.container.name, host.name))
| filter matchesValue(app, array("agrex*", "alfresco*", "bcsubledger*", "ebroker*", "esbv4*", "jobscheduler*",
                                 "legacybridge*", "mailservice*", "portals*", "tts"))
| filter not in(app, array("ebroker_batch", "alfrescoaev", "portals-claim-vendor-backend", "portals-claim-vendor-frontend"))
| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ app }
| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000
| filter last_seen_sec > 3600
| fieldsAdd minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0),
            hours_behind   = round(toDouble(last_seen_sec) / 3600, decimals:1),
            days_behind    = round(toDouble(last_seen_sec) / 86400, decimals:1),
            last_event_jst = formatTimestamp(last_event, format:"EEE MMM dd HH:mm:ss yyyy", timezone:"Asia/Tokyo")
| sort minutes_behind desc
| fields app, last_event_jst, minutes_behind, hours_behind, days_behind
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-7d` | Reads 7 days of logs. Dynatrace has no ready-made "last event per app" list, so it must look at the logs. | `\| metadata type=sourcetypes index=*` |
| `\| fieldsAdd app = lower(coalesce(k8s.workload.name, k8s.container.name, host.name))` | Builds an app name from the workload, then the container, then the host. This plays the role of the sourcetype. | The `sourcetype` column. |
| `\| filter matchesValue(app, array("agrex*", ..., "jobscheduler*",` | `array()` builds a list. `matchesValue` is true when the value matches any pattern in the list. `*` is a wildcard here, and the match ignores case. | `where (like(sourcetype,"agrex%") OR ...)` |
| `"legacybridge*", "mailservice*", "portals*", "tts"))` | The rest of the list. `"tts"` has no star, so it must match exactly. | `... OR like(sourcetype,"tts"))` |
| `\| filter not in(app, array("ebroker_batch", ...))` | `in` is true when the value is one of the list items. `not` flips it, so these four expected-quiet apps are removed. | `where NOT like(sourcetype,"ebroker_batch") AND ...` |
| `\| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ app }` | One row per app with its line count, first event time, and last event time. `max(timestamp)` is the newest log. | The `totalCount`, `firstTime`, and `recentTime` columns from `metadata`. |
| `\| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000` | `toLong` turns a time into a whole number of nanoseconds. The difference divided by one billion gives seconds since the last log. | `now()-recentTime` |
| `\| filter last_seen_sec > 3600` | Keeps apps silent for more than one hour (3600 seconds). | `where 'Minutes Behind' > 60` |
| `\| fieldsAdd minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0),` | `toDouble` makes a decimal number. `round` rounds it. This gives whole minutes. | `eval "Minutes Behind"=round((now()-recentTime)/60,0)` |
| `hours_behind = round(toDouble(last_seen_sec) / 3600, decimals:1),` | Hours behind, one decimal place. | `eval "Hours Behind"=...` |
| `days_behind = round(toDouble(last_seen_sec) / 86400, decimals:1),` | Days behind, one decimal place. | `eval "Days Behind"=...` |
| `last_event_jst = formatTimestamp(last_event, format:"...", timezone:"Asia/Tokyo")` | `formatTimestamp` turns a time into readable text, here in Japan time. | `eval "Last Seen"=strftime(recentTime,"%a %b %d %H:%M:%S %Y")` |
| `\| sort minutes_behind desc` | The app silent the longest goes to the top. | `sort "Minutes Behind" desc` |
| `\| fields app, last_event_jst, minutes_behind, hours_behind, days_behind` | Shows the report columns. | `table sourcetype "Last Seen" "Minutes Behind" "Hours Behind" "Days Behind"` |

**Watch out:** an app that has been silent for more than 7 days has no logs in the window, so it disappears from the report instead of showing at the top as the worst one.

### #77 Bangauto Quote Requests That Hit The Pc Quote Timeout

**What it finds:** bangauto quote requests whose request ID also appears in a policy center quote timeout error.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/bangauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

Why two parts: the timeout line does not say which channel sent the quote. The request line does. Both carry the same request ID. This is the reverse of #72: here the outer query is the request and the inner query is the error.

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Outer query. Reads the last 24 hours. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "esbv4")` | Keeps esbv4 pods. | `index=esbv4` |
| `\| filter contains(content, "Sending request to /esb/ebroker/bangauto/online/_quote", caseSensitive:false)` | Keeps bangauto quote request lines. | `AND "Sending request to /esb/ebroker/bangauto/online/_quote"` |
| `\| parse content, "LD (...UUID...):query"` | Pulls the request ID out of the request line. Same UUID pattern as #72. | No line. Splunk matches the ID as a plain word. |
| `\| lookup [` | Runs the inner query and joins its rows onto the outer rows. | `\| search [` |
| `fetch logs, from:now()-24h` (inner) | Inner query. Reads the same 24 hours. | The subsearch time range. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` (inner) | Builds `src` for the inner query. | No line. |
| `\| filter startsWith(src, "esbv4")` (inner) | Inner query reads esbv4 only. | `index=esbv4` applies to the subsearch too. |
| `\| filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)` (inner) | Keeps the pc quote timeout error lines. Only the end of the long Splunk phrase is used, which is enough to identify them. | `\| search "Error(esb-ebroker.xml) ... failed: Timeout exceeded."` |
| `\| parse content, "LD (...UUID...):query"` (inner) | Pulls the request ID out of each timeout line. | `rex field=_raw "(?<query>...UUID...)"` |
| `\| filter isNotNull(query)` (inner) | Drops timeout lines with no ID. | No line. |
| `\| dedup query` (inner) | One row per ID. | No line. |
| `\| fields query` (inner) | Keeps only the ID column. | `fields query` |
| `], sourceField:query` | Closes the inner query. Match on the outer `query` (the ID from the request line). | `format]` |
| `lookupField:query` | Compare with the inner `query` (the ID from the timeout line). | The words written by `format`. |
| `prefix:"err."` | The inner ID arrives as `err.query`. | No line. |
| `\| filter isNotNull(err.query)` | Keeps only requests that had a timeout. | The `AND` that combines the subsearch and the phrase. |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, query, content` | Shows time, pod, ID, and the request line. | No line. |

Extra query in the same file:

| Extra query | Purpose |
|---|---|
| One-row count version | Counts all bangauto requests and the timed-out ones with `countIf` (count only rows where a condition is true), then shows the timeout percentage. |

**Watch out:** only the exact text `Timeout exceeded.` is counted, so a timeout logged with different wording (for example "Read timed out") is silently left out.

### #78 Inswebauto Quote Requests That Hit The Pc Quote Timeout

**What it finds:** inswebauto quote requests that timed out at the policy center.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Outer query. Reads the last 24 hours. | The time picker. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Builds `src` from the pod or host name. | No line. |
| `\| filter startsWith(src, "esbv4")` | Keeps esbv4 pods. | `index=esbv4` |
| `\| filter contains(content, "Sending request to /esb/ebroker/inswebauto/online/_quote", caseSensitive:false)` | Keeps inswebauto quote request lines. | `AND "Sending request to /esb/ebroker/inswebauto/online/_quote"` |
| `\| parse content, "LD (...UUID...):query"` | Pulls the request ID from the request line. | No line. |
| `\| lookup [` | Runs the inner query and joins it to the outer rows. | `\| search [` |
| `fetch logs, from:now()-24h` (inner) | Inner query. Reads the same 24 hours. | The subsearch time range. |
| `\| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` (inner) | Builds `src` for the inner query. | No line. |
| `\| filter startsWith(src, "esbv4")` (inner) | Inner query reads esbv4 only. | `index=esbv4` |
| `\| filter contains(content, "Error(esb-ebroker.xml) ... failed: Timeout exceeded.", caseSensitive:false)` (inner) | Keeps the timeout error lines. This version uses the full Splunk phrase, word for word. | `\| search "Error(esb-ebroker.xml) ... failed: Timeout exceeded."` |
| `\| parse content, "LD (...UUID...):query"` (inner) | Pulls the request ID from each timeout line. | `rex field=_raw "(?<query>...UUID...)"` |
| `\| filter isNotNull(query)` (inner) | Drops lines with no ID. | No line. |
| `\| dedup query` (inner) | One row per ID. | No line. |
| `\| fields query` (inner) | Keeps only the ID column. | `fields query` |
| `], sourceField:query` | Closes the inner query. Match on the outer ID. | `format]` |
| `lookupField:query` | Compare with the inner ID. | The words written by `format`. |
| `prefix:"err."` | The inner ID arrives as `err.query`. | No line. |
| `\| filter isNotNull(err.query)` | Keeps only requests that timed out. | The `AND`. |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, src, query, content` | Shows time, pod, ID, and the request line. | No line. |

**Watch out:** the top of the Splunk #78 query was cut off in the screenshot and is assumed to match #79, so check the saved search if the counts disagree.

### #79 Inswebbike Quote Requests That Hit The Pc Quote Timeout

**What it finds:** inswebbike quote requests that timed out at the policy center.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebbike/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

Same as #78 except the outer `contains` uses the channel `inswebbike`.

**Watch out:** if you copy #78 and forget to change the channel name, you get inswebauto results under the inswebbike title.

### #80 Kakakucomauto Quote Requests That Hit The Pc Quote Timeout

**What it finds:** Kakaku.com car insurance quote requests that timed out at the policy center.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/kakakucomauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

Same as #78 except the outer `contains` uses the channel `kakakucomauto`.

Other shapes for the same question:

| Extra query | Purpose |
|---|---|
| Version 2, one scan | Reads the logs once instead of twice. It keeps both request lines and timeout lines, groups them by request ID, and shows one row per ID that has both a request and a timeout. Better for daily checks and dashboards. Version 1 (above) is better for comparing with Splunk line by line. |
| All channels in one table | Uses the same lookup, but labels each request with its channel and counts requests and timeouts per channel. |

**Watch out:** when both versions return 0 rows, test the UUID `parse` on a single request line first, because a parse that finds no ID makes the join silently empty.

### #81 Ebroker SSL Certificate Expiring Within 30 Days

**What it finds:** a row only if the ebroker HTTPS certificate expires in less than 30 days.

This is Option A. It works only if someone uploads Splunk's `sslcert_lookup` table to Grail as a lookup file. Option B is recommended instead: a Synthetic HTTP monitor on the ebroker URL with the "certificate expires in less than 30 days" check turned on. Option B needs no query.

```
load "/lookups/sslcert_lookup"
| filter dest == "ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa"
| fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))
| fieldsAdd days_left = toLong((ssl_end - now()) / 1d)
| filter ssl_end < now() + 30d
| fields dest, ssl_end, days_left
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `load "/lookups/sslcert_lookup"` | `load` reads a table file stored in Grail, instead of reading logs. | `\| makeresults` plus `lookup sslcert_lookup` |
| `\| filter dest == "ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa"` | Keeps the row for the ebroker host. | `eval dest="ebroker-inssuite-prod..."` plus the `dest` match in `lookup` |
| `\| fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))` | The table stores the end date as Unix seconds (seconds since 1970). `toLong` makes it a whole number, and `timestampFromUnixSeconds` turns it into a real time value. | `OUTPUT ssl_end_time` (Splunk compares the raw seconds directly). |
| `\| fieldsAdd days_left = toLong((ssl_end - now()) / 1d)` | Days until the certificate ends. `1d` is a duration of one day. | No line. Added for readability. |
| `\| filter ssl_end < now() + 30d` | Keeps the row only if the end date is earlier than 30 days from now. | `where ssl_end_time < relative_time(now(), "+30d")` |
| `\| fields dest, ssl_end, days_left` | Shows the host, the end date, and the days left. | No line. |

Extra query in the same file:

| Extra query | Purpose |
|---|---|
| Option B check | After the Synthetic monitor exists, lists recent Davis problems whose name mentions "certificate" or "SSL". |

**Watch out:** a Grail lookup file is a copy, so if nobody refreshes it the query reports an old date and shows no row even when the real certificate is about to expire.

---

### Before #82 to #85: These Return 0 Today

The portals-amp-backend logs are **not in Dynatrace yet**. The 2026-10-15 checks (answers 9 and 10) found that the only "portals-amp" matches were Splunk's own search logs. The log forwarder (multilogforwarder) only sends the AXA Life namespaces. So #82 to #85 will return 0 rows until portals-amp is onboarded. The queries are still correct to keep ready.

A second fix applies to all four. `message.url` holds the **full https URL**, not a short name. An exact match with `==` or `in()` never matches it. The corrected queries use `contains()`, and #82 uses `endsWith()` for its short names.

### #82 Portals-Amp-Backend Errors On Save, Coverages, Quote, Bind

**What it finds:** error-level JSON logs from the AMP backend for the save, ampupdateCoverages, quote, and bind calls.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), level = toString(j[level])
| filter endsWith(msg_url, "/save") or endsWith(msg_url, "/ampupdateCoverages") or endsWith(msg_url, "/quote") or endsWith(msg_url, "/bind")
| filter lower(level) == "error"
| sort timestamp desc
| fields timestamp, msg_url, level, raw
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1d` | Reads the last day of logs. | `earliest=-1d` |
| `\| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, ...) or contains(log.source, ...)` | Keeps logs whose container, pod, or log source name mentions the AMP backend. Three places are checked because we do not know yet where the name will appear after onboarding. | `sourcetype="portals-amp-backend"` |
| `\| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | `replaceString` swaps plain text (not regex). The inner call turns every `\"` into `"`. The outer call deletes any backslash left. The result is valid JSON. | `eval _raw=replace(_raw,"\\\\\"","\"")` and then `eval _raw=replace(_raw,"\\\\","")` |
| `\| parse raw, "JSON:j"` | The DPL `JSON` matcher reads the whole text as a JSON object and stores it in a field `j`. | `spath` |
| `\| fieldsAdd msg_url = toString(j[message][url]), level = toString(j[level])` | `j[message][url]` reaches into the nested JSON. `toString` turns the value into text. | The `message.url` field from `spath`, plus `spath level` |
| `\| filter endsWith(msg_url, "/save") or endsWith(...) or ...` | `endsWith` is true when the text ends with the given value. It matches the last part of the full URL. The old line was `filter in(msg_url, array("save", ...))`, which never matched because the URL is longer than the short name. `contains` is not used because short words like "quote" would match too many URLs. | `search (message.url="save" OR message.url="ampupdateCoverages" OR message.url="quote" OR message.url="bind")` |
| `\| filter lower(level) == "error"` | Keeps error-level entries, in any case. | `search level=error` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, msg_url, level, raw` | Shows time, URL, level, and the cleaned JSON. | No line. |

**Watch out:** besides the missing logs, a URL with a trailing slash or a query string (for example `/quote?id=1`) fails `endsWith` and is silently left out.

### #83 PayWithCreditCard Caught Exception On Backend

**What it finds:** credit-card payment calls in the last day that hit an exception on the backend.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "payWithCreditCard_Adj") and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1d` | Reads the last day of logs. | `earliest=-1d` |
| `\| filter contains(k8s.container.name, "portals-amp-backend") or ...` | Keeps AMP backend logs by container, pod, or log source name. | `sourcetype="portals-amp-backend"` |
| `\| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | Cleans escaped quotes and leftover backslashes so the text is valid JSON. | The two `eval _raw=replace(...)` lines |
| `\| parse raw, "JSON:j"` | Reads the JSON into `j`. | `spath` |
| `\| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])` | Pulls the URL and the message type out of the JSON. | `message.url` and `message.type` from `spath` |
| `\| filter contains(msg_url, "payWithCreditCard_Adj") and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` | Keeps credit-card calls that ended in a backend exception. `contains` is the corrected check for the full URL. The old line used `msg_url == ...`, which never matched. | `search message.url="*payWithCreditCard_Adj*" message.type="CAUGHT_EXCEPTION_ON_BACKEND"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, msg_url, msg_type, raw` | Shows time, URL, type, and the cleaned JSON. | No line. |

**Watch out:** `msg_type ==` is case-sensitive, so a log that writes the type in a different case returns 0 rows even after onboarding.

### #84 PayWithCreditCard Execution Completed One Day

**What it finds:** credit-card payment calls in the last day that completed.

```
fetch logs, from:now()-1d
| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "payWithCreditCard_Adj") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, msg_url, msg_type, raw
```

Same as #83 except the type is `EXECUTION_COMPLETED`.

**Watch out:** same as #83: 0 rows until portals-amp logs reach Dynatrace.

### #85 PayWithCreditCard Execution Completed One Hour

**What it finds:** credit-card payment calls in the last hour that completed.

This is the fixed notebook query (Step 2 of the 2026-10-15 fix). It has a different shape from #84, so it gets a full table.

```
fetch logs, from:now()-1h
| filter contains(content, "payWithCreditCard_Adj")
| filter contains(k8s.container.name, "portals-amp")
    or contains(k8s.pod.name, "portals-amp")
    or contains(log.source, "portals-amp")
    or contains(host.name, "portals-amp")
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]),
            msg_type = toString(j[message][type]),
            request_id = toString(j[message][request_id]),
            target_system = toString(j[message][target_system])
| filter contains(msg_url, "payWithCreditCard_Adj")
| filter msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, msg_type, request_id, target_system, msg_url, raw
```

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-1h` | Reads the last hour of logs. | `earliest=-1h` |
| `\| filter contains(content, "payWithCreditCard_Adj")` | A cheap text check first. It throws away most lines before the slower JSON work. | No line. Splunk's search does this on its own. |
| `\| filter contains(k8s.container.name, "portals-amp")` | Keeps logs whose container name mentions portals-amp. | `sourcetype="portals-amp-backend"` |
| `or contains(k8s.pod.name, "portals-amp")` | Or whose pod name mentions it. | Same `sourcetype` line. |
| `or contains(log.source, "portals-amp")` | Or whose log source (file path or stream) mentions it. | Same `sourcetype` line. |
| `or contains(host.name, "portals-amp")` | Or whose host name mentions it. Four places are checked because we do not know yet where the name will appear. | Same `sourcetype` line. |
| `\| fieldsAdd raw = replaceString(content, "\\\"", "\"")` | Turns every `\"` into `"`. Only the quote fix is needed here, matching the Splunk #85 clean-up. | `eval _raw=replace(_raw,"\\\\\"","\"")` (twice) |
| `\| parse raw, "JSON:j"` | Reads the JSON into `j`. | `spath` |
| `\| fieldsAdd msg_url = toString(j[message][url]),` | Pulls out the URL. | `message.url` |
| `msg_type = toString(j[message][type]),` | Pulls out the message type. | `message.type` |
| `request_id = toString(j[message][request_id]),` | Pulls out the request ID, useful to follow one call. | `message.request_id` |
| `target_system = toString(j[message][target_system])` | Pulls out the system that was called. | `message.target_system` |
| `\| filter contains(msg_url, "payWithCreditCard_Adj")` | Keeps credit-card calls. `contains` works on the full URL. | `search message.url="*payWithCreditCard_Adj*"` |
| `\| filter msg_type == "EXECUTION_COMPLETED"` | Keeps calls that finished. | `message.type="EXECUTION_COMPLETED"` |
| `\| sort timestamp desc` | Newest first. | No line. |
| `\| fields timestamp, msg_type, request_id, target_system, msg_url, raw` | Shows the useful columns and the cleaned JSON. | No line. |

Extra queries in the related files:

| Extra query | Purpose |
|---|---|
| Step 1 presence check | Counts `payWithCreditCard_Adj` lines anywhere in Dynatrace, grouped by namespace, pod, container, host, and log source. If it returns 0, the logs are not in Dynatrace. |
| Step 3 exception version | Same as Step 2 but keeps `CAUGHT_EXCEPTION_ON_BACKEND`, which is #83 with a one-hour window. |
| Count by pod | Counts completed calls per pod, to compare with Splunk's event count. |
| Per-minute chart | Uses `makeTimeseries completed = count(), interval:1m`. `makeTimeseries` turns rows into a time chart, with one count per minute, like the Splunk timeline bars. |
| Portals-amp onboarding check | Counts any log with "portals-amp" in the host, pod, container, or log source over 24 hours, grouped by where it came from. |

**Watch out:** this query uses only the quote fix, so if the real log also has stray backslashes, `parse` fails, `msg_url` stays empty, and the result is 0 rows even after onboarding.


---

## Data flow map

```
fetch logs, from:  → read Grail logs for the time range
 → fieldsAdd src   → one lower-case source name (pod or host)
 → filter          → app (startsWith / in / contains on src)
 → filter          → text (contains / matchesPhrase / not)
 → parse / fieldsAdd → extract values (ID, level, date, JSON fields)
 → lookup [ ]      → optional join with a second query
 → summarize / makeTimeseries → optional grouping
 → sort + fields   → rows on screen
```

## Related files

| File | Purpose |
|---|---|
| `16-dql-1-to-85-line-by-line.md` | This document: all 85 DQL queries line by line |
| `part-1-01-30.md` | DQL 1 to 30 on their own |
| `part-2-31-60.md` | DQL 31 to 60 on their own |
| `part-3-61-85.md` | DQL 61 to 85 on their own |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Where each DQL came from |
| `2-result.md` | Open items |
| `3-glossary.md` | DQL glossary |
| `16.sh` | Git one-liners (not run) |
| 2026-10-15 answer 15 | The Splunk side, line by line |

## Commands

See `16.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/16-dql-1-to-85-line-by-line
git commit -m "dql 1 to 85 line by line"
git push
```
