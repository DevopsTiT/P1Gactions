# DQL Match Examples 1 To 85

## Decision tree

```
Want to test a DQL before trusting it?
 → take the sample record for that number
 → check each filter line against the sample
   source filter → does src / host.name start with the right prefix?
   contains (no caseSensitive) → is the case exactly the same?
   matchesPhrase → is the word whole, with space or punctuation around it?
   parse → would the pattern extract the value the next filter expects?
   not → is the excluded text really absent?
   lookup → do the outer and inner lines share the same ID?
 → all pass → the row appears
 → one fails → look at the "near miss" line for that number
```

## Short takeaway

| Question | Answer |
|---|---|
| What is in this document? | For every DQL #1 to #85: a sample record that matches, why it passes each line, the output row, and a near miss that does not match. |
| Are the samples real logs? | No. They are made-up but realistic. Hosts, IDs and URLs are fake except the phrases copied from the queries. |
| Which have no sample? | #10, because the Splunk query was never shown. |
| Which share a sample? | #12 uses #11. #44 to #49 use #38 to #43. #53 uses #49. #56 uses #55. |
| Which return 0 rows today? | #20, #23 to #28 and #82 to #85, because portals-amp logs are not in Dynatrace yet. |

## Summary

Use a sample line to understand what a query is looking for, or paste a similar real line into a Dynatrace notebook test to see if the filters behave as expected. The near miss line shows the most common reason a real log is silently dropped.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Sample record | A made-up log record with the fields the query reads (`timestamp`, `host.name`, `k8s.pod.name`, `content`). |
| Match | The record passes every `filter` line and reaches the final `fields` line. |
| Near miss | A record that looks almost right but is dropped by one line. |
| `src` | The helper field `lower(coalesce(k8s.pod.name, host.name))`. When a pod name exists, it is used instead of the host name. |
| Escaped JSON | JSON stored with `\"` instead of `"`. The `replaceString` line fixes it before `parse "JSON:j"`. |

### Samples that depend on behaviour not yet tested

| Query | What to confirm |
|---|---|
| #13, #16, #33, #40, #45, #46, #57 | How `matchesPhrase` splits words around dots, underscores and `=`. The samples put the words between spaces, so they should match. |
| #22 | That the expiry date is read in the expected time zone. |
| #41, #47 | That `LD` before `','` stops at the first comma. Test the parse lines on one real line. |
| #65 | That the class name capture comes out in full. |
| #67 | That `INT` reads `2026-10-15` as three numbers and not as negative numbers. |
| #81 | Whether `toLong` drops or rounds the fraction of days. The row is kept either way. |

## Result

The samples follow in three parts.

## Part 1: Match Examples For DQL 1 to 30

This part shows, for each DQL query #1 to #30, one fake log record that would pass every filter, plus the row the query would print for it. Each entry also shows a near miss, which is a record that looks almost the same but gets dropped, so you can see exactly which check is strict.

---

### #1 Envelope Exceptions With Keyword Tags

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: biloss-envelope-list-prod
k8s.pod.name: (empty)
log.source: /ecs/biloss-envelope-list-prod/app
content: 2026-10-15 09:12:34.567 ERROR [main] EnvelopeListService - Failed to list envelopes: com.example.cmx.CmxApiException: HTTP 503 from CMX
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter in(host.name, array("biloss-envelope-list-prod", "start-envelope-executions-prod"))` | The host is exactly `biloss-envelope-list-prod`, all lowercase, which is the first value in the list. |
| `\| filter contains(content, "Exception", caseSensitive:false)` | The text `CmxApiException` contains the word `Exception`. |
| `or contains(content, "ERROR", caseSensitive:false)` | The line also has `ERROR`, so this check is true as well. Only one of the two is needed. |
| `if(contains(content, "CmxApiException"), "CmxApiException")` | The exact-case text `CmxApiException` is in the line, so this tag is added. |
| `if(contains(content, "Exception"), "Exception")` | `CmxApiException` ends with `Exception`, so the generic `Exception` tag is also added. |
| `if(contains(content, "ERROR"), "ERROR")` | The uppercase word `ERROR` is in the line, so this tag is added. |
| The other five `if(contains(...))` tag lines | None of `RuntimeException`, `NetworkException`, `PSQLException`, `NullPointerException`, or `IllegalArgumentException` appear, so they return null and `arrayRemoveNulls` drops them. |

**Result row:**

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-15 09:12:34 JST | biloss-envelope-list-prod | ["CmxApiException", "Exception", "ERROR"] | 2026-10-15 09:12:34.567 ERROR [main] EnvelopeListService - Failed to list envelopes: ... |

**Near miss (would NOT match):** `host.name: Biloss-Envelope-List-Prod` with the same content. It is dropped because `in(host.name, ...)` is an exact, case-sensitive compare and the capital letters do not match the lowercase list values.

---

### #2 PC2 Batch AfterBind Exception

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-3-15.ap-northeast-1.compute.internal
k8s.pod.name: pc2-batch-inssuite-prod-7f9c4d6b8-x2k8p
log.source: /var/log/containers/pc2-batch-inssuite-prod-7f9c4d6b8-x2k8p_pc2-batch.log
content: 2026-10-15 09:12:34,567 ERROR [BatchWorker-3] PolicyBatchRunner - Exception occured for job RenewalBatch-20261015 during afterBind_Adj process: java.lang.NullPointerException
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter startsWith(host.name, "pc2-batch-inssuite-prod-")` | This check is false, because the host is a node name. That is fine, because the next line is joined with `or`. |
| `or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")` | The pod name `pc2-batch-inssuite-prod-7f9c4d6b8-x2k8p` begins with the exact prefix. |
| `\| filter contains(content, "Exception occured for job", caseSensitive:false)` | The line has `Exception occured for job`, with the app's own spelling `occured`. |
| `and contains(content, "during afterBind_Adj process", caseSensitive:false)` | The line also has `during afterBind_Adj process`, so both required phrases are present. |

**Result row:**

| timestamp | host.name | k8s.pod.name | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | ip-10-20-3-15.ap-northeast-1.compute.internal | pc2-batch-inssuite-prod-7f9c4d6b8-x2k8p | 2026-10-15 09:12:34,567 ERROR [BatchWorker-3] ... during afterBind_Adj process: ... |

**Near miss (would NOT match):** `content: ... Exception occurred for job RenewalBatch-20261015 during afterBind_Adj process ...`. It is dropped because the correct spelling `occurred` does not contain the text `occured`, so the first phrase check fails.

---

### #3 BC2 GMO Duplicate Order IDs

**Sample records that match (three records, two of them form a duplicate group):**

```
# Record 1
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: bc2-payment-prod-6d8f7b9c5-abcde
k8s.pod.name: bc2-payment-prod-6d8f7b9c5-abcde
log.source: /var/log/bc2/payment.log
content: 2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-5] Integration.GMO - Map returned by method call: [acs=0&paytimes=&tranid=2610150912345678&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ORD-20261015-PA001091234-01&trandate=20261015091234&forward=2a99662]

# Record 2
timestamp: 2026-10-15T09:13:01.204+09:00
host.name: bc2-payment-prod-6d8f7b9c5-abcde
k8s.pod.name: bc2-payment-prod-6d8f7b9c5-abcde
log.source: /var/log/bc2/payment.log
content: 2026-10-15 09:13:01,204 INFO [http-nio-8080-exec-7] Integration.GMO - Map returned by method call: [acs=0&paytimes=&tranid=2610150913017788&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ORD-20261015-PA001091301-01&trandate=20261015091301&forward=2a99662]

# Record 3
timestamp: 2026-10-15T09:20:45.880+09:00
host.name: bc2-payment-prod-6d8f7b9c5-fghij
k8s.pod.name: bc2-payment-prod-6d8f7b9c5-fghij
log.source: /var/log/bc2/payment.log
content: 2026-10-15 09:20:45,880 INFO [http-nio-8080-exec-2] Integration.GMO - Map returned by method call: [acs=0&paytimes=&tranid=2610150920451234&clientfield3=&clientfield2=&method=1&clientfield1=&orderid=ORD-20261015-PB777092045-01&trandate=20261015092045&forward=2a99662]
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter startsWith(host.name, "bc2-") or startsWith(k8s.pod.name, "bc2-")` | Both the host and the pod begin with `bc2-`. |
| `\| filter contains(content, "Integration.GMO")` | The logger name `Integration.GMO` appears with the exact same case. |
| `and contains(content, "Map returned by method call", caseSensitive:false)` | The phrase `Map returned by method call` is in each line. |
| `and contains(content, "[acs=0&paytimes=&tranid=")` | Each line has the exact piece `[acs=0&paytimes=&tranid=` right after the colon. |
| `and contains(content, "&clientfield3=&clientfield2=&method=1&clientfield1=")` | Each line has this exact middle piece, in the same order. |
| `and contains(content, "&orderid=")` | Each line has `&orderid=`. |
| `and contains(content, "&trandate=")` | Each line has `&trandate=`. |
| `\| fieldsAdd after_orderid = substring(content, from: indexOf(content, "&orderid=") + 9)` | For record 1 this gives `ORD-20261015-PA001091234-01&trandate=...`, which is everything after `&orderid=`. |
| `\| fieldsAdd orderid = substring(after_orderid, from:0, to: indexOf(after_orderid, "&"))` | The cut stops at the next `&`, so record 1 gets `ORD-20261015-PA001091234-01`. |
| `\| dedup orderid` | The three order IDs are all different, so all three rows stay. |
| `\| filter stringLength(orderid) >= 24` | Each order ID is 27 characters long, so none are dropped. |
| `OrderID_noTime = substring(orderid, from:0, to:18)` | Record 1 and record 2 both give `ORD-20261015-PA001`. |
| `Time = substring(orderid, from:18, to:24)` | Record 1 gives `091234` and record 2 gives `091301`. These are the parts that differ. |
| `Rest = substring(orderid, from:24)` | Record 1 and record 2 both give `-01`. |
| `\| fieldsAdd OrderIDPattern = concat(OrderID_noTime, "*", Rest)` | Record 1 and record 2 both become `ORD-20261015-PA001*-01`. Record 3 becomes `ORD-20261015-PB777*-01`. |
| `\| summarize count = count(), orderids = collectDistinct(orderid), by:{ OrderIDPattern }` | The PA001 pattern gets a count of 2. The PB777 pattern gets a count of 1. |
| `\| filter count > 1` | Only the PA001 pattern has more than one row, so only it survives. |

**Result row:**

| OrderIDPattern | count | orderids |
|---|---|---|
| ORD-20261015-PA001*-01 | 2 | ["ORD-20261015-PA001091234-01", "ORD-20261015-PA001091301-01"] |

**Near miss (would NOT match):** the same line as record 1 but with `integration.GMO` in lowercase. It is dropped because `contains(content, "Integration.GMO")` has no `caseSensitive:false`, so the lowercase `i` fails the check.

---

### #4 Camunda Error And Fatal

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-30-1-22.ap-northeast-1.compute.internal
k8s.pod.name: camunda8-prod-zeebe-gateway-5c7d9b8f6-qwert
log.source: /var/log/containers/camunda8-prod-zeebe-gateway-5c7d9b8f6-qwert_zeebe-gateway.log
content: 2026-10-15 09:12:34.567 [grpc-executor-2] ERROR io.camunda.zeebe.gateway - Failed to activate jobs for worker payment-worker: DEADLINE_EXCEEDED
```

| DQL line | Why this sample passes |
|---|---|
| The three `startsWith(host.name, ...)` lines | All three are false, because the host is a node name. The pod checks below still allow the row. |
| `or startsWith(k8s.pod.name, "camunda8-prod-zeebe-")` | The pod name `camunda8-prod-zeebe-gateway-5c7d9b8f6-qwert` begins with `camunda8-prod-zeebe-`. The gateway is covered by this Zeebe prefix. |
| `\| filter contains(content, "ERROR") or contains(content, "FATAL")` | The line has uppercase `ERROR`, which is what the case-sensitive check wants. |
| `if(contains(content, "ERROR"), "ERROR")` | `ERROR` is present, so the tag is added. |
| `if(contains(content, "FATAL"), "FATAL")` | `FATAL` is not present, so this returns null and is removed. |

**Result row:**

| time | host.name | k8s.pod.name | matched_keywords | content |
|---|---|---|---|---|
| 2026-10-15 09:12:34 JST | ip-10-30-1-22.ap-northeast-1.compute.internal | camunda8-prod-zeebe-gateway-5c7d9b8f6-qwert | ["ERROR"] | 2026-10-15 09:12:34.567 [grpc-executor-2] ERROR io.camunda.zeebe.gateway - ... |

**Near miss (would NOT match):** `content: level=error msg="Failed to activate jobs"` on the same pod. It is dropped because `contains(content, "ERROR")` is case-sensitive and the line only has lowercase `error`.

---

### #5 Camunda Operate Error

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-30-2-41.ap-northeast-1.compute.internal
k8s.pod.name: camunda8-prod-operate-7b9f6c5d4-zx12k
log.source: /var/log/containers/camunda8-prod-operate-7b9f6c5d4-zx12k_operate.log
content: 2026-10-15 09:12:34.567 ERROR 1 --- [import_1] i.c.o.zeebeimport.ImportJob : Error while importing Zeebe records into Elasticsearch
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter startsWith(host.name, "camunda8-prod-operate-")` | This is false for the node host name, but the next `or` line covers it. |
| `or startsWith(k8s.pod.name, "camunda8-prod-operate-")` | The pod name begins with `camunda8-prod-operate-`. |
| `\| filter contains(content, "ERROR")` | The line has the uppercase word `ERROR`. |

**Result row:**

| time | host.name | k8s.pod.name | content |
|---|---|---|---|
| 2026-10-15 09:12:34 JST | ip-10-30-2-41.ap-northeast-1.compute.internal | camunda8-prod-operate-7b9f6c5d4-zx12k | 2026-10-15 09:12:34.567 ERROR 1 --- [import_1] ... |

**Near miss (would NOT match):** `content: 2026-10-15 09:12:34.567 WARN 1 --- [import_1] i.c.o.zeebeimport.ImportJob : Error while importing Zeebe records`. It is dropped because `Error` with a capital E and lowercase letters is not the same text as `ERROR` in a case-sensitive check.

---

### #6 BILoss Retrieve Files CMX Seven Phrases

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: BILoss-retrieve-files-cmx-prod
k8s.pod.name: (empty)
log.source: /ecs/BILoss-retrieve-files-cmx-prod/app
content: 2026-10-15 09:12:34.567 ERROR RetrieveFilesJob - Failed getCCInformations for batch 20261015-07: com.example.cmx.CmxApiException: timeout after 30000 ms
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` | `lower("BILoss-retrieve-files-cmx-prod")` becomes `biloss-retrieve-files-cmx-prod`, which is exactly equal to the value. |
| `\| filter contains(content, "CC Error", caseSensitive:false)` | This is false, because the line has no `CC Error`. One of the `or` lines below still makes the filter true. |
| `or contains(content, "CmxApiException", caseSensitive:false)` | The line has `CmxApiException`. |
| `or contains(content, "Failed getCCInformations", caseSensitive:false)` | The line also has `Failed getCCInformations`. |
| `if(contains(content, "CmxApiException"), "CmxApiException")` | The exact-case text is present, so the tag is added. |
| `if(contains(content, "Failed getCCInformations"), "Failed getCCInformations")` | The exact-case text is present, so the tag is added. |
| The other five tag lines | `CC Error`, `NetworkException`, `RuntimeException`, `Failed to initialize clients`, and `NullPointerException` are absent, so those tags are removed as nulls. |

**Result row:**

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-15 09:12:34 JST | BILoss-retrieve-files-cmx-prod | ["CmxApiException", "Failed getCCInformations"] | 2026-10-15 09:12:34.567 ERROR RetrieveFilesJob - Failed getCCInformations ... |

**Near miss (would NOT match):** `host.name: BILoss-retrieve-files-cmx-prod-6f7d8c9b5-abc12` with the same content. It is dropped because `==` needs the whole name to be equal, and the extra pod suffix makes it different.

---

### #7 BILoss Retrieve Files CMX Error

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: BILoss-retrieve-files-cmx-prod
k8s.pod.name: (empty)
log.source: /ecs/BILoss-retrieve-files-cmx-prod/app
content: 2026-10-15 09:12:34.567 ERROR CmxFileFetcher - CMX Error: response code 500 while retrieving file list for batch 20261015-07
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` | The lowercased host is exactly `biloss-retrieve-files-cmx-prod`. |
| `\| filter contains(content, "CMX Error")` | The line has `CMX Error` with uppercase `CMX` and capital `E`, which matches the case-sensitive check. |

