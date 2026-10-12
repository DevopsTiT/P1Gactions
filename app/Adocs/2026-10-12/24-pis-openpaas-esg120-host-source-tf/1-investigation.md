# PIS OpenPaaS ESG120 Investigation

| What was checked | Finding |
|---|---|
| Alert | PIS Connection issue (Batch->OpenPaaS) Alert |
| Search | `index=claims host="CEAA20B8.prprivmgmt.intraxa" sourcetype=pis_defaultlog \| regex _raw = "\"errorCode\":\s\"ESG120\""` |
| Host spelling | Alert screen reads CEAA2088, event list reads CEAA20B8. |
| Source | /IFDATA/DATA/PC/LOG/PISP2/pisp2.log |
| Event text | errorCode ESG120, errorMessage Routing failed |
| Time range | Last 5 minutes, cron every 5 minutes |
| Trigger | Results greater than 0, once |
| Action | Email only, Normal. Recipient not copied. |
| Matches | 18 of 2,106,626 events |
