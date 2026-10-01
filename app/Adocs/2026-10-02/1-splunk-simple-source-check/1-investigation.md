# Investigation

| What was checked | Finding |
|---|---|
| Earlier answer (seq 49 on 2026-10-01) | Correct but long; uses makeresults, append and stats |
| tstats | Fastest option; returns only sources that have events |
| metadata | Very fast summary; counts are approximate |
| Plain search with stats | Works but scans raw events, so it is slow |
