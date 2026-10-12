# Control-M Job Update Detector Investigation

| What I looked at | What it shows |
|---|---|
| Seq 79 tf on 2026-10-08 | The detector query and identity fields |
| Splunk screenshot | Sources, field building, stats by job_id and table_id, append for successors |
| Splunk schedule | Every 30 minutes over 60 minutes, so duplicates without identity fields |
| Cut-off part | The end of the Splunk search is not visible |
