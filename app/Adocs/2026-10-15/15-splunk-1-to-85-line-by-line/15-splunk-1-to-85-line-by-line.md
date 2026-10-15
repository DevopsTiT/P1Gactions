# Splunk 1 To 85 Line By Line

## Decision tree

```
Reading any Splunk line → ask four questions
 1. Where does it read from?  index= / sourcetype= / host= / metadata / makeresults
 2. What text must the line contain?
    bare word → whole word, any case
    "quoted phrase" → exact phrase, any case (a * inside is a wildcard)
    match() / regex / CASE() → exact case
    field=value → a named field must equal the value
 3. What happens after each pipe | ?
    rex → pull a value out | spath → read JSON | eval → make a field
    stats / timechart → group and count | where / search → filter again
    dedup → remove repeats | table / fields → choose columns | sort → order
 4. Is there a [ subsearch ]? → it runs first and feeds IDs to the outer search
Unknown text (Japanese garbled, cut off, #10) → placeholder → check against your file
```

## Short takeaway

| Question | Answer |
|---|---|
| How many queries are explained? | All 85 numbers. #10 was never shown, so it has a placeholder entry. |
| How exact is the Splunk text? | 48 are exact from screenshots or notes. 36 are rebuilt from the translation notes and marked "check against your file". |
| Which are repeats? | #12 (of #11), #44 to #49 (of #38 to #43), #53 (of #43), #56 (of #55). |
| Which have unreadable parts? | #29, #34, #54, #58 and #62 (Japanese text), and #65 (class prefix). |
| Most common shape | Pick the app with `index=`, then search for words or phrases. |

## Summary

Each query below shows the Splunk text with one pipe stage per line, then a table that explains every line in plain English, then one sentence on how DQL does the same thing. Read the rule table in each part first: most surprises come from case rules (bare words ignore case, `match()` and `regex` do not) and from Splunk's implicit AND.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| SPL | Splunk Processing Language, the Splunk query language. |
| Pipe `\|` | Sends the rows from one command to the next. |
| `_raw` | The full original log line in Splunk. Dynatrace calls it `content`. |
| `_time` | The event time in Splunk. Dynatrace calls it `timestamp`. |
| `index` | A Splunk storage area, usually one per app. Dynatrace has none. |
| `sourcetype` | A Splunk label for one kind of log. Dynatrace has none. |
| `host` | The machine or pod that sent the log. In this setup it is often the pod name. |
| Bare word | A word without quotes. Matches a whole word, ignoring case. |
| Quoted phrase | Text in quotes. Matches the phrase, ignoring case. |
| Implicit AND | Two search terms next to each other must both match. |
| Subsearch | A search in `[ ]` that runs first and is pasted into the outer search. |

### Where the Splunk text came from

| Source | Queries |
|---|---|
| Today's screenshots (exact) | #7, #44 to #65, #77, #85 |
| 2026-10-14 notes with exact quotes | #2, #3, #5, #11 to #13, #15, #16, #19, #31, #38 to #43, #78 to #80 |
| Rebuilt from the 2026-10-14 translation notes | #1, #4, #6, #8, #9, #14, #17, #18, #20 to #30, #32 to #37, #66 to #76, #81 to #84 |
| Never shown | #10 |

## Result

The full line-by-line explanation follows in three parts.

## Part 1: Queries 1 to 30

This part walks through the first 30 Splunk searches, one pipe stage at a time. A pipe stage is everything between two `|` characters. Splunk runs the stages left to right, and each stage works on the rows the previous stage produced.

Some Splunk rules come up again and again in this part:

| Rule | What it means |
|---|---|
| Bare words ignore case | `error` also finds `ERROR` and `Error`. |
| Bare words match whole words | `error` does not find `errors` or `terror`. |
| Quoted phrases ignore case | `"CMX Error"` also finds `cmx error`. |
| `match()` is case-sensitive | `match(_raw, "ERROR")` does not find `error`. |
| `regex` is case-sensitive | `regex _raw="ERROR"` keeps only exact uppercase. |
| `OR` binds tighter than the implicit AND | `a OR b c` means "(a or b) and c". |
| `*` inside quotes is a wildcard | `"*AuthenticationFailedException*"` means "anything around this word". |
| `field=value` is a field match | `host="X"` checks the host field, not the text of the line. |

---

### #1 Envelope Exceptions With Keyword Tags

**What it finds:** Exception and ERROR lines from two envelope services, with a column listing which exception names appear in each line.

```
(host="biloss-envelope-list-prod" OR host="start-envelope-executions-prod")
| search ("Exception" OR "ERROR")
| eval matched_keywords=mvappend(
    if(match(_raw,"RuntimeException"),"RuntimeException",null()),
    if(match(_raw,"CmxApiException"),"CmxApiException",null()),
    if(match(_raw,"NetworkException"),"NetworkException",null()),
    if(match(_raw,"PSQLException"),"PSQLException",null()),
    if(match(_raw,"NullPointerException"),"NullPointerException",null()),
    if(match(_raw,"IllegalArgumentException"),"IllegalArgumentException",null()),
    if(match(_raw,"Exception"),"Exception",null()),
    if(match(_raw,"ERROR"),"ERROR",null()))
| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S %Z")
| table time host matched_keywords _raw
```

Rebuilt from the translation notes; check against your file. The keyword list inside `mvappend` was copied from the DQL, and the exact spacing may differ.

| Line | What it does |
|---|---|
| `(host="biloss-envelope-list-prod" OR host="start-envelope-executions-prod")` | Keeps events from either of the two hosts. `host` is the Splunk field for the machine or service that sent the log. Splunk ignores case on `host=`. |
| `\| search ("Exception" OR "ERROR")` | `search` filters rows by text. It keeps lines that contain "Exception" or "ERROR" in any case. |
| `\| eval matched_keywords=mvappend(...)` | `eval` creates or changes a field. Here it creates `matched_keywords`. `mvappend` builds a multi-value field, which is a list. |
| `if(match(_raw,"RuntimeException"),"RuntimeException",null())` | `_raw` is the full log line. `match()` tests a regular expression and is case-sensitive. `if` returns the name when it matches, else `null()`, which means empty. `mvappend` skips empty values. |
| The other seven `if(match(...))` lines | Same check for each other keyword. A line with `PSQLException` also gets `Exception`, because that word is inside the longer name. |
| `\| eval time=strftime(_time,"%Y-%m-%d %H:%M:%S %Z")` | `_time` is the event time. `strftime` turns it into readable text such as `2026-10-14 08:59:12 JST`. |
| `\| table time host matched_keywords _raw` | `table` shows only these columns, in this order. |

**DQL in one line:** `host=` becomes `in(host.name, array(...))`, and `mvappend(if(match(...)))` becomes `arrayRemoveNulls(array(if(contains(...))))`.

---

### #2 PC2 Batch AfterBind Exception

**What it finds:** Lines from the pc2 batch pods that say a job threw an exception during the afterBind_Adj step.

```
index="pc2-batch" host="pc*"
| search "Exception occured for job" AND "during afterBind_Adj process"
| fields + _raw
```

| Line | What it does |
|---|---|
| `index="pc2-batch"` | `index` is a Splunk storage area. This reads only the pc2-batch area. |
| `host="pc*"` | Keeps hosts whose name starts with "pc". `*` is a wildcard. In practice only `pc2-batch-inssuite-prod-0` and `-1` match. |
| `\| search "Exception occured for job"` | Keeps lines containing this phrase, any case. "occured" is misspelled in the app's own log, so keep it as is. |
| `AND "during afterBind_Adj process"` | The line must also contain this second phrase. |
| `\| fields + _raw` | `fields +` keeps only the listed fields. Here that is just the raw line. |

**DQL in one line:** `index="pc2-batch" host="pc*"` becomes `startsWith(host.name, "pc2-batch-inssuite-prod-")`, and each phrase becomes `contains(content, "...", caseSensitive:false)`.

---

### #3 BC2 GMO Duplicate Order IDs

**What it finds:** GMO payment order IDs that appear more than once when you ignore the 6-character time part, which can point to duplicate payments.

```
index=bc2* Integration.GMO AND "Map returned by method call" AND "[acs=0&paytimes=&tranid=*&checkstring=*&clientfield3=&clientfield2=&method=1&clientfield1=*&orderid=*&forward=*&approve=*&trandate=*]"
| dedup orderid
| rex field=orderid "(?<OrderID_noTime>.{18})(?<Time>.{6})(?<Rest>.*)"
| eval OrderIDPattern=OrderID_noTime."*".Rest
| stats count by OrderIDPattern
| where count > 1
| sort - count
```

| Line | What it does |
|---|---|
| `index=bc2*` | Reads every index whose name starts with "bc2". |
| `Integration.GMO` | A bare word. Keeps lines that contain the GMO logger name. Bare words ignore case and match whole words. |
| `AND "Map returned by method call"` | Keeps lines that also contain this phrase. |
| `AND "[acs=0&...&trandate=*]"` | Keeps lines that contain the GMO parameter string. Each `*` inside the quotes means "any text here". |
| (automatic) `orderid` field | Splunk sees `orderid=...` in the text and creates an `orderid` field by itself. This is called automatic key=value extraction. |
| `\| dedup orderid` | `dedup` keeps only the first row for each value. Each order ID now appears once. |
| `\| rex field=orderid "(?<OrderID_noTime>.{18})(?<Time>.{6})(?<Rest>.*)"` | `rex` cuts text into named parts with a regular expression. First 18 characters, then 6 time characters, then the rest. |
| `\| eval OrderIDPattern=OrderID_noTime."*".Rest` | Joins the first part, a star, and the rest. The `.` operator joins text. The time part is dropped. |
| `\| stats count by OrderIDPattern` | `stats` groups rows and calculates. This counts rows per pattern. |
| `\| where count > 1` | `where` keeps rows where the condition is true. Only patterns seen more than once remain. |
| `\| sort - count` | `sort` orders rows. The minus sign means biggest first. |

**DQL in one line:** `index=bc2*` becomes `startsWith(host.name, "bc2-")`, and `rex` with fixed lengths becomes `substring(orderid, from:0, to:18)` and friends.

---

### #4 Camunda Error And Fatal

**What it finds:** Lines with uppercase ERROR or FATAL from Camunda 8 identity, Zeebe, Zeebe gateway, and Keycloak pods.

