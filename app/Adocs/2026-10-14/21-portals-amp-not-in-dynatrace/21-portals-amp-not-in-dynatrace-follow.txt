# Portals AMP Not In Dynatrace

## Decision tree

```
Check query: "portals-amp" in host, pod, container, log.source → 0 records (171 GiB scanned)
 Check A: search the text "payWithCreditCard_Adj" with no source filter
   rows found? → name lives in another field → use that field
   0? → go on
 Check B: list buckets you can see
   expected bucket missing? → permission problem → ask for access
   all there? → go on
 Check C / D: does Dynatrace see the pods or workload?
   yes → app is monitored, but logs are not forwarded → onboarding request
   no → app not monitored at all → same request, plus OneAgent coverage question
 Result (expected): logs go pod → S3 → Splunk only, same as eopt
   → send the request in 21-...-request.txt
   → DQL for #20, #23–#28, #82–#85 waits for onboarding
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the screen show? | 0 records for "portals-amp" across four name fields, 24 hours, 171 GiB scanned. |
| Is that a query mistake? | Unlikely. The query is broad and uses `caseSensitive:false`. |
| Most likely reason | portals-amp logs are not forwarded to Dynatrace. Splunk gets them from S3. |
| Before concluding | Run checks A and B to rule out other field names and permissions. |
| What to do | Send the onboarding request (English and Japanese draft included). |
| Which DQL is blocked? | #20, #23 to #28, #82 to #85. |

## Summary

The search scanned 171 GiB and found nothing with "portals-amp" in any name field. Splunk proves the app is busy (75 payment events an hour), so the data exists but is not reaching Dynatrace. This is the same gap we found for eopt: the logs only travel through the S3 forwarder to Splunk. Two quick checks rule out the other explanations, then the fix is an onboarding request to add the app's namespace to the Dynatrace log forwarder.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Scanned bytes | How much log data Grail read to answer the query. |
| 0 records | Nothing matched the filters. |
| Bucket | A storage area in Grail. Access can be limited per bucket. |
| ClusterLogForwarder | OpenShift setting that decides which namespaces send logs where. |
| Onboarding | Adding an app's logs to Dynatrace. |
| App-only OneAgent | Dynatrace agent inside the pod. It reports the pod as a host. |

### Reading the screen

| Part | What it shows | What it means |
|---|---|---|
| Query lines 2 to 5 | `contains(... "portals-amp", caseSensitive:false)` on host, pod, container, log.source | A wide net. Any spelling or case would match. |
| Line 6 | `summarize lines = count(), by:{...}` | Would show one row per place the name appears. |
| `0 records` | No row at all | The name does not appear in any of the four fields. |
| Timeframe | 10/13 16:34 to 10/14 16:34 | A full day, so this is not a quiet-hour issue. |
| Scanned bytes 171.29 GiB | A lot of data was read | The query really searched. It did not fail early. |
| "Try adjusting the timeframe, segment, data or permissions" | Standard Dynatrace hint | Reminds us to rule out permissions (check B). |

### Evidence so far

| Source | What it shows |
|---|---|
| Splunk screenshot (answer 19) | 75 events in 1 hour from pods `portals-amp-backend-...`. |
| Splunk `source` field | `s3://axa-gi-jp-logforwarders-prod/...`. Logs go through S3. |
| This Dynatrace query | 0 records in 24 hours. |
| Earlier eopt finding (2026-10-13) | Same pattern: S3 path only, namespace not in the Dynatrace forwarder. |

### The checks to finish the proof

| Check | What it rules out | Query |
|---|---|---|
| A. Text search with no source filter | The app name is stored in a field we did not check. | `filter contains(content, "payWithCreditCard_Adj")` |
| B. Buckets you can see | You lack permission for the bucket that holds these logs. | `summarize count() by dt.system.bucket` |
| C. Host entities | Whether Dynatrace sees the pods at all. | `fetch dt.entity.host` with name filter |
| D. Kubernetes workload | Which namespace the app runs in (needed for the request). | `fetch dt.entity.cloud_application` with name filter |
| E. Other portals apps | Which portals apps are onboarded already. | `startsWith(src, "portals")` count |

## Result

| If you see | Meaning | Next step |
|---|---|---|
| Check A finds rows | The logs exist under another name. | Change the DQL source filter to that field. |
| Check B misses a bucket | Permission gap. | Ask for read access to that bucket. |
| A and B show nothing unusual | The logs are not in Dynatrace. | Send the onboarding request. |
| Check D shows a namespace | You know which namespace to add. | Put the namespace name in the request. |

Request draft: `21-portals-amp-not-in-dynatrace-request.txt` (English and Japanese).

Blocked DQL until onboarding: #20, #23 to #28, #82 to #85 (portals-amp-frontend and portals-amp-backend).

## Data flow map

```
Today
  portals-amp-backend pods
    -> S3 log forwarder (axa-gi-jp-logforwarders-prod)
    -> Splunk  (75 events per hour)
    -X-> Dynatrace  (0 records)

After onboarding
  portals-amp-backend pods
    -> OpenShift ClusterLogForwarder (Dynatrace output, namespace added)
    -> Dynatrace logs ingest
    -> Grail
    -> DQL from answer 19 works
```

## Related files

| File | What it holds |
|---|---|
| `21-portals-amp-not-in-dynatrace.dql` | Checks A to E |
| `21-portals-amp-not-in-dynatrace-request.txt` | Onboarding request, English and Japanese |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Evidence |
| `2-result.md` | Next steps |
| `3-glossary.md` | Glossary |
| `21.sh` | Git one-liners |

## Commands

See `21.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/21-portals-amp-not-in-dynatrace
git commit -m "Portals AMP not in Dynatrace"
git push
```
