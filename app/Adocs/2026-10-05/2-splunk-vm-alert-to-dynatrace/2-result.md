# Result

| Step | Do this |
|---|---|
| 1 | Run the Step 1 DQL to confirm the VM logs and field names |
| 2 | Create an OpenPipeline Davis event rule (any line) or an Anomaly Detection alert (threshold) |
| 3 | Link the event to the host with `dt.source_entity` so AGO tags reach the SILVA workflow |
| 4 | Test with `eventcreate` on the VM and watch the problem, SILVA ticket and PD alert |
| 5 | Paste the real Splunk SPL if it has extra filters, for an exact conversion |
