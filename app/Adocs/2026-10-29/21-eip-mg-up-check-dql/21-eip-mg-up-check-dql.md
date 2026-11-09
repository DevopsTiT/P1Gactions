# EIP MG UP Check Tile

```
Splunk panel for DCI (Keppel)
  index eip1015
  sourcetype eip_mg_up_check
  two hosts
    WPALJA21BC.prprivngmt.intraxa
    WPALJA21B9.prprivngmt.intraxa
  table columns host and MG_Result.MG_Status
  window Last 3 minutes
  this run → 2 events, one per host
Dynatrace
  discovery query first
  table tile locked to the last 3 minutes
  one row per host
  empty last_seen → no UP-check event in that window
```

| Key point | Detail |
|---|---|
| Panel | A table, not a single number. The visible title fragment is DCI (Keppel). |
| Search | `index=eip1015 sourcetype=eip_mg_up_check` for two hosts. |
| Columns | `host` and `MG_Result.MG_Status`. |
| Window | Last 3 minutes. This run is 4:13:53 PM to 4:16:53 PM. |
| This run | 2 events. One for each host. |
| Refresh | No auto refresh. A progress bar shows while a search runs. |

## Summary

This Splunk panel lists the latest UP-check row for two Keppel hosts over the last 3 minutes. In Dynatrace, add a table tile whose DQL is locked to the last 3 minutes. Each row is one host. A blank `last_seen` means that host sent no UP-check event in the window.

## Investigation

| Source | Finding |
|---|---|
| Search | `index=eip1015 sourcetype=eip_mg_up_check` with `host="WPALJA21BC.prprivngmt.intraxa"` OR `host="WPALJA21B9.prprivngmt.intraxa"`. |
| Table command | `table host MG_Result.MG_Status`. |
| Time range control | Use time picker, and the window used here is Last 3 minutes. |
| Auto refresh | No auto refresh. |
| Refresh indicator | Progress bar. |
| Result | 2 events. 10/29/2026 4:13:53 PM to 4:16:53 PM. |
| Host values | `WPALJA21B9.prprivngmt.intraxa` 1 event. `WPALJA21BC.prprivngmt.intraxa` 1 event. |
| Event text | `EIP UP Check` plus the host short name. Sourcetype `eip_mg_up_check`. |

The status values in `MG_Result.MG_Status` are not visible on these screens. The table query keeps the log line until that field name is confirmed.

## Result

### Check the log

In Notebooks, run:

```
fetch logs, from: now()-3m
| filter contains(log.source, "eip_mg_up_check", caseSensitive:false)
    or contains(content, "EIP UP Check", caseSensitive:false)
| limit 5
```

No rows means Dynatrace does not have this UP-check log yet. The Splunk sourcetype is `eip_mg_up_check`. Open one of the five rows and find the field that matches `MG_Result.MG_Status`.

### Table query

This keeps both hosts on the table. `from: now()-3m` locks the tile to 3 minutes, which is this panel’s window.

```
data record(unit = "WPALJA21BC"), record(unit = "WPALJA21B9")
| lookup [
    fetch logs, from: now()-3m
    | filter contains(log.source, "eip_mg_up_check", caseSensitive:false)
        or contains(content, "EIP UP Check", caseSensitive:false)
    | fieldsAdd unit = if(contains(host.name, "WPALJA21BC", caseSensitive:false) or contains(content, "WPALJA21BC", caseSensitive:false), "WPALJA21BC", else: if(contains(host.name, "WPALJA21B9", caseSensitive:false) or contains(content, "WPALJA21B9", caseSensitive:false), "WPALJA21B9", else: null))
    | filter isNotNull(unit)
    | sort timestamp desc
    | summarize last_seen = takeFirst(timestamp), line = takeFirst(content), by: { unit }
  ], sourceField: unit, lookupField: unit
| fields unit, last_seen, line
```

| Column | What it means |
|---|---|
| `unit` | `WPALJA21BC` or `WPALJA21B9`. |
| `last_seen` | Time of the newest UP-check event for that host. |
| `line` | That event’s text, until you swap in `MG_Result.MG_Status`. |

A blank `last_seen` means no UP-check event for that host in the last 3 minutes. This run in Splunk had one event for each host.

When the discovery rows show the status field, change `line = takeFirst(content)` to `mg_status = takeFirst(MG_Result.MG_Status)` and add `mg_status` to the `fields` line. Use the field name Dynatrace actually stored.

### Dashboard

1. Open Dashboards.
2. Create a dashboard, or open the incident helper dashboard.
3. Add a DQL tile and paste the table query.
4. Choose the Table visualization.
5. Title the tile `EIP MG UP check`. The Splunk panel sits in the DCI (Keppel) area.
6. Leave dashboard auto-refresh off to match this panel. The query still uses the last 3 minutes because `from: now()-3m` is inside it.
7. Save.

The progress bar in Splunk is the wait while the search runs. The Dynatrace tile shows its own loading state.

`from: now()-3m` does not follow a 15-minute dashboard picker. That matches this panel. The API Gateway failure tile was built to follow the shared picker. This UP-check tile stays on 3 minutes.

## Data flow map

```
eip_mg_up_check events
 index eip1015
 last 3 minutes
        |
        +--> WPALJA21BC.prprivngmt.intraxa
        |      this run: 1 event
        |
        +--> WPALJA21B9.prprivngmt.intraxa
               this run: 1 event
        |
        v
Dynatrace table
 unit, last_seen, line
 blank last_seen = no event in 3 minutes
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the two screenshots show. |
| `2-result.md` | The DQL and the dashboard steps. |
| `3-glossary.md` | Terms. |
| `21-eip-mg-up-check-dql-follow.txt` | Same steps for mobile. |
| `21.sh` | Copy commands. |

Commands: [21.sh](21.sh)
