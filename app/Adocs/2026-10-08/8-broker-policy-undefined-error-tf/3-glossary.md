# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Cannot read properties of undefined | JavaScript error when code reads a field from an empty value | A burst usually means a bug or bad data after a release |
| OCP | OpenShift Container Platform, Red Hat's Kubernetes | The pods run there; the alert says to check pod status |
| `timechart span=1m count` | Splunk count per minute | Replaced by `summarize ... by bin(timestamp, 1m)` |
| `bin(timestamp, 1m)` | DQL rounds each timestamp down to the minute | Groups lines into one-minute buckets |
| `where count > 50` | Keep only busy minutes | Same as `filter count > 50` |
| Records detector | Opens a problem when the query returns rows | No `makeTimeseries` needed |
