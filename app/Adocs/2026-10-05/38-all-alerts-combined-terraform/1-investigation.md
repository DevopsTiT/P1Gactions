# Investigation

| Checked | Evidence |
|---|---|
| tf files today | Seq 4 to 37, 33 files |
| Latest versions chosen | Cisco seq 22, OUD seq 26, Control-M seq 31 |
| Left out | Seq 4, 21, 25, 30, 37 and both house-style files |
| Resource blocks in combined file | 51: 24 detectors, 25 workflows, 2 log event rules |
| Duplicate resource addresses | None |
| Duplicate locals | None among included files |
| Variables | `cdus_pagerduty_routing_key` and `bre_pagerduty_routing_key`, both sensitive, no default |
| Seq 35 placeholder | `{violating_samples}` is not a Dynatrace placeholder |
| Seq 35 series | 1-minute max can be sparse; 5 of 10 may never be reached |
| Seq 34 and 36 | `{dims:...}` placeholders valid; settings match Splunk |
