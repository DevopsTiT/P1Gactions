# Glossary

| Term | What it means |
|---|---|
| index | A storage bucket in Splunk where events are kept, like `aaa` |
| source | Where an event came from, usually a file path like `/var/log/app/a.log` |
| tstats | A command that reads index summaries (tsidx files) instead of raw events, so it is fast |
| tsidx | The index lookup files Splunk builds for each bucket |
| metadata | A command that lists sources, hosts or sourcetypes with first and last seen times |
| makeresults | Creates fake rows so you can inject your own list |
| mvexpand | Splits one multi-value field into separate rows |
| append | Adds the results of a subsearch below the main results |
| time range | The window Splunk searches; sources outside it look missing |
