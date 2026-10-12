# Dynatrace Notebook Queries Part 2 Result

| Cell | Verdict | Fix |
|---|---|---|
| A | Syntax error | Use softwareTechnologies |
| B | Works, cut | Summarize by version, limit 10000 |
| C | SQL, not DQL | timeseries with from, to, interval:1h |
| D | Works, misses older problems | Problems from 7 days, limit 10000 |
| F | Null column | Lookup host table |
| G | Works | limit 10000 |
