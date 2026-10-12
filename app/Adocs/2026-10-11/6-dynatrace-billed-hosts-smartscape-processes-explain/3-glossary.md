# Billed Hosts, Smartscape And Processes Glossary

| Term | What it means | Why you care |
|---|---|---|
| Interval | Time slice of each point. | Widened automatically when there are too many. |
| countDistinct | Counts different values. | Billed hosts per slice. |
| smartscapeNodes | Reads the Smartscape topology from Grail. | Lists AWS resources. |
| Aggregation | count, sum, avg, max and similar. | summarize needs one. |
| Davis event | A finding on an entity, such as process unavailable. | Health column. |
| Davis problem | Related events grouped as one incident. | Investigation mode. |
| dt.davis.events.snapshots | Every saved state of each event. | dedup keeps the newest. |
| executionOrder:leftFirst | Run the main query first, then the lookup. | Faster lookups. |
| union:true | Keep a series if any metric has data. | Finds host and group for every process. |
| ebpfHasPublicTraffic | Process talks to the internet, seen by eBPF. | Security view. |
| ctm-ag-uploader.jar | Control-M agent part that uploads job output. | The process being checked. |
| p_ctmat | Another Control-M agent process. | Commented out in the query. |
