# 1 Investigation

| Check | Finding |
|-------|---------|
| Topic | Dynatrace log PII filtering / masking |
| Primary control order | App → OneAgent capture → OpenPipeline ingest → Grail store |
| Weakest if used alone | DQL query-time mask (does not erase Grail) |
| Official docs | Dynatrace “Mask sensitive data in logs” + OneAgent sensitive data masking |
| Built-in OneAgent email/card rules | Exist but often off until enabled |
| Adocs/Files status before today backfill | Adocs had main md + sh + follow; missing 0/1/2/3 companions; Files missing folder |

## Evidence used

- Existing answer pack `1-dynatrace-logs-pii-filter.md` (defense-in-depth, OpenPipeline steps, OneAgent steps, DQL examples)
- Companion `1.sh` verification DQL one-liners
