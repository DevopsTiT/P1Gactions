# Jenkins URL Monitor With Host Filter

## Decision tree

```
Seq 10 query had no host condition
 Jenkins server fixed? → yes, ceaa2099.prprivmgmt.intraxa (every line in the search)
  → add filter matchesValue(host.name, "ceaa2099*") as the first filter
 Why matchesValue?
  wildcard covers the short and full name (ceaa2099, ceaa2099.prprivmgmt.intraxa)
  case-insensitive → also matches CEAA2099
 Host shows differently in Dynatrace? → check query 1 → adjust the pattern
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from seq 10? | One new line: `filter matchesValue(host.name, "ceaa2099*")` |
| Why? | The Jenkins server is fixed, so only its logs should be read |
| Benefit | Less data scanned every minute; no false matches from other hosts logging "[HTTP Monitor]" |
| Everything else | Same as seq 10 |
| Apply with seq 10? | No. Same resource name; apply only this one. |

## Summary

The detector now reads only logs from the Jenkins server ceaa2099 before looking for `[HTTP Monitor]` lines. The rest of the logic (2 or more failures, no 200, per application and check, paging split) is unchanged.

## Query now

```
fetch logs, from:now()-15m
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(log.source, "/console")
| filter contains(content, "[HTTP Monitor]")
| fieldsAdd src = replaceString(replaceString(log.source, "job/", ""), "%20", " ")
| parse src, "LD:name '/' INT '/console'"
| parse content, "LD 'status' LD INT:responsecode"
| lookup [ load "/lookups/jenkins/configuration" ], sourceField:name, lookupField:job_name, prefix:"cfg.", fields:{ application, pager_duty }
| fieldsAdd application = coalesce(cfg.application, "-"), pager_duty = coalesce(toString(cfg.pager_duty), "1")
| summarize fails = countIf(responsecode != 200), oks = countIf(responsecode == 200),
            last_code = takeLast(responsecode), last_seen = max(timestamp),
            by:{ application, name, pager_duty }
| filter fails >= 2 and oks == 0
| filter pager_duty != "0"      (page detector; no_page uses == "0")
```

## Data flow

```
ceaa2099 (Jenkins) → console logs → Dynatrace
 → filter host ceaa2099 → "[HTTP Monitor]" lines
   → per application + check: fails >= 2, no 200 → problem
   → first 200 → problem closes
```

## Investigation

| What was checked | Finding |
|---|---|
| Search screenshot (seq 10) | host = ceaa2099.prprivmgmt.intraxa on every visible line |
| Seq 10 query | Filtered by source and content only |
| User | Host name is fixed |

## Result

| Step | What to do |
|---|---|
| 1 | Run check query 1 to see how the host appears in Dynatrace |
| 2 | Use this file instead of seq 10 |
| 3 | Other steps from seq 10 still apply (lookup upload, status position, maintenance macro) |

## Related files

| File | Purpose |
|---|---|
| `11-jenkins-url-monitor-host-filter-tf.tf` | Detectors with host filter |
| `11-jenkins-url-monitor-host-filter-tf-check.dql` | Check queries |
| `11.sh` | Commands |

## Commands

See `11.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/11-jenkins-url-monitor-host-filter-tf"
terraform init
terraform validate
terraform plan
```
