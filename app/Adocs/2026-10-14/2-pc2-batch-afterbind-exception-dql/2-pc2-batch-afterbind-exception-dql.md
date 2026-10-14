# PC2 Batch AfterBind Exception DQL

## Decision tree

```
Splunk: index="pc2-batch" host="pc*" | search "Exception occured for job" AND "during afterBind_Adj process" | fields + _raw
 index="pc2-batch"      → no index in Dynatrace → use the host prefix
 host="pc*"             → only 2 hosts: pc2-batch-inssuite-prod-0 and -1 → startsWith "pc2-batch-inssuite-prod-"
 "..." AND "..."        → two contains(), joined by and, case ignored
 fields + _raw          → fields timestamp, host.name, content
 main query empty?
   → check 1: are pc2-batch logs in Dynatrace at all?
       no → same gap as eopt (S3 to Splunk only) → onboarding request
       yes → check 2: phrase only → copy the field that holds the pod name
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | Log lines that say "Exception occured for job" and "during afterBind_Adj process" from the pc2 batch pods. |
| Hosts | pc2-batch-inssuite-prod-0 and pc2-batch-inssuite-prod-1. |
| Spelling | Keep "occured" as written. The app logs it with that spelling. |
| Main risk | Splunk gets these logs from S3 `axa-gi-jp-logforwarders-prod`. They may not be in Dynatrace, like eopt. |

## Summary

The search keeps two phrases from the pc2 batch pods and shows only the raw line. In DQL that is a host filter, two `contains()` checks joined by `and`, and a `fields` list. The host names look like Kubernetes pod names, so the filter checks both `host.name` and `k8s.pod.name`.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| `index` | Splunk's storage bucket for a group of logs. | Dynatrace has no index. Filter by host or source instead. |
| `host="pc*"` | Any host starting with "pc". | In this index only two pods match. |
| `fields + _raw` | Keep only the raw line. | DQL `fields` keeps the columns you list. |
| `k8s.pod.name` | Kubernetes pod name field on forwarded logs. | Pod names may be here instead of `host.name`. |
| `-0` and `-1` suffix | Typical StatefulSet pod names (fixed numbered pods). | The prefix stays the same, so `startsWith` is safe. |

### What the screenshots show

| Item | Value |
|---|---|
| Base search | `index="pc2-batch" host="pc*"` |
| Events | 1,314,737 |
| Host 1 | pc2-batch-inssuite-prod-1 (825,823 events, 62.19%) |
| Host 2 | pc2-batch-inssuite-prod-0 (502,075 events, 37.81%) |
| Source | s3://axa-gi-jp-logforwarders-prod/2026/10/14/... |
| Line format | `2026-10-14 09:16:38,299 INFO [MW-Writer[66]-4] KPI.Messaging ...` |
| Target search | `search "Exception occured for job" AND "during afterBind_Adj process" \| fields + _raw` |

### Splunk to DQL

| Splunk | DQL | Note |
|---|---|---|
| `index="pc2-batch"` | Not needed. | The host filter already limits it to pc2 batch pods. |
| `host="pc*"` | `startsWith(host.name, "pc2-batch-inssuite-prod-") or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")` | Narrower than `pc*`, but covers both hosts seen. |
| `search "Exception occured for job"` | `contains(content, "Exception occured for job", caseSensitive:false)` | Splunk search ignores case. |
| `AND "during afterBind_Adj process"` | `and contains(content, "during afterBind_Adj process", caseSensitive:false)` | Both phrases must be in the line. |
| `fields + _raw` | `fields timestamp, host.name, k8s.pod.name, content` | Time and host added so the rows make sense. Remove them if you want only `content`. |
| Time picker | `fetch logs, from:now()-24h` | Change to match your range. |

## Result

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "pc2-batch-inssuite-prod-")
    or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")
| filter contains(content, "Exception occured for job", caseSensitive:false)
    and contains(content, "during afterBind_Adj process", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

Exact Splunk output (raw line only):

```
fetch logs, from:now()-24h
| filter startsWith(host.name, "pc2-batch-inssuite-prod-")
    or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")
| filter contains(content, "Exception occured for job", caseSensitive:false)
    and contains(content, "during afterBind_Adj process", caseSensitive:false)
| fields content
```

### If it returns 0

| Check | Result | Meaning |
|---|---|---|
| Check 1 (pc2-batch in any field) | 0 | pc2 batch logs are not in Dynatrace. Same gap as eopt. Ask the platform team to forward them. |
| Check 1 | Rows | Logs exist. Look at which field holds the pod name and use it. |
| Check 2 (phrase only, 7 days) | Rows | The phrase exists. Copy the host or pod value from the result. |
| Check 2 | 0 | Either no such errors in 7 days, or logs are missing. Check 1 tells which. |

Both checks and a per-day count query are in the `.dql` file.

## Data flow map

```
pc2-batch-inssuite-prod-0 / -1 (pods)
  → S3 axa-gi-jp-logforwarders-prod → Splunk ✔ (confirmed)
  → Dynatrace Grail ? (check 1)
        → fetch logs, last 24 h
        → keep pc2-batch-inssuite-prod-* pods
        → keep lines with both phrases
        → newest first → time, host, pod, line
```

## Related files

| File | What it holds |
|---|---|
| `2-pc2-batch-afterbind-exception-dql.dql` | Main query, two checks and a per-day count. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the screenshots show. |
| `2-result.md` | Final query and what to do if empty. |
| `3-glossary.md` | Words used. |
| `2.sh` | Git one-liners. |
| `Daily Files/2026-10-13/3-find-missing-app-logs-logic/` | Steps if the logs are missing. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`2.sh`](./2.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/2-pc2-batch-afterbind-exception-dql
git commit -m "PC2 batch afterBind exception DQL"
git push
```
