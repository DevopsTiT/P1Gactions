# Dynatrace Notebook Queries Pic

```
Cell 1: timeseries by process_group     → 1 record, OK (6h buckets; use interval:1h)
Cell 2: timeseries by instance + PROCESS_GROUP- ID → 0 records (wrong ID type)
          fix → filter dt.entity.process_group
Cell 3: fetch logs | loglevel == ERROR → 642 rows, mostly Qualys agent
          fix → summarize by log.source, exclude qualys
Cell 4: fetch process_group_instance NODE_JS → 574 processes, not hosts
          fix → summarize by host, lookup name
```

```
HOST → PROCESS_GROUP_INSTANCE → PROCESS_GROUP
OneAgent → metrics / logs / entities → Notebook cells
```
