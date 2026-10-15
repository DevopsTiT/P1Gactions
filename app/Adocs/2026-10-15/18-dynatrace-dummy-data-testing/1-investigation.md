# Dynatrace Dummy Data Investigation

| Option | Stored in Grail? | Needs a token? | Can fire alerts? | Cleanup |
|---|---|---|---|---|
| `data` command | No | No | No | Nothing to clean |
| Log ingest API | Yes | Yes, `logs.ingest` | Yes | Stays until retention ends |
| Metrics ingest API | Yes | Yes, `metrics.ingest` | Yes, if a metric event matches | Stays until retention ends |
| Lookup upload | Yes, as a file | Yes, storage write permission | No | Delete the file |