**Result row:**

| time | host.name | content |
|---|---|---|
| 2026-10-15 09:12:34 JST | BILoss-retrieve-files-cmx-prod | 2026-10-15 09:12:34.567 ERROR CmxFileFetcher - CMX Error: response code 500 ... |

**Near miss (would NOT match):** `content: ... CmxFileFetcher - Cmx Error: response code 500 ...`. It is dropped because `Cmx Error` is not the same case as `CMX Error`, and this `contains` is case-sensitive.

---

### #8 BILoss Processing Three Hosts

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: BILoss-pre-processing-prod
k8s.pod.name: (empty)
log.source: /ecs/BILoss-pre-processing-prod/app
content: 2026-10-15 09:12:34.567 ERROR PreProcessingService - callCamundaProcess error: org.postgresql.util.PSQLException: Connection to db-host:5432 refused
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter in(lower(host.name), array("biloss-processing-prod", "biloss-pre-processing-prod", "biloss-link-data-to-cc-prod"))` | The lowercased host `biloss-pre-processing-prod` is exactly the second value in the list. |
| `or contains(content, "callCamundaProcess error", caseSensitive:false)` | The line has `callCamundaProcess error`. |
| `or contains(content, "PSQLException", caseSensitive:false)` | The line also has `PSQLException`. |
| `if(contains(content, "callCamundaProcess error"), "callCamundaProcess error")` | The exact-case text is present, so the tag is added. |
| `if(contains(content, "Camunda Error"), "Camunda Error")` | This tag is not added. In the line, `Camunda` is followed by `Process`, not by ` Error`. |
| `if(contains(content, "PSQLException"), "PSQLException")` | The exact-case text is present, so the tag is added. |
| The other four tag lines | `CC Error`, `RuntimeException`, `Failed to initialize clients`, and `IllegalArgumentException` are absent, so they are removed. |

**Result row:**

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-15 09:12:34 JST | BILoss-pre-processing-prod | ["callCamundaProcess error", "PSQLException"] | 2026-10-15 09:12:34.567 ERROR PreProcessingService - callCamundaProcess error: ... |

**Near miss (would NOT match):** `host.name: BILoss-pre-processing-stg` with the same content. It is dropped because `biloss-pre-processing-stg` is not one of the three exact names in the list.

---

### #9 BILoss Upload To CMX

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: BILoss-upload-to-cmx-prod
k8s.pod.name: (empty)
log.source: /ecs/BILoss-upload-to-cmx-prod/app
content: 2026-10-15 09:12:34.567 ERROR UploadToCmxJob - java.lang.RuntimeException: Failed to initialize clients (S3 client config not found)
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter lower(host.name) == "biloss-upload-to-cmx-prod"` | The lowercased host is exactly `biloss-upload-to-cmx-prod`. |
| `or contains(content, "RuntimeException", caseSensitive:false)` | The line has `RuntimeException`. |
| `or contains(content, "Failed to initialize clients", caseSensitive:false)` | The line also has `Failed to initialize clients`. |
| `if(contains(content, "RuntimeException"), "RuntimeException")` | The exact-case text is present, so the tag is added. |
| `if(contains(content, "Failed to initialize clients"), "Failed to initialize clients")` | The exact-case text is present, so the tag is added. |
| `if(contains(content, "CMX Error"), "CMX Error")` | `CMX Error` is absent, so this tag is removed. |

**Result row:**

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-15 09:12:34 JST | BILoss-upload-to-cmx-prod | ["RuntimeException", "Failed to initialize clients"] | 2026-10-15 09:12:34.567 ERROR UploadToCmxJob - java.lang.RuntimeException: ... |

**Near miss (would NOT match):** `content: 2026-10-15 09:12:34.567 ERROR UploadToCmxJob - java.lang.IllegalStateException: upload queue is full`. It is dropped because none of the three phrases appear, and the word `ERROR` alone is not one of this query's checks.

---

### #10 Not Shown

There is no sample for #10. The Splunk query was never shown, so no DQL exists to match against.

---

### #11 Error Words Or Access Log Failures

**Sample records that match (one for each half of the filter):**

```
# Record 1: matches the error-word half
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: payment-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/payment-api/app.log
loglevel: ERROR
content: 2026-10-15 09:12:34,567 ERROR [worker-4] Request failed: upstream returned error code 502

# Record 2: matches the access-log half
timestamp: 2026-10-15T09:12:35.101+09:00
host.name: web-front-prod-02
k8s.pod.name: (empty)
log.source: access_combined
loglevel: NONE
content: 10.1.2.3 - - [15/Oct/2026:09:12:35 +0900] "GET /api/orders HTTP/1.1" 503 512 "-" "Mozilla/5.0"
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter matchesPhrase(content, "error")` | Record 1 has `ERROR` and `error` as whole words. `matchesPhrase` ignores case, so either one is enough. |
| `or matchesPhrase(content, "failed")` | Record 1 also has `failed` as a whole word, which is another way to pass. |
| `or matchesPhrase(content, "severe")` | Neither record has `severe`. This line is not needed for either sample. |
| `startsWith(log.source, "access_")` | Record 2 has `log.source` equal to `access_combined`, which begins with `access_`. |
| `and (matchesPhrase(content, "404") or matchesPhrase(content, "500") or matchesPhrase(content, "503"))` | Record 2 has `503` standing alone between spaces, so it counts as a whole word. |

**Result rows:**

| timestamp | host.name | log.source | loglevel | content |
|---|---|---|---|---|
| 2026-10-15T09:12:35.101+09:00 | web-front-prod-02 | access_combined | NONE | 10.1.2.3 - - [15/Oct/2026:09:12:35 +0900] "GET /api/orders HTTP/1.1" 503 512 ... |
| 2026-10-15T09:12:34.567+09:00 | payment-api-prod-01 | /var/log/payment-api/app.log | ERROR | 2026-10-15 09:12:34,567 ERROR [worker-4] Request failed: ... |

**Near miss (would NOT match):** `content: 2026-10-15 09:12:34,567 WARN 3 errors were retried successfully` on `log.source: /var/log/payment-api/app.log`. It is dropped because `matchesPhrase` needs the whole word `error`, and `errors` is a different word. The source is not an access log, so the status-code half cannot help either.

---

### #12 Error Words Or Access Log Failures (Repeat)

Same sample as #11. The DQL is identical, so the same two records match and the same near miss is dropped.

---

### #13 PC2 UI Legacy Claims FAIL

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-40-1-17.ap-northeast-1.compute.internal
k8s.pod.name: pc2-ui-6c8d9f7b5-mn4pq
k8s.container.name: pc2-ui
log.source: /var/log/containers/pc2-ui-6c8d9f7b5-mn4pq_pc2-ui.log
content: 2026-10-15 09:12:34,567 ERROR [ClaimsClient] POST https://esbv4-inssuite-prod.example.internal/esb/legacyclaims/services/legacydata/claims - FAIL (HTTP 500)
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(log.source, "pc2-ui", caseSensitive:false)` | The source path has `pc2-ui` in it. |
| `or contains(k8s.container.name, "pc2-ui", caseSensitive:false)` | The container name is `pc2-ui`, which is another way to pass. |
| `or startsWith(k8s.pod.name, "pc2-ui")` | The pod name begins with `pc2-ui`, which is a third way to pass. |
| `\| filter contains(content, "esbv4-inssuite-prod", caseSensitive:false)` | The URL host `esbv4-inssuite-prod.example.internal` contains this text. |
| `and contains(content, "/esb/legacyclaims/services/legacydata/claims", caseSensitive:false)` | The URL path is exactly `/esb/legacyclaims/services/legacydata/claims`. |
| `\| filter matchesPhrase(content, "FAIL")` | `FAIL` stands alone between spaces, so it counts as a whole word. |

**Result row:**

| timestamp | host.name | k8s.pod.name | log.source | content |
|---|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | ip-10-40-1-17.ap-northeast-1.compute.internal | pc2-ui-6c8d9f7b5-mn4pq | /var/log/containers/pc2-ui-6c8d9f7b5-mn4pq_pc2-ui.log | 2026-10-15 09:12:34,567 ERROR [ClaimsClient] POST https://esbv4-inssuite-prod... - FAIL (HTTP 500) |

**Near miss (would NOT match):** the same line ending with `- FAILED (HTTP 500)`. It is dropped because `matchesPhrase` needs the whole word `FAIL`, and `FAILED` is a different word.

---

### #14 Splunk License Usage Per Day

This query does not filter anything. It measures every log line, so the sample shows normal log records and the size row they add up to.

**Sample records that match (two records in the same group):**

```
# Record 1
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: payment-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/payment-api/app.log
dt.openpipeline.source: oneagent
dt.system.bucket: default_logs
content: INFO Health check OK

# Record 2
timestamp: 2026-10-15T09:15:02.010+09:00
host.name: payment-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/payment-api/app.log
dt.openpipeline.source: oneagent
dt.system.bucket: default_logs
content: WARN Slow response 2300 ms
```

| DQL line | Why this sample passes |
|---|---|
| `fetch logs, from:now()-7d` | Both records are from today, which is inside the 7-day window. |
| `\| fieldsAdd b = stringLength(content)` | Record 1 is 20 characters long. Record 2 is 26 characters long. |
| `s = coalesce(log.source, "(SQUASHED)")` | Both records have a source, so `s` is `/var/log/payment-api/app.log`. |
| `st = coalesce(dt.openpipeline.source, "(SQUASHED)")` | Both records have `oneagent`, so `st` is `oneagent`. |
| `h = coalesce(host.name, "(SQUASHED)")` | Both records have the host `payment-api-prod-01`. |
| `idx = coalesce(dt.system.bucket, "(UNKNOWN)")` | Both records are in the bucket `default_logs`. |
| `\| summarize b = sum(b), by:{ day = bin(timestamp, 1d), s, st, h, idx }` | 09:12 JST is 00:12 UTC on the same date, so both fall in the UTC day 2026-10-15 and land in one group. The sum is 46. |
| `\| fieldsAdd gb = round(toDouble(b) / 1073741824, decimals:3)` | 46 divided by 1073741824 is far below 0.001, so it rounds to 0. Real hosts produce millions of lines, which is when this column shows non-zero values. |

**Result row:**

| day | s | st | h | idx | b | gb |
|---|---|---|---|---|---|---|
| 2026-10-15T00:00:00Z | /var/log/payment-api/app.log | oneagent | payment-api-prod-01 | default_logs | 46 | 0 |

**Near miss (would NOT match):** a record with `timestamp: 2026-10-07T09:12:34.567+09:00`. It is dropped because it is more than 7 days old, so `fetch logs, from:now()-7d` never reads it.

---

### #15 Mailservice Authentication Failure

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: mailservice-prod-01
k8s.pod.name: (empty)
log.source: /opt/tomcat/logs/catalina.out
content: 2026-10-15 09:12:34,567 ERROR [MailSender-2] javax.mail.AuthenticationFailedException: 535 5.7.8 Authentication credentials invalid
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(host.name, "mailservice", caseSensitive:false)` | The host `mailservice-prod-01` contains `mailservice`. |
| `or contains(k8s.namespace.name, "mailservice", caseSensitive:false)` | This sample has no namespace. That is fine, because the host check already passed. |
| `or contains(dt.system.bucket, "mailservice", caseSensitive:false)` | Not needed for this sample, for the same reason. |
| `\| filter contains(content, "AuthenticationFailedException", caseSensitive:false)` | The class name `javax.mail.AuthenticationFailedException` contains the exact text. |

**Result row:**

| timestamp | host.name | log.source | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | mailservice-prod-01 | /opt/tomcat/logs/catalina.out | 2026-10-15 09:12:34,567 ERROR [MailSender-2] javax.mail.AuthenticationFailedException: 535 ... |

**Near miss (would NOT match):** `content: 2026-10-15 09:12:34,567 ERROR [MailSender-2] SMTP authentication failed for relay`. It is dropped because the text `AuthenticationFailedException` never appears, even though the meaning is similar.

---

### #16 Mailservice Tomcat Startup

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: mailservice-prod-01
k8s.pod.name: (empty)
log.source: /opt/tomcat/logs/catalina.out
content: 15-Oct-2026 09:12:34.567 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [12345] milliseconds
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(host.name, "mailservice", caseSensitive:false)` | The host `mailservice-prod-01` contains `mailservice`. |
| `\| filter matchesPhrase(content, "Catalina.start Server startup")` | The words `Catalina`, `start`, `Server`, and `startup` appear in this exact order, joined by the same dot and spaces. `matchesPhrase` ignores case. |

**Result row:**

| timestamp | host.name | log.source | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | mailservice-prod-01 | /opt/tomcat/logs/catalina.out | 15-Oct-2026 09:12:34.567 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in [12345] milliseconds |

**Near miss (would NOT match):** `content: Server startup in [12345] milliseconds` where the parser moved `org.apache.catalina.startup.Catalina.start` into a separate logger attribute. It is dropped because the `Catalina.start` part of the phrase is no longer in `content`.

---

### #17 Throughput Top Five Sources

This query does not filter. It counts every log line from the last hour per source, so the sample shows log records and the series they produce.

**Sample records that match (three records from one source):**

```
# Record 1
timestamp: 2026-10-15T09:12:05.100+09:00
host.name: payment-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/payment-api/app.log
content: 2026-10-15 09:12:05,100 INFO [worker-1] Order 20261015-000123 accepted

# Record 2
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: payment-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/payment-api/app.log
content: 2026-10-15 09:12:34,567 INFO [worker-2] Order 20261015-000124 accepted

# Record 3
timestamp: 2026-10-15T09:13:10.900+09:00
host.name: payment-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/payment-api/app.log
content: 2026-10-15 09:13:10,900 INFO [worker-1] Order 20261015-000125 accepted
```

| DQL line | Why this sample passes |
|---|---|
| `fetch logs, from:now()-1h` | All three records are from the last hour. |
| `\| makeTimeseries events = count(), by:{ log.source }, interval:1m` | All three share the source `/var/log/payment-api/app.log`, so they go into one series. The 09:12 slot gets 2 and the 09:13 slot gets 1. |
| `\| fieldsAdd total = arraySum(events)` | Adding the slots gives 3 for this source, assuming no other lines in the hour. |
| `\| sort total desc` | The row is ranked against the other sources by `total`. |
| `\| limit 5` | The row is kept only if this source is one of the five busiest. |

**Result row:**

| log.source | events (one value per minute) | total |
|---|---|---|
| /var/log/payment-api/app.log | [0, ..., 0, 2, 1, 0, ..., 0] | 3 |

The real output also has `timeframe` and `interval` columns, which `makeTimeseries` adds on its own.

**Near miss (would NOT match):** a record from the same source with `timestamp: 2026-10-15T07:50:00.000+09:00` when the query runs at 09:12. It is dropped because it is older than one hour, so it is not counted in any slot.

---

### #18 Silent Production Hosts

Assume the query runs at `now() = 2026-10-15T09:12:34+09:00`.

**Sample records that match (two records from a host that went quiet):**

```
# Record 1
timestamp: 2026-10-14T22:30:00.000+09:00
host.name: order-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/order-api/app.log
content: 2026-10-14 22:30:00,000 INFO [main] Nightly reconciliation started

