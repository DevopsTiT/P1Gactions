# Add Exception Logs Section Step By Step

```
Want exception logs on a dashboard?
  │
  ├─ Use NEW Dashboards (recommended)
  │     Add section header → DQL tile → fetch logs Exception
  └─ Classic board
        Weak for detail tables → open Logs app, or use new board beside it
```

| Key point | Detail |
| --- | --- |
| Goal | A dashboard **section** that shows **Exception** log lines in detail |
| Best place | **Dynatrace → Dashboards** (new), not Classic Data Explorer |
| Query | DQL `fetch logs` filtered on Exception / Traceback |

## Summary

Add a markdown title row (“LOGS — Exceptions”), then a **DQL** table tile with a log query. Same timeframe as the rest of the board. Optionally filter by app. This is the correct way to “see exception logs in detail” on a dashboard.

---

## Before you start

| Check | Why |
| --- | --- |
| Log Monitoring is on for the hosts | Otherwise the tile is empty |
| You can find Exception lines in **Logs** app manually | Confirms data exists |
| Prefer **new Dashboards** app | Classic cannot show a good live exception table easily |

---

## Step-by-step (New Dashboards)

### Step 1 — Open or create the dashboard

1. Dynatrace → **Dashboards** (new Dashboards app)
2. Open your multi-app / must-watch board **or** **Create dashboard**
3. Name example: `App-Must-Watch-With-Exceptions`
4. Set timeframe (e.g. **Last 2 hours**) — same as you use for metrics

### Step 2 — Add a section title (the “section”)

1. Click **Add** → **Markdown** (or Text)
2. Paste:

```markdown
## LOGS — Exceptions (detail)
```

3. Place it **below** metrics (Traffic / Errors / CPU), as its own row
4. Save / done editing that tile

That markdown row **is** your section header.

### Step 3 — Add the Exception detail tile

1. Click **Add** → **DQL** / **Query** (wording may be “Dynatrace Query Language”)
2. Title the tile: `Exception / Traceback logs`
3. Paste this query:

```dql
fetch logs
| filter matchesPhrase(content, "Exception")
    or matchesPhrase(content, "exception")
    or matchesPhrase(content, "Traceback")
    or matchesPhrase(content, "OutOfMemory")
| sort timestamp desc
| fields timestamp, loglevel, content, host.name, dt.source_entity
| limit 100
```

4. Run the query
5. Set visualization to **Table**
6. Resize the tile wide (full width under the section header)
7. Save the dashboard

### Step 4 — (Optional) Add ERROR level next to it

Same as Step 3, second tile titled `ERROR / FATAL logs`:

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
    or matchesValue(status, "ERROR") or matchesValue(status, "FATAL")
| sort timestamp desc
| fields timestamp, loglevel, content, host.name, dt.source_entity
| limit 100
```

Layout idea:

| Row | Tiles |
| --- | --- |
| Section | Markdown: LOGS — Exceptions |
| Detail | Exception table (wide) |
| Detail | ERROR table (wide or half) |

### Step 5 — (Optional) Filter by any app

1. Dashboard → **Variables** → Add variable  
   - Name: `app`  
   - Type: list / CSV  
   - Values: `All`, plus your app names (any monitored apps)
2. Change the Exception query to:

```dql
fetch logs
| filter matchesPhrase(content, "Exception")
    or matchesPhrase(content, "exception")
    or matchesPhrase(content, "Traceback")
| filter $app == "All"
    or contains(content, $app)
    or contains(toUpperCase(toString(host.name)), toUpperCase($app))
| sort timestamp desc
| fields timestamp, loglevel, content, host.name, dt.source_entity
| limit 100
```

3. Use the dropdown: `All` = everything; pick one app name to narrow

(Tagging hosts/services `app:<name>` makes filtering more reliable later.)

### Step 6 — How to read the section (manual habit)

| Look at | Meaning |
| --- | --- |
| Empty table | No matching exceptions in this timeframe (good, or logs not ingested) |
| Many rows | Click one line → expand **content** for stack detail |
| Same Exception repeating | Pattern — open host/service from the row |
| Time column | Should align with Problems / error-rate spikes above |

---

## If you stay on Classic only

| Action | Result |
| --- | --- |
| Add Markdown “open Logs and filter Exception” | Reminder only — **not** live detail |
| Expect Classic DATA_EXPLORER to show Exception text | Usually **wrong tool** |
| Better | Keep Classic for metrics; put Exception **section on a new Dashboard** |

Classic path for detail (not a tile):

1. Note time + host from Classic board  
2. **Logs** app → same time  
3. Filter: `content="Exception"`  
4. Open a line to read the stack  

---

## Ready-made JSON (optional)

If you want import instead of clicking:

| File | Folder |
| --- | --- |
| `App-Wrong-Logs-Dashboards.json` | `../6-dashboard-logs-wrong-section/` |

Import into **new Dashboards**, then keep or rename the Exception tile.

Companion queries: `../6-dashboard-logs-wrong-section/wrong-logs.dql`

---

## Checklist

| Step | Done when |
| --- | --- |
| 1 | Dashboard open (new) |
| 2 | Markdown section `## LOGS — Exceptions` |
| 3 | DQL table shows Exception lines |
| 4 | Timeframe matches metrics |
| 5 | (Optional) `$app` variable works |
| 6 | You can open one row and read the stack |
