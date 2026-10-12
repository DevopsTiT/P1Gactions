# Dynatrace Notebook Queries Result

| Cell | Verdict | Fix |
|---|---|---|
| 1 | Correct | Optional interval:1h |
| 2 | Wrong ID type | Filter dt.entity.process_group |
| 3 | Noisy | Group by log.source, exclude Qualys |
| 4 | Processes, not hosts | Summarize by host |
