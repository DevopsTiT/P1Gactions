# 2 Result

## What to do (order)

| Step | Action |
|------|--------|
| 1 | Stop logging PII in the application logger |
| 2 | Enable OneAgent sensitive data masking for capture paths |
| 3 | Add OpenPipeline processors (mask / remove fields / drop) before Grail |
| 4 | Use Sensitive Data Center if PII already stored |
| 5 | Use DQL query masks only as analyst safety net |

## Deliverables for seq 1

| File | Role |
|------|------|
| `1-dynatrace-logs-pii-filter.md` | Full answer |
| `0-pic.md` | Decision trees |
| `1-investigation.md` | This investigation |
| `2-result.md` | This result |
| `3-glossary.md` | Terms |
| `1.sh` | Verification DQL |
| `1-dynatrace-logs-pii-filter-follow.txt` | Mobile follow |

## Dual-write roots

- Files: `/Users/k/Work/AIProjects/Files/2026-08-28/1-dynatrace-logs-pii-filter/`
- Adocs: `.../app/Adocs/2026-08-28/1-dynatrace-logs-pii-filter/`
