# Result

1. Paste search 1 from `48-splunk-check-sources-in-index.spl`, set `index=<your_index>`, run.
2. FOUND rows: check `last_seen` is recent.
3. NOT FOUND rows: run search 2 (rotation), 3 (other index), 4 (all time), 5 (forwarder logs).
4. Still missing: on the server run `splunk btool inputs list --debug` and `splunk list monitor`.
