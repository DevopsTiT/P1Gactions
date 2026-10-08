# Investigation

| What was checked | Finding |
|---|---|
| Dialog type | Edit Search (report), not Edit Alert |
| Search input | `inputlookup monitor_logs` |
| Filter | Yesterday only |
| Output | OK, NG, Maintenance counts per application |
| Destination | `collect` into `monitoring_summary_idx`, sourcetype `application_summary` |
| Summary index content | 46 rows at 10/8 01:00:18 from host CEAA2101 |
| Notification | None |
