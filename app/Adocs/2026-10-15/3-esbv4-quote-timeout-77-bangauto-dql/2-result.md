# ESBv4 Quote Timeout 77 Result

Use `3-esbv4-quote-timeout-77-bangauto-dql-77-bangauto.dql`.

| Outcome | What to do |
|---|---|
| List query returns rows | Note the times and request IDs, then check the pc-inssuite quote service around those times. |
| List query returns 0 rows | Run the count query in the same file. |
| Count shows requests = 0 | Confirm esbv4 logs exist in Dynatrace before trusting the result. |
| Count shows timed_out = 0 | bangauto had no quote timeouts in the last 24 hours. |
