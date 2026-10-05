# Investigation

| Checked | Evidence |
|---|---|
| Splunk migration tf files today | Seq 27, 28, 29, 30, 31, 32, 34, 35, 36 |
| Seq 30 | Replaced by seq 31 (v2), so left out |
| Seq 33 | WeChat question, no tf |
| Resource blocks in the combined file | 17 blocks, all unique names |
| Objects after for_each | 5 OpenPaaS, 3 IWFM, 2 Jenkins, 4 Control-M daily reports, plus 7 single resources: 21 total |
| Local values | No clashing names across the four locals blocks |
| Variables and secrets | None |
| Provider block | Added once at the top (same as seq 4) |
