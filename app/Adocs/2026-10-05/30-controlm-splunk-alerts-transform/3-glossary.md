# Control-M Alerts Glossary

| Term | What it means | Why you care |
|---|---|---|
| Control-M | BMC's batch job scheduler | Source of every alert here |
| activejobs | Periodic snapshot of each job's state | The same run appears many times, so dedup matters |
| order_id | ID of one job run | Group by this, not job_name, to follow a single run |
| odate | Control-M order date (business date) | Used for "yesterday's run" reports |
| Ended not OK | Control-M status for a failed job (abend) | The real incident signal |
| Lookup file | CSV stored in Grail under `/lookups/` | Replaces Splunk `inputlookup` and `lookup` |
| `load` | DQL command that reads a lookup file | Used inside `lookup [ ... ]` |
| `with_items` | Workflow task loop over a list | Sends one email per job |
| First seen in slot | Report an event only when its first appearance falls in the latest schedule slot | Exactly-once emails without a throttle |
| `takeLast` | DQL aggregation that keeps the last value | Latest status of a run |
| `for_each` | Terraform loop that makes one resource per map entry | Four daily reports from one block |