```
sourcetype="camunda-platform" (host="camunda8-prod-identity-*" OR host="camunda8-prod-zeebe-*" OR host="camunda8-prod-zeebe-gateway-*" OR host="camunda8-prod-keycloak-*")
| search ("ERROR" OR "FATAL")
| eval matched_keywords=mvappend(if(match(_raw,"ERROR"),"ERROR",null()), if(match(_raw,"FATAL"),"FATAL",null()))
| where isnotnull(matched_keywords)
| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")
| table time host matched_keywords _raw
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `sourcetype="camunda-platform"` | `sourcetype` is a Splunk label for the log format. This keeps only Camunda platform logs. |
| `(host="camunda8-prod-identity-*" OR ...)` | Keeps the four Camunda components by host prefix. The zeebe prefix already covers the zeebe-gateway hosts. |
| `\| search ("ERROR" OR "FATAL")` | Keeps lines with either word, any case. |
| `\| eval matched_keywords=mvappend(...)` | Tags each line with ERROR, FATAL, or both. `match()` is case-sensitive, so lowercase "error" gets no tag. |
| `\| where isnotnull(matched_keywords)` | `isnotnull` is true when the field has a value. Lines with no uppercase keyword are dropped. The net effect is a case-sensitive search. |
| `\| eval time=strftime(...)` | Turns the event time into readable text. |
| `\| table time host matched_keywords _raw` | Shows these four columns. |

**DQL in one line:** the host list becomes three `startsWith(host.name, ...)` checks, and the search plus `where isnotnull` becomes a plain case-sensitive `contains(content, "ERROR")`.

---

### #5 Camunda Operate Error

**What it finds:** Lines with uppercase ERROR from the Camunda 8 Operate pods.

```
sourcetype="camunda-platform" host="camunda8-prod-operate-*"
| search "ERROR"
| regex _raw="ERROR"
| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")
| table time host _raw
```

| Line | What it does |
|---|---|
| `sourcetype="camunda-platform"` | Keeps Camunda platform logs. |
| `host="camunda8-prod-operate-*"` | Keeps only the Operate pods. Operate is Camunda's web tool for watching running processes. |
| `\| search "ERROR"` | Fast first filter. It ignores case, so "error" also passes. |
| `\| regex _raw="ERROR"` | `regex` keeps rows where a regular expression matches. It is case-sensitive, so only uppercase ERROR survives. |
| `\| eval time=strftime(...)` | Readable time column. |
| `\| table time host _raw` | Shows time, host, and the raw line. |

**DQL in one line:** `search` plus `regex` collapse into one case-sensitive `contains(content, "ERROR")`.

---

### #6 BILoss Retrieve Files CMX Seven Phrases

**What it finds:** Error lines from BILoss-retrieve-files-cmx-prod with any of seven error phrases, tagged with the phrases found.

```
host="BILoss-retrieve-files-cmx-prod"
| search ("CC Error" OR "CmxApiException" OR "NetworkException" OR "RuntimeException" OR "Failed to initialize clients" OR "Failed getCCInformations" OR "NullPointerException")
| eval matched_keywords=mvappend(
    if(match(_raw,"CC Error"),"CC Error",null()),
    if(match(_raw,"CmxApiException"),"CmxApiException",null()),
    if(match(_raw,"NetworkException"),"NetworkException",null()),
    if(match(_raw,"RuntimeException"),"RuntimeException",null()),
    if(match(_raw,"Failed to initialize clients"),"Failed to initialize clients",null()),
    if(match(_raw,"Failed getCCInformations"),"Failed getCCInformations",null()),
    if(match(_raw,"NullPointerException"),"NullPointerException",null()))
| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")
| table time host matched_keywords _raw
```

Rebuilt from the translation notes; check against your file. Only the first `if()` of the list was quoted in the notes.

| Line | What it does |
|---|---|
| `host="BILoss-retrieve-files-cmx-prod"` | Keeps one host. The match ignores case. |
| `\| search ("CC Error" OR ... OR "NullPointerException")` | Keeps lines with any of the seven phrases, any case. |
| `\| eval matched_keywords=mvappend(...)` | Builds the tag list. Each `match()` is case-sensitive. |
| No `where isnotnull` stage | Unlike #4, lines with only a lowercase phrase stay, with an empty tag list. |
| `\| eval time=strftime(...)` | Readable time column. |
| `\| table time host matched_keywords _raw` | Shows four columns. |

**DQL in one line:** `host=` becomes `lower(host.name) == "biloss-retrieve-files-cmx-prod"`, and each phrase becomes `contains(..., caseSensitive:false)` joined by `or`.

---

### #7 BILoss Retrieve Files CMX Error

**What it finds:** Lines that contain exactly "CMX Error" from BILoss-retrieve-files-cmx-prod.

```
host="BILoss-retrieve-files-cmx-prod"
| search "CMX Error"
| regex _raw="CMX Error"
| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")
| table time host _raw
```

| Line | What it does |
|---|---|
| `host="BILoss-retrieve-files-cmx-prod"` | Keeps one host, any case. |
| `\| search "CMX Error"` | Fast filter for the phrase, any case. |
| `\| regex _raw="CMX Error"` | Keeps only exact-case "CMX Error". |
| `\| eval time=strftime(...)` | Readable time column. |
| `\| table time host _raw` | Shows three columns. |

Note: #6 searches "CC Error". This one searches "CMX Error". They are different phrases.

**DQL in one line:** `search` plus `regex` become one case-sensitive `contains(content, "CMX Error")`.

---

### #8 BILoss Processing Three Hosts

**What it finds:** Error lines from three BILoss services with any of seven phrases, tagged with the phrases found.

```
(host="BILoss-processing-prod" OR host="BILoss-pre-processing-prod" OR host="BILoss-link-data-to-cc-prod")
| search ("CC Error" OR "Camunda Error" OR "callCamundaProcess error" OR "RuntimeException" OR "Failed to initialize clients" OR "PSQLException" OR "IllegalArgumentException")
| eval matched_keywords=mvappend(
    if(match(_raw,"CC Error"),"CC Error",null()),
    if(match(_raw,"Camunda Error"),"Camunda Error",null()),
    if(match(_raw,"callCamundaProcess error"),"callCamundaProcess error",null()),
    if(match(_raw,"RuntimeException"),"RuntimeException",null()),
    if(match(_raw,"Failed to initialize clients"),"Failed to initialize clients",null()),
    if(match(_raw,"PSQLException"),"PSQLException",null()),
    if(match(_raw,"IllegalArgumentException"),"IllegalArgumentException",null()))
| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")
| table time host matched_keywords _raw
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `(host="BILoss-processing-prod" OR ...)` | Keeps the three BILoss hosts, any case. |
| `\| search (... seven phrases ...)` | Keeps lines with any of the phrases, any case. |
| `\| eval matched_keywords=mvappend(...)` | Builds a case-sensitive tag list of the phrases found. |
| `\| eval time=strftime(...)` | Readable time column. |
| `\| table time host matched_keywords _raw` | Shows four columns. |

**DQL in one line:** the three hosts become `in(lower(host.name), array(...))`, and the tag list becomes `arrayRemoveNulls(array(if(contains(...))))`.

---

### #9 BILoss Upload To CMX

**What it finds:** Lines from BILoss-upload-to-cmx-prod with any of three error phrases, tagged with the phrases found.

