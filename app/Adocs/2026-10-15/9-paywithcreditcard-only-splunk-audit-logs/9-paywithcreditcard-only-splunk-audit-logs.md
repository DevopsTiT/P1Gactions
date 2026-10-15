# PayWithCreditCard Only Splunk Audit Logs

## Decision tree

```
Step 1 found 3 rows for "payWithCreditCard_Adj"
 log.source = /app/splunk/var/log/splunk/... ?
  yes → these are the Splunk servers' own logs of YOUR Splunk searches
       → not portals-amp application logs
       → Step 2 and Step 3 = 0 is correct
       → portals-amp is not in Dynatrace → onboarding request
  no → real app logs → use that pod or container name in Step 2
```

## Short takeaway

| Question | Answer |
|---|---|
| Did Step 1 find the app logs? | No. All 3 rows come from Splunk server log files. |
| What are those rows? | Splunk's own records of the searches you ran, which contain the text "payWithCreditCard_Adj". |
| Why do Step 2 and Step 3 return 0? | There are no portals-amp logs in Dynatrace to match. The query is fine. |
| What fixes it? | Onboarding portals-amp-backend logs to Dynatrace, not changing the DQL. |

## Summary

The only matches in Dynatrace are lines from `remote_searches.log` and `splunkd_ui_access.log` on Splunk servers. Those files record searches typed into Splunk, so they contain the word you searched for. The real portals-amp-backend logs (68 events in Splunk) are not in Dynatrace. This confirms the 2026-10-14 finding.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `log.source` | The file path or stream the log line came from. |
| `remote_searches.log` | Splunk internal file that records searches sent to Splunk search peers. |
| `splunkd_ui_access.log` | Splunk internal file that records web UI requests, including search text. |
| Onboarding | Setting up log shipping so a service's logs reach Dynatrace. |

### Evidence

| Check | Result |
|---|---|
| Step 1 rows | 3 |
| Row 1 | host `ceaa20c0.prprivmgmt.intraxa`, source `/app/splunk/var/log/splunk/remote_searches.log`, count 6 |
| Row 2 | host `ceaa20c6.prprivmgmt.intraxa`, source `/app/splunk/var/log/splunk/remote_searches.log`, count 6 |
| Row 3 | host `WPALJA2195.prprivmgmt.intraxa`, source `/app/splunk/var/log/splunk/splunkd_ui_access.log`, count 2 |
| k8s fields | All null, so none of these rows come from Kubernetes pods. |
| Step 2 (EXECUTION_COMPLETED) | 0 records, 5.09 GiB scanned |
| Step 3 (CAUGHT_EXCEPTION_ON_BACKEND) | 0 records, 5.10 GiB scanned |
| Splunk same hour | 68 events |

## Result

Stop tuning the query. Send the portals-amp onboarding request (the draft is in 2026-10-14 answer 21). After onboarding, Step 2 from answer 8 should work as written.

Optional confirmation queries are in `9-paywithcreditcard-only-splunk-audit-logs.dql`.

| Query | What it confirms |
|---|---|
| Check A | Removes Splunk's own files. Expect 0 rows. |
| Check B | Any portals-amp log at all in 24 hours. Expect 0 rows. |

## Data flow map

```
portals-amp-backend pods → JSON logs → forwarder → S3 → Splunk   (68 events)
                                                  ✗ Dynatrace     (not onboarded)

You search in Splunk → Splunk writes remote_searches.log and splunkd_ui_access.log
 → Splunk servers have OneAgent → those files reach Dynatrace
 → that is why Step 1 found 3 rows
```

## Related files

| File | Purpose |
|---|---|
| `9-paywithcreditcard-only-splunk-audit-logs.dql` | Check A and Check B |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Evidence table |
| `2-result.md` | Next step |
| `3-glossary.md` | Terms |
| `9.sh` | Git one-liners (not run) |

## Commands

See `9.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/9-paywithcreditcard-only-splunk-audit-logs
git commit -m "paywithcreditcard only splunk audit logs"
git push
```