# Record 2 (the last line this host ever sent)
timestamp: 2026-10-15T07:00:00.000+09:00
host.name: order-api-prod-01
k8s.pod.name: (empty)
log.source: /var/log/order-api/app.log
content: 2026-10-15 07:00:00,000 INFO [main] Heartbeat OK
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(host.name, "-prod-") and not contains(host.name, "amazonaws")` | The host `order-api-prod-01` contains `-prod-` and does not contain `amazonaws`. |
| `\| summarize count = count(), first_event = min(timestamp), last_event = max(timestamp), by:{ host.name }` | The host gets count 2. Its first event is 2026-10-14 22:30 JST and its last event is 2026-10-15 07:00 JST. |
| `\| fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000` | From 07:00:00 to 09:12:34 is 2 hours, 12 minutes, and 34 seconds, which is 7954 seconds. |
| `\| filter last_seen_sec > 3600` | 7954 is more than 3600, so the host is kept as silent. |
| `minutes_behind = round(toDouble(last_seen_sec) / 60, decimals:0)` | 7954 divided by 60 is 132.57, which rounds to 133. |
| `hours_behind = round(toDouble(last_seen_sec) / 3600, decimals:1)` | 7954 divided by 3600 is 2.209, which rounds to 2.2. |
| `days_behind = round(toDouble(last_seen_sec) / 86400, decimals:1)` | 7954 divided by 86400 is 0.092, which rounds to 0.1. |
| `last_event_jst = formatTimestamp(last_event, format:"EEE MMM dd HH:mm:ss yyyy", timezone:"Asia/Tokyo")` | The last event becomes the text `Thu Oct 15 07:00:00 2026`. |

**Result row:**

| host.name | last_event_jst | minutes_behind | hours_behind | days_behind |
|---|---|---|---|---|
| order-api-prod-01 | Thu Oct 15 07:00:00 2026 | 133 | 2.2 | 0.1 |

**Near miss (would NOT match):** `host.name: ec2-prod-node.ap-northeast-1.compute.amazonaws.com` with its last line at 07:00. It is dropped because the name contains `amazonaws`, and the `not contains` check removes it before counting.

---

### #19 ESBv4 NetSuite HTTP Error

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-50-2-33.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-inssuite-prod-5f6d7c8b9-p9q8r
log.source: /var/log/containers/esbv4-inssuite-prod-5f6d7c8b9-p9q8r_esbv4.log
content: 2026-10-15 09:12:34,567 ERROR [http-outbound-3] HttpRequester - Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443/app/site/hosting/restlet.nl. Message: Connection timed out
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(host.name, "esbv4", caseSensitive:false)` | This is false for the node host name. The pod check below passes instead. |
| `or contains(k8s.pod.name, "esbv4", caseSensitive:false)` | The pod name begins with `esbv4`. |
| `\| filter contains(content, "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443", caseSensitive:false)` | The line has this whole phrase, including the account number `3903926` and the port `:443`. Extra text after the port is fine for `contains`. |

**Result row:**

| timestamp | host.name | k8s.pod.name | log.source | content |
|---|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | ip-10-50-2-33.ap-northeast-1.compute.internal | esbv4-inssuite-prod-5f6d7c8b9-p9q8r | /var/log/containers/esbv4-inssuite-prod-5f6d7c8b9-p9q8r_esbv4.log | 2026-10-15 09:12:34,567 ERROR [http-outbound-3] HttpRequester - Error sending HTTP request to https://3903926... |

**Near miss (would NOT match):** `content: ... Error sending HTTP request to https://3903926.restlets.api.netsuite.com/app/site/hosting/restlet.nl ...`. It is dropped because `:443` is missing, so the long phrase is not in the line.

---

### #20 Portals AMP Distinct Accounts Per Day

Note: this query returns 0 rows today, because portals-amp logs are not in Dynatrace yet. The samples show what will match after onboarding.

**Sample records that match (three records, two different accounts):**

```
# Record 1
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-60-1-12.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-frontend-7d9c6b5f4-xk2lp
k8s.container.name: portals-amp-frontend
log.source: /var/log/containers/portals-amp-frontend-7d9c6b5f4-xk2lp_portals-amp-frontend.log
content: {\"level\":\"info\",\"message\":{\"account_number\":\"A12345678 PREMIUM\",\"url\":\"https://portals-amp-frontend.example.internal/policy/list\"}}

# Record 2 (same account, later the same day)
timestamp: 2026-10-15T10:40:02.118+09:00
host.name: ip-10-60-1-12.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-frontend-7d9c6b5f4-xk2lp
k8s.container.name: portals-amp-frontend
log.source: /var/log/containers/portals-amp-frontend-7d9c6b5f4-xk2lp_portals-amp-frontend.log
content: {\"level\":\"info\",\"message\":{\"account_number\":\"A12345678 PREMIUM\",\"url\":\"https://portals-amp-frontend.example.internal/policy/detail\"}}

# Record 3 (different account)
timestamp: 2026-10-15T11:05:47.300+09:00
host.name: ip-10-60-1-13.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-frontend-7d9c6b5f4-pq9rs
k8s.container.name: portals-amp-frontend
log.source: /var/log/containers/portals-amp-frontend-7d9c6b5f4-pq9rs_portals-amp-frontend.log
content: {\"level\":\"info\",\"message\":{\"account_number\":\"B98765432 STANDARD\",\"url\":\"https://portals-amp-frontend.example.internal/policy/list\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(k8s.container.name, "portals-amp-frontend") or contains(k8s.pod.name, "portals-amp-frontend") or contains(log.source, "portals-amp-frontend")` | The container name is exactly `portals-amp-frontend` in lowercase, which passes the case-sensitive check. The pod and source also contain it. |
| `\| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | The inner call turns every `\"` into a plain `"`. The outer call removes any backslash left over. Record 1 becomes `{"level":"info","message":{"account_number":"A12345678 PREMIUM",...}}`, which is clean JSON. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into the field `j`. |
| `\| fieldsAdd acct = toString(j[message][account_number])` | Record 1 and record 2 get `A12345678 PREMIUM`. Record 3 gets `B98765432 STANDARD`. |
| `\| filter isNotNull(acct) and contains(acct, " ")` | All three values exist and all three have a space before the plan name. |
| `\| fieldsAdd accountNo = substring(acct, from:0, to:indexOf(acct, " "))` | The text before the first space is kept. That gives `A12345678`, `A12345678`, and `B98765432`. |
| `\| summarize count = countDistinctExact(accountNo), by:{ day = bin(timestamp, 1d) }` | All three times are on the UTC day 2026-10-15. There are two different account numbers, so the count is 2. |
| `\| fieldsAdd date = formatTimestamp(day, format:"yyyy-MM-dd", timezone:"Asia/Tokyo")` | The UTC midnight of the day is 09:00 JST on the same date, so the label is `2026-10-15`. |

**Result row:**

| date | count |
|---|---|
| 2026-10-15 | 2 |

**Near miss (would NOT match):** `content: {\"level\":\"info\",\"message\":{\"account_number\":\"C11112222\",\"url\":\"...\"}}`. It is dropped because the account value has no space, so `contains(acct, " ")` is false.

---

### #21 PC UI CPU Percent Of Limit

This query reads metrics, not logs. The sample shows metric data points for one pod instead of a log line.

**Sample data points that match:**

```
# Metric: dt.kubernetes.container.cpu_usage (millicores)
timestamp: 2026-10-15T09:12:00.000+09:00
host.name: ip-10-70-1-21.ap-northeast-1.compute.internal
k8s.pod.name: pc-ui-5b7c9d8f6-abcde
k8s.workload.name: pc-ui
values over 24h (simplified to 3 points): 210, 250, 230

# Metric: dt.kubernetes.container.limits_cpu (millicores)
timestamp: 2026-10-15T09:12:00.000+09:00
host.name: ip-10-70-1-21.ap-northeast-1.compute.internal
k8s.pod.name: pc-ui-5b7c9d8f6-abcde
k8s.workload.name: pc-ui
values over 24h (simplified to 3 points): 1000, 1000, 1000
```

| DQL line | Why this sample passes |
|---|---|
| `timeseries { usage = avg(dt.kubernetes.container.cpu_usage), cpu_limit = avg(dt.kubernetes.container.limits_cpu) },` | The pod reports both metrics, so `usage` becomes `[210, 250, 230]` and `cpu_limit` becomes `[1000, 1000, 1000]`. |
| `by:{ k8s.pod.name },` | Both metrics carry the pod name `pc-ui-5b7c9d8f6-abcde`, so they line up in one row. |
| `filter: k8s.workload.name == "pc-ui",` | The workload name is exactly `pc-ui`. |
| `\| fieldsAdd percent = round(arrayAvg(usage) / arrayAvg(cpu_limit) * 100, decimals:2)` | The average usage is 230 and the average limit is 1000. 230 divided by 1000, times 100, is 23. |

**Result row:**

| k8s.pod.name | percent |
|---|---|
| pc-ui-5b7c9d8f6-abcde | 23 |

**Near miss (would NOT match):** the same data points with `k8s.workload.name: pc-ui-v2`. It is dropped because `==` needs the workload name to be exactly `pc-ui`.

---

### #22 ESBv4 License Expiring Soon

Assume the query runs on 2026-10-15, so `now() + 100d` is 2027-01-23.

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-50-2-33.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-inssuite-prod-5f6d7c8b9-p9q8r
log.source: /var/log/containers/esbv4-inssuite-prod-5f6d7c8b9-p9q8r_esbv4.log
content: 2026-10-15 09:12:34,567 INFO [LicenseCheck] Valid license key --> Evaluation = false, Expiration Date = Mon Dec 14 23:59:59 JST 2026
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(host.name, "esbv4", ...) or contains(k8s.namespace.name, ...) or contains(k8s.pod.name, ...)` | The pod name contains `esbv4`. |
| `\| filter contains(content, "Valid license key --> Evaluation = false, Expiration Date = ")` | The line has this exact text, with the same case, arrow, and spacing. |
| `\| fieldsAdd expiration_date = trim(substring(content, from:indexOf(content, "Expiration Date = ") + 18))` | `Expiration Date = ` is 18 characters, so the cut starts at `Mon`. The result is `Mon Dec 14 23:59:59 JST 2026`. The line ends at the year, so nothing extra is picked up. |
| `\| fieldsAdd exp_clean = replaceString(expiration_date, " JST ", " ")` | Removing ` JST ` gives `Mon Dec 14 23:59:59 2026`. |
| `\| parse exp_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):exp_as_utc"` | The text fits the pattern exactly, so `exp_as_utc` becomes 2026-12-14T23:59:59Z. |
| `\| fieldsAdd expiration_epoch = exp_as_utc - 9h` | Taking away 9 hours gives 2026-12-14T14:59:59Z, which is 23:59:59 in Japan time. |
| `\| filter expiration_epoch < now() + 100d` | December 14, 2026 is 60 days away, which is less than 100 days. |

**Result row:**

| timestamp | host.name | expiration_date | expiration_epoch | content |
|---|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | ip-10-50-2-33.ap-northeast-1.compute.internal | Mon Dec 14 23:59:59 JST 2026 | 2026-12-14T14:59:59Z | 2026-10-15 09:12:34,567 INFO [LicenseCheck] Valid license key --> ... |

**Near miss (would NOT match):** the same line ending with `Expiration Date = Wed Jun 30 23:59:59 JST 2027`. It is dropped because June 30, 2027 is more than 100 days away, so the final filter removes it.

---

### #23 AMP Backend doCancel Backend Exception

Note: this query returns 0 rows today, because portals-amp logs are not in Dynatrace yet. The sample shows what will match after onboarding.

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-60-2-21.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6b8d7c9f5-lm3no
k8s.container.name: portals-amp-backend
log.source: /var/log/containers/portals-amp-backend-6b8d7c9f5-lm3no_portals-amp-backend.log
content: {\"level\":\"error\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/doCancel\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\",\"request_id\":\"3f2b9c1e-7a4d-4e8b-9c21-5d6e7f8a9b0c\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, "portals-amp-backend") or contains(log.source, "portals-amp-backend")` | The container name is exactly `portals-amp-backend` in lowercase. |
| `\| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | The inner call turns each `\"` into `"`. The outer call removes leftover backslashes. The result is clean JSON like `{"level":"error","message":{"url":"https://...","type":"CAUGHT_EXCEPTION_ON_BACKEND",...}}`. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into `j`. |
| `\| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])` | `msg_url` becomes the full URL ending in `/api/doCancel`. `msg_type` becomes `CAUGHT_EXCEPTION_ON_BACKEND`. |
| `\| filter contains(msg_url, "doCancel") and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` | The full URL contains `doCancel`, and the type is exactly `CAUGHT_EXCEPTION_ON_BACKEND`. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | https://portals-amp-backend.example.internal/api/doCancel | CAUGHT_EXCEPTION_ON_BACKEND | {"level":"error","message":{"url":"https://portals-amp-backend.example.internal/api/doCancel",...}} |

**Near miss (would NOT match):** the same content with `\"type\":\"EXECUTION_COMPLETED\"`. It is dropped because `msg_type ==` needs exactly `CAUGHT_EXCEPTION_ON_BACKEND`. That record belongs to #24 instead.

---

### #24 AMP Backend doCancel Completed