```
host="BILoss-upload-to-cmx-prod"
| search ("CMX Error" OR "RuntimeException" OR "Failed to initialize clients")
| eval matched_keywords=mvappend(
    if(match(_raw,"CMX Error"),"CMX Error",null()),
    if(match(_raw,"RuntimeException"),"RuntimeException",null()),
    if(match(_raw,"Failed to initialize clients"),"Failed to initialize clients",null()))
| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")
| table time host matched_keywords _raw
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `host="BILoss-upload-to-cmx-prod"` | Keeps one host, any case. |
| `\| search ("CMX Error" OR ...)` | Keeps lines with any of the three phrases, any case. |
| `\| eval matched_keywords=mvappend(...)` | Case-sensitive tag list. |
| `\| eval time=strftime(...)` | Readable time column. |
| `\| table time host matched_keywords _raw` | Shows four columns. |

**DQL in one line:** same shape as #6, with `lower(host.name) == "biloss-upload-to-cmx-prod"` and three `contains()` checks.

---

### #10 Not Shown

**What it finds:** Unknown. Query #10 was never shown in any screenshot, so there is nothing to explain or translate yet. Send the screenshot to complete it.

---

### #11 Error Words Or Access Log Failures

**What it finds:** Any line with the word error, failed, or severe, or any access log line with 404, 500, or 503.

```
error OR failed OR severe OR ( sourcetype=access_* ( 404 OR 500 OR 503 ) )
```

| Line | What it does |
|---|---|
| `error` | Bare word. Matches "error" as a whole word, any case. It does not match "errors". |
| `OR failed` | Or the whole word "failed". |
| `OR severe` | Or the whole word "severe". |
| `OR ( sourcetype=access_* ...` | Or a line whose sourcetype starts with `access_`. That usually means web server access logs. |
| `( 404 OR 500 OR 503 ) )` | Inside the access logs, the line must also contain one of these status codes. Splunk searches the raw text for the numbers. |
| No index given | Splunk searches all default indexes. This can be a very large search. |

**DQL in one line:** each bare word becomes `matchesPhrase(content, "error")`, and `sourcetype=access_*` becomes a placeholder `startsWith(log.source, "access_")` that you confirm with a check query.

---

### #12 Error Words Or Access Log Failures (Repeat)

**What it finds:** Same as #11. The text is identical, so the explanation and the DQL are the same.

```
error OR failed OR severe OR ( sourcetype=access_* ( 404 OR 500 OR 503 ) )
```

**DQL in one line:** same DQL as #11.

---

### #13 PC2 UI Legacy Claims FAIL

**What it finds:** pc2-ui lines that call the legacy claims ESB URL and contain the word FAIL.

```
sourcetype="pc2-ui" "https://esbv4-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa/esb/legacyclaims/services/legacydata/claims" FAIL
```

| Line | What it does |
|---|---|
| `sourcetype="pc2-ui"` | Keeps pc2-ui logs. |
| `"https://esbv4-inssuite-prod.op-prod-lpl..."` | Keeps lines that contain this full URL, any case. In the screenshot, `lpl` could also read `1p1`. |
| `FAIL` | Bare word. The line must also contain the whole word FAIL, any case. |
| Spaces between the three parts | A space means AND. All three must be true. |

**DQL in one line:** the long URL is split into two `contains()` checks (host part and path part), and the bare word becomes `matchesPhrase(content, "FAIL")`.

---

### #14 Splunk License Usage Per Day

**What it finds:** How many bytes Splunk ingested per day, split by license pool, source, sourcetype, host, and index.

```
index=_internal source=*license_usage.log* type="Usage"
| eval h=if(len(h)=0 OR isnull(h),"(SQUASHED)",h)
| eval s=if(len(s)=0 OR isnull(s),"(SQUASHED)",s)
| eval idx=if(len(idx)=0 OR isnull(idx),"(UNKNOWN)",idx)
| bin _time span=1d
| stats sum(b) as b by _time, pool, s, st, h, idx
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index=_internal` | `_internal` is Splunk's log about itself. It is not your application data. |
| `source=*license_usage.log*` | Keeps the license log, where Splunk records ingested bytes. |
| `type="Usage"` | Keeps the usage records. |
| `\| eval h=if(len(h)=0 OR isnull(h),"(SQUASHED)",h)` | `len` is text length. `isnull` checks for no value. Empty host values become "(SQUASHED)". |
| `\| eval s=...` | Same fill-in for the source field. |
| `\| eval idx=...` | Empty index values become "(UNKNOWN)". |
| `\| bin _time span=1d` | `bin` rounds time into buckets. Here each event is placed in its day. |
| `\| stats sum(b) as b by _time, pool, s, st, h, idx` | Adds up bytes (`b`) per day, pool, source, sourcetype, host, and index. |

**DQL in one line:** Dynatrace has no Splunk license log, so bytes become `sum(stringLength(content))` per `bin(timestamp, 1d)`, which is only an approximation.

---

### #15 Mailservice Authentication Failure

**What it finds:** mailservice lines with `AuthenticationFailedException`, which means a login to the mail server failed.

```
index=mailservice "*AuthenticationFailedException*"
```

| Line | What it does |
|---|---|
| `index=mailservice` | Reads the mailservice index. |
| `"*AuthenticationFailedException*"` | The stars inside the quotes are wildcards. It finds the word even when it is glued to other text, such as a Java package name. |

**DQL in one line:** `index=mailservice` becomes a host, namespace, or bucket filter that contains "mailservice", and the phrase becomes `contains(content, "AuthenticationFailedException", caseSensitive:false)`.

---

### #16 Mailservice Tomcat Startup

**What it finds:** Tomcat "server started" lines in mailservice, which show each restart.

```
index=mailservice "Catalina.start Server startup"
```

| Line | What it does |
|---|---|
| `index=mailservice` | Reads the mailservice index. |
| `"Catalina.start Server startup"` | Quoted phrase, any case. Tomcat writes it when startup finishes. |

**DQL in one line:** same source filter as #15, and the phrase becomes `matchesPhrase(content, "Catalina.start Server startup")`.

---

### #17 Splunk Throughput Top Five Sources

**What it finds:** Events per minute for the five busiest log sources, from Splunk's own throughput log.

```
index=_internal source=*metrics.log group=per_source_thruput NOT filetracker
| eval events=eps*kb/kbps
| timechart span=1m sum(events) by series limit=5
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index=_internal source=*metrics.log` | Reads Splunk's throughput log. |
| `group=per_source_thruput` | Keeps the per-source throughput records. |
| `NOT filetracker` | Drops Splunk's internal file tracker source. |
| `\| eval events=eps*kb/kbps` | Works out an event count from events per second, kilobytes, and kilobytes per second. |
| `\| timechart span=1m sum(events) by series limit=5` | `timechart` makes a chart over time. One point per minute, one line per source (`series`), top 5 only. |

**DQL in one line:** Dynatrace has no metrics.log, so this becomes `makeTimeseries count(), by:{ log.source }, interval:1m` and then the top 5.

---

### #18 Silent Production Hosts

**What it finds:** Production hosts that have not sent any log for more than one hour.

```
| metadata type=hosts
| where like(host, "%-prod-%") AND NOT like(host, "%amazonaws%")
| eval Last_Seen=now()-recentTime
| where Last_Seen > 3600
| eval Minutes_Behind=round(Last_Seen/60, 0)
| eval Hours_Behind=round(Last_Seen/3600, 1)
| eval Days_Behind=round(Last_Seen/86400, 1)
| eval recentTime=strftime(recentTime, "%c")
| sort - Last_Seen
| table host recentTime Minutes_Behind Hours_Behind Days_Behind
```

Rebuilt from the translation notes; check against your file. The original may also have had `index=*` on the first line.

| Line | What it does |
|---|---|
| `\| metadata type=hosts` | `metadata` reads Splunk's summary list instead of events. Here it gives one row per host with its first and most recent event time. |
| `\| where like(host, "%-prod-%")` | `like` is a simple pattern match where `%` means any text. Keeps production hosts. |
| `AND NOT like(host, "%amazonaws%")` | Drops raw AWS host names. |
| `\| eval Last_Seen=now()-recentTime` | `now()` is the current time. This gives seconds since the last event. |
| `\| where Last_Seen > 3600` | Keeps hosts silent for more than one hour. |
| `\| eval Minutes_Behind=round(Last_Seen/60, 0)` | `round` rounds a number. Silence in whole minutes. |
| `\| eval Hours_Behind=...` | Silence in hours, one decimal. |
| `\| eval Days_Behind=...` | Silence in days, one decimal. |
| `\| eval recentTime=strftime(recentTime, "%c")` | Shows the last event time as readable text. |
| `\| sort - Last_Seen` | Longest silence first. |
| `\| table host recentTime ...` | Shows the result columns. |

**DQL in one line:** Dynatrace has no host list, so `metadata` becomes `summarize max(timestamp), by:{ host.name }`, then seconds since that time.

---

### #19 ESBv4 NetSuite HTTP Error

**What it finds:** ESBv4 lines saying it could not send an HTTP request to NetSuite.

```
index=esbv4 "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443"
```

| Line | What it does |
|---|---|
| `index=esbv4` | Reads the esbv4 index. ESBv4 is the service bus that calls other systems. |
| `"Error sending HTTP request to https://...:443"` | Quoted phrase, any case. `:443` is the HTTPS port. |

**DQL in one line:** `index=esbv4` becomes a host, namespace, pod, or bucket filter for "esbv4", and the phrase becomes `contains(content, "...", caseSensitive:false)`.

---

### #20 Portals AMP Distinct Accounts Per Day

**What it finds:** How many different account numbers used the portals-amp-frontend app each day.

```
sourcetype="portals-amp-frontend"
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| rex field=message.account_number "(?<accountNo>\w+)(?<accountNo2>\s.+)"
| eval date=strftime(_time, "%Y-%m-%d")
| dedup accountNo date
| timechart span=1day count
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `sourcetype="portals-amp-frontend"` | Keeps the AMP frontend logs. |
| `\| eval _raw=replace(_raw,"\\\\\"","\"")` | `replace` swaps text. The app writes JSON with escaped quotes. This turns each escaped quote back into a plain quote. |
| `\| eval _raw=replace(_raw,"\\\\","")` | Removes the leftover backslashes so the line is valid JSON. |
| `\| spath` | `spath` reads JSON into fields, such as `message.account_number`. |
| `\| rex field=message.account_number "(?<accountNo>\w+)(?<accountNo2>\s.+)"` | Takes the first word of the account number as `accountNo`. It only matches when a space follows. |
| `\| eval date=strftime(_time, "%Y-%m-%d")` | Makes a day label. |
| `\| dedup accountNo date` | Keeps one row per account per day. |
| `\| timechart span=1day count` | Counts rows per day. After the dedup, that is the number of distinct accounts. |

**DQL in one line:** `replace` plus `spath` become `replaceString` plus `parse raw, "JSON:j"`, and dedup plus count become `countDistinctExact(accountNo)` per day.

---

### #21 PC UI CPU Percent Of Limit

**What it finds:** For each pc-ui pod, how much CPU it uses as a percent of its CPU limit.

```
index=openshift_stats host=ljpiosa* openshift_deploymentconfig_name=pc-ui
| stats avg(openshift_stats_cpu_percent_of_limit) as cpu_percent by openshift_pod_name
```

Rebuilt from the translation notes; check against your file. The exact command and pod field name were not in the notes.

| Line | What it does |
|---|---|
| `index=openshift_stats` | Reads OpenShift container statistics, which are numbers rather than log text. |
| `host=ljpiosa*` | Keeps one cluster's nodes by host prefix. |
| `openshift_deploymentconfig_name=pc-ui` | Field match. Keeps only the pc-ui application. |
| `\| stats avg(openshift_stats_cpu_percent_of_limit) ... by openshift_pod_name` | Average CPU percent of limit, one row per pod. |

**DQL in one line:** this is a metric, so it becomes `timeseries` on `dt.kubernetes.container.cpu_usage` divided by `limits_cpu`, filtered by `k8s.workload.name == "pc-ui"`.

---

### #22 ESBv4 License Expiring Soon

**What it finds:** ESBv4 license lines whose expiry date is less than 100 days away.

```
index=esbv4 "Valid license key --> Evaluation = false, Expiration Date = "
| rex "Expiration Date = (?<expiration_date>.+)"
| eval expiration_epoch=strptime(expiration_date, "%a %b %d %T JST %Y")
| where expiration_epoch < relative_time(now(), "+100d")
| table _time host expiration_date
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index=esbv4` | Reads the esbv4 index. |
| `"Valid license key --> Evaluation = false, Expiration Date = "` | Keeps the license check lines. |
| `\| rex "Expiration Date = (?<expiration_date>.+)"` | Cuts the date text after "Expiration Date = " into a field. |
| `\| eval expiration_epoch=strptime(...)` | `strptime` turns date text into a time number. The format reads dates like `Mon Jan 05 10:00:00 JST 2027`. |
| `\| where expiration_epoch < relative_time(now(), "+100d")` | `relative_time` moves a time forward or back. Keeps dates earlier than 100 days from now. |
| `\| table _time host expiration_date` | Shows when, where, and the expiry date. |

**DQL in one line:** `rex` becomes `indexOf` plus `substring`, `strptime` becomes `parse ..., "TIMESTAMP(...)"` with a 9-hour JST fix, and `relative_time(now(), "+100d")` becomes `now() + 100d`.

---

### #23 AMP Backend doCancel Backend Exception

**What it finds:** doCancel calls in the last day that ended with CAUGHT_EXCEPTION_ON_BACKEND.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search message.url="doCancel" message.type="CAUGHT_EXCEPTION_ON_BACKEND"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `sourcetype="portals-amp-backend"` | Keeps the AMP backend logs. |
| `earliest=-1d` | `earliest` sets the start of the time range. Here, one day ago. |
| `\| eval _raw=replace(...)` (first) | Turns escaped quotes into plain quotes. |
| `\| eval _raw=replace(...)` (second) | Removes leftover backslashes. |
| `\| spath` | Reads the JSON into fields. |
| `\| search message.url="doCancel"` | Field match on the JSON field `message.url`. |
| `message.type="CAUGHT_EXCEPTION_ON_BACKEND"` | And the call type must be a backend exception. |

**DQL in one line:** `parse raw, "JSON:j"` then `filter j[message][url] == "doCancel" and j[message][type] == "CAUGHT_EXCEPTION_ON_BACKEND"`.

---

### #24 AMP Backend doCancel Completed

**What it finds:** doCancel calls in the last day that finished normally.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search message.url="doCancel" message.type="EXECUTION_COMPLETED"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| All lines except the last | Same as #23. |
| `\| search ... message.type="EXECUTION_COMPLETED"` | Keeps calls that completed, instead of backend exceptions. |

**DQL in one line:** same as #23 with `msg_type == "EXECUTION_COMPLETED"`.

---

### #25 AMP Backend doesRefundExist Completed

**What it finds:** doesRefundExist calls in the last day that finished normally.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search message.url="doesRefundExist" message.type="EXECUTION_COMPLETED"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| All lines except the last | Same as #23. |
| `\| search message.url="doesRefundExist" ...` | Checks the refund lookup call instead of doCancel. |

**DQL in one line:** same as #23 with `msg_url == "doesRefundExist"` and `msg_type == "EXECUTION_COMPLETED"`.

---

### #26 AMP Backend isPolicyCancelAvailable Completed One Week

**What it finds:** isPolicyCancelAvailable calls in the last week that finished normally.

