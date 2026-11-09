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
