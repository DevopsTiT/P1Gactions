# Dynatrace Failure Count Tile

```
Same number as APIGateway FAILURE
  are these logs in Dynatrace?
    discovery query returns no rows → ingest the server.log path first
    rows come back → which field holds the status text
  count tile
    log path apigw5500/server.log
    status text FAILURE
    dashboard time Last 15 minutes
    show 0 when nothing matches
  color → 1 and above red
  refresh → 1 minute
  host table → same filters, split by host.name
  success tile → same query, status text SUCCESS
```

| Key point | Detail |
|---|---|
| Splunk constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Dynatrace equivalent | A DQL tile that counts those failure lines. |
| Log file | `/opt/softwareag/log/1015/apigw5500/server.log`. |
| Time | Dashboard time picker set to Last 15 minutes. |
| Zero | The query keeps a 0 so an empty window still shows a number. |
| Page | One dashboard. One tile per Splunk box. |

## Summary

Build this in a Dynatrace dashboard. Each Splunk box becomes one tile that follows the dashboard time picker. The failure tile counts log lines from the API Gateway server log whose text contains `Status: FAILURE`. Set the picker to Last 15 minutes and refresh every minute. Run the short discovery query first. If it returns no rows, that log file is not in Dynatrace yet.

## Investigation

| Source | Finding |
|---|---|
| Splunk data model | `APIGW1015_Failure_count`. |
| Constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Raw status text | A visible event contains `Status: SUCCESS`, so the failure line uses the same `Status:` text. |
| Log path | `/opt/softwareag/log/1015/apigw5500/server.log`. |
| Hosts on the Splunk field window | `WPLALJ2BF`, `WPLALJ2CB`, `WPLALJ2BC`, `WPLALJ2BB`, domain `prprivngt.intraxa`. |
| Splunk panel time | Shared picker, Last 15 minutes, refresh every 1 minute. |

The open Splunk search without `Status=FAILURE` counted successes too. The Dynatrace tile keeps the failure filter.

## Result

A tile is one query and one picture, the same idea as a Splunk panel. The dashboard time picker is the shared clock, the same idea as `searchByTimer`.

### 1. Check that the log is in Dynatrace

Open **Notebooks**. Add a **DQL** section. Set the time picker to **Last 15 minutes**. Run:

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| limit 5
```

| Result | What you do |
|---|---|
| Five log rows | Go to the count tile. Read one row and confirm the status text looks like `Status: FAILURE`. |
| No rows | Dynatrace does not have this file yet. Add a log ingest rule for `/opt/softwareag/log/1015/apigw5500/server.log` on the mediator hosts, then run this query again. |

`log.source` is the field Dynatrace uses for the log path or logger name. If the five rows come from a different field, use that field in the count query instead of `log.source`.

### 2. Create the dashboard

1. Open **Dashboards**.
2. Create a dashboard. Name it EIP DIS Incident Helper.
3. Set the time picker to **Last 15 minutes**.
4. Set auto-refresh to **1 minute**.
5. Add a tile. Choose **DQL**.
6. Paste the failure query below.
7. Choose the **Single value** visualization. Bind it to `failure_count`.
8. Title the tile `APIGateway FAILURE`.
9. Set the color threshold: **1 and above is red**. **0** stays a calm color.
10. Save.

```
data record(failure_count = 0)
| append [
    fetch logs
    | filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
    | filter contains(content, "Status: FAILURE", caseSensitive:false)
    | summarize failure_count = count()
  ]
| summarize failure_count = sum(failure_count)
```

Leave `from:` out of `fetch logs`. The tile then follows the dashboard time picker. Last 15 minutes on the picker is the Splunk window.

The first line plants a 0. The append adds the real count when failure lines exist. The last line adds them together. An empty window stays **0**. A blank tile means the query failed or the visualization has no field selected.

`content` is the log line. The Splunk event text uses `Status: SUCCESS`, so the failure filter uses `Status: FAILURE`. `caseSensitive:false` keeps `failure` and `FAILURE` together.

### 3. Success tile

Duplicate the tile. Title it `APIGateway SUCCESS`. Change the status text and the field name.

```
data record(success_count = 0)
| append [
    fetch logs
    | filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
    | filter contains(content, "Status: SUCCESS", caseSensitive:false)
    | summarize success_count = count()
  ]
| summarize success_count = sum(success_count)
```

Color this one green. A green **0** means no success lines in the window.

### 4. Failures by host

Add a tile. Choose the **Table** visualization.

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| filter contains(content, "Status: FAILURE", caseSensitive:false)
| summarize failure_count = count(), by: { host.name }
| sort failure_count desc
```

`host.name` is the host Dynatrace attached to the log. If that column is empty, the machine name is only inside the line. Use the four names from Splunk while you confirm the field:

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| filter contains(content, "Status: FAILURE", caseSensitive:false)
| filter contains(content, "WPLALJ2BF", caseSensitive:false)
    or contains(content, "WPLALJ2CB", caseSensitive:false)
    or contains(content, "WPLALJ2BC", caseSensitive:false)
    or contains(content, "WPLALJ2BB", caseSensitive:false)
| summarize failure_count = count()
```

That last query is one total for those four names. It is the fallback while `host.name` is empty.

### 5. The other Splunk boxes

IS Success, IS Failure, and ND Mode use different Splunk searches. Duplicate this tile after you open each Splunk Edit Search, and change the filter to that box’s constraint. The layout stays one tile per box, all on the same time picker.

## Data flow map

```
server.log on the mediator hosts
 /opt/softwareag/log/1015/apigw5500/server.log
        |
        v
Dynatrace log ingest
        |
        v
Dashboard time picker = Last 15 minutes
 refresh every 1 minute
        |
        +--> failure tile
        |      log path + Status: FAILURE
        |      single value failure_count
        |      1 and above = red
        |
        +--> success tile
        |      same path + Status: SUCCESS
        |      green
        |
        +--> host table
               same failure filter
               one row per host.name
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | The Splunk facts this tile copies. |
| `2-result.md` | The DQL to paste. |
| `3-glossary.md` | Terms. |
| `12-dynatrace-failure-count-tile-follow.txt` | Same steps for mobile. |
| `12.sh` | Copy commands. |

Commands: [12.sh](12.sh)
