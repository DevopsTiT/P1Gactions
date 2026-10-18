# Splunk To DQL Queries 17-19

## Decision tree

```
Which Splunk block?
  17 (internal metrics.log thruput)
    → No 1:1 Splunk _internal in Dynatrace
    → Approx: top log.source by count (timeseries) OR use ingest metrics if licensed
  18 (metadata type=hosts, stale > 1h)
    → Closest: summarize last log timestamp by host.name
    → Alt: dt.entity.host monitoring freshness (OneAgent hosts)
  19 (index=esbv4 + NetSuite error string)
    → filter content + host/namespace/pod/bucket contains esbv4
```

## Short takeaway

| # | Splunk idea | DQL approach |
|---|---|---|
| 17 | Top thruput sources from `_internal` | Approx top `log.source` by event count (not exact eps×kb/kbps) |
| 18 | Hosts with no data > 1 hour | `summarize max(timestamp) by host` then age > 1h; filter `%-prod-%`, exclude `amazonaws` |
| 19 | Index + exact error phrase | `contains(content, "…")` plus esbv4 on host/k8s/bucket |

## Summary

Query **18** is the one that still needed a full transform: Splunk `metadata type=hosts` becomes a **last-seen-by-host** DQL over logs (or entity hosts). Queries **17** and **19** already had DQL sketches in your file; cleaned versions are below. Dynatrace has no Splunk `_internal` or `metadata type=hosts` API.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| `metadata type=hosts` | Splunk catalog of hosts + last event time | Not available in DQL; rebuild from logs or entities |
| `recentTime` / Last_Seen | Seconds since last data | In DQL: `now() - max(timestamp)` |
| `log.source` | Where the log stream came from | Stand-in for Splunk source / sourcetype pieces |
| `dt.entity.host` | Monitored host entity in Dynatrace | Alternate for “host not reporting” if OneAgent is the truth |

---

### Query 17 — DQL (approximation)

Splunk used `_internal` metrics thruput (`eps*kb/kbps`). Dynatrace cannot run that exact math on Splunk’s internal index. Closest **ops** view: busiest log sources by count.

```dql
fetch logs, from:now()-1h
| makeTimeseries events = count(), by:{ log.source }, interval:1m
| fieldsAdd total = arraySum(events)
| sort total desc
| limit 5
```

If you ingest **log ingest volume** metrics, prefer those over this approximation (tenant-specific metric keys).

---

### Query 18 — DQL (main transform)

**Splunk intent:** list hosts whose last event is older than **1 hour**, show lag in minutes/hours/days, keep only host names like `%-prod-%`, drop `amazonaws`.

#### Option A — last log from each host (closest to index metadata)

```dql
fetch logs, from:now()-7d
| filter matchesPhrase(host.name, "-prod-")
| filter not matchesPhrase(host.name, "amazonaws")
| summarize last_event = max(timestamp), by:{ host.name }
| fieldsAdd behind = now() - last_event
| filter behind > 1h
| fieldsAdd minutes_behind = toLong(behind) / 60000000000
| fieldsAdd hours_behind = toDouble(toLong(behind)) / 3600000000000
| fieldsAdd days_behind = toDouble(toLong(behind)) / 86400000000000
| fieldsAdd last_event_fmt = formatTimestamp(last_event, format:"yyyy-MM-dd HH:mm:ss z")
| fields host.name, last_event_fmt, minutes_behind, hours_behind, days_behind
| sort hours_behind desc
```

**Simpler age math** (if your tenant accepts duration helpers):

```dql
fetch logs, from:now()-7d
| filter matchesPhrase(host.name, "-prod-")
| filter not matchesPhrase(host.name, "amazonaws")
| summarize last_event = max(timestamp), by:{ host.name }
| fieldsAdd behind = now() - last_event
| filter behind > 1h
| fieldsAdd minutes_behind = behind / 1m
| fieldsAdd hours_behind = behind / 1h
| fieldsAdd days_behind = behind / 1d
| fieldsAdd last_event_fmt = formatTimestamp(last_event, format:"yyyy-MM-dd HH:mm:ss z")
| fields host.name, last_event_fmt, minutes_behind, hours_behind, days_behind
| sort hours_behind desc
```

If `host.name` is empty, switch filters/`by` to `host`.

#### Option B — monitored hosts (OneAgent), not log index

Use when “silent host” means monitoring stopped, not “no log lines”:

```dql
fetch dt.entity.host
| fields id, entity.name
// Then join or filter using host availability / last metric sample in a follow-up timeseries query
// Example pattern: hosts with no CPU sample in the last hour do not appear in:
// timeseries avg(dt.host.cpu.usage), by:{dt.entity.host}, from:now()-1h, to:now()
```

Practical check for Option B:

```dql
timeseries avg(dt.host.cpu.usage), by:{ dt.entity.host }, from:now()-2h, interval:5m
| fieldsAdd entityName = entityName(dt.entity.host)
| filter matchesPhrase(entityName, "-prod-")
| filter not matchesPhrase(entityName, "amazonaws")
```

Hosts missing from that result for a long window are candidates for “not seen” (compare against a full host inventory separately).

---

### Query 19 — DQL (cleaned)

```dql
fetch logs, from:now()-24h
| filter contains(host.name, "esbv4", caseSensitive:false)
    or contains(k8s.namespace.name, "esbv4", caseSensitive:false)
    or contains(k8s.pod.name, "esbv4", caseSensitive:false)
    or contains(dt.system.bucket, "esbv4", caseSensitive:false)
| filter contains(
    content,
    "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443",
    caseSensitive:false
  )
| sort timestamp desc
```

Narrower if `esbv4` is only a log bucket / app id:

```dql
fetch logs, from:now()-24h
| filter matchesValue(dt.system.bucket, "esbv4")
    or matchesPhrase(content, "esbv4")
| filter matchesPhrase(
    content,
    "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443"
  )
| sort timestamp desc
```

## Result

| Query | Status |
|---|---|
| 17 | Approx DQL (top log sources); not exact Splunk thruput formula |
| 18 | Full DQL for stale prod hosts via last log time |
| 19 | DQL filter for NetSuite HTTP error + esbv4 scope |

## Data flow map

```
18 Splunk metadata hosts
  → last event time per host
  → age = now - last
  → age > 1h
  → filter %-prod-%, not amazonaws
  → table host, last event, minutes/hours/days behind

18 DQL
  fetch logs
  → filter prod / not amazonaws
  → summarize max(timestamp) by host.name
  → behind = now() - last_event
  → filter behind > 1h
  → fields lag columns
```

## Related files

| File | Purpose |
|---|---|
| `2-splunk-to-dql-queries-17-19.md` | This guide |
| `2-splunk-to-dql-queries-17-19.dql` | Pasteable DQL |
| `../1-splunk-to-dql-biloss-queries/` | Earlier queries 8–11 |
| `2.sh` | Git one-liners (not run) |

## Commands

See `2.sh`. None have been run. Paste into Dynatrace Notebooks / Logs yourself.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-19/2-splunk-to-dql-queries-17-19
git commit -m "splunk to dql queries 17-19"
git push
```
