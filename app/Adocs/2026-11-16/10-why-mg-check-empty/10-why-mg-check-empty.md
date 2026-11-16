# Why MG Check Is Empty

```
DQL filtered log.source for EIP UP Check
  that text is the Splunk source field
  Dynatrace log.source is a different field
        |
        v
no rows
        |
        v
search the line text over 24 hours
  MG_Result
  EIP UP Check
        |
        +-- rows come back --> read log.source, then use that field
        |
        +-- still 0 --> these checks are not in Dynatrace yet
```

| Filter that was used | What happened |
|---|---|
| `log.source` contains `EIP UP Check` | Splunk stores that text in `source`. It is not proven to be in Dynatrace `log.source`. |
| `from: now()-3m` | Only the last 3 minutes. The 992 events are spread across about 25 hours. |

## Summary

The query looked for `EIP UP Check` in `log.source`. On the Splunk screen that text is the `source` field, and the line body is an `MG_Result` object. Dynatrace did not match those rows. Search the line text over 24 hours first. The last 3 minutes is the panel window, after the rows are found.

## Investigation

Splunk returned 992 events from 2026-11-15 10:00 through 2026-11-16 10:50.

| Source | Count |
|---|---|
| `eip_mg_up_check://EIP UP Check WPALJA21B9` | 496 |
| `eip_mg_up_check://EIP UP Check WPALJA21BC` | 496 |

An opened event shows:

```
host = WPALJA21BC.prprivmgmt.intraxa
source = eip_mg_up_check://EIP UP Check WPALJA21BC
{ MG_Result: { ... } }
```

`MG_Result.MG_Status` is inside that object. The screenshot leaves the object closed, so the status word is not visible.

The panel uses Last 3 minutes. About 496 events per host in 25 hours is roughly one event every 3 minutes. A 3-minute window can be empty when the filter is wrong, and it can also be empty when the newest check has not arrived yet. The 24-hour text search separates those two cases.

Earlier `sql-monitoring` rows used `log.source` = `sql-monitoring`, not the Splunk source name. The same split can be true here.

## Result

Paste this. It searches the line text and `log.source` for the last 24 hours.

```
fetch logs, from: now()-24h
| filter contains(content, "MG_Result", caseSensitive:false)
    or contains(content, "EIP UP Check", caseSensitive:false)
    or contains(log.source, "EIP UP Check", caseSensitive:false)
    or contains(content, "eip_mg_up_check", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| sort timestamp desc
| limit 20
```

Read `log.source` and `content` on the rows that come back.

| What you see | What to do |
|---|---|
| Rows, and `log.source` is a file path or `sql-monitoring` | Keep using `content` for `MG_Result`. Do not require `EIP UP Check` inside `log.source`. |
| Rows, and `log.source` contains `EIP UP Check` | The first filter was only too short. Run it again with `from: now()-24h`. |
| 0 records | These up-check events are not in Dynatrace for this window. |

After rows exist, the panel window is:

```
fetch logs, from: now()-3m
| filter contains(content, "MG_Result", caseSensitive:false)
| fields timestamp, host.name, log.source, content
| sort timestamp desc
```

## Data flow map

```
Splunk source
  eip_mg_up_check://EIP UP Check WPALJA21BC
  body MG_Result { }
        |
        v
DQL looked in log.source
        |
        v
no match
        |
        v
search content for MG_Result
  last 24 hours
```

## Related files

| File | Purpose |
|---|---|
| `10-why-mg-check-empty.dql` | The 24-hour search and the 3-minute follow-up. |
| `0-pic.md` | Why the filter matched nothing. |
| `1-investigation.md` | The Splunk source values and the event body. |
| `2-result.md` | The query that looks in the line text. |
| `3-glossary.md` | The words. |
| `10-why-mg-check-empty-follow.txt` | The same steps for a phone. |
| `10.sh` | Copy commands. |

Commands: [10.sh](10.sh)