Note: this query returns 0 rows today, because portals-amp logs are not in Dynatrace yet. The sample shows what will match after onboarding.

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-60-2-21.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6b8d7c9f5-lm3no
k8s.container.name: portals-amp-backend
log.source: /var/log/containers/portals-amp-backend-6b8d7c9f5-lm3no_portals-amp-backend.log
content: {\"level\":\"info\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/doCancel\",\"type\":\"EXECUTION_COMPLETED\",\"request_id\":\"8c1d2e3f-4a5b-4c6d-8e7f-9a0b1c2d3e4f\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(k8s.container.name, "portals-amp-backend") or ...` | The container name is exactly `portals-amp-backend`. |
| `\| fieldsAdd raw = replaceString(...)` | The escaped quotes are turned back into plain quotes, the same as #23, so the text becomes clean JSON. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into `j`. |
| `\| fieldsAdd msg_url = ..., msg_type = ...` | `msg_url` is the full doCancel URL and `msg_type` is `EXECUTION_COMPLETED`. |
| `\| filter contains(msg_url, "doCancel") and msg_type == "EXECUTION_COMPLETED"` | The URL contains `doCancel`, and the type is exactly `EXECUTION_COMPLETED`. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | https://portals-amp-backend.example.internal/api/doCancel | EXECUTION_COMPLETED | {"level":"info","message":{"url":"https://portals-amp-backend.example.internal/api/doCancel",...}} |

**Near miss (would NOT match):** the same content with `\"type\":\"execution_completed\"` in lowercase. It is dropped because `==` is an exact compare, and the lowercase value is a different string.

---

### #25 AMP Backend doesRefundExist Completed

Note: this query returns 0 rows today, because portals-amp logs are not in Dynatrace yet. The sample shows what will match after onboarding.

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-60-2-21.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6b8d7c9f5-lm3no
k8s.container.name: portals-amp-backend
log.source: /var/log/containers/portals-amp-backend-6b8d7c9f5-lm3no_portals-amp-backend.log
content: {\"level\":\"info\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/doesRefundExist\",\"type\":\"EXECUTION_COMPLETED\",\"request_id\":\"a7b8c9d0-1e2f-4a3b-8c4d-5e6f7a8b9c0d\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(k8s.container.name, "portals-amp-backend") or ...` | The container name is exactly `portals-amp-backend`. |
| `\| fieldsAdd raw = replaceString(...)` | The escaped JSON is cleaned the same way as #23. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into `j`. |
| `\| fieldsAdd msg_url = ..., msg_type = ...` | `msg_url` ends in `/api/doesRefundExist` and `msg_type` is `EXECUTION_COMPLETED`. |
| `\| filter contains(msg_url, "doesRefundExist") and msg_type == "EXECUTION_COMPLETED"` | The URL contains `doesRefundExist` with the same case, and the type is exactly `EXECUTION_COMPLETED`. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | https://portals-amp-backend.example.internal/api/doesRefundExist | EXECUTION_COMPLETED | {"level":"info","message":{"url":"https://portals-amp-backend.example.internal/api/doesRefundExist",...}} |

**Near miss (would NOT match):** the same content with the URL ending in `/api/doesrefundexist`. It is dropped because `contains(msg_url, "doesRefundExist")` is case-sensitive, and the lowercase `r` and `e` do not match.

---

### #26 AMP Backend isPolicyCancelAvailable Completed One Week

Note: this query returns 0 rows today, because portals-amp logs are not in Dynatrace yet. The sample shows what will match after onboarding.

**Sample record that matches:**

```
timestamp: 2026-10-12T14:05:10.250+09:00
host.name: ip-10-60-2-21.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6b8d7c9f5-lm3no
k8s.container.name: portals-amp-backend
log.source: /var/log/containers/portals-amp-backend-6b8d7c9f5-lm3no_portals-amp-backend.log
content: {\"level\":\"info\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/isPolicyCancelAvailable\",\"type\":\"EXECUTION_COMPLETED\",\"request_id\":\"5d6e7f80-91a2-4b3c-8d4e-f5a6b7c8d9e0\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `fetch logs, from:now()-7d` | The record is from 3 days ago, which is inside the one-week window. |
| `\| filter contains(k8s.container.name, "portals-amp-backend") or ...` | The container name is exactly `portals-amp-backend`. |
| `\| fieldsAdd raw = replaceString(...)` | The escaped JSON is cleaned the same way as #23. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into `j`. |
| `\| fieldsAdd msg_url = ..., msg_type = ...` | `msg_url` ends in `/api/isPolicyCancelAvailable` and `msg_type` is `EXECUTION_COMPLETED`. |
| `\| filter contains(msg_url, "isPolicyCancelAvailable") and msg_type == "EXECUTION_COMPLETED"` | The URL contains `isPolicyCancelAvailable` with the same case, and the type is exact. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-12T14:05:10.250+09:00 | https://portals-amp-backend.example.internal/api/isPolicyCancelAvailable | EXECUTION_COMPLETED | {"level":"info","message":{"url":"https://portals-amp-backend.example.internal/api/isPolicyCancelAvailable",...}} |

**Near miss (would NOT match):** the same record with `timestamp: 2026-10-07T14:05:10.250+09:00`. It is dropped because it is 8 days old, which is outside `from:now()-7d`.

---

### #27 AMP Backend isPolicyCancelAvailable Completed One Day

Note: this query returns 0 rows today, because portals-amp logs are not in Dynatrace yet. The sample shows what will match after onboarding.

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-60-2-21.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6b8d7c9f5-lm3no
k8s.container.name: portals-amp-backend
log.source: /var/log/containers/portals-amp-backend-6b8d7c9f5-lm3no_portals-amp-backend.log
content: {\"level\":\"info\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/isPolicyCancelAvailable\",\"type\":\"EXECUTION_COMPLETED\",\"request_id\":\"0f1e2d3c-4b5a-4968-8778-695a4b3c2d1e\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `fetch logs, from:now()-1d` | The record is from today, which is inside the one-day window. |
| `\| filter contains(k8s.container.name, "portals-amp-backend") or ...` | The container name is exactly `portals-amp-backend`. |
| `\| fieldsAdd raw = replaceString(...)` | The escaped JSON is cleaned the same way as #23. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into `j`. |
| `\| fieldsAdd msg_url = ..., msg_type = ...` | `msg_url` ends in `/api/isPolicyCancelAvailable` and `msg_type` is `EXECUTION_COMPLETED`. |
| `\| filter contains(msg_url, "isPolicyCancelAvailable") and msg_type == "EXECUTION_COMPLETED"` | The URL contains the method name with the same case, and the type is exact. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | https://portals-amp-backend.example.internal/api/isPolicyCancelAvailable | EXECUTION_COMPLETED | {"level":"info","message":{"url":"https://portals-amp-backend.example.internal/api/isPolicyCancelAvailable",...}} |

**Near miss (would NOT match):** the #26 sample record from `2026-10-12T14:05:10.250+09:00`. It is dropped here because it is 3 days old, which is outside `from:now()-1d`, even though #26 shows it.

---

### #28 Claim Customer applySimplePayment Errors

Note: this query returns 0 rows today, because the portals logs are not in Dynatrace yet. The sample shows what will match after onboarding.

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-60-3-31.ap-northeast-1.compute.internal
k8s.pod.name: portals-claim-customer-backend-8f7e6d5c4-rs7tu
k8s.container.name: portals-claim-customer-backend
log.source: /var/log/containers/portals-claim-customer-backend-8f7e6d5c4-rs7tu_portals-claim-customer-backend.log
content: {\"level\":\"ERROR\",\"message\":{\"url\":\"https://portals-api-gateway.example.internal/customer/exposure/applySimplePayment\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\",\"request_id\":\"b1c2d3e4-f5a6-4b7c-8d9e-0f1a2b3c4d5e\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(k8s.container.name, "portals-claim-customer-frontend") or ...` | This first group is false, because this record is from the backend. The `or` line below allows it. |
| `or contains(k8s.container.name, "portals-claim-customer-backend") or ...` | The container name is exactly `portals-claim-customer-backend`. |
| `\| fieldsAdd raw = replaceString(...)` | The escaped quotes become plain quotes and leftover backslashes are removed, so the text becomes clean JSON. |
| `\| parse raw, "JSON:j"` | The clean JSON is read into `j`. |
| `\| fieldsAdd level = toString(j[level]), msg_url = toString(j[message][url])` | `level` becomes `ERROR`. `msg_url` becomes the full gateway URL. |
| `\| filter lower(level) == "error" and contains(msg_url, "/customer/exposure/applySimplePayment")` | `lower("ERROR")` is `error`, so the level check passes. The full URL contains the exact path `/customer/exposure/applySimplePayment`. |

**Result row:**

| timestamp | k8s.pod.name | level | msg_url | raw |
|---|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | portals-claim-customer-backend-8f7e6d5c4-rs7tu | ERROR | https://portals-api-gateway.example.internal/customer/exposure/applySimplePayment | {"level":"ERROR","message":{"url":"https://portals-api-gateway.example.internal/customer/exposure/applySimplePayment",...}} |

**Near miss (would NOT match):** the same content with `\"level\":\"warn\"`. It is dropped because `lower("warn")` is `warn`, which is not `error`.

---

### #29 Inssuite BadInputException ContactName

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: pc-api-inssuite-prod-03
k8s.pod.name: (empty)
log.source: /opt/guidewire/logs/pc-api.log
content: 2026-10-15 09:12:34,567 ERROR [RestHandler-12] gw.api.rest.exceptions.BadInputException: ContactName: <JP_TEXT>
```

Replace `<JP_TEXT>` with the real Japanese message once it is known. It was unreadable in the source screenshot, and the current DQL does not check it.

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(host.name, "-inssuite-prod-", caseSensitive:false) or contains(k8s.pod.name, ...)` | The host `pc-api-inssuite-prod-03` contains `-inssuite-prod-`, including the dash on both sides. |
| `\| filter contains(content, "gw.api.rest.exceptions.BadInputException: ContactName:", caseSensitive:false)` | The line has the exact class name followed by `: ContactName:`, including both colons. |

**Result row:**

| timestamp | host.name | k8s.pod.name | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | pc-api-inssuite-prod-03 | (empty) | 2026-10-15 09:12:34,567 ERROR [RestHandler-12] gw.api.rest.exceptions.BadInputException: ContactName: <JP_TEXT> |

**Near miss (would NOT match):** `host.name: inssuite-prod-db01` with the same content. It is dropped because the name starts with `inssuite-prod-` and has no dash before `inssuite`, so it does not contain `-inssuite-prod-`.

---

### #30 PC2 UI Metaspace Exhausted

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-40-1-17.ap-northeast-1.compute.internal
k8s.pod.name: pc2-ui-6c8d9f7b5-mn4pq
k8s.container.name: pc2-ui
log.source: /var/log/containers/pc2-ui-6c8d9f7b5-mn4pq_pc2-ui.log
content: [2026-10-15T09:12:34.567+0900] JVMDUMP039I Processing dump event "systhrow", detail "java/lang/OutOfMemoryError" - Posting Resource Exhausted event: Metaspace
```

| DQL line | Why this sample passes |
|---|---|
| `\| filter contains(k8s.container.name, "pc2-ui") or contains(k8s.pod.name, "pc2-ui") or contains(log.source, "pc2-ui")` | The container name is exactly `pc2-ui` in lowercase, which passes the case-sensitive check. The pod and source also contain it. |
| `\| filter contains(content, "Posting Resource Exhausted event: Metaspace", caseSensitive:false)` | The line has this exact phrase, including the colon before `Metaspace`. |

**Result row:**

| timestamp | host.name | k8s.pod.name | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | ip-10-40-1-17.ap-northeast-1.compute.internal | pc2-ui-6c8d9f7b5-mn4pq | [2026-10-15T09:12:34.567+0900] JVMDUMP039I Processing dump event ... Posting Resource Exhausted event: Metaspace |

**Near miss (would NOT match):** a record with `k8s.container.name: PC2-UI`, `log.source: /var/log/PC2-UI/app.log`, an empty pod name, and the same content. It is dropped because all three name checks are case-sensitive, and `PC2-UI` in capitals does not contain `pc2-ui`.


---

## Part 2: Match Examples For DQL 31 to 60

This part gives one fake but realistic log record for each DQL query from #31 to #60, and shows line by line why that record passes every filter. Each entry also shows the output row you would see, and one "near miss" record that looks similar but gets dropped, so you can see exactly where the filter draws the line.

---

### #31 Alfrescoacr Failed To Get Lock

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.namespace.name: alfresco
k8s.pod.name: alfrescoacr-6d8f7b9c4-q7wzt
log.source: /var/log/containers/alfrescoacr-6d8f7b9c4-q7wzt_alfresco_repo.log
content: 2026-10-15 09:12:34,567 WARN [org.alfresco.repo.lock.JobLockServiceImpl] [DefaultScheduler_Worker-4] Failed to get lock 'ContentStoreCleaner' after 3 retries
```

| DQL line | Why this sample passes |
|---|---|
| `filter contains(host.name, "alfrescoacr", caseSensitive:false) or ... contains(k8s.pod.name, "alfrescoacr", caseSensitive:false) or ...` | The pod name `alfrescoacr-6d8f7b9c4-q7wzt` contains `alfrescoacr`. Only one of the four checks needs to be true, so this is enough. |
| `filter contains(content, "Failed to get lock", caseSensitive:false)` | The content contains the exact text `Failed to get lock`. |

**Result row:**

| timestamp | host.name | k8s.pod.name | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | ip-10-20-31-45.ap-northeast-1.compute.internal | alfrescoacr-6d8f7b9c4-q7wzt | 2026-10-15 09:12:34,567 WARN ... Failed to get lock 'ContentStoreCleaner' after 3 retries |

**Near miss (would NOT match):** `content: ... Failed to acquire lock 'ContentStoreCleaner' after 3 retries` from the same pod. It is dropped because the text says `acquire` instead of `get`, so the substring `Failed to get lock` is not present.

---

### #32 Network Errors Counted Per App

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.namespace.name: bc2
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-7] GmoClient - Read timeout after 30000 ms calling payment gateway
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | The pod name is not empty, so `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter matchesValue(src, array(... "bc2-ui*", ...))` | `src` begins with `bc2-ui`, so it matches the pattern `bc2-ui*` in the list. |
| `filter matchesPhrase(content, "SSL") or ... "timeout" or ... "socket" or ... "connect"` | The content has the whole word `timeout` (it is surrounded by spaces). One of the four words is enough. |
| `summarize record_count = count(), by:{ index = coalesce(k8s.namespace.name, k8s.workload.name, src) }` | The namespace is `bc2`, so this record is counted in the group `index = bc2`. |

**Result row:** this query counts, so here are three matching records and the rows they produce.

| Record | k8s.namespace.name | k8s.pod.name | Matching word in content |
|---|---|---|---|
| 1 | bc2 | bc2-ui-7f9c6d-x2kqp | `Read timeout after 30000 ms` |
| 2 | bc2 | bc2-batch-5c8d7f-m4tzr | `SSL handshake failed with peer` |
| 3 | esb | esb-6b9f8c-k2wpd | `Unable to connect to backend 10.20.40.12:8443` |

| index | record_count |
|---|---|
| bc2 | 2 |
| esb | 1 |

**Near miss (would NOT match):** `content: ... Connection reset by peer` from `bc2-ui-7f9c6d-x2kqp`. It is dropped because `Connection` is not the whole word `connect`, and none of `SSL`, `timeout`, or `socket` appear.

---

### #33 PC2 Batch Cancellation Waiting For Midnight

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-21.ap-northeast-1.compute.internal
k8s.pod.name: pc2-batch-84d6c7b5f-r9lqv
log.source: /var/log/containers/pc2-batch-84d6c7b5f-r9lqv_pc2_batch.log
content: 2026-10-15 09:12:34,567 INFO [WorkQueue-2] Workflow step bcCancellationFinished_Adj is in state WaitForMidNight for policy PC-000481
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `pc2-batch-84d6c7b5f-r9lqv`. |
| `filter startsWith(src, "pc2-batch")` | `src` begins with `pc2-batch`. |
| `filter matchesPhrase(content, "bcCancellationFinished_Adj") and ...` | The content has `bcCancellationFinished_Adj` with a space on each side, so it is a whole phrase. |
| `... and matchesPhrase(content, "WaitForMidNight")` | The same line also has `WaitForMidNight` as a whole word. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | pc2-batch-84d6c7b5f-r9lqv | ... Workflow step bcCancellationFinished_Adj is in state WaitForMidNight for policy PC-000481 |

**Near miss (would NOT match):** `content: ... Workflow step bcCancellationFinished_Adj completed for policy PC-000481` from the same pod. It is dropped because the second word `WaitForMidNight` is missing from that line.

---

### #34 BC2 GMO SEARCHTRADE Exception

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-3] GmoClient - Exception during GMO call SEARCHTRADE:<JP_TEXT> OrderID=ORD-20261015-0091
```

Replace `<JP_TEXT>` with the real Japanese message when you have it. The DQL does not check it, so the sample matches either way.

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter startsWith(src, "bc2")` | `src` begins with `bc2`. |
| `filter contains(content, "Exception during GMO call SEARCHTRADE", caseSensitive:false)` | The content has the exact text `Exception during GMO call SEARCHTRADE`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-ui-7f9c6d-x2kqp | ... Exception during GMO call SEARCHTRADE:<JP_TEXT> OrderID=ORD-20261015-0091 |

**Near miss (would NOT match):** the same content from pod `pc2-ui-6c7d8e-h3nvb`. It is dropped because `src` begins with `pc2`, not `bc2`.

---

### #35 BC2 Batch DirectDebit PaymentDueDate Mismatch

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-15 09:12:34,567 WARN Server.BatchProcess.DirectDebitBatchProcess - Record with ID DD-000917 has different PaymentDueDate value 2026-10-27 than previous rows
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2-batch")` | `src` begins with `bc2-batch`. |
| `filter contains(content, "Server.BatchProcess.DirectDebitBatchProcess", caseSensitive:false)` | The logger name `Server.BatchProcess.DirectDebitBatchProcess` is in the content. |
| `filter contains(content, "Record with ID ", caseSensitive:false)` | The content has `Record with ID ` including the trailing space before `DD-000917`. |
| `and contains(content, " has different PaymentDueDate value ", caseSensitive:false)` | The content has ` has different PaymentDueDate value ` with a space on each side. |
| `and contains(content, " than previous rows", caseSensitive:false)` | The content ends with ` than previous rows`, including the leading space. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-batch-5c8d7f-m4tzr | ... Record with ID DD-000917 has different PaymentDueDate value 2026-10-27 than previous rows |

**Near miss (would NOT match):** `content: ... DirectDebitBatchProcess - Record with ID DD-000917 has a different PaymentDueDate value 2026-10-27 than previous rows`. It is dropped because the extra word `a` breaks the exact piece ` has different PaymentDueDate value `.

---

### #36 BC2 Concurrent Data Change In Delinquency Process

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-15 09:12:34,567 ERROR [PolicyDlnqProcess:bc] com.guidewire.pl.system.exception.ConcurrentDataChangeException: Bean PolicyPeriod:2048 was changed by another user
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2-")` | `src` begins with `bc2-` including the dash. |
| `filter contains(content, "com.guidewire.pl.system.exception.ConcurrentDataChangeException", caseSensitive:false)` | The full exception class name is in the content. |
| `and contains(content, "PolicyDlnqProcess:bc", caseSensitive:false)` | The thread label `[PolicyDlnqProcess:bc]` contains `PolicyDlnqProcess:bc`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-batch-5c8d7f-m4tzr | ... [PolicyDlnqProcess:bc] com.guidewire.pl.system.exception.ConcurrentDataChangeException: Bean PolicyPeriod:2048 ... |

**Near miss (would NOT match):** the same exception line from pod `bc2batch-legacy-01` (no dash after `bc2`). It is dropped because `src` does not begin with `bc2-`.

---

