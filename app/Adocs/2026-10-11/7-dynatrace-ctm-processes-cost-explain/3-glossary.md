# Control-M Processes And Cost Glossary

| Term | What it means | Why you care |
|---|---|---|
| p_ctmag | Control-M agent listener. | Receives jobs from the server. |
| p_ctmat | Control-M agent tracker. | Sends job status back. |
| ctm-ag-uploader.jar | Agent part that uploads job output. | Checked in the Processes query. |
| Availability | Percent of time a process was running. | 100 means never down in the window. |
| interval in nanoseconds | DQL stores bucket length in ns. | 60,000,000,000 ns is one minute. |
| containerRecord | Container the process ran in. | Null means a normal server. |
| prefix | Text put in front of lookup field names. | Gives host.id, host.host_name. |
| Cost allocation | Splitting billed usage by product or cost center tags. | Shows each team's share. |
| dt.cost.product | Product tag used for the split. | The query keeps EIP. |
| data json | A small table typed inside the query. | Holds the price list. |
| GiB-hour | Memory size times hours monitored. | Full-Stack billing unit. |
| Host-hour | One host for one hour. | Infrastructure billing unit. |