```
sourcetype="portals-amp-backend" earliest=-1w
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search message.url="isPolicyCancelAvailable" message.type="EXECUTION_COMPLETED"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `earliest=-1w` | Looks back one week instead of one day. |
| The middle lines | Same as #23. |
| `\| search message.url="isPolicyCancelAvailable" ...` | Checks the "can this policy be cancelled" call. |

**DQL in one line:** same as #23 with `from:now()-7d` and `msg_url == "isPolicyCancelAvailable"`.

---

### #27 AMP Backend isPolicyCancelAvailable Completed One Day

**What it finds:** Same as #26, but for the last day only.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search message.url="isPolicyCancelAvailable" message.type="EXECUTION_COMPLETED"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `earliest=-1d` | The only difference from #26. One day instead of one week. |

**DQL in one line:** same as #26 with `from:now()-1d`.

---

### #28 Claim Customer applySimplePayment Errors

**What it finds:** Error-level JSON lines from the claim-customer frontend or backend on the applySimplePayment call.

```
(sourcetype="portals-claim-customer-frontend" OR sourcetype="portals-claim-customer-backend")
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search level="error" message.url="/customer/exposure/applySimplePayment"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `(sourcetype="...frontend" OR sourcetype="...backend")` | Keeps either of the two claim-customer apps. |
| `\| eval _raw=replace(...)` (two lines) | Unescape the JSON, as in #23. |
| `\| spath` | Reads the JSON into fields. |
| `\| search level="error"` | Field match on the JSON log level. Splunk field matches ignore case on the value. |
| `message.url="/customer/exposure/applySimplePayment"` | And the call must be the simple payment endpoint. |

**DQL in one line:** `parse raw, "JSON:j"` then `filter lower(j[level]) == "error" and j[message][url] == "/customer/exposure/applySimplePayment"`.

---

### #29 Inssuite BadInputException ContactName

**What it finds:** Lines from inssuite-prod hosts where an API rejected a request because of a bad ContactName.

```
host="*-inssuite-prod-*" "gw.api.rest.exceptions.BadInputException: ContactName:" "<JP_TEXT>"
```

Rebuilt from the translation notes; check against your file. The Japanese text after "ContactName:" was unreadable in the screenshot, so it is shown as `<JP_TEXT>`.

| Line | What it does |
|---|---|
| `host="*-inssuite-prod-*"` | Keeps any host whose name contains `-inssuite-prod-`. |
| `"gw.api.rest.exceptions.BadInputException: ContactName:"` | Keeps lines with this Java exception about the contact name, any case. |
| `"<JP_TEXT>"` | A Japanese error message. Unreadable in the screenshot. |

**DQL in one line:** `host="*-inssuite-prod-*"` becomes `contains(host.name, "-inssuite-prod-")`, and the phrase becomes `contains(content, "...", caseSensitive:false)`.

---

### #30 PC2 UI Metaspace Exhausted

**What it finds:** pc2-ui lines saying Java ran out of Metaspace, the memory area that holds class data. This often comes before a crash.