### #37 Bcsubledger Exception Error Or Warn

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-35-08.ap-northeast-1.compute.internal
k8s.pod.name: bcsubledger-7b5d9c6f8-t2xkn
log.source: /var/log/containers/bcsubledger-7b5d9c6f8-t2xkn_bc2_app.log
loglevel: ERROR
content: 2026-10-15 09:12:34,567 ERROR [LedgerWorker-3] SubledgerPostingService - Posting failed for journal JRN-20261015-0042
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bcsubledger-7b5d9c6f8-t2xkn`. |
| `filter startsWith(src, "bcsubledger")` | `src` begins with `bcsubledger`. |
| `filter matchesPhrase(content, "Exception") or ... "ERROR" or ... "WARN"` | The content has `ERROR` as a whole word with spaces around it. One of the three words is enough. |

**Result row:**

| timestamp | src | loglevel | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bcsubledger-7b5d9c6f8-t2xkn | ERROR | ... ERROR [LedgerWorker-3] SubledgerPostingService - Posting failed for journal JRN-20261015-0042 |

**Near miss (would NOT match):** `content: ... WARNING [LedgerWorker-3] java.lang.NullPointerException at SubledgerPostingService` from the same pod. It is dropped because `WARNING` is not the whole word `WARN`, and `java.lang.NullPointerException` does not contain the standalone word `Exception`.

---

### #38 BC2 UI GMO Error Code E01050004

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 WARN [http-nio-8080-exec-5] GmoClient - EntryTran response: errcode=E01&errinfo=E01050004&OrderID=ORD-20261015-0103
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter startsWith(src, "bc2-ui")` | `src` begins with `bc2-ui`. |
| `filter contains(content, "errcode=E01&errinfo=E01050004", caseSensitive:false)` | The content has the exact text `errcode=E01&errinfo=E01050004` in that order with no spaces. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-ui-7f9c6d-x2kqp | ... EntryTran response: errcode=E01&errinfo=E01050004&OrderID=ORD-20261015-0103 |

**Near miss (would NOT match):** `content: ... errinfo=E01050004&errcode=E01&OrderID=ORD-20261015-0103`. It is dropped because the two codes are in the opposite order, so the exact substring is not present.

---

### #39 BC2 CVS Offline Payment Notification Exception

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-15 09:12:34,567 ERROR Integration.CVS [CvsNotifyWorker-2] Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:pc:10482]
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2")` | `src` begins with `bc2`. |
| `filter matchesPhrase(content, "ERROR")` | The content has `ERROR` as a whole word. |
| `and contains(content, "Integration.CVS", caseSensitive:false)` | The logger name `Integration.CVS` is in the content. |
| `and contains(content, "Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:", caseSensitive:false)` | The content has this exact text, including the `[` bracket and the `:` right after `_Adj`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-batch-5c8d7f-m4tzr | ... ERROR Integration.CVS ... Exception caught while processing item [entity.CvsOfflinePaymentNotification_Adj:pc:10482] |

**Near miss (would NOT match):** the same line logged at `WARN` level instead of `ERROR`. It is dropped because the whole word `ERROR` is no longer in the content.

---

### #40 BC2 Multiple Matches On ContactID

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-9] gw.api.database.MultipleMatchesException: More than one row found for query on Contact where ContactID_Adj = ? Values: [C-000123]
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter startsWith(src, "bc2")` | `src` begins with `bc2`. |
| `filter contains(content, "gw.api.database.MultipleMatchesException", caseSensitive:false)` | The full exception name is in the content. |
| `and matchesPhrase(content, "ContactID_Adj")` | `ContactID_Adj` stands alone with spaces around it, so it is a whole word. |
| `and matchesPhrase(content, "Values")` | `Values` is followed by `:`, which is punctuation, so it still counts as a whole word. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-ui-7f9c6d-x2kqp | ... gw.api.database.MultipleMatchesException: ... where ContactID_Adj = ? Values: [C-000123] |

**Near miss (would NOT match):** `content: ... gw.api.database.MultipleMatchesException: More than one row found for findByContactID_Adj Values: [C-000123]`. It is dropped because `ContactID_Adj` is glued into the longer word `findByContactID_Adj`.

---

### #41 BC2 Batch Duplicate CVS Offline Quick Records

**Sample record that matches:**

```
timestamp: 2026-10-14T02:10:05.120+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-14 02:10:05,120 INFO [CvsImport-1] PaymentRecordType=Quick record for CVS Offline, Identifier=CVS-000731, Amount=12800, PaymentDate=Wed Oct 14 10:00:00 JST 2026, RunID=R-0101
```

| DQL line | Why this sample passes |
|---|---|
| `fetch logs, from:now()-7d` | The record is from 2026-10-14, which is inside the last 7 days. |
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2-batch")` | `src` begins with `bc2-batch`. |
| `filter contains(content, "PaymentRecordType=Quick record for CVS Offline", caseSensitive:false)` | The content has the exact text `PaymentRecordType=Quick record for CVS Offline`. |
| `dedup content` | The two duplicate lines (see below) have different timestamps and different `RunID` values in the text, so their content differs and both survive `dedup`. |
| `parse content, "LD 'Identifier=' LD:Identifier ','"` | The text after `Identifier=` up to the next comma is `CVS-000731`. |
| `parse content, "LD 'Amount=' LD:Amount ','"` | The text after `Amount=` up to the next comma is `12800`. |
| `parse content, "LD 'PaymentDate=' LD:PaymentDate ','"` | The text after `PaymentDate=` up to the next comma is `Wed Oct 14 10:00:00 JST 2026`. |
| `summarize count = count(), by:{ Identifier, Amount, PaymentDate }` | Both lines share the same three values, so they land in one group with `count = 2`. |
| `filter count > 1` | The group count is 2, which is greater than 1. |
| `fieldsAdd pd_clean = replaceString(PaymentDate, " JST ", " ")` | ` JST ` is removed, giving `Wed Oct 14 10:00:00 2026`. |
| `parse pd_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):PaymentDateForSort"` | `Wed Oct 14 10:00:00 2026` fits the pattern exactly. October 14, 2026 really is a Wednesday. |

**Result row:** this query groups records, so here are three input records and the row they produce.

| Record | Content (shortened) | Kept after dedup |
|---|---|---|
| 1 | `2026-10-14 02:10:05,120 ... Identifier=CVS-000731, Amount=12800, PaymentDate=Wed Oct 14 10:00:00 JST 2026, RunID=R-0101` | Yes |
| 2 | `2026-10-14 03:10:04,880 ... Identifier=CVS-000731, Amount=12800, PaymentDate=Wed Oct 14 10:00:00 JST 2026, RunID=R-0102` | Yes, because its text differs from record 1. |
| 3 | `2026-10-14 02:10:05,340 ... Identifier=CVS-000732, Amount=5400, PaymentDate=Wed Oct 14 11:30:00 JST 2026, RunID=R-0101` | Yes, but its group has count 1 and is filtered out. |

| Identifier | Amount | PaymentDate |
|---|---|---|
| CVS-000731 | 12800 | Wed Oct 14 10:00:00 JST 2026 |

**Near miss (would NOT match):** two lines with exactly the same full text, for example a log shipper sending the same line twice. They are dropped as duplicates because `dedup content` keeps only one of them, so the group count becomes 1 and fails `count > 1`.

---

### #42 API Exception When Executing In Three BC2 Apps

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-35-08.ap-northeast-1.compute.internal
k8s.pod.name: bcsubledger-7b5d9c6f8-t2xkn
log.source: /var/log/containers/bcsubledger-7b5d9c6f8-t2xkn_bc2_app.log
content: 2026-10-15 09:12:34,567 ERROR [ApiWorker-1] RestGateway - API - Exception when executing POST /ledger/v1/postings: java.net.SocketTimeoutException
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bcsubledger-7b5d9c6f8-t2xkn`. |
| `filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` | `src` begins with `bcsubledger`, which satisfies the third check. |
| `filter contains(content, "API - Exception when executing", caseSensitive:false)` | The content has the exact text `API - Exception when executing` with single spaces around the dash. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bcsubledger-7b5d9c6f8-t2xkn | ... API - Exception when executing POST /ledger/v1/postings: java.net.SocketTimeoutException |

**Near miss (would NOT match):** the same content from pod `bc2-ws-6f7a8b-p5cjd`. It is dropped because `bc2-ws` does not start with any of the three allowed prefixes.

---

### #43 GMO EXECTRAN Exception In Three BC2 Apps

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-15 09:12:34,567 ERROR [CardChargeWorker-4] GmoClient - Exception during GMO call EXECTRAN: java.net.SocketTimeoutException: Read timed out OrderID=ORD-20261015-0120
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` | `src` begins with `bc2-batch`, which satisfies the second check. |
| `filter contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)` | The content has the exact text `Exception during GMO call EXECTRAN`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-batch-5c8d7f-m4tzr | ... Exception during GMO call EXECTRAN: java.net.SocketTimeoutException: Read timed out OrderID=ORD-20261015-0120 |

**Near miss (would NOT match):** `content: ... Exception during GMO call ENTRYTRAN: ...` from the same pod. It is dropped because the action name is `ENTRYTRAN`, not `EXECTRAN`.

---

### #44 BC2 UI GMO Error Code E01050004

Same sample as #38. The DQL is identical, so the #38 record matches for the same reasons.

---

### #45 BC2 CVS Offline Payment Notification Exception

Same sample as #39. This version checks `matchesPhrase(content, "Integration.CVS")` instead of `contains()`, and the #39 sample still matches because `Integration.CVS` sits between a space and another space, so it is a whole phrase.

---

### #46 BC2 Multiple Matches On ContactID

Same sample as #40. This version also uses `matchesPhrase()` for `gw.api.database.MultipleMatchesException`, and the #40 sample still matches because the exception name is preceded by a space and followed by `:`, so it is a whole phrase.

---

### #47 BC2 Batch Duplicate CVS Offline Quick Records

Same sample as #41. The DQL is identical, so the same two records produce the same duplicate row.

---

### #48 API Exception When Executing In Three BC2 Apps

Same sample as #42. The DQL is identical, so the #42 record matches for the same reasons.

---

### #49 GMO EXECTRAN Exception In Three BC2 Apps

Same sample as #43. The DQL is identical, so the #43 record matches for the same reasons.

---

### #50 BC2 UI Error Code E01 Minus Known Codes

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-2] GmoClient - Map returned by method call EntryTran: errcode=E01&errinfo=E01170006&OrderID=ORD-20261015-0144
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter startsWith(src, "bc2-ui")` | `src` begins with `bc2-ui`. |
| `filter contains(content, "Map returned by method call", caseSensitive:false)` | The content has the exact text `Map returned by method call`. |
| `parse content, "LD 'errcode=' ALNUM:errcode"` | The pattern skips to `errcode=` and then `ALNUM` grabs letters and digits. It grabs `E01` and stops at `&`, because `&` is not a letter or digit. |
| `filter errcode == "E01"` | The parsed value is exactly `E01`. |
| `filter not matchesPhrase(content, "E01390002")` | The content does not contain `E01390002`, so the record is kept. |
| `filter not matchesPhrase(content, "E01260010")` | The content does not contain `E01260010`, so the record is kept. |
| `filter not matchesPhrase(content, "E01110002")` | The content does not contain `E01110002`, so the record is kept. Its detail code is `E01170006`, which is not on the known list. |

Why the `&` matters: `ALNUM` is greedy and keeps reading as long as it sees letters or digits. If the line said `errcode=E01050004` (one code glued together), `errcode` would become `E01050004`. That is not equal to `E01`, so the `==` test would fail and the line would be dropped.

**Result row:**

| timestamp | src | errcode | content |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-ui-7f9c6d-x2kqp | E01 | ... Map returned by method call EntryTran: errcode=E01&errinfo=E01170006&OrderID=ORD-20261015-0144 |

**Near miss (would NOT match):** `content: ... Map returned by method call EntryTran: errcode=E01&errinfo=E01390002&OrderID=ORD-20261015-0145`. It is dropped because it contains the known detail code `E01390002`, which the first `not` filter removes.

---

### #51 BC2 Batch SaveCardWithOrderID Errors On Writer 54

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-15 09:12:34,567 ERROR [MW-Writer-[54]] CardSaveWriter - Errors in saveCardWithOrderID call for OrderID=ORD-20261015-0137
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2-batch")` | `src` begins with `bc2-batch`. |
| `filter contains(content, "Errors in saveCardWithOrderID call", caseSensitive:false)` | The content has the exact text `Errors in saveCardWithOrderID call`. |
| `filter contains(content, "MW-Writer-[54]", caseSensitive:false)` | The thread label contains the literal text `MW-Writer-[54]`, square brackets included. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-batch-5c8d7f-m4tzr | ... ERROR [MW-Writer-[54]] CardSaveWriter - Errors in saveCardWithOrderID call for OrderID=ORD-20261015-0137 |

**Near miss (would NOT match):** the same error from thread `[MW-Writer-[5]]`. It is dropped because the text `MW-Writer-[54]` is not present; `[5]` is a different thread.

---

### #52 GMO SearchTrade Used To Confirm ExecTran

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-6] GmoClient - GMO SearchTrade used to confirm ExecTran status with OrderID ORD-20261015-0152: status=CAPTURE
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` | `src` begins with `bc2-ui`, which satisfies the first check. |
| `filter contains(content, "GMO SearchTrade used to confirm ExecTran status with OrderID", caseSensitive:false)` | The content has the full phrase word for word with single spaces. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-ui-7f9c6d-x2kqp | ... GMO SearchTrade used to confirm ExecTran status with OrderID ORD-20261015-0152: status=CAPTURE |

**Near miss (would NOT match):** `content: ... GMO SearchTrade used to confirm ExecTran status with Order ID ORD-20261015-0152`. It is dropped because `Order ID` has a space, so the exact phrase ending in `OrderID` is not present.

---

### #53 GMO EXECTRAN Exception In Three BC2 Apps

Same sample as #43. The main DQL is identical to #49 and #43, so the #43 record matches. In the extra hourly chart query, the #43 record would be labeled `bc2-batch` and counted in that app's line for the 09:00 hour.

---

### #54 Operation Failed For A Producer

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-36-14.ap-northeast-1.compute.internal
k8s.pod.name: pc2-ui-6c7d8e-h3nvb
log.source: /var/log/containers/pc2-ui-6c7d8e-h3nvb_pc2_app.log
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-1] ProducerService - Operation failed: ProducerCode <JP_TEXT_1> (code=AG-00417)
```

Replace `<JP_TEXT_1>` with the real Japanese text in both the DQL and the log. Until then this sample only matches because it also contains the placeholder text.

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `pc2-ui-6c7d8e-h3nvb`. |
| `filter startsWith(src, "pc2-ui") or startsWith(src, "bc2-ui")` | `src` begins with `pc2-ui`, which satisfies the first check. |
| `filter contains(content, "Operation failed", caseSensitive:false)` | The content has the exact text `Operation failed`. |
| `filter contains(content, "ProducerCode <JP_TEXT_1>", caseSensitive:false)` | The content has `ProducerCode <JP_TEXT_1>` with one space between them. |
| `or contains(content, "Producer <JP_TEXT_2>", caseSensitive:false)` | Not needed here. The first producer check already passed, and only one of the two must be true. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | pc2-ui-6c7d8e-h3nvb | ... Operation failed: ProducerCode <JP_TEXT_1> (code=AG-00417) |

**Near miss (would NOT match):** `content: ... Operation failed: Account <JP_TEXT_1> (code=AC-00981)`. It is dropped because neither `ProducerCode <JP_TEXT_1>` nor `Producer <JP_TEXT_2>` is present.

---

### #55 BC2 Producer Contact Missing

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-17.ap-northeast-1.compute.internal
k8s.pod.name: bc2-batch-5c8d7f-m4tzr
log.source: /var/log/containers/bc2-batch-5c8d7f-m4tzr_bc2_batch.log
content: 2026-10-15 09:12:34,567 WARN [CommissionWorker-2] ProducerSync - Producer Contact is missing for Producer AG-00417
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-batch-5c8d7f-m4tzr`. |
| `filter startsWith(src, "bc2")` | `src` begins with `bc2`. |
| `filter contains(content, "Producer Contact is missing for Producer", caseSensitive:false)` | The content has the exact phrase `Producer Contact is missing for Producer`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-batch-5c8d7f-m4tzr | ... Producer Contact is missing for Producer AG-00417 |

**Near miss (would NOT match):** `content: ... Producer contact missing for Producer AG-00417`. It is dropped because the word `is` is missing, so the exact phrase is not found.

---

### #56 BC2 Producer Contact Missing

Same sample as #55. The DQL is identical, so the #55 record matches for the same reasons.

---

### #57 BC2 Server RunLevel Ready

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: bc2-ui-7f9c6d-x2kqp
log.source: /var/log/containers/bc2-ui-7f9c6d-x2kqp_bc2_app.log
content: 2026-10-15 09:12:34,567 INFO Server.RunLevel Server run level MULTIUSER is ready
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bc2-ui-7f9c6d-x2kqp`. |
| `filter startsWith(src, "bc2-")` | `src` begins with `bc2-`. |
| `filter matchesPhrase(content, "Server.RunLevel")` | `Server.RunLevel` stands alone with spaces on both sides, so it is a whole phrase. |
| `filter matchesPhrase(content, "ready")` | `ready` is the last word of the line, so it is a whole word. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bc2-ui-7f9c6d-x2kqp | ... INFO Server.RunLevel Server run level MULTIUSER is ready |

