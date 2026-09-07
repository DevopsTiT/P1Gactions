# Identify Error Logs Manually From Dashboard

```
See something wrong on the dashboard (Problems / Errors % / red host)?
  │
  ├─ 1 Open that Problem or service/host from the tile
  ├─ 2 Go to Logs (or Logs and events)
  ├─ 3 Filter ERROR / Exception manually
  ├─ 4 Narrow by time + host/service / app
  └─ 5 Read 1–2 sample lines → confirm real error vs noise
```

| Key point | Detail |
| --- | --- |
| Goal | Manually find **error logs** that explain the dashboard alert |
| Do not need first | A LOGS markdown tile or a second “Wrong-Logs” JSON board |
| Where | Dynatrace **Logs** app (from the same timeframe as the dashboard) |

## Summary

Your Classic board shows **symptoms** (Problems, error rate, CPU). To identify **errors in logs**, leave that board, open **Logs**, and filter by time + ERROR/Exception + the same host/service/app. Do this by hand before building any log dashboard.

## Manual steps (do this first)

### Step 1 — Note what the dashboard shows

| On the board | Write down |
| --- | --- |
| Time range | e.g. Last 2 hours (same as dashboard) |
| App filter | empty = all, or tag `app:<name>` |
| Clue | Problem title, service name, host name, spike time |

### Step 2 — Open Logs

1. In Dynatrace left menu open **Logs** (or **Logs and events**)
2. Set the **same timeframe** as the dashboard (important)
3. If you use segments / management zone, keep the same scope as the board

### Step 3 — Filter for error-type logs (start simple)

Try these **one at a time** in the Logs filter box (wording can vary slightly by tenant):

**A — Error level**

```
status="ERROR" OR loglevel="ERROR"
```

**B — Exceptions**

```
content="Exception" OR content="Traceback"
```

**C — Fail / timeout / HTTP 5xx text**

```
content="failed" OR content="timeout" OR content=" 500" OR content=" 503"
```

If A returns too much, add your host or service from Step 1.

### Step 4 — Narrow to the failing entity

| If dashboard pointed to… | Add this kind of filter |
| --- | --- |
| A host | Host name / `dt.entity.host` for that host |
| A service | Service / process related to that service |
| An app tag | Tag `app:<name>` or host/service name containing the app |

Example idea (adapt field names to what your Logs UI offers):

```
status="ERROR" AND host="YOUR-HOST-NAME"
```

### Step 5 — Read like an SRE (manual check)

| Check | Question |
| --- | --- |
| Timestamp | Matches the chart spike / Problem time? |
| Message | Real app error or known noise? |
| Repeat | Same error many times = pattern |
| Next hop | Open one log line → related trace / service if link exists |

**Done when:** you can say “this ERROR line explains the dashboard signal” (or “logs are clean; look at metrics only”).

## Path from a Problem tile (best manual flow)

```
Dashboard Problems tile
  → open one Problem
  → note impacted host/service + time
  → Logs with same time
  → filter ERROR for that host/service
  → read messages
```

## Path from Errors % tile

```
Dashboard Errors (failure rate) chart
  → note which service is high
  → open that service
  → Logs / errors for that service
  → filter Exception or ERROR
```

## What not to do first

| Skip for now | Why |
| --- | --- |
| Classic “LOGS — wrong / bad logs” markdown only | It does not show logs; it only tells you to import another board |
| Building a full log dashboard first | Learn manual Logs filters first |
| Scanning all indexes with huge keyword lists | Too wide; start from the failing host/service |

## Optional later (after manual works)

| Later | Purpose |
| --- | --- |
| Pin a saved Logs query | Faster next time |
| New Dashboard DQL table | Standing ERROR view |
| JP PII scan DQL | Privacy scan — separate from error hunting |

## Cheat sheet (copy into Logs)

```
status="ERROR" OR loglevel="ERROR"
```

```
content="Exception" OR content="Traceback"
```

```
content="failed" OR content="timeout" OR content=" 500"
```

Same time range as the dashboard. Then add host/service/app.
