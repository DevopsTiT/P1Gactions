# Outlier Investigation

| What I checked | What I found |
|---|---|
| Sourcetype | text:jenkins, which is missing. |
| Job | HTTP Monitor - AGGW LB. |
| Method | 10-minute max, median ± 20 × MAD. |
| head 1 | Oldest bucket. |
| Action | Email to one person, "[TEST]" subject. |