**Near miss (would NOT match):** `content: ... INFO Server.RunLevel Server already at run level MULTIUSER`. It is dropped because `already` contains `ready` only inside a longer word, and `matchesPhrase` needs the whole word.

---

### #58 Bcsubledger Japanese Text Search

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-35-08.ap-northeast-1.compute.internal
k8s.pod.name: bcsubledger-7b5d9c6f8-t2xkn
log.source: /var/log/containers/bcsubledger-7b5d9c6f8-t2xkn_bc2_app.log
content: 2026-10-15 09:12:34,567 ERROR [LedgerWorker-1] SubledgerImportService - <JP_TEXT> file=SL_20261015_01.csv
```

Replace `<JP_TEXT>` with the real Japanese error message in both the DQL and the log.

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `bcsubledger-7b5d9c6f8-t2xkn`. |
| `filter startsWith(src, "bcsubledger")` | `src` begins with `bcsubledger`. |
| `filter contains(content, "<JP_TEXT>", caseSensitive:false)` | The content contains the same `<JP_TEXT>` text as the filter. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | bcsubledger-7b5d9c6f8-t2xkn | ... SubledgerImportService - <JP_TEXT> file=SL_20261015_01.csv |

**Near miss (would NOT match):** the same message written with escaped characters such as `\u4ed5\u8a33...` instead of real Japanese. It is dropped because the escaped text is not the same characters as `<JP_TEXT>`.

---

### #59 PC2 Batch Payment Request Creation Failure

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-21.ap-northeast-1.compute.internal
k8s.pod.name: pc2-batch-84d6c7b5f-r9lqv
log.source: /var/log/containers/pc2-batch-84d6c7b5f-r9lqv_pc2_batch.log
content: 2026-10-15 09:12:34,567 ERROR [PaymentRequestWorker-3] Creation of a payment request for transaction TXN-20261015-0077 ended in failure
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `pc2-batch-84d6c7b5f-r9lqv`. |
| `filter startsWith(src, "pc2-batch")` | `src` begins with `pc2-batch`. |
| `filter contains(content, "Creation of a payment request for transaction", caseSensitive:false)` | The content has the exact phrase `Creation of a payment request for transaction`. |
| `filter matchesPhrase(content, "failure")` | `failure` is the last word of the line, so it is a whole word. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | pc2-batch-84d6c7b5f-r9lqv | ... Creation of a payment request for transaction TXN-20261015-0077 ended in failure |

**Near miss (would NOT match):** `content: ... Creation of a payment request for transaction TXN-20261015-0077 failed`. It is dropped because `failed` is not the whole word `failure`.

---

### #60 CC RemoveDocumentChain Execution Duration

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-37-09.ap-northeast-1.compute.internal
k8s.pod.name: cc-batch-6f5b8d9c7-w8jzm
log.source: /var/log/containers/cc-batch-6f5b8d9c7-w8jzm_cc_batch.log
content: 2026-10-15 09:12:34,567 INFO [DocWorker-2] RemoveDocumentChain Execution Duration: 1234 ms
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `cc-batch-6f5b8d9c7-w8jzm`. |
| `filter startsWith(src, "cc-ui") or startsWith(src, "cc-batch")` | `src` begins with `cc-batch`, which satisfies the second check. |
| `filter contains(src, "cc-")` | `src` contains `cc-` at the start. |
| `filter matchesPhrase(content, "RemoveDocumentChain")` | `RemoveDocumentChain` stands alone with spaces around it. |
| `filter matchesPhrase(content, "Execution")` | `Execution` is a separate word. |
| `filter matchesPhrase(content, "Duration")` | `Duration` is a separate word, followed by `:` which is punctuation. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | cc-batch-6f5b8d9c7-w8jzm | ... RemoveDocumentChain Execution Duration: 1234 ms |

**Near miss (would NOT match):** `content: ... RemoveDocumentChain ExecutionDuration=1234ms` from the same pod. It is dropped because `Execution` and `Duration` are glued into one word, so neither is a whole word on its own.

---


---

## Part 3: Match Examples For DQL 61 to 85

This part shows, for each DQL query from #61 to #85, one fake log record that the query would return and why each filter line lets it through. Every example also has a "near miss" record that looks almost the same but is dropped, so you can see exactly where the query is strict.

All values below are fake. Unless a query says otherwise, assume the query was run at `2026-10-15T09:30:00+09:00`, so a record at `09:12:34` is inside every `from:now()-24h`, `from:now()-1d`, and `from:now()-1h` window.

---

### #61 Cc-Batch ERROR Lines For EnqueteWorkItem

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.pod.name: cc-batch-0
k8s.container.name: cc-batch
content: 2026-10-15 09:12:34,567 ERROR [worker-3] c.e.cc.batch.EnqueteWorkItem_Adj - Work item failed for enquete id 48213
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | The pod name is filled in, so `src` becomes `cc-batch-0`. |
| `filter startsWith(src, "cc-batch")` | `cc-batch-0` begins with `cc-batch`. |
| `parse content, "LD DIGIT+ '-' DIGIT+ '-' DIGIT+ ' ' DIGIT+ ':' DIGIT+ ':' DIGIT+ ',' DIGIT+ SPACE+ WORD:loglevel"` | The text `2026-10-15 09:12:34,567 ERROR` fits the date, the single space, the time, the comma, the milliseconds, and one space. The next word `ERROR` is saved as `loglevel`. |
| `filter loglevel == "ERROR"` | `loglevel` is exactly `ERROR` in upper case. |
| `filter contains(content, "EnqueteWorkItem_Adj", caseSensitive:false)` | The logger name `c.e.cc.batch.EnqueteWorkItem_Adj` contains the text. |
| `summarize ... by:{ timestamp }` | Rows with the same timestamp are grouped into one output row. |

**Result row:** two pods logged the same error at the same millisecond.

| Input record | k8s.pod.name | content (short) |
|---|---|---|
| 1 | `cc-batch-0` | `2026-10-15 09:12:34,567 ERROR ... EnqueteWorkItem_Adj - Work item failed for enquete id 48213` |
| 2 | `cc-batch-1` | `2026-10-15 09:12:34,567 ERROR ... EnqueteWorkItem_Adj - Work item failed for enquete id 48214` |

| timestamp | loglevel | log |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `["ERROR"]` | `["...enquete id 48213", "...enquete id 48214"]` |

**Near miss (would NOT match):** `2026-10-15 09:12:34.567 ERROR [worker-3] c.e.cc.batch.EnqueteWorkItem_Adj - Work item failed` is dropped because the dot before the milliseconds breaks the `','` piece of the pattern, so `loglevel` stays empty and fails the ERROR filter.

---

### #62 Cc-Batch MessageQueueMonitor ERROR With Detail Lines

**Sample record that matches:** one record whose `content` has three lines.

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.pod.name: cc-batch-2
k8s.container.name: cc-batch
content: 2026-10-15 09:12:34,567 ERROR [monitor-1] c.e.cc.batch.MessageQueueMonitor_Adj - [MQ] Found 2 stuck messages in queue CC_OUT
1234567890 POLICY-0001 stuck since 2026-10-15 08:00
2345678901 POLICY-0002 stuck since 2026-10-15 08:05
```

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | `src` becomes `cc-batch-2`. |
| `filter contains(src, "cc-batch")` | `cc-batch-2` contains `cc-batch`. |
| `parse content, "LD DIGIT+ ... WORD:loglevel"` | The first line starts with `2026-10-15 09:12:34,567 ERROR`, so `loglevel` is `ERROR`. |
| `filter loglevel == "ERROR"` | `loglevel` is exactly `ERROR`. |
| `filter contains(content, "MessageQueueMonitor_Adj", caseSensitive:false)` | The logger name `MessageQueueMonitor_Adj` is in the first line. |
| `filter not contains(content, "Sonpovan <JP_TEXT>", caseSensitive:false)` | The content has no `Sonpovan` text at all, so the check is true. Replace `<JP_TEXT>` with the real Japanese words before running. |
| `filter contains(content, "Found ")` | The first line has `Found ` with a capital F and a space after it. |
| `fieldsAdd queueMessage = substring(content, from: indexOf(content, "Found "))` | `queueMessage` starts at `Found 2 stuck messages in queue CC_OUT`. It runs to the end of `content`, so it also carries the two detail lines. |
| `fieldsAdd line = splitString(content, "\n")` | The content is cut at each newline into a list of three lines. |
| `expand line` | The one record becomes three rows, one per line. |
| `parse line, "(DIGIT{10} SPACE LD):detail"` | Line 1 starts with `2026-10-15`, which is only 4 digits before a dash, so `detail` stays empty. Line 2 starts with `1234567890 ` (10 digits and a space), so `detail` is the whole line. Line 3 starts with `2345678901 `, so it matches too. |
| `filter isNotNull(detail)` | Line 1 is dropped. Lines 2 and 3 survive. |
| `summarize details = collectArray(detail), by:{ timestamp, src, queueMessage }` | Lines 2 and 3 share the same timestamp, src, and queueMessage, so they become one row with a list of two details. |

**Result row:**

| timestamp | src | queueMessage | details |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `cc-batch-2` | `Found 2 stuck messages in queue CC_OUT` (plus the two detail lines that follow it in content) | `["1234567890 POLICY-0001 stuck since 2026-10-15 08:00", "2345678901 POLICY-0002 stuck since 2026-10-15 08:05"]` |

**Near miss (would NOT match):** the same error where Dynatrace stores `1234567890 POLICY-0001 ...` as its own separate record is dropped, because that separate record has no `ERROR` date header and no `Found ` text, and the header record has no 10-digit line left to keep.

---

### #63 Cc-Batch DocNotif Work Item Failed

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.pod.name: cc-batch-0
k8s.container.name: cc-batch
content: 2026-10-15 09:12:34,567 INFO [worker-1] c.e.cc.batch.WorkItemRunner - Work item processed "DocNotif_Adj" id=48213 failed=true elapsedMs=1520
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "cc-batch")` | `src` is `cc-batch-0`, which begins with `cc-batch`. |
| `filter contains(content, "Work item processed \"DocNotif_Adj\"", caseSensitive:false)` | The content has `Work item processed "DocNotif_Adj"` with real double quotes around the name. |
| `filter contains(content, "failed=true", caseSensitive:false)` | The content has `failed=true` with no spaces around the equals sign. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `cc-batch-0` | `... Work item processed "DocNotif_Adj" id=48213 failed=true elapsedMs=1520` |

**Near miss (would NOT match):** `... Work item processed "DocNotif_Adj" id=48213 failed=false elapsedMs=900` is dropped because it has `failed=false`, not `failed=true`.

---

### #64 Cc-Batch FinancialsEsc Work Item Failed

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.pod.name: cc-batch-1
k8s.container.name: cc-batch
content: 2026-10-15 09:12:34,567 INFO [worker-2] c.e.cc.batch.WorkItemRunner - Work item processed "FinancialsEscalation_Adj" id=77120 failed=true elapsedMs=3011
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "cc-batch")` | `src` is `cc-batch-1`. |
| `filter contains(content, "Work item processed \"FinancialsEsc", caseSensitive:false)` | The content has `Work item processed "FinancialsEsc` followed by `alation_Adj"`. The open quote in the DQL lets any name starting with `FinancialsEsc` match. |
| `filter contains(content, "failed=true", caseSensitive:false)` | The content has `failed=true`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `cc-batch-1` | `... Work item processed "FinancialsEscalation_Adj" id=77120 failed=true elapsedMs=3011` |

**Near miss (would NOT match):** `... Work item processed "FinancialsEscalation_Adj" id=77120 failed = true` is dropped because the spaces around `=` mean the exact text `failed=true` is not present.

---

### #65 Sonpovan Account Statement Tasklet Warnings

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: sonpovan-batch-7d9f8c6b5-x2k4q
k8s.container.name: sonpovan-batch
content: 2026-10-15 09:12:34,567 WARN [step-1] j.c.s.batch.VanTRecvAccountStatementCallApiTasklet - claim 2026/004512 Message : <400 characters of response text>ERR-STMT-0042-API
```

How long the message is:

| Piece | Length | What it holds |
|---|---|---|
| `<400 characters of response text>` | 400 characters | Plain text on one line. It has no newline, no `Message : `, and no digits next to a slash. |
| `ERR-STMT-0042-API` | 17 characters | The value we want in `suffix`. |
| Whole `message` field | 417 characters | Everything after `Message : `. |

| DQL line | Why this sample passes |
|---|---|
| `filter contains(src, "sonpov")` | `src` is `sonpovan-batch-7d9f8c6b5-x2k4q`, which contains `sonpov`. |
| `filter matchesPhrase(content, "WARN")` | `WARN` appears as a whole word after the time. |
| `filter contains(content, "VanTRecvAccountStatementCallApiTasklet", caseSensitive:false)` | The logger name is in the content. |
| `filter contains(content, "Message")` | `Message` appears with a capital M, which this case-sensitive check needs. |
| `parse content, "LD (DIGIT+ '/' DIGIT+):claimNumber"` | `2026/004512` is digits, a slash, and digits, so it becomes `claimNumber`. |
| `parse content, "LD 'Message : ' LD:message"` | The literal `Message : ` is found, and the 417 characters after it are saved as `message`. |
| `fieldsAdd suffix = if(stringLength(message) > 400, substring(message, from:400, to:417))` | The length 417 is more than 400. Counting from 0, positions 400 to 416 are characters 401 to 417, which hold `ERR-STMT-0042-API`. |

**Result row:**

| timestamp | src | claimNumber | message | suffix |
|---|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `sonpovan-batch-7d9f8c6b5-x2k4q` | `2026/004512` | `<400 characters of response text>ERR-STMT-0042-API` | `ERR-STMT-0042-API` |

**Near miss (would NOT match):** the same line with `WARNING` instead of `WARN` is dropped, because `matchesPhrase` needs the whole word `WARN` and `WARNING` is a different word.

---

### #66 Cc Apps NoUpdatePaymentError

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.pod.name: cc-ui-6f8d9c7b4-abcde
k8s.container.name: cc-ui
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-5] c.e.cc.payment.PaymentService - NoUpdatePaymentError: payment record 88123 is locked by another process
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "cc-")` | `src` is `cc-ui-6f8d9c7b4-abcde`, which begins with `cc-`. |
| `filter contains(content, "NoUpdatePaymentError", caseSensitive:false)` | The content has `NoUpdatePaymentError` right after the logger name. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `cc-ui-6f8d9c7b4-abcde` | `... NoUpdatePaymentError: payment record 88123 is locked by another process` |

**Near miss (would NOT match):** the same line from pod `acc-ui-6f8d9c7b4-abcde` is dropped because `acc-ui` does not begin with `cc-`.

---

