# Glossary

| Term | What it means |
|---|---|
| Query box | The four-line editor under Data type. This is the text the alert runs. |
| 0 records | The metric stored no points in that time range. The condition stays false. |
| `timeseries cpu` | The first words of the query that already returned a line. |
| Below 101 | The CPU line is under 20, so this condition is already true. |
| `{dt.entity.host}` | Copies the host id from the query row onto the problem. Keep the braces. |
| `TESTDUMMY host entity` | The title to search for in Problems. Disable the alert after it appears. |
