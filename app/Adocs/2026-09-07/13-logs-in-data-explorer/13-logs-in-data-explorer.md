# Identify Logs In Data Explorer

```
Want logs in Data Explorer?
  │
  ├─ Classic Data Explorer (your screenshot)
  │     → Built for METRICS (Disk %, Request count, …)
  │     → Raw ERROR/FATAL log lines? Usually NO
  │     → Possible: log count / error count METRICS if they exist
  │
  └─ For real log text (Exception, ERROR lines)
        → Logs app  OR  Notebooks / new Dashboards with DQL `fetch logs`
```

| Key point | Detail |
| --- | --- |
| Your screen | Metric: Disk used % — Split by Host + Disk — Top list |
| Is that logs? | **No** — that is a **host disk metric** |
| Raw log lines in Classic Data Explorer? | Usually **not supported** well |
| Where to identify ERROR/FATAL text | **Logs** app or DQL `fetch logs` |

## Summary

**Data Explorer (Classic)** is for metrics charts (CPU, disk, request count). It is **not** the main tool to read Exception / ERROR log content. You can sometimes chart **log-related metrics** there. To **identify** error log details, use **Logs** (or DQL).

---

## What your screenshot is doing

| UI control | Your value | Meaning |
| --- | --- | --- |
| Visualization | Top list | Ranking bars |
| Metric | Disk used % | `builtin:host.disk.usedPct` style metric |
| Aggregation | Average | Avg over time |
| Split by | Host, Disk | One bar per host+disk |
| Thresholds | Red ≥ 90 | Bars turn red when high |

That answers “which disks are full?” — **not** “which ERROR logs happened?”

---

## Can Data Explorer do logs at all?

| Goal | Classic Data Explorer | Better place |
| --- | --- | --- |
| See ERROR / FATAL **message text** | Usually **no** | Logs app / DQL |
| Count of errors over time (metric) | **Maybe** if a log metric exists | Data Explorer or DQL |
| Disk / CPU / Request count | **Yes** | Data Explorer (what you have) |
| Summarize by entity, service, host, source, status | DQL `fetch logs` | Notebooks / new Dashboards |

---

## Step-by-step — identify errors in **Logs** (recommended)

1. Dynatrace → **Logs** (Logs and events)
2. Set timeframe (same as dashboard / Data Explorer)
3. Filter:

```
loglevel="ERROR" OR loglevel="FATAL"
```

or:

```
status="ERROR" OR status="FATAL"
```

4. Optional: add host / service from your board
5. Open one line → read content (Exception stack, etc.)

That is how you **identify** error logs.

---

## Step-by-step — if you still want Data Explorer for “log-ish” metrics

Only if your tenant has log **metrics** (not every environment does).

1. Open **Data explorer** (as in your screenshot)
2. Keep visualization: **Top list** or **Table** / **Graph**
3. In metric search, try keywords such as:
   - `log`
   - `error`
   - `dsfm:logs` (name varies by version)
4. If you find something like log error count:
   - Aggregation: as offered (often **value** / **auto** — follow the yellow warning like your Request count note)
   - **Split by**: Host, Service, or dimensions available
5. **Run query** → **Pin to dashboard**

| If metric search finds nothing | Meaning |
| --- | --- |
| No log metrics | Use **Logs** + DQL instead — normal |

Classic Data Explorer **Advanced mode** is usually **metric selector** syntax, **not** full `fetch logs` DQL.

---

## Step-by-step — DQL for ERROR/FATAL summary (right tool for your summarize)

1. Dynatrace → **Notebooks** or **Dashboards (new)** → Add **DQL** tile  
   (Not Classic Data Explorer metric builder)
2. Paste:

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd entity = coalesce(toString(dt.source_entity), "unknown-entity")
| fieldsAdd service = coalesce(toString(dt.entity.service), "unknown-service")
| fieldsAdd status = coalesce(loglevel, status, "UNKNOWN")
| summarize error_fatal_count = count(), by: { entity, service, host, source, status }
| sort error_fatal_count desc
| limit 200
```

3. Run → Table visualization → Pin / save to dashboard

That matches “summarize entity, service, host, source, status”.

---

## Practical setup for your boards

| Board / tool | Put here |
| --- | --- |
| Classic dashboard + Data Explorer | Disk %, CPU, Request count, Failure rate (metrics) |
| Logs app | Manual ERROR/FATAL identification |
| New Dashboard / Notebook DQL | Exception / ERROR tables + summarize by service/host |

---

## Short decision

```
Need disk/CPU/request chart? → Data Explorer (your current UI) ✓
Need ERROR/FATAL log text or summarize by service/host/source?
  → Logs app or DQL fetch logs  ✓
  → Classic Data Explorer alone ✗
```