### #67 Sonpov And Temp Receipt ERROR Lines

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.000+09:00
host.name: ip-10-20-32-11.ap-northeast-1.compute.internal
k8s.pod.name: temp-receipt-accounting-5c8d7f9b6-m3n7p
k8s.container.name: temp-receipt-accounting
content: 2026-10-15 09:12:34 ERROR [main] j.c.t.receipt.ReceiptJob - Receipt export failed for batch 3021
```

| DQL line | Why this sample passes |
|---|---|
| `filter contains(src, "sonpov") or contains(src, "temp-receipt-accounting")` | `src` contains `temp-receipt-accounting`, so the second check is true. |
| `parse content, "INT '-' INT '-' INT SPACE INT ':' INT ':' INT SPACE ALPHA:loglevel_parsed"` | The line starts with `2026-10-15 09:12:34 ERROR`. There are no milliseconds, so exactly one space follows the seconds. `ERROR` is letters only, so it becomes `loglevel_parsed`. |
| `filter loglevel_parsed == "ERROR"` | `loglevel_parsed` is exactly `ERROR`. |
| `summarize ... podname = collectDistinct(src), by:{ timestamp }` | Records with the same timestamp are grouped into one row. |

**Result row:** two apps logged an error in the same second.

| Input record | k8s.pod.name | content (short) |
|---|---|---|
| 1 | `temp-receipt-accounting-5c8d7f9b6-m3n7p` | `2026-10-15 09:12:34 ERROR ... Receipt export failed for batch 3021` |
| 2 | `sonpovan-batch-7d9f8c6b5-x2k4q` | `2026-10-15 09:12:34 ERROR ... Account sync failed for claim 2026/004512` |

| timestamp | loglevel | log | podname |
|---|---|---|---|
| 2026-10-15T09:12:34.000+09:00 | `["ERROR"]` | `["...Receipt export failed for batch 3021", "...Account sync failed for claim 2026/004512"]` | `["temp-receipt-accounting-5c8d7f9b6-m3n7p", "sonpovan-batch-7d9f8c6b5-x2k4q"]` |

**Near miss (would NOT match):** `2026-10-15 09:12:34,567 ERROR [main] ...` is dropped because `,567` sits where the pattern expects a space, so `loglevel_parsed` stays empty.

---

### #68 Cc-Ui RemoveDocument Called

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-31-45.ap-northeast-1.compute.internal
k8s.pod.name: cc-ui-6f8d9c7b4-abcde
k8s.container.name: cc-ui
content: 2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-9] c.e.cc.docs.DocumentService - removeDocument called for document with DocUID DOC-000731
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "cc-ui")` | `src` is `cc-ui-6f8d9c7b4-abcde`. |
| `filter contains(content, "removeDocument called for document with DocUID", caseSensitive:false)` | The content has this exact text with single spaces between the words. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `cc-ui-6f8d9c7b4-abcde` | `... removeDocument called for document with DocUID DOC-000731` |

**Near miss (would NOT match):** `... removeDocument called for document  with DocUID DOC-000731` is dropped because the double space before `with` breaks the exact text.

---

### #69 Esbv4 Call To Ebroker Failed With 503

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-4] c.e.esb.ErrorHandler - Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/ebroker/api/policy/issue' failed: service unavailable (503).
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` | `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Error(esb.xml) error payload: HTTP POST on resource 'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/", caseSensitive:false)` | The content has the error header and the base URL including `:443/`. |
| `and contains(content, "' failed: service unavailable (503).", caseSensitive:false)` | After the path `ebroker/api/policy/issue`, the content has `' failed: service unavailable (503).` with the closing quote and the final dot. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `... HTTP POST on resource 'https://ebroker-inssuite-prod...:443/ebroker/api/policy/issue' failed: service unavailable (503).` |

**Near miss (would NOT match):** the same line with `'https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa/ebroker/api/policy/issue'` (no `:443`) is dropped because the first `contains` needs `:443/` character for character.

---

### #70 Ebroker Address Conversion Failures

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-21.ap-northeast-1.compute.internal
k8s.pod.name: ebroker-api-5b7c9d8f6-q8w2r
k8s.container.name: ebroker-api
content: 2026-10-15 09:12:34,567 WARN [http-nio-8080-exec-3] c.e.ebroker.address.AddressService - Address conversion failed.Request to agrex Zipcode: 1000001
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "ebroker")` | `src` is `ebroker-api-5b7c9d8f6-q8w2r`. |
| `filter contains(content, "Address conversion failed.Request to agrex Zipcode:", caseSensitive:false)` | The content has this text with no space after `failed.`. |
| `or contains(content, "Address conversion failed.Status code", caseSensitive:false)` | Not needed here. The first check is already true, and `or` needs only one. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `ebroker-api-5b7c9d8f6-q8w2r` | `... Address conversion failed.Request to agrex Zipcode: 1000001` |

**Near miss (would NOT match):** `... Address conversion failed. Request to agrex Zipcode: 1000001` is dropped because the space after `failed.` breaks both exact texts.

---

### #71 Ebroker Startup Lines

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-21.ap-northeast-1.compute.internal
k8s.pod.name: ebroker-api-5b7c9d8f6-q8w2r
k8s.container.name: ebroker-api
content: 2026-10-15 09:12:34,567 INFO [main] c.e.ebroker.ApiMain - Starting ApiMain on ebroker-api-5b7c9d8f6-q8w2r with PID 1
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "ebroker")` | `src` is `ebroker-api-5b7c9d8f6-q8w2r`. |
| `filter contains(content, "Starting ApiMain on ebroker", caseSensitive:false)` | The content has `Starting ApiMain on ebroker` because the pod host name right after `on` starts with `ebroker`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `ebroker-api-5b7c9d8f6-q8w2r` | `... Starting ApiMain on ebroker-api-5b7c9d8f6-q8w2r with PID 1` |

**Near miss (would NOT match):** `... Starting ApiMain v2.4.1 on ebroker-api-5b7c9d8f6-q8w2r with PID 1` is dropped because the version number between `ApiMain` and `on` breaks the exact text.

---

### #72 Esbv4 Ebroker Requests That Hit An Interceptor Exception

**Sample records that match:** two esbv4 records share the request ID `3f9a2c1e-7b4d-4e8a-9c21-0d5e6f7a8b9c`.

Outer record (the exception line):

```
timestamp: 2026-10-15T09:12:35.101+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:35,101 WARN [http-nio-8080-exec-7] o.a.c.p.PhaseInterceptorChain - [requestId=3f9a2c1e-7b4d-4e8a-9c21-0d5e6f7a8b9c] Interceptor for {http://ebroker.example/}QuoteService has thrown exception, unwinding now
```

Inner record (the request line):

```
timestamp: 2026-10-15T09:12:34.880+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,880 INFO [http-nio-8080-exec-7] c.e.esb.EbrokerRouter - [requestId=3f9a2c1e-7b4d-4e8a-9c21-0d5e6f7a8b9c] Sending request to /esb/ebroker/inswebauto/online/_quote
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` (outer) | The outer record's `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Interceptor for", caseSensitive:false)` (outer) | The outer content has `Interceptor for {http://...}`. |
| `and contains(content, "has thrown exception", caseSensitive:false)` (outer) | The outer content has `has thrown exception`. |
| `parse content, "LD ([0-9a-z]{8} ... [0-9a-z]{12}):query"` (outer) | The outer content has one UUID in lower-case hex with groups of 8, 4, 4, 4, and 12. So `query` is `3f9a2c1e-7b4d-4e8a-9c21-0d5e6f7a8b9c`. |
| `filter startsWith(src, "esbv4")` (inner) | The inner record also comes from the esbv4 pod. |
| `filter contains(content, "Sending request to /esb/ebroker", caseSensitive:false)` (inner) | The inner content has `Sending request to /esb/ebroker/inswebauto/online/_quote`, which starts with the needed text. |
| `parse content, "LD (...UUID...):query"` (inner) | The inner `query` is the same UUID `3f9a2c1e-7b4d-4e8a-9c21-0d5e6f7a8b9c`. |
| `filter isNotNull(query)` (inner) | The inner ID was found, so the row stays. |
| `dedup query` (inner) | Only one inner row for this ID remains. |
| `lookup [...], sourceField:query, lookupField:query, prefix:"req."` | The outer `query` equals the inner `query`, so the inner ID is copied onto the outer row as `req.query`. |
| `filter isNotNull(req.query)` | `req.query` has a value, so the exception row is kept. |

**Result row:**

| timestamp | src | query | content |
|---|---|---|---|
| 2026-10-15T09:12:35.101+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `3f9a2c1e-7b4d-4e8a-9c21-0d5e6f7a8b9c` | `... Interceptor for {http://ebroker.example/}QuoteService has thrown exception, unwinding now` |

**Near miss (would NOT match):** an exception line carrying `[requestId=9b8a7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d]` is dropped because no `Sending request to /esb/ebroker` line has that ID, so the lookup finds nothing and `req.query` stays empty.

---

### #73 Ebroker POST Request Ottif Started

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-34-21.ap-northeast-1.compute.internal
k8s.pod.name: ebroker-api-5b7c9d8f6-q8w2r
k8s.container.name: ebroker-api
content: 2026-10-15 09:12:34,567 INFO [http-nio-8080-exec-2] c.e.ebroker.web.RequestLogFilter - Started: POST /request/ottif
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "ebroker")` | `src` is `ebroker-api-5b7c9d8f6-q8w2r`. |
| `filter contains(content, "Started: POST /request/ottif", caseSensitive:false)` | The content ends with this exact text, including the colon and single spaces. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `ebroker-api-5b7c9d8f6-q8w2r` | `... Started: POST /request/ottif` |

**Near miss (would NOT match):** `... Started: GET /request/ottif` is dropped because the method is `GET`, not `POST`.

---

### #74 Esbv4 Call To Pc Quote Failed

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-6] c.e.esb.ErrorHandler - Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Read timed out
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` | `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource '...ebroker/quote' failed: ", caseSensitive:false)` | The content has the whole phrase, ending with `failed:` and one space. The reason after it (`Read timed out`) can be anything. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `... /pc/service/edge/ebroker/quote' failed: Read timed out` |

**Near miss (would NOT match):** the same line with `.../ebroker/quote' failed:Read timed out` (no space after the colon) is dropped because the search text needs `failed: ` with a trailing space.

---

### #75 Esbv4 Cannot Reach Localhost 8082

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-1] c.e.esb.HttpClient - Error sending HTTP request to http://localhost:8082/api/token: Connection refused
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` | `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Error sending HTTP request to http://localhost:8082", caseSensitive:false)` | The content has this text, followed by the path `/api/token`. |

**Result row:**

| timestamp | src | content |
|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `... Error sending HTTP request to http://localhost:8082/api/token: Connection refused` |

**Near miss (would NOT match):** `... Error sending HTTP request to http://127.0.0.1:8082/api/token: Connection refused` is dropped because the text says `127.0.0.1`, not `localhost`.

---

### #76 Apps That Stopped Logging

For this query, assume it was run at `2026-10-15T09:30:00+09:00`.

**Sample record that matches:** the newest of three mailservice records.

```
timestamp: 2026-10-15T06:00:00.000+09:00
host.name: ip-10-20-35-02.ap-northeast-1.compute.internal
k8s.workload.name: mailservice
k8s.pod.name: mailservice-6b8c9d7f5-t4r2w
k8s.container.name: mailservice
content: 2026-10-15 06:00:00,000 INFO [scheduler-1] c.e.mail.MailQueue - Mail queue drained, 0 messages pending
```

Other mailservice records in the 7-day window:

| Record | timestamp |
|---|---|
| 1 | 2026-10-14T22:10:00.000+09:00 |
| 2 | 2026-10-15T03:30:00.000+09:00 |
| 3 (newest) | 2026-10-15T06:00:00.000+09:00 |

| DQL line | Why this sample passes |
|---|---|
| `fieldsAdd app = lower(coalesce(k8s.workload.name, k8s.container.name, host.name))` | The workload name is filled in, so `app` becomes `mailservice`. |
| `filter matchesValue(app, array("agrex*", ..., "mailservice*", "portals*", "tts"))` | `mailservice` matches the pattern `mailservice*`. |
| `filter not in(app, array("ebroker_batch", "alfrescoaev", ...))` | `mailservice` is not in the list of expected-quiet apps, so `not in` is true. |
| `summarize ... last_event = max(timestamp), by:{ app }` | The three records collapse into one row. `last_event` is the newest one, 06:00:00. |
| `fieldsAdd last_seen_sec = (toLong(now()) - toLong(last_event)) / 1000000000` | From 06:00:00 to 09:30:00 is 3.5 hours, which is 12600 seconds. |
| `filter last_seen_sec > 3600` | 12600 is more than 3600, so the app counts as silent. |
| `fieldsAdd minutes_behind = ...` | 12600 divided by 60 is 210 minutes. |
| `hours_behind = ...` | 12600 divided by 3600 is 3.5 hours. |
| `days_behind = ...` | 12600 divided by 86400 is about 0.146, which rounds to 0.1 days. |
| `last_event_jst = formatTimestamp(...)` | 06:00:00 Japan time on Thursday 15 October 2026 prints as `Thu Oct 15 06:00:00 2026`. |

**Result row:**

| app | last_event_jst | minutes_behind | hours_behind | days_behind |
|---|---|---|---|---|
| `mailservice` | `Thu Oct 15 06:00:00 2026` | 210 | 3.5 | 0.1 |

**Near miss (would NOT match):** an `agrex` workload whose newest record is `2026-10-15T09:25:00+09:00` is dropped because it was silent for only 300 seconds, which is not more than 3600.

---

### #77 Bangauto Quote Requests That Hit The Pc Quote Timeout

**Sample records that match:** two esbv4 records share the request ID `a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d`.

Outer record (the request line):

```
timestamp: 2026-10-15T09:12:04.210+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:04,210 INFO [http-nio-8080-exec-3] c.e.esb.EbrokerRouter - [requestId=a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d] Sending request to /esb/ebroker/bangauto/online/_quote
```

Inner record (the timeout line):

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-3] c.e.esb.ErrorHandler - [requestId=a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d] Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` (outer) | The outer `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Sending request to /esb/ebroker/bangauto/online/_quote", caseSensitive:false)` (outer) | The outer content has this exact path. |
| `parse content, "LD (...UUID...):query"` (outer) | The outer `query` is `a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d`. |
| `filter startsWith(src, "esbv4")` (inner) | The inner record also comes from esbv4. |
| `filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)` (inner) | The inner content ends with `/pc/service/edge/ebroker/quote' failed: Timeout exceeded.` including the closing quote and the final dot. |
| `parse content, "LD (...UUID...):query"` (inner) | The inner `query` is the same UUID. The URL has no 8-4-4-4-12 shape, so it cannot be picked by mistake. |
| `filter isNotNull(query)` (inner) | The inner ID was found. |
| `dedup query` (inner) | One inner row for this ID. |
| `lookup [...], sourceField:query, lookupField:query, prefix:"err."` | The outer ID equals the inner ID, so `err.query` is filled in on the request row. |
| `filter isNotNull(err.query)` | `err.query` has a value, so the request row is kept. |

**Result row:**

| timestamp | src | query | content |
|---|---|---|---|
| 2026-10-15T09:12:04.210+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d` | `... Sending request to /esb/ebroker/bangauto/online/_quote` |

**Near miss (would NOT match):** a bangauto request line with `[requestId=c0ffee12-3456-4789-abcd-ef0123456789]` that finished normally is dropped because no timeout line carries that ID, so `err.query` stays empty.

---

### #78 Inswebauto Quote Requests That Hit The Pc Quote Timeout

**Sample records that match:** two esbv4 records share the request ID `5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e`.

Outer record (the request line):

```
timestamp: 2026-10-15T09:12:04.210+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:04,210 INFO [http-nio-8080-exec-8] c.e.esb.EbrokerRouter - [requestId=5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e] Sending request to /esb/ebroker/inswebauto/online/_quote
```

Inner record (the timeout line):

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-8] c.e.esb.ErrorHandler - [requestId=5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e] Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` (outer) | The outer `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Sending request to /esb/ebroker/inswebauto/online/_quote", caseSensitive:false)` (outer) | The outer content has this exact path. |
| `parse content, "LD (...UUID...):query"` (outer) | The outer `query` is `5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e`. |
| `filter startsWith(src, "esbv4")` (inner) | The inner record also comes from esbv4. |
| `filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource '...ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)` (inner) | The inner content has the full phrase word for word, from `Error(esb-ebroker.xml)` to `Timeout exceeded.`. |
| `parse content, "LD (...UUID...):query"` (inner) | The inner `query` is the same UUID. |
| `filter isNotNull(query)` (inner) | The inner ID was found. |
| `dedup query` (inner) | One inner row for this ID. |
| `lookup [...], sourceField:query, lookupField:query, prefix:"err."` | The two IDs are equal, so `err.query` is filled in. |
| `filter isNotNull(err.query)` | `err.query` has a value, so the request row is kept. |

**Result row:**

| timestamp | src | query | content |
|---|---|---|---|
| 2026-10-15T09:12:04.210+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `5d6e7f80-91a2-4b3c-8d4e-5f6a7b8c9d0e` | `... Sending request to /esb/ebroker/inswebauto/online/_quote` |

**Near miss (would NOT match):** an inswebauto request line with `[requestId=0a1b2c3d-4e5f-4061-8273-94a5b6c7d8e9]` is dropped because that request got a normal answer and has no timeout line, so `err.query` stays empty.

---

### #79 Inswebbike Quote Requests That Hit The Pc Quote Timeout

**Sample records that match:** two esbv4 records share the request ID `7e8f9a0b-1c2d-4e3f-9a4b-5c6d7e8f9a0b`.

Outer record (the request line):

