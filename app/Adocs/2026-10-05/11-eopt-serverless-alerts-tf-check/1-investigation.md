# Investigation

| What was checked | Finding |
|---|---|
| Alert 1 | Log group eopt-serverless-prod, parse level, ERROR only, every 5 minutes, email etool_maintenance |
| Alert 2 | Same query, daily at 10:00 over 24 hours, email etool_maintenance and chungyueh.chiu |
| Resource type | Both `dynatrace_log_alert`, not in the provider |
| Parse | Skips four hyphens then takes the next word after whitespace; matches Node.js default Lambda lines only |
| `limit 100` in the daily alert | Would hide the real total if there are more than 100 errors |
| Secrets | None |