```
sourcetype="pc2-ui" "Posting Resource Exhausted event: Metaspace"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `sourcetype="pc2-ui"` | Keeps pc2-ui logs. |
| `"Posting Resource Exhausted event: Metaspace"` | Keeps the Metaspace exhaustion message, any case. |

**DQL in one line:** `sourcetype="pc2-ui"` becomes a pod, container, or `log.source` filter for "pc2-ui", and the phrase becomes `contains(content, "...", caseSensitive:false)`.


---

## Part 2: Queries 31 to 60

How to read this part:

- Each query is split into one line per pipe stage. The pipe `|` hands results to the next command.
- A long search line is split into rows: first the source part (`index=...`), then each word or phrase.
- Splunk puts an invisible `AND` between search terms that sit next to each other. This is called the implicit AND.
- In Dynatrace there is no `index`. The DQL versions build a helper field called `src` from the pod name (or the host name when there is no pod name). `index=bc2*` then becomes `startsWith(src, "bc2")`.

Splunk rules used again and again in this part:

| Rule | What it means |
|---|---|
| Bare word | A word without quotes, like `ERROR`. It ignores case and matches a whole word only. `connect` does not match `connection`. |
| Quoted phrase | Text in quotes, like `"Failed to get lock"`. It ignores case and must appear as written. |
| `*` inside quotes | Still a wildcard. It means "any text here". |
| `OR` before `AND` | Splunk joins `OR` terms first, then applies the implicit `AND`. |
| `field=value` | Compares a named field, not the raw text. `errcode=E01` means the field is exactly `E01`. |
| `\[` | An escaped square bracket. It means a literal `[`. |
| `host` | In this setup the Splunk `host` field holds the pod name. |

Queries #32 to #37 were rebuilt from the translation notes because the original Splunk text was only in screenshots. Each of those entries says so.

---

### #31 Alfrescoacr Failed To Get Lock

**What it finds:** Log lines from the alfrescoacr app that say a lock could not be taken.

```
index="alfrescoacr" "Failed to get lock"
```

| Line | What it does |
|---|---|
| `index="alfrescoacr"` | Keeps events from the index named exactly `alfrescoacr`. This is the `field=value` form: the field `index` must equal the value. There is no `*`, so it is not a prefix match. |
| `"Failed to get lock"` | Keeps lines that contain this exact phrase. Case is ignored. |

**DQL in one line:** `contains(k8s.pod.name, "alfrescoacr")` replaces the index, and `contains(content, "Failed to get lock", caseSensitive:false)` replaces the phrase.

---

### #32 Network Errors Counted Per App

**What it finds:** Lines with SSL, timeout, socket, or connect across about 29 apps, counted per app.

Rebuilt from the translation notes; check against your file.

```
(index=accounting* OR index=agrex* OR index=alfrescoaca* OR index=alfrescoacr* OR index=alfrescoacr-batch* OR index=alfrescoaev* OR index=alfrescocollabsrv* OR index=batch_server* OR index=bc-batch* OR index=bc-ui* OR index=bc2-batch* OR index=bc2-ui* OR index=bcsubledger* OR index=cc-batch* OR index=cc-ui* OR index=cm-ui* OR index=cm2-ui* OR index=ebroker* OR index=esb* OR index=hulft* OR index=legacybridge* OR index=mailservice* OR index=pc-batch* OR index=pc-ui* OR index=portals* OR index=sonpovan* OR index=staging* OR index=temp-receipt-accounting* OR index=tts*)
(SSL OR timeout OR socket OR connect)
#OR "Operation started"
| stats count as record_count by index
| sort - record_count
```

| Line | What it does |
|---|---|
| `(index=accounting* OR ... OR index=tts*)` | Keeps events from any of the listed app indexes. The `*` at the end makes each one a prefix match. |
| `OR` | Means "either side is enough". Here it joins the index names so any one of them counts. |
| `(SSL OR timeout OR socket OR connect)` | Keeps lines that contain at least one of these four bare words. |
| Implicit AND between the two groups | The line must come from a listed index and also contain one of the four words. |
| `SSL` | Bare word. Matches `SSL` or `ssl` as a whole word. |
| `timeout` | Bare word. Matches the whole word `timeout`, not `timeouts`. |
| `socket` | Bare word. Matches the whole word `socket`. |
| `connect` | Bare word. It does not match `connection` or `connected`. |
| `#OR "Operation started"` | The earlier notes treated this line as switched off. Splunk's official comment syntax is triple backticks, so check how your saved search really treats this line. |
| `stats count as record_count by index` | `stats` groups events and calculates numbers. Here it counts events per index and names the count `record_count`. |
| `sort - record_count` | `sort` orders the rows. The `-` means largest first. |

**DQL in one line:** `matchesValue(src, array(...))` replaces the index list, `matchesPhrase()` replaces each bare word, and `summarize count(), by:{...}` replaces `stats`.

---

### #33 PC2 Batch Cancellation Waiting For Midnight

**What it finds:** pc2-batch lines that mention both the cancellation step and the wait-for-midnight step.

Rebuilt from the translation notes; check against your file.

```
index=pc2-batch* bcCancellationFinished_Adj AND WaitForMidNight
```

| Line | What it does |
|---|---|
| `index=pc2-batch*` | Keeps events from any index whose name starts with `pc2-batch`. |
| `bcCancellationFinished_Adj` | Bare word. The line must contain this word. Case is ignored. |
| `AND` | Both sides must be true. Writing it is the same as leaving a space. |
| `WaitForMidNight` | Bare word. The line must also contain this word. |

**DQL in one line:** two `matchesPhrase()` checks joined with `and`, after `startsWith(src, "pc2-batch")`.

---

### #34 BC2 GMO SEARCHTRADE Exception

**What it finds:** bc2 lines where a call to the GMO payment gateway's SEARCHTRADE action threw an exception.

Rebuilt from the translation notes; check against your file. The Japanese text after `SEARCHTRADE:` was unreadable, so it is shown as `<JP_TEXT>`.

```
index=bc2* "Exception during GMO call SEARCHTRADE:<JP_TEXT>"
```

| Line | What it does |
|---|---|
| `index=bc2*` | Keeps events from any index starting with `bc2`. This covers bc2-ui and bc2-batch. |
| `"Exception during GMO call SEARCHTRADE:` | The English part of the phrase. GMO is the card payment gateway. SEARCHTRADE looks up a past payment. |
| `<JP_TEXT>"` | The Japanese error text that follows. Unreadable in the screenshot. |

**DQL in one line:** `contains(content, "Exception during GMO call SEARCHTRADE", caseSensitive:false)` with the Japanese part left out until it is pasted in.

---

### #35 BC2 Batch DirectDebit PaymentDueDate Mismatch

**What it finds:** DirectDebit batch lines saying a record has a different payment due date than earlier rows.

Rebuilt from the translation notes; check against your file.

```
index=bc2-batch* "Server.BatchProcess.DirectDebitBatchProcess" "Record with ID * has different PaymentDueDate value * than previous rows"
```

| Line | What it does |
|---|---|
| `index=bc2-batch*` | Keeps events from bc2-batch indexes. |
| `"Server.BatchProcess.DirectDebitBatchProcess"` | Keeps lines written by the DirectDebit batch class. |
| `"Record with ID * has different PaymentDueDate value * than previous rows"` | A phrase with two wildcards. The `*` stands for the record ID and the date, which change on every line. |

**DQL in one line:** DQL `contains()` has no wildcard, so the phrase is split into three `contains()` parts around each `*`.

---

### #36 BC2 Concurrent Data Change In Delinquency Process

**What it finds:** bc2 lines where two processes changed the same data at once during the policy delinquency process.

Rebuilt from the translation notes; check against your file.

```
index=bc2-* "com.guidewire.pl.system.exception.ConcurrentDataChangeException" AND "PolicyDlnqProcess:bc"
```

| Line | What it does |
|---|---|
| `index=bc2-*` | Keeps events from indexes starting with `bc2-`. |
| `"com.guidewire.pl.system.exception.ConcurrentDataChangeException"` | The Guidewire error raised when a record changed under you. |
| `AND` | Both phrases must appear. |
| `"PolicyDlnqProcess:bc"` | Limits it to the policy delinquency (late payment) process. |

**DQL in one line:** two `contains(..., caseSensitive:false)` checks joined with `and`.

---

### #37 Bcsubledger Exception Error Or Warn

**What it finds:** bcsubledger lines that contain Exception, ERROR, or WARN.

Rebuilt from the translation notes; check against your file.

```
index=bcsubledger* (Exception OR " ERROR " OR WARN)
```

| Line | What it does |
|---|---|
| `index=bcsubledger*` | Keeps events from bcsubledger indexes. |
| `Exception` | Bare word. Matches the whole word `Exception`. |
| `" ERROR "` | Quoted with spaces around it. Splunk still treats it as the whole word `ERROR`. |
| `WARN` | Bare word. Matches the whole word `WARN`. |
| `( ... OR ... )` | Any one of the three words is enough. |

**DQL in one line:** three `matchesPhrase()` checks joined with `or`.

---

### #38 BC2 UI GMO Error Code E01050004

**What it finds:** bc2-ui lines that carry the GMO error code E01 with detail code E01050004.

```
index=bc2-ui* "errcode=E01&errinfo=E01050004"
```

| Line | What it does |
|---|---|
| `index=bc2-ui*` | Keeps events from bc2-ui indexes. |
| `"errcode=E01&errinfo=E01050004"` | Keeps lines with this exact text. Because it is in quotes, it is a text search, not a field match. |

**DQL in one line:** `contains(content, "errcode=E01&errinfo=E01050004", caseSensitive:false)`.

---

### #39 BC2 CVS Offline Payment Notification Exception

**What it finds:** bc2 ERROR lines where processing a convenience store (CVS) payment notice failed.

```
index=bc2* ERROR AND Integration.CVS AND "Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:"
```

| Line | What it does |
|---|---|
| `index=bc2*` | Keeps events from bc2 indexes. |
| `ERROR` | Bare word. The line must contain the whole word `ERROR`. |
| `AND` | The next term must also match. |
| `Integration.CVS` | Bare term. The logger name for the CVS integration. |
| `AND` | The next term must also match. |
| `"Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:"` | The exact error phrase. The `[` is plain text inside quotes. |

**DQL in one line:** `matchesPhrase(content, "ERROR")` plus two `contains()` checks.

---

### #40 BC2 Multiple Matches On ContactID

**What it finds:** bc2 lines where a lookup by ContactID_Adj found more than one record.

```
index=bc2* gw.api.database.MultipleMatchesException AND ContactID_Adj AND Values
```

| Line | What it does |
|---|---|
| `index=bc2*` | Keeps events from bc2 indexes. |
| `gw.api.database.MultipleMatchesException` | Bare term. The Guidewire error for "expected one row, got several". |
| `AND ContactID_Adj` | The line must also mention the field `ContactID_Adj`. |
| `AND Values` | The line must also contain the whole word `Values`. |

**DQL in one line:** one `contains()` for the exception name plus two `matchesPhrase()` checks.

---

### #41 BC2 Batch Duplicate CVS Offline Quick Records

**What it finds:** CVS Offline quick payment records that appear more than once with the same ID, amount, and date.

```
index=bc2-batch* "PaymentRecordType=Quick record for CVS Offline"
| dedup _raw
| stats count by Identifier, Amount, PaymentDate
| where count > 1
| eval PaymentDateForSort=strptime(PaymentDate, "%a %b %d %H:%M:%S %Z %Y")
| sort PaymentDateForSort
| fields Identifier, Amount, PaymentDate
```

| Line | What it does |
|---|---|
| `index=bc2-batch*` | Keeps events from bc2-batch indexes. |
| `"PaymentRecordType=Quick record for CVS Offline"` | Keeps only CVS Offline quick record lines. |
| `dedup _raw` | `dedup` removes repeats. `_raw` is the full log line, so identical lines are kept only once. |
| `stats count by Identifier, Amount, PaymentDate` | Counts lines for each combination of ID, amount, and date. Splunk pulled these fields out of `key=value` text on its own. |
| `where count > 1` | `where` keeps rows that pass a test. Here only combinations seen more than once survive. |
| `eval PaymentDateForSort=...` | `eval` creates a new field. |
| `strptime(PaymentDate, "%a %b %d %H:%M:%S %Z %Y")` | `strptime` turns date text like `Wed Oct 14 10:00:00 JST 2026` into a real time value that sorts correctly. |
| `sort PaymentDateForSort` | Orders rows by that time, oldest first. |
| `fields Identifier, Amount, PaymentDate` | `fields` keeps only the listed columns in the output. |

**DQL in one line:** DQL must `parse` the three key=value fields first, then `summarize count(), by:{...}` and `filter count > 1` replace `stats` and `where`.

---

### #42 API Exception When Executing In Three BC2 Apps

**What it finds:** "API - Exception when executing" lines in bc2-ui, bc2-batch, or bcsubledger.

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "API - Exception when executing"
```

| Line | What it does |
|---|---|
| `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` | Keeps events from any of these three exact index names. There is no `*`, so each name must match fully. |
| `AND` | The phrase must also match. |
| `"API - Exception when executing"` | The exact error phrase. |

**DQL in one line:** three `startsWith(src, ...)` checks joined with `or`, then one `contains()`.

---

### #43 GMO EXECTRAN Exception In Three BC2 Apps

**What it finds:** Lines where the GMO EXECTRAN call (the step that actually charges the card) threw an exception.

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "Exception during GMO call EXECTRAN"
```

| Line | What it does |
|---|---|
| `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` | Keeps events from any of the three apps. |
| `AND` | The phrase must also match. |
| `"Exception during GMO call EXECTRAN"` | The exact error phrase. EXECTRAN means "execute transaction". |

**DQL in one line:** same three `startsWith()` checks as #42, with `contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)`.

---

### #44 BC2 UI GMO Error Code E01050004

**What it finds:** Same as #38.

```
index=bc2-ui* "errcode=E01&errinfo=E01050004"
```

**DQL in one line:** reuse the #38 DQL.

---

### #45 BC2 CVS Offline Payment Notification Exception

**What it finds:** Same as #39.

```
index=bc2* ERROR AND Integration.CVS AND "Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:"
```

**DQL in one line:** reuse the #39 DQL.

---

### #46 BC2 Multiple Matches On ContactID

**What it finds:** Same as #40.

```
index=bc2* gw.api.database.MultipleMatchesException AND ContactID_Adj AND Values
```

**DQL in one line:** reuse the #40 DQL.

---

### #47 BC2 Batch Duplicate CVS Offline Quick Records

**What it finds:** Same as #41.

```
index=bc2-batch* "PaymentRecordType=Quick record for CVS Offline"
| dedup _raw
| stats count by Identifier, Amount, PaymentDate
| where count > 1
| eval PaymentDateForSort=strptime(PaymentDate, "%a %b %d %H:%M:%S %Z %Y")
| sort PaymentDateForSort
| fields Identifier, Amount, PaymentDate
```

**DQL in one line:** reuse the #41 DQL.

---

### #48 API Exception When Executing In Three BC2 Apps

**What it finds:** Same as #42.

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "API - Exception when executing"
```

**DQL in one line:** reuse the #42 DQL.

---

### #49 GMO EXECTRAN Exception In Three BC2 Apps

**What it finds:** Same as #43.

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "Exception during GMO call EXECTRAN"
```

**DQL in one line:** reuse the #43 DQL.

---

### #50 BC2 UI Error Code E01 Minus Known Codes

**What it finds:** bc2-ui "Map returned by method call" lines with error code E01, leaving out three detail codes that are already known.

```
index=bc2-ui* "Map returned by method call" AND errcode=E01 AND NOT E01390002 AND NOT E01260010 AND NOT E01110002
```

| Line | What it does |
|---|---|
| `index=bc2-ui*` | Keeps events from bc2-ui indexes. |
| `"Map returned by method call"` | Keeps lines with this phrase. It is the log line that prints the GMO response. |
| `AND errcode=E01` | A field match. Splunk pulled `errcode` out of the text, and it must equal exactly `E01`. A longer code such as `E01390002` does not count. |
| `AND NOT E01390002` | `NOT` throws away lines that contain the word. This drops detail code E01390002. |
| `AND NOT E01260010` | Drops detail code E01260010. |
| `AND NOT E01110002` | Drops detail code E01110002. |

**DQL in one line:** `parse content, "LD 'errcode=' ALNUM:errcode"` then `filter errcode == "E01"`, plus three `not` checks.

---

### #51 BC2 Batch SaveCardWithOrderID Errors On Writer 54

**What it finds:** bc2-batch lines from worker thread MW-Writer-[54] where saving a card with an order ID failed.

```
index="bc2-batch" "Errors in saveCardWithOrderID call" "MW-Writer-\[54\]"
```

| Line | What it does |
|---|---|
| `index="bc2-batch"` | Keeps events from the index named exactly `bc2-batch`. |
| `"Errors in saveCardWithOrderID call"` | The error phrase for the card save call. |
| `"MW-Writer-\[54\]"` | The thread name. The backslashes escape the brackets, so it means the literal text `MW-Writer-[54]`. |
| Implicit AND between the phrases | Both phrases must be on the line. |

**DQL in one line:** two `contains()` checks, with plain `[54]` because DQL `contains()` needs no escaping.

---

### #52 GMO SearchTrade Used To Confirm ExecTran

**What it finds:** Lines where the app used GMO SearchTrade to double-check the result of an ExecTran charge.

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "GMO SearchTrade used to confirm ExecTran status with OrderID"
```

| Line | What it does |
|---|---|
| `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` | Keeps events from any of the three apps. |
| `AND` | The phrase must also match. |
| `"GMO SearchTrade used to confirm ExecTran status with OrderID"` | The exact phrase. It usually means the first charge reply was unclear. |

**DQL in one line:** three `startsWith()` checks and one `contains()`.

---

### #53 GMO EXECTRAN Exception In Three BC2 Apps

**What it finds:** Same as #49 (and #43).

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger) AND "Exception during GMO call EXECTRAN"
```

**DQL in one line:** reuse the #43 DQL.

---

### #54 Operation Failed For A Producer

**What it finds:** pc2-ui or bc2-ui lines where an operation failed and the message is about a producer (sales agent) or producer code.

The Japanese words were unreadable in the screenshot, so they are shown as `<JP_TEXT>`.

```
index=pc2-ui* OR index=bc2-ui* "Operation failed" AND ("ProducerCode <JP_TEXT>" OR "Producer <JP_TEXT>")
```

| Line | What it does |
|---|---|
| `index=pc2-ui* OR index=bc2-ui*` | Keeps events from pc2-ui or bc2-ui indexes. Because `OR` binds first, these two are grouped together. |
| `"Operation failed"` | The line must contain this phrase. |
| `AND` | The next group must also match. |
| `"ProducerCode <JP_TEXT>"` | One possible message: about the producer code. |
| `OR "Producer <JP_TEXT>"` | The other possible message: about the producer. |
| `( ... )` | Either producer phrase is enough. |

**DQL in one line:** two `startsWith()` checks with `or`, one `contains()` for "Operation failed", and two placeholder `contains()` checks to fill in.

---

### #55 BC2 Producer Contact Missing

**What it finds:** bc2 lines saying a producer has no contact record.

```
index=bc2* "Producer Contact is missing for Producer"
```

| Line | What it does |
|---|---|
| `index=bc2*` | Keeps events from bc2 indexes. |
| `"Producer Contact is missing for Producer"` | The exact phrase. |

**DQL in one line:** `startsWith(src, "bc2")` and `contains(content, "Producer Contact is missing for Producer", caseSensitive:false)`.

---

### #56 BC2 Producer Contact Missing

**What it finds:** Same as #55.

```
index=bc2* "Producer Contact is missing for Producer"
```

**DQL in one line:** reuse the #55 DQL.

---

### #57 BC2 Server RunLevel Ready

**What it finds:** bc2 lines saying the server reached a run level and is ready. These show when a bc2 server started or restarted.

```
index=bc2-* Server.RunLevel AND ready
```

| Line | What it does |
|---|---|
| `index=bc2-*` | Keeps events from indexes starting with `bc2-`. |
| `Server.RunLevel` | Bare term. The Guidewire logger that reports server start-up stages. |
| `AND ready` | The line must also contain the whole word `ready`. |

**DQL in one line:** two `matchesPhrase()` checks joined with `and`.

---

### #58 Bcsubledger Japanese Text Search

**What it finds:** bcsubledger lines that contain a Japanese error message.

The Japanese text was unreadable in the screenshot, so it is shown as `<JP_TEXT>`.

```
index=bcsubledger <JP_TEXT>
```

| Line | What it does |
|---|---|
| `index=bcsubledger` | Keeps events from the index named exactly `bcsubledger`. |
| `<JP_TEXT>` | The Japanese words to search for. Unreadable in the screenshot. |

**DQL in one line:** `startsWith(src, "bcsubledger")` plus a placeholder `contains(content, "<JP_TEXT>")` to fill in.

---

### #59 PC2 Batch Payment Request Creation Failure

**What it finds:** pc2-batch lines where creating a payment request for a transaction failed.

```
index=pc2-batch "Creation of a payment request for transaction" failure
```

| Line | What it does |
|---|---|
| `index=pc2-batch` | Keeps events from the index named exactly `pc2-batch`. |
| `"Creation of a payment request for transaction"` | The phrase for the payment request step. |
| `failure` | Bare word. The line must also contain the whole word `failure`. `failures` would not match. |

**DQL in one line:** `contains()` for the phrase plus `matchesPhrase(content, "failure")`.

---

### #60 CC RemoveDocumentChain Execution Duration

**What it finds:** cc-ui or cc-batch lines that report how long the RemoveDocumentChain step took.

```
(index=cc-ui OR index=cc-batch) AND host="*cc-*" RemoveDocumentChain Execution Duration
```

| Line | What it does |
|---|---|
| `(index=cc-ui OR index=cc-batch)` | Keeps events from either of these two exact indexes. |
| `AND host="*cc-*"` | A field match with wildcards. In this setup `host` holds the pod name, so the pod name must contain `cc-`. |
| `RemoveDocumentChain` | Bare word. The name of the document removal step. |
| `Execution` | Bare word. Must also be on the line. |
| `Duration` | Bare word. Must also be on the line. |

**DQL in one line:** two `startsWith()` checks with `or`, `contains(src, "cc-")` for the host, and three `matchesPhrase()` checks.


---

## Part 3: Queries 61 to 85

This part covers batch jobs in cc-batch and sonpovan, the esbv4 and ebroker integration logs, a "which apps went silent" report, an SSL certificate check, and the portals-amp-backend JSON logs.

### Splunk commands you meet in this part

| Command | What it means | Why you care |
|---|---|---|
| `index=` | The Splunk storage area to read from. A `*` is a wildcard. | Dynatrace has no index. We filter on pod or host name instead. |
| `sourcetype=` | The Splunk label for one kind of log, usually one app. | Also missing in Dynatrace. We use the container, workload, or pod name. |
| `rex` | Pulls a value out of the log text with a regular expression. `(?<name>...)` names the captured piece. | DQL has no regex extract. It uses `parse` with DPL patterns. |
| `rex max_match=0` | Keeps every match in the text, not just the first one. The field becomes a list. | DQL must split the line, expand, parse, and collect the list again. |
| `stats values(x) as y by _time` | Groups events by time and lists the unique values of `x` in each group. | DQL uses `summarize y = collectDistinct(x), by:{ timestamp }`. |
| `search` after a pipe | Filters the results that came out of the previous step. | Works on fields you created, not only on raw text. DQL uses `filter`. |
| `mvjoin(list, sep)` | Glues a list of values into one string with a separator. | Only for display. Dynatrace shows arrays as lists, so it is often not needed. |
| `CASE(word)` | Makes Splunk match that word with exact upper and lower case. | DQL `contains()` is already case-sensitive by default. |
| `substr(text, start, length)` | Cuts a piece out of a string. Splunk counts from 1. | DQL `substring()` counts from 0 and takes an end position. |
| Subsearch `[ ... ]` | A search inside square brackets. It runs first, and its result is pasted into the outer search. | DQL uses `lookup` to join the two queries. |
| `format` | Turns the subsearch rows into a search string like `( "id1" ) OR ( "id2" )`. | This is how the inner result becomes part of the outer search. |
| `metadata type=sourcetypes` | Lists each sourcetype with the time of its first and last event. No logs are read. | Dynatrace has no such list. We compute `max(timestamp)` per app. |
| `makeresults` | Creates one empty row so you can add fields to it. | Used when the query reads a table, not logs. |
| `lookup` (Splunk) | Reads a stored CSV table and copies matching columns into the row. | Becomes a Grail lookup file with `load`, or a different Dynatrace feature. |
| `relative_time(now(), "+30d")` | The time 30 days from now. | DQL writes it as `now() + 30d`. |
| `earliest=-1h` | Start the time range 1 hour ago. | DQL uses `from:now()-1h`. |
| `replace(text, regex, new)` | Finds text that matches a regex and swaps it. | DQL uses `replaceString()`, which is plain text, not regex. |
| `spath` | Reads JSON in the event and makes fields like `message.url`. | DQL uses `parse raw, "JSON:j"` and then `j[message][url]`. |

### The subsearch field named query trick

Queries #72 and #77 to #80 all use a subsearch that ends with `| fields query | format`.

| Point | What it means |
|---|---|
| Normal field name | If the field were called `id`, `format` would write `( id="abc" ) OR ( id="def" )`. The outer search would then need an `id` field. |
| Field named `query` | Splunk treats `query` (and `search`) as a special name. `format` writes only the values, as plain words: `( "abc" ) OR ( "def" )`. |
| Effect on the outer search | The outer search looks for the ID anywhere in the raw text. No field extraction is needed on the outer side. |
| Why the authors used it | The ID sits in a different place on the two log lines. Plain-word matching finds it wherever it is. |
| DQL version | DQL cannot paste words into a search. It parses the ID on both sides and joins them with `lookup`. |

---

### #61 Cc-Batch ERROR Lines For EnqueteWorkItem

**What it finds:** ERROR-level log lines from cc-batch that mention the `EnqueteWorkItem_Adj` work item.

```
index="cc-batch"
| rex field=_raw "\d+-\d+-\d+\s\d+:\d+:\d+,\d+\s+(?<loglevel>\w+)"
| stats values(loglevel) as loglevel, values(_raw) as log by _time
| search loglevel="ERROR"
| search log="*EnqueteWorkItem_Adj*"
```

| Line | What it does |
|---|---|
| `index="cc-batch"` | Reads logs from the cc-batch app. |
| `rex field=_raw "...(?<loglevel>\w+)"` | Skips the date and time at the start of the line (like `2026-10-15 09:12:33,123`) and saves the next word as `loglevel`. |
| `stats values(loglevel) as loglevel, values(_raw) as log by _time` | Groups events that share the same timestamp. Keeps the unique levels and the unique raw lines for each time. |
| `search loglevel="ERROR"` | Keeps only groups where the level is ERROR. |
| `search log="*EnqueteWorkItem_Adj*"` | Keeps only groups whose log text contains `EnqueteWorkItem_Adj`. The stars mean "anywhere in the text". |

**DQL in one line:** `rex` becomes `parse content, "LD DIGIT+ '-' ... SPACE+ WORD:loglevel"`, and `stats values` becomes `summarize collectDistinct(), by:{ timestamp }`.

### #62 Cc-Batch MessageQueueMonitor ERROR With Detail Lines

**What it finds:** ERROR lines from `MessageQueueMonitor_Adj` that list stuck queue messages, showing the summary and every 10-digit detail line.

```
index="*cc-batch*"
| rex field=_raw "\d+-\d+-\d+\s\d+:\d+:\d+,\d+\s+(?<loglevel>\w+)\s\[.+\]\s(?<logger>.+)\s-\s\["
| stats values(loglevel) as loglevel, values(_raw) as log by _time
| search loglevel="ERROR"
| search log="*MessageQueueMonitor_Adj*"
| search log!="*Sonpovan <JP_TEXT>*"
| rex field=log "(?<queueMessage>Found .*$)"
| rex field=log max_match=0 "((?<details>[0-9]{10}\s.*)$)"
| search details="*"
| eval prettyPrint = queueMessage."<newline>".mvjoin(details,"<newline>")
```

The Japanese text after "Sonpovan" was garbled in the screenshot, so it is shown as `<JP_TEXT>`. `<newline>` stands for the newline character in the original.

| Line | What it does |
|---|---|
| `index="*cc-batch*"` | Reads any index whose name contains `cc-batch`. |
| `rex ... (?<loglevel>\w+)\s\[.+\]\s(?<logger>.+)\s-\s\[` | Saves the log level, skips the thread name in square brackets, and saves the logger (class) name. |
| `stats values(loglevel) ..., values(_raw) as log by _time` | Groups by timestamp and keeps the unique levels and raw lines. |
| `search loglevel="ERROR"` | Keeps ERROR groups only. |
| `search log="*MessageQueueMonitor_Adj*"` | Keeps groups about the message queue monitor. |
| `search log!="*Sonpovan <JP_TEXT>*"` | Drops one known Sonpovan message that the team does not want to see. |
| `rex field=log "(?<queueMessage>Found .*$)"` | Saves the text from "Found" to the end of the line, for example "Found 3 messages in queue". |
| `rex field=log max_match=0 "((?<details>[0-9]{10}\s.*)$)"` | Saves every line that starts with a 10-digit ID. `max_match=0` means keep all matches, so `details` becomes a list. |
| `search details="*"` | Keeps only events that had at least one detail line. |
| `eval prettyPrint = queueMessage."<newline>".mvjoin(details,"<newline>")` | Builds one display string: the summary, then each detail on its own line. The `.` joins strings. `mvjoin` glues the list together. |

**DQL in one line:** `rex max_match=0` becomes `splitString` + `expand` + `parse` + `collectArray`, and `mvjoin` is dropped because Dynatrace shows the array as a list.

### #63 Cc-Batch DocNotif Work Item Failed

**What it finds:** cc-batch lines where the `DocNotif_Adj` work item finished with `failed=true`.

```
index=cc-batch
| search _raw="*Work item processed \"DocNotif_Adj\"*"
| rex field=_raw "failed=(?<failed>(true|false))"
| search failed = true
| stats values(_raw) as log, values(failed) as failed by _time
```

| Line | What it does |
|---|---|
| `index=cc-batch` | Reads the cc-batch logs. |
| `search _raw="*Work item processed \"DocNotif_Adj\"*"` | Keeps lines that contain `Work item processed "DocNotif_Adj"`. The `\"` is a literal quote inside the search string. |
| `rex field=_raw "failed=(?<failed>(true\|false))"` | Saves the word after `failed=` into a field called `failed`. |
| `search failed = true` | Keeps only failed work items. |
| `stats values(_raw) as log, values(failed) as failed by _time` | Groups by timestamp and lists the lines and the failed flag. |

**DQL in one line:** the `rex` plus `search failed=true` pair becomes a simple `contains(content, "failed=true")`.

### #64 Cc-Batch FinancialsEsc Work Item Failed

**What it finds:** cc-batch lines where a `FinancialsEsc...` work item finished with `failed=true`.

```
index=cc-batch
| search _raw="*Work item processed \"FinancialsEsc*"
| rex field=_raw "failed=(?<failed>(true|false))"
| search failed = true
| stats values(_raw) as log, values(failed) as failed by _time
```

Same as #63 except the work item name is `FinancialsEsc*`. The trailing star matches any work item whose name starts with FinancialsEsc.

**DQL in one line:** same as #63, with `contains(content, "Work item processed \"FinancialsEsc")`.

### #65 Sonpovan Account Statement Tasklet Warnings

**What it finds:** WARN lines from the sonpovan account statement API tasklet, with the claim number, the message, and a 17-character slice of the message.

```
index="*sonpov*" WARN <class>.VanTRecvAccountStatementCallApiTasklet CASE(Message)
| rex field=_raw "(?<claimNb>[0-9]+/[0-9]+)"
| rex field=_raw "Message : (?<message>.*)"
| stats values(claimNb) as claimNumber, values(message) as message, values(eval(substr(message,401,17))) as suffix, values(_raw) as log by _time
```

The package prefix of the class name was partly unreadable, so it is shown as `<class>`.

| Line | What it does |
|---|---|
| `index="*sonpov*"` | Reads any index whose name contains `sonpov`. |
| `WARN` | Bare word. Keeps lines with the word WARN, in any case. |
| `<class>.VanTRecvAccountStatementCallApiTasklet` | Keeps lines from the account statement tasklet class. |
| `CASE(Message)` | Keeps lines with `Message` written with exactly this upper and lower case. |
| `rex field=_raw "(?<claimNb>[0-9]+/[0-9]+)"` | Saves a claim number shaped like `12345/678`. |
| `rex field=_raw "Message : (?<message>.*)"` | Saves everything after `Message : ` as `message`. |
| `stats values(claimNb) as claimNumber` | Lists the claim numbers for each timestamp. |
| `values(message) as message` | Lists the messages for each timestamp. |
| `values(eval(substr(message,401,17))) as suffix` | Cuts 17 characters starting at character 401 of the message. Splunk counts from 1. |
| `values(_raw) as log by _time` | Lists the raw lines, grouped by timestamp. |

**DQL in one line:** `rex` becomes `parse`, and `substr(message,401,17)` becomes `substring(message, from:400, to:417)` because DQL counts from 0.

### #66 Cc Apps NoUpdatePaymentError

**What it finds:** any cc app log line that contains `NoUpdatePaymentError`.

```
index="cc-*"
"*NoUpdatePaymentError*"
```

Rebuilt from the translation notes; check against your file. Today's screenshot is cut off after `index="cc-*"`, and the word `NoUpdatePaymentError` was blurry in the earlier one.

| Line | What it does |
|---|---|
| `index="cc-*"` | Reads every index starting with `cc-` (cc-ui, cc-batch, and so on). |
| `"*NoUpdatePaymentError*"` | Keeps lines that contain the error name anywhere. |

**DQL in one line:** `index="cc-*"` becomes `startsWith(src, "cc-")`, and the phrase becomes `contains(content, "NoUpdatePaymentError", caseSensitive:false)`.

### #67 Sonpov And Temp Receipt ERROR Lines

**What it finds:** ERROR lines from the sonpov and temp-receipt-accounting apps, grouped by time with the pod name.

```
index="*sonpov*" OR index="*temp-receipt-accounting*"
| rex field=_raw "^\d+-\d+-\d+\s\d+:\d+:\d+\S*\s+(?<loglevel>[A-Z]+)"
| stats values(loglevel) as loglevel, values(_raw) as log, values(host) as podname by _time
| search loglevel="ERROR"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index="*sonpov*" OR index="*temp-receipt-accounting*"` | Reads logs from either app. |
| `rex ... (?<loglevel>[A-Z]+)` | Skips the date and time at the start of the line and saves the upper-case word after it as the level. |
| `stats values(loglevel) ..., values(_raw) as log, values(host) as podname by _time` | Groups by timestamp. Lists the levels, the raw lines, and which pod wrote them. |
| `search loglevel="ERROR"` | Keeps ERROR groups only. |

**DQL in one line:** `rex` becomes `parse content, "INT '-' INT '-' INT SPACE ... ALPHA:loglevel_parsed"`, and `stats values` becomes `collectDistinct`.

### #68 Cc-Ui RemoveDocument Called

**What it finds:** cc-ui lines saying a document was removed.

```
index="cc-ui*"
"removeDocument called for document with DocUID"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index="cc-ui*"` | Reads the cc-ui logs. |
| `"removeDocument called for document with DocUID"` | Keeps lines with this exact phrase, ignoring case. |

**DQL in one line:** index becomes `startsWith(src, "cc-ui")`, and the phrase becomes `contains(..., caseSensitive:false)`.

### #69 Esbv4 Call To Ebroker Failed With 503

**What it finds:** esbv4 errors where a POST to any ebroker URL got "service unavailable (503)".

```
index="esbv4*"
"Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/*' failed: service unavailable (503)."
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index="esbv4*"` | Reads the esbv4 logs. |
| `"Error(esb.xml) ... :443/*' failed: service unavailable (503)."` | Keeps the 503 error lines. The `*` inside the quotes is a wildcard, so any ebroker path matches. |

**DQL in one line:** DQL `contains()` has no wildcard, so the phrase is split into two `contains()` checks, one before the `*` and one after it.

### #70 Ebroker Address Conversion Failures

**What it finds:** ebroker lines where converting a zip code to an address failed.

```
index="ebroker*"
("Address conversion failed.Request to agrex Zipcode:" OR "Address conversion failed.Status code")
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index="ebroker*"` | Reads the ebroker logs. |
| `"Address conversion failed.Request to agrex Zipcode:"` | First failure type: the request to the agrex zip code service failed. |
| `OR "Address conversion failed.Status code"` | Second failure type: agrex answered with a bad status code. |

**DQL in one line:** two `contains()` checks joined with `or`.

### #71 Ebroker Startup Lines

**What it finds:** each time ebroker started, which shows restarts.

```
index="ebroker*"
"Starting ApiMain on ebroker"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index="ebroker*"` | Reads the ebroker logs. |
| `"Starting ApiMain on ebroker"` | Keeps the Spring Boot startup line. One line means one start. |

**DQL in one line:** prefix filter plus one `contains()`.

### #72 Esbv4 Ebroker Requests That Hit An Interceptor Exception

**What it finds:** Interceptor exception lines in esbv4 whose request ID belongs to a request sent to ebroker.

```
index=esbv4
[| search "Sending request to /esb/ebroker"
 | rex field=_raw "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
 | fields query
 | format]
AND "Interceptor for*has thrown exception"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index=esbv4` | The outer search reads esbv4 logs. |
| `[\| search "Sending request to /esb/ebroker"` | The subsearch runs first. It finds every request esbv4 sent to ebroker. |
| `rex ... (?<query>UUID pattern)` | Pulls the request ID (a 36-character UUID) into a field named `query`. |
| `fields query` | Keeps only the ID column. |
| `format]` | Turns the IDs into `( "id1" ) OR ( "id2" ) ...`. Because the field is named `query`, they are plain words that match anywhere in the text. |
| `AND "Interceptor for*has thrown exception"` | The outer search also needs the exception text. The `*` is a wildcard for the interceptor name. |

**DQL in one line:** the subsearch becomes `lookup [ ... ], sourceField:query, lookupField:query`, with `parse` pulling the UUID on both sides.

### #73 Ebroker POST Request Ottif Started

**What it finds:** ebroker lines showing a `POST /request/ottif` call started.

```
index="ebroker*"
"Started: POST /request/ottif"
```

Rebuilt from the translation notes; check against your file. The word `ottif` was blurry in the screenshot.

| Line | What it does |
|---|---|
| `index="ebroker*"` | Reads the ebroker logs. |
| `"Started: POST /request/ottif"` | Keeps the request-started line for this endpoint. |

**DQL in one line:** prefix filter plus one `contains()`.

### #74 Esbv4 Call To Pc Quote Failed

**What it finds:** any esbv4 failure when calling the policy center quote API, whatever the reason.

```
index="esbv4*"
"Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: *"
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `index="esbv4*"` | Reads the esbv4 logs. |
| `"Error(esb-ebroker.xml) ... /quote' failed: *"` | Keeps the failure lines. The trailing `*` matches any reason, such as a timeout or a 500. |

**DQL in one line:** the phrase is cut at the `*` and becomes one `contains()` on the part before it.

### #75 Esbv4 Cannot Reach Localhost 8082

**What it finds:** esbv4 errors when it cannot send an HTTP request to a local service on port 8082.

```
index="esbv4*"
"Error sending HTTP request to http://localhost:8082"
```

Rebuilt from the translation notes; check against your file. `localhost:8082` was blurry in the screenshot.

| Line | What it does |
|---|---|
| `index="esbv4*"` | Reads the esbv4 logs. |
| `"Error sending HTTP request to http://localhost:8082"` | Keeps the connection error lines. Usually a sidecar or local agent on that port is down. |

**DQL in one line:** prefix filter plus one `contains()`.

### #76 Apps That Stopped Logging

**What it finds:** a list of apps (Splunk sourcetypes) whose last log was more than an hour ago, with how far behind each one is.

```
| metadata type=sourcetypes index=*
| where (like(sourcetype,"agrex%") OR like(sourcetype,"alfresco%") OR like(sourcetype,"bcsubledger%") OR like(sourcetype,"ebroker%") OR like(sourcetype,"esbv4%") OR like(sourcetype,"jobscheduler%") OR like(sourcetype,"legacybridge%") OR like(sourcetype,"mailservice%") OR like(sourcetype,"portals%") OR like(sourcetype,"tts"))
| where NOT like(sourcetype,"ebroker_batch") AND NOT like(sourcetype,"alfrescoaev") AND NOT like(sourcetype,"portals-claim-vendor-backend") AND NOT like(sourcetype,"portals-claim-vendor-frontend")
| eval "Minutes Behind"=round((now()-recentTime)/60,0)
| eval "Hours Behind"=round((now()-recentTime)/3600,1)
| eval "Days Behind"=round((now()-recentTime)/86400,1)
| where 'Minutes Behind' > 60
| eval "Last Seen"=strftime(recentTime,"%a %b %d %H:%M:%S %Y")
| table sourcetype "Last Seen" "Minutes Behind" "Hours Behind" "Days Behind"
| sort "Minutes Behind" desc
```

Rebuilt from the translation notes; check against your file. The app list, the exclusions, the three "Behind" columns, and the final sort are confirmed. The exact order of the middle lines and anything after the sort are not, because the screenshot was cut off.

| Line | What it does |
|---|---|
| `\| metadata type=sourcetypes index=*` | Starts from Splunk's own list of sourcetypes. Each row has `recentTime`, the time of the newest event. No logs are read. |
| `where (like(sourcetype,"agrex%") OR ...)` | Keeps only the app families the team owns. In `like()`, `%` means "anything". |
| `like(sourcetype,"tts")` | Has no `%`, so it must match `tts` exactly. |
| `where NOT like(sourcetype,"ebroker_batch") AND ...` | Removes four sourcetypes that are expected to be quiet. |
| `eval "Minutes Behind"=...` | Minutes since the last event. |
| `eval "Hours Behind"=...` | Hours since the last event. |
| `eval "Days Behind"=...` | Days since the last event. |
| `where 'Minutes Behind' > 60` | Keeps apps silent for more than an hour. |
| `eval "Last Seen"=strftime(...)` | Turns the last event time into a readable date. |
| `table ...` | Shows only these columns. |
| `sort "Minutes Behind" desc` | Puts the app that has been silent longest at the top. |

**DQL in one line:** `metadata` becomes `summarize last_event = max(timestamp), by:{ app }` over 7 days of logs, and `like()` becomes `matchesValue()`.

### #77 Bangauto Quote Requests That Hit The Pc Quote Timeout

**What it finds:** bangauto quote requests whose request ID also appears in a policy center quote timeout error.

```
index=esbv4
| search
  [| search "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded."
   | rex field=_raw "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
   | fields query
   | format]
  AND "Sending request to /esb/ebroker/bangauto/online/_quote"
```

Why two searches: the timeout line does not say which channel sent the quote. The request line does. Both lines carry the same request ID, so the ID links them.

| Line | What it does |
|---|---|
| `index=esbv4` | The outer search reads esbv4 logs. |
| `\| search [ ... ]` | Filters the outer results using the subsearch output. |
| `\| search "Error(esb-ebroker.xml) ... failed: Timeout exceeded."` | Runs first. Finds every pc quote timeout error. |
| `rex field=_raw "(?<query>...UUID...)"` | Pulls the request ID out of each timeout line into a field named `query`. |
| `fields query` | Keeps only the ID column. |
| `format` | Writes the IDs as plain words: `( "id1" ) OR ( "id2" ) ...`. The special field name `query` is why they are plain words and not `query="id1"`. |
| `AND "Sending request to /esb/ebroker/bangauto/online/_quote"` | Keeps only bangauto request lines that also contain one of those IDs anywhere in the text. |

**DQL in one line:** the subsearch becomes `lookup [ timeout lines \| parse UUID as query ], sourceField:query, lookupField:query`, then `filter isNotNull(err.query)`.

### #78 Inswebauto Quote Requests That Hit The Pc Quote Timeout

**What it finds:** inswebauto quote requests that timed out at the policy center.

```
index=esbv4
| search
  [| search "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded."
   | rex field=_raw "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
   | fields query
   | format]
  AND "Sending request to /esb/ebroker/inswebauto/online/_quote"
```

Same as #77 except the channel in the last line is `inswebauto`. The top lines were cut off in the screenshot and are assumed to match #77.

**DQL in one line:** same `lookup` query as #77 with `inswebauto` in the outer `contains()`.

### #79 Inswebbike Quote Requests That Hit The Pc Quote Timeout

**What it finds:** inswebbike quote requests that timed out at the policy center.

```
index=esbv4
| search
  [| search "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded."
   | rex field=_raw "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
   | fields query
   | format]
  AND "Sending request to /esb/ebroker/inswebbike/online/_quote"
```

Same as #77 except the channel in the last line is `inswebbike`.

**DQL in one line:** same `lookup` query as #77 with `inswebbike` in the outer `contains()`.

### #80 Kakakucomauto Quote Requests That Hit The Pc Quote Timeout

**What it finds:** Kakaku.com car insurance quote requests that timed out at the policy center.

```
index=esbv4
| search
  [| search "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded."
   | rex field=_raw "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
   | fields query
   | format]
  AND "Sending request to /esb/ebroker/kakakucomauto/online/_quote"
```

Same as #77 except the channel in the last line is `kakakucomauto`.

**DQL in one line:** same `lookup` query as #77 with `kakakucomauto` in the outer `contains()`. A combined version counts timeouts for all channels in one table.

### #81 Ebroker SSL Certificate Expiring Within 30 Days

**What it finds:** a row only if the ebroker HTTPS certificate expires in less than 30 days.

```
| makeresults
| eval dest="ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa"
| lookup sslcert_lookup dest OUTPUT ssl_end_time
| where ssl_end_time < relative_time(now(), "+30d")
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `\| makeresults` | Starts with one empty row. No logs are read. |
| `eval dest="ebroker-inssuite-prod..."` | Puts the ebroker host name into the row. |
| `lookup sslcert_lookup dest OUTPUT ssl_end_time` | Finds that host in the stored certificate table and copies its end time (Unix seconds) into the row. |
| `where ssl_end_time < relative_time(now(), "+30d")` | Keeps the row only if the end time is before "now plus 30 days". |

How to read the result: one row means "renew soon". No row means the certificate is fine, or the table is stale.

**DQL in one line:** the Splunk lookup table becomes a Grail lookup file read with `load`, but the better choice is a Synthetic HTTP monitor with the certificate expiry check turned on.

### #82 Portals-Amp-Backend Errors On Save, Coverages, Quote, Bind

**What it finds:** error-level JSON logs from the AMP backend for the save, ampupdateCoverages, quote, and bind calls.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search (message.url="save" OR message.url="ampupdateCoverages" OR message.url="quote" OR message.url="bind")
| spath level
| search level=error
```

Rebuilt from the translation notes; check against your file.

| Line | What it does |
|---|---|
| `sourcetype="portals-amp-backend"` | Reads the AMP backend logs. |
| `earliest=-1d` | Looks back one day. |
| `eval _raw=replace(_raw,"\\\\\"","\"")` | Turns every escaped quote `\"` into a normal quote `"`. |
| `eval _raw=replace(_raw,"\\\\","")` | Deletes any backslash that is left, so the line becomes valid JSON. |
| `spath` | Reads the JSON and creates fields such as `message.url` and `message.type`. |
| `search (message.url="save" OR ... "bind")` | Keeps the four business calls. |
| `spath level` | Makes sure the `level` field is extracted. |
| `search level=error` | Keeps error-level entries only. |

**DQL in one line:** `replace` becomes `replaceString`, `spath` becomes `parse raw, "JSON:j"`, and the url list becomes `in(msg_url, array(...))`.

### #83 PayWithCreditCard Caught Exception On Backend

**What it finds:** credit-card payment calls in the last day that hit an exception on the backend.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\\"","\"")
| spath
| search message.url="*payWithCreditCard_Adj*" message.type="CAUGHT_EXCEPTION_ON_BACKEND"
```

Rebuilt from the translation notes; check against your file. The shape is taken from #85, with one day instead of one hour and a different type.

| Line | What it does |
|---|---|
| `sourcetype="portals-amp-backend" earliest=-1d` | AMP backend logs from the last day. |
| `eval _raw=replace(...)` (first) | Turns `\"` into `"`. |
| `eval _raw=replace(...)` (second) | Runs the same clean-up again, in case quotes were escaped twice. |
| `spath` | Reads the JSON into fields. |
| `search message.url="*payWithCreditCard_Adj*"` | Keeps calls whose URL contains `payWithCreditCard_Adj`. The stars are needed because the field holds the full URL. |
| `message.type="CAUGHT_EXCEPTION_ON_BACKEND"` | Keeps only calls that ended with a backend exception. |

**DQL in one line:** `spath` becomes `parse raw, "JSON:j"`, then filter on `j[message][url]` and `j[message][type]`.

### #84 PayWithCreditCard Execution Completed One Day

**What it finds:** credit-card payment calls in the last day that completed.

```
sourcetype="portals-amp-backend" earliest=-1d
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\\"","\"")
| spath
| search message.url="*payWithCreditCard_Adj*" message.type="EXECUTION_COMPLETED"
```

Same as #83 except `message.type="EXECUTION_COMPLETED"`. Rebuilt from the translation notes; check against your file.

**DQL in one line:** same as #83 with `msg_type == "EXECUTION_COMPLETED"`.

### #85 PayWithCreditCard Execution Completed One Hour

**What it finds:** credit-card payment calls in the last hour that completed.

```
sourcetype="portals-amp-backend" earliest=-1h
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\\"","\"")
| spath
| search message.url="*payWithCreditCard_Adj*" message.type="EXECUTION_COMPLETED"
```

Same as #84 except `earliest=-1h`.

| Line | What it does |
|---|---|
| `sourcetype="portals-amp-backend"` | Reads the AMP backend logs. |
| `earliest=-1h` | Only the last hour, up to now. |
| `eval _raw=replace(_raw,"\\\\\"","\"")` (twice) | Turns escaped quotes into normal quotes. In a Splunk string, `\\\\\"` is the regex for one backslash followed by a quote. |
| `spath` | Reads the cleaned JSON into fields. |
| `search message.url="*payWithCreditCard_Adj*"` | Keeps credit-card payment calls. |
| `message.type="EXECUTION_COMPLETED"` | Keeps calls that finished. |

Note: an earlier answer (2026-10-14 answer 20) showed the second line as `replace(_raw,"\\\\","")`, which deletes leftover backslashes. Check which one your saved search uses.

**DQL in one line:** `earliest=-1h` becomes `from:now()-1h`, `replace` becomes `replaceString`, and `spath` becomes `parse raw, "JSON:j"`.


---

## Data flow map

```
Splunk query
 → source: index / sourcetype / host / metadata / makeresults
 → text filter: bare words, phrases, field=value, NOT, OR
 → pipe stages: rex / spath / eval → dedup / where / search → stats / timechart → table / sort
 → optional [ subsearch ] → IDs pasted into the outer search
 → rows on screen

Same query in Dynatrace
 → fetch logs (from:) → src = pod or host name filter
 → contains / matchesPhrase / parse
 → fieldsAdd / filter / summarize / makeTimeseries / lookup
 → fields + sort
```

## Related files

| File | Purpose |
|---|---|
| `15-splunk-1-to-85-line-by-line.md` | This document: all 85 queries line by line |
| `part-1-01-30.md` | Queries 1 to 30 on their own |
| `part-2-31-60.md` | Queries 31 to 60 on their own |
| `part-3-61-85.md` | Queries 61 to 85 on their own |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Where each Splunk text came from |
| `2-result.md` | Open items |
| `3-glossary.md` | Splunk command glossary |
| `15.sh` | Git one-liners (not run) |
| 2026-10-14 answers 1 to 18 and 2026-10-15 answers 1 to 14 | The full DQL for each query |

## Commands

See `15.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/15-splunk-1-to-85-line-by-line
git commit -m "splunk 1 to 85 line by line"
git push
```