```
timestamp: 2026-10-15T09:12:04.210+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:04,210 INFO [http-nio-8080-exec-2] c.e.esb.EbrokerRouter - [requestId=7e8f9a0b-1c2d-4e3f-9a4b-5c6d7e8f9a0b] Sending request to /esb/ebroker/inswebbike/online/_quote
```

Inner record (the timeout line):

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-2] c.e.esb.ErrorHandler - [requestId=7e8f9a0b-1c2d-4e3f-9a4b-5c6d7e8f9a0b] Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` (outer) | The outer `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Sending request to /esb/ebroker/inswebbike/online/_quote", caseSensitive:false)` (outer) | The outer content has the `inswebbike` path. |
| `parse content, "LD (...UUID...):query"` (outer) | The outer `query` is `7e8f9a0b-1c2d-4e3f-9a4b-5c6d7e8f9a0b`. |
| `filter startsWith(src, "esbv4")` (inner) | The inner record also comes from esbv4. |
| `filter contains(content, "Error(esb-ebroker.xml) description: ... failed: Timeout exceeded.", caseSensitive:false)` (inner) | The inner content has the full timeout phrase word for word. |
| `parse content, "LD (...UUID...):query"` (inner) | The inner `query` is the same UUID. |
| `filter isNotNull(query)` (inner) | The inner ID was found. |
| `dedup query` (inner) | One inner row for this ID. |
| `lookup [...], sourceField:query, lookupField:query, prefix:"err."` | The two IDs are equal, so `err.query` is filled in. |
| `filter isNotNull(err.query)` | `err.query` has a value, so the request row is kept. |

**Result row:**

| timestamp | src | query | content |
|---|---|---|---|
| 2026-10-15T09:12:04.210+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `7e8f9a0b-1c2d-4e3f-9a4b-5c6d7e8f9a0b` | `... Sending request to /esb/ebroker/inswebbike/online/_quote` |

**Near miss (would NOT match):** an inswebbike request line with `[requestId=1f2e3d4c-5b6a-4798-8a7b-6c5d4e3f2a1b]` is dropped because no timeout line has that ID, so `err.query` stays empty.

---

### #80 Kakakucomauto Quote Requests That Hit The Pc Quote Timeout

**Sample records that match:** two esbv4 records share the request ID `b4c5d6e7-f809-4a1b-9c2d-3e4f5a6b7c8d`.

Outer record (the request line):

```
timestamp: 2026-10-15T09:12:04.210+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:04,210 INFO [http-nio-8080-exec-5] c.e.esb.EbrokerRouter - [requestId=b4c5d6e7-f809-4a1b-9c2d-3e4f5a6b7c8d] Sending request to /esb/ebroker/kakakucomauto/online/_quote
```

Inner record (the timeout line):

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-33-08.ap-northeast-1.compute.internal
k8s.pod.name: esbv4-7c9d8b6f5-k2m4p
k8s.container.name: esbv4
content: 2026-10-15 09:12:34,567 ERROR [http-nio-8080-exec-5] c.e.esb.ErrorHandler - [requestId=b4c5d6e7-f809-4a1b-9c2d-3e4f5a6b7c8d] Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.
```

| DQL line | Why this sample passes |
|---|---|
| `filter startsWith(src, "esbv4")` (outer) | The outer `src` is `esbv4-7c9d8b6f5-k2m4p`. |
| `filter contains(content, "Sending request to /esb/ebroker/kakakucomauto/online/_quote", caseSensitive:false)` (outer) | The outer content has the `kakakucomauto` path. |
| `parse content, "LD (...UUID...):query"` (outer) | The outer `query` is `b4c5d6e7-f809-4a1b-9c2d-3e4f5a6b7c8d`. |
| `filter startsWith(src, "esbv4")` (inner) | The inner record also comes from esbv4. |
| `filter contains(content, "Error(esb-ebroker.xml) description: ... failed: Timeout exceeded.", caseSensitive:false)` (inner) | The inner content has the full timeout phrase word for word. |
| `parse content, "LD (...UUID...):query"` (inner) | The inner `query` is the same UUID. |
| `filter isNotNull(query)` (inner) | The inner ID was found. |
| `dedup query` (inner) | One inner row for this ID. |
| `lookup [...], sourceField:query, lookupField:query, prefix:"err."` | The two IDs are equal, so `err.query` is filled in. |
| `filter isNotNull(err.query)` | `err.query` has a value, so the request row is kept. |

**Result row:**

| timestamp | src | query | content |
|---|---|---|---|
| 2026-10-15T09:12:04.210+09:00 | `esbv4-7c9d8b6f5-k2m4p` | `b4c5d6e7-f809-4a1b-9c2d-3e4f5a6b7c8d` | `... Sending request to /esb/ebroker/kakakucomauto/online/_quote` |

**Near miss (would NOT match):** a kakakucomauto request line with `[requestId=2c3d4e5f-6a7b-4c8d-9e0f-1a2b3c4d5e6f]` is dropped because no timeout line has that ID, so `err.query` stays empty.

---

### #81 Ebroker SSL Certificate Expiring Within 30 Days

This query reads a lookup file, not logs. For this query, assume it was run at `2026-10-15T09:30:00+09:00`, which is `2026-10-15T00:30:00Z`.

**Sample record that matches:** one row in `/lookups/sslcert_lookup`.

```
dest: ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa
ssl_end_time: 1793836800
```

`1793836800` Unix seconds is `2026-11-05T00:00:00Z`, which is `2026-11-05T09:00:00+09:00`.

| DQL line | Why this sample passes |
|---|---|
| `load "/lookups/sslcert_lookup"` | The row lives in the uploaded lookup file. |
| `filter dest == "ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa"` | `dest` is exactly the ebroker host name. |
| `fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))` | `1793836800` becomes the time `2026-11-05T00:00:00Z`. |
| `fieldsAdd days_left = toLong((ssl_end - now()) / 1d)` | The gap from `2026-10-15T00:30:00Z` to `2026-11-05T00:00:00Z` is 20 days and 23.5 hours, about 20.98 days. `toLong` drops the fraction, so `days_left` is 20. |
| `filter ssl_end < now() + 30d` | `now() + 30d` is `2026-11-14T00:30:00Z`. The end date of 5 November is earlier, so the row is kept. This is the same as "days to expiry is under 30". |

**Result row:**

| dest | ssl_end | days_left |
|---|---|---|
| `ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa` | 2026-11-05T00:00:00Z | 20 |

**Near miss (would NOT match):** a row with `ssl_end_time: 1798675200` (`2026-12-31T00:00:00Z`) is dropped because it is about 77 days away, which is later than `now() + 30d`.

---

### Before #82 to #85: These Return 0 Today

The portals-amp-backend logs are not in Dynatrace yet, so #82 to #85 return 0 rows today. The samples below show what a record would look like after portals-amp is onboarded.

In the samples, `content` is written exactly as stored, with a backslash before every inner double quote (`\"`).

---

### #82 Portals-Amp-Backend Errors On Save, Coverages, Quote, Bind

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-36-14.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6d7c8b9a5-h5j6k
log.source: /var/log/containers/portals-amp-backend-6d7c8b9a5-h5j6k_amp_portals-amp-backend.log
k8s.container.name: portals-amp-backend
content: {\"level\":\"error\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/quote\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\",\"request_id\":\"req-20261015-000417\",\"target_system\":\"pc\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `filter contains(k8s.container.name, "portals-amp-backend") or contains(k8s.pod.name, ...) or contains(log.source, ...)` | The container name is `portals-amp-backend`, so the first check is true. |
| `fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | The inner call turns every `\"` into `"`. The outer call removes any backslash still left, and here none are left. `raw` becomes `{"level":"error","message":{"url":"https://portals-amp-backend.example.internal/api/quote",...}}`. |
| `parse raw, "JSON:j"` | `raw` is now valid JSON, so it is stored in `j`. |
| `fieldsAdd msg_url = toString(j[message][url]), level = toString(j[level])` | `j[message][url]` is the `url` inside `message`, so `msg_url` is `https://portals-amp-backend.example.internal/api/quote`. `level` is `error`. |
| `filter endsWith(msg_url, "/save") or ... endsWith(msg_url, "/quote") or ...` | `msg_url` ends with `/quote`. |
| `filter lower(level) == "error"` | `lower("error")` is `error`. |

**Result row:**

| timestamp | msg_url | level | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `https://portals-amp-backend.example.internal/api/quote` | `error` | `{"level":"error","message":{"url":".../api/quote","type":"CAUGHT_EXCEPTION_ON_BACKEND",...}}` |

**Near miss (would NOT match):** the same record with `\"url\":\"https://portals-amp-backend.example.internal/api/quote?id=1\"` is dropped because the URL ends with `?id=1`, not `/quote`. A trailing slash such as `/api/quote/` is dropped for the same reason.

---

### #83 PayWithCreditCard Caught Exception On Backend

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-36-14.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6d7c8b9a5-h5j6k
log.source: /var/log/containers/portals-amp-backend-6d7c8b9a5-h5j6k_amp_portals-amp-backend.log
k8s.container.name: portals-amp-backend
content: {\"level\":\"error\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\",\"request_id\":\"req-20261015-000512\",\"target_system\":\"payment-gateway\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `filter contains(k8s.container.name, "portals-amp-backend") or ...` | The container name is `portals-amp-backend`. |
| `fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | Every `\"` becomes `"`, so `raw` is valid JSON. |
| `parse raw, "JSON:j"` | The JSON is stored in `j`. |
| `fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])` | `msg_url` is `https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj`. `msg_type` is `CAUGHT_EXCEPTION_ON_BACKEND`. |
| `filter contains(msg_url, "payWithCreditCard_Adj") and ...` | The URL contains `payWithCreditCard_Adj` with the same upper and lower case. |
| `... and msg_type == "CAUGHT_EXCEPTION_ON_BACKEND"` | `msg_type` is exactly `CAUGHT_EXCEPTION_ON_BACKEND` in upper case. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj` | `CAUGHT_EXCEPTION_ON_BACKEND` | `{"level":"error","message":{"url":".../payWithCreditCard_Adj","type":"CAUGHT_EXCEPTION_ON_BACKEND",...}}` |

**Near miss (would NOT match):** the same record with `\"type\":\"caught_exception_on_backend\"` is dropped because `==` is case-sensitive and the lower-case type is not equal.

---

### #84 PayWithCreditCard Execution Completed One Day

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-36-14.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6d7c8b9a5-h5j6k
log.source: /var/log/containers/portals-amp-backend-6d7c8b9a5-h5j6k_amp_portals-amp-backend.log
k8s.container.name: portals-amp-backend
content: {\"level\":\"info\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj\",\"type\":\"EXECUTION_COMPLETED\",\"request_id\":\"req-20261015-000513\",\"target_system\":\"payment-gateway\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `filter contains(k8s.container.name, "portals-amp-backend") or ...` | The container name is `portals-amp-backend`. |
| `fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")` | Every `\"` becomes `"`, so `raw` is valid JSON. |
| `parse raw, "JSON:j"` | The JSON is stored in `j`. |
| `fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])` | `msg_url` ends in `payWithCreditCard_Adj`. `msg_type` is `EXECUTION_COMPLETED`. |
| `filter contains(msg_url, "payWithCreditCard_Adj") and ...` | The URL contains `payWithCreditCard_Adj`. |
| `... and msg_type == "EXECUTION_COMPLETED"` | `msg_type` is exactly `EXECUTION_COMPLETED`. |

**Result row:**

| timestamp | msg_url | msg_type | raw |
|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj` | `EXECUTION_COMPLETED` | `{"level":"info","message":{"url":".../payWithCreditCard_Adj","type":"EXECUTION_COMPLETED",...}}` |

**Near miss (would NOT match):** the same record with `\"url\":\"https://portals-amp-backend.example.internal/api/payment/paywithcreditcard_adj\"` is dropped because `contains` without `caseSensitive:false` needs the exact case `payWithCreditCard_Adj`.

---

### #85 PayWithCreditCard Execution Completed One Hour

**Sample record that matches:**

```
timestamp: 2026-10-15T09:12:34.567+09:00
host.name: ip-10-20-36-14.ap-northeast-1.compute.internal
k8s.pod.name: portals-amp-backend-6d7c8b9a5-h5j6k
log.source: /var/log/containers/portals-amp-backend-6d7c8b9a5-h5j6k_amp_portals-amp-backend.log
k8s.container.name: portals-amp-backend
content: {\"level\":\"info\",\"message\":{\"url\":\"https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj\",\"type\":\"EXECUTION_COMPLETED\",\"request_id\":\"req-20261015-000514\",\"target_system\":\"payment-gateway\"}}
```

| DQL line | Why this sample passes |
|---|---|
| `fetch logs, from:now()-1h` | The record is at 09:12:34, which is inside the hour before 09:30:00. |
| `filter contains(content, "payWithCreditCard_Adj")` | The raw content already has `payWithCreditCard_Adj` in the exact case. |
| `filter contains(k8s.container.name, "portals-amp")` | The container name `portals-amp-backend` contains `portals-amp`. |
| `or contains(k8s.pod.name, "portals-amp")` | Also true, but not needed because the container check already passed. |
| `or contains(log.source, "portals-amp")` | Also true, but not needed. |
| `or contains(host.name, "portals-amp")` | False here, because the host is a node name. It does not matter because one true check is enough. |
| `fieldsAdd raw = replaceString(content, "\\\"", "\"")` | Every `\"` becomes `"`. The content has no other backslashes, so `raw` is valid JSON with only this one fix. |
| `parse raw, "JSON:j"` | The JSON is stored in `j`. |
| `fieldsAdd msg_url = toString(j[message][url]),` | `msg_url` is `https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj`. |
| `msg_type = toString(j[message][type]),` | `msg_type` is `EXECUTION_COMPLETED`. |
| `request_id = toString(j[message][request_id]),` | `request_id` is `req-20261015-000514`. |
| `target_system = toString(j[message][target_system])` | `target_system` is `payment-gateway`. |
| `filter contains(msg_url, "payWithCreditCard_Adj")` | The URL contains the operation name. |
| `filter msg_type == "EXECUTION_COMPLETED"` | `msg_type` is exactly `EXECUTION_COMPLETED`. |

**Result row:**

| timestamp | msg_type | request_id | target_system | msg_url |
|---|---|---|---|---|
| 2026-10-15T09:12:34.567+09:00 | `EXECUTION_COMPLETED` | `req-20261015-000514` | `payment-gateway` | `https://portals-amp-backend.example.internal/api/payment/payWithCreditCard_Adj` |

**Near miss (would NOT match):** the same record escaped twice, starting `{\\\"level\\\":\\\"info\\\",...`, is dropped because this query only turns `\"` into `"`, so a stray backslash is left before every quote, the JSON parse fails, `msg_url` stays empty, and the `contains(msg_url, ...)` check fails.

---

### Notes On Samples I Am Less Sure About

| Query | What to double-check |
|---|---|
| #65 | If DPL's `LD` grabs as much text as it can before `DIGIT+`, `claimNumber` could come out as `6/004512` instead of `2026/004512`. The row still matches, but test the parse on one real line. |
| #67 | The sample assumes `INT` reads `2026`, `10`, and `15` as separate numbers split by the literal dashes. Test the parse on one real line if the result is 0. |
| #81 | The sample assumes `toLong` drops the fraction of 20.98 days and gives 20. If it rounds instead, `days_left` shows 21. The row is kept either way. |


---

## Data flow map

```
sample record (timestamp, host.name, k8s.pod.name, content)
 → src = lower(coalesce(pod, host))   → prefix check
 → text filters                       → contains / matchesPhrase / not
 → parse / replaceString + JSON:j     → extracted fields
 → lookup (outer ID = inner ID)       → only for #72, #77 to #80
 → summarize                          → only for count queries
 → result row
```

## Related files

| File | Purpose |
|---|---|
| `17-dql-1-to-85-match-examples.md` | This document |
| `part-1-01-30.md` | Samples for #1 to #30 |
| `part-2-31-60.md` | Samples for #31 to #60 |
| `part-3-61-85.md` | Samples for #61 to #85 |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Samples that need confirming |
| `2-result.md` | How to use the samples |
| `3-glossary.md` | Terms |
| `17.sh` | Git one-liners (not run) |
| 2026-10-15 answer 16 | The DQL line-by-line explanation these samples are based on |

## Commands

See `17.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/17-dql-1-to-85-match-examples
git commit -m "dql 1 to 85 match examples"
git push
```
