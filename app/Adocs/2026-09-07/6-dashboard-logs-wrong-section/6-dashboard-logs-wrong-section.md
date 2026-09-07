# Dashboard Logs Wrong Section

Add a **LOGS** section that shows **wrong logs** (ERROR / FATAL / Exception / fail / 5xx / timeout).

| Key point | Detail |
| --- | --- |
| Live log tables | Import `App-Wrong-Logs-Dashboards.json` (new Dashboards) |
| Classic Must-watch | Updated JSON adds a LOGS header + how-to markdown |
| App choose | Variable / filter `app` = All or any app name |

## Files

| File | Use |
| --- | --- |
| `App-Wrong-Logs-Dashboards.json` | **Import this** for live wrong-log tiles |
| `App-Must-Should-Watch-Classic.json` | Classic board + LOGS section notes |
| `wrong-logs.dql` | Same queries for Logs app / Notebooks |
| `6.sh` | Open paths |

## Import (logs board)

1. Dynatrace → **Dashboards** (new) → Upload / paste `App-Wrong-Logs-Dashboards.json`
2. Name: **App-Wrong-Logs**
3. Set `app=All` or any app
4. Keep Classic **App-Must-Should-Watch** for metrics; use this for log evidence

## What “wrong logs” means here

| Signal | Meaning |
| --- | --- |
| ERROR / FATAL | Explicit error level |
| Exception / Traceback / OOM | Crash / stack evidence |
| failed / FAILURE / timeout / 5xx | Failure keywords in content |

## Tiles on App-Wrong-Logs

| Tile | Shows |
| --- | --- |
| Wrong logs — ERROR / FATAL | Table of bad lines |
| Wrong logs — count by host | Which hosts are noisy |
| Exception / Traceback | Stack-style lines |
| fail / 5xx / timeout | Failure keywords |
| Wrong-log volume | Single count (0 = good) |
