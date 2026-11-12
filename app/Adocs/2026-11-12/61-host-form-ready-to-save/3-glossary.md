# Glossary

| Term | What it means |
|---|---|
| Violating samples | How many points inside the window must be below 101 before Davis opens the event. |
| Sliding window | How many recent points Davis looks at. Here that number is 5. |
| Preview | A chart of this alert. The CPU line should sit under the line drawn at 101. |
| `{dt.entity.host}` | Copies the host id from the query onto the problem. The braces stay. |
| `{dt.smartscape_source.id}` | A placeholder for a column this query does not have. Remove that row. |
| Problems | The page that lists the opened problem. This test does not send email. |
