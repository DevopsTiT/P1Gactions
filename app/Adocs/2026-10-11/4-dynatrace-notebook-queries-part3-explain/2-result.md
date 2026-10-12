# Dynatrace Notebook Queries Part 3 Result

| Cell | Verdict | Fix |
|---|---|---|
| G | Works, cut | limit 10000 |
| H | Works | Filter after expand |
| I | Wrong filter value | osType == "WINDOWS" |
| J | Exact tag match fails | Check tags, use contains() |
