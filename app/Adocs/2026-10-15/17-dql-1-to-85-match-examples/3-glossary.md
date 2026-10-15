# DQL Match Examples Glossary

| Term | What it means |
|---|---|
| Sample record | A made-up record used to show what a query matches. |
| Near miss | A record that almost matches but is dropped by one filter. |
| Case-sensitive | `ERROR` and `error` are treated as different text. |
| Whole word | `matchesPhrase` needs the word to stand alone, not inside a longer word. |
| Greedy capture | A parse piece such as `ALNUM` takes as many matching characters as it can. |
| Escaped JSON | JSON with `\"` instead of `"`, fixed by `replaceString`. |
| UUID | An ID shaped like 8-4-4-4-12 hex characters, used to join request and timeout lines. |
| Lookup file | A table uploaded to Dynatrace, read with `load`. |
| Metric data point | A number recorded over time, read with `timeseries`. |
