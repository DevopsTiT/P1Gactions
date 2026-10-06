# Datalake Batch Result Investigation

| What was checked | Finding |
|---|---|
| Splunk event source | `/app/splunk/var/log/splunk/datalake_transfer.log` |
| Splunk event host | `ceaa20bd.prprivmgmt.intraxa`. Older lines show upper case `CEAA20BD`. |
| Splunk sourcetype | `datalake_transfer` |
| Event count | 240 in 30 days, which is 8 lines per night |
| Batch time | About 02:00 JST, all lines in the same second |
| Seq 11 filter | Used the Splunk index name, which does not exist in Dynatrace |
| Recurring failure | `Failed to delete Data LINEBOT.csv` every night |
