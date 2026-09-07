# Configure Dashboard Layout Manually Step By Step

```
DASHBOARD LAYOUT VISUAL (11 rows)
  Row 1  Application selector (All / any app via tag app)
  Row 2–3  Problems / Root cause / Alert summary
  Row 4–5  Requests / Errors / Response time
  Row 6–7  Windows CPU / Linux CPU / Memory
  Row 8–9  Error logs / Exception traces
  Row 10–11  DB / Queries / External
```

| Key point | Detail |
| --- | --- |
| Where | Dynatrace **Dashboards Classic** for metrics; **Logs** or **new Dashboards** for log text |
| App filter | Tag key **`app`** (you already have `app: DYNATRACE`, etc.) |
| Order | Create shell → selector → each section top to bottom |

## Summary

Build **one** Classic board following the layout picture. Use **Dashboard filter → Tag → `app`** as the application selector (All = clear filter). Add Problems and Data Explorer tiles for metrics. For Error Logs / Exceptions, use the Logs app or a new Dashboard DQL tile — Classic cannot show full log text well.

---

## Before you start

| Check | Why |
| --- | --- |
| Hosts/services have tag `app:<name>` | Selector can filter any app |
| OneAgent + metrics flowing | Request/CPU tiles fill |
| Log Monitoring on (for row 8–9) | ERROR / Exception lines exist |

---

## Step 0 — Create the dashboard shell

1. Dynatrace → **Dashboards** → **Dashboards Classic** (or Create dashboard → Classic)
2. **Create dashboard**
3. Name: e.g. `App-Health-Layout` or `DashboardTestK - Enhanced`
4. Timeframe: **Last 2 hours**
5. **Save**

---

## Row 1 — APPLICATION SELECTOR `[All][EIP][API][Payment]…`

Classic has **no chip buttons** like the picture. Use the **dashboard filter**.

1. Open the dashboard → find **Filter** (top of board)
2. Add filter → **Tag**
3. Key: **`app`**
4. Value: pick any (e.g. `DYNATRACE`, `eip`, …) → board narrows to that app’s entities
5. **Clear filter** = **All** apps

| Picture chip | What you do in UI |
| --- | --- |
| All | Clear dashboard filter |
| EIP / API / Payment / … | Filter Tag `app` = that value |

Optional: Add a **Markdown** tile at the top:

```markdown
## APPLICATION SELECTOR
Use Dashboard filter → Tag → `app:<name>`
Clear filter = All apps
```

---

## Row 2 — CRITICAL ALERTS & AI ROOT CAUSE (section title)

1. Edit dashboard → **Add tile** → **Header** (or Markdown)
2. Title: `CRITICAL ALERTS & AI ROOT CAUSE`
3. Place at top under the selector markdown
4. Save

---

## Row 3 — Problems | Root Cause | Alert Summary

### 3A — Problems

1. Add tile → **Problems** / **Open problems**
2. Title: `Problems`
3. Leave tile filter empty (dashboard `app` filter applies when set)
4. Place left

### 3B — Root Cause (Davis)

Classic cannot embed live Davis RCA as one metric tile.

1. Add tile → **Markdown**
2. Paste:

```markdown
## Root Cause (Davis)
1. Open a Problem on the left
2. Read Root cause + impacted entities
3. Jump to host / service / Logs
```

### 3C — Alert Summary

1. Add tile → **Markdown** (or a second Problems-style summary if available)
2. Paste:

```markdown
## Alert Summary
Use Problems tile severity counts.
Critical → page
Error → investigate
Info → watch
```

---

## Row 4 — APPLICATION PERFORMANCE METRICS (section title)

1. Add **Header** / Markdown: `APPLICATION PERFORMANCE METRICS`

---

## Row 5 — Requests | Errors | Response Time

For each tile: **Add tile** → **Data explorer** → configure → **Pin to dashboard**.

### 5A — Requests

1. Data explorer → Metric: **Request count** (`builtin:service.requestCount.total`)
2. Split by: **Service**
3. Aggregation: follow UI (often Value/Auto; Sum may warn)
4. Visualization: **Graph** or **Top list**
5. Pin → name `Requests`

### 5B — Errors

1. Metric: **Failure rate** / server errors  
   (`builtin:service.errors.server.rate` or similar in picker)
2. Split by: **Service**
3. Graph → Pin → `Errors`

### 5C — Response Time

1. Metric: **Response time** (`builtin:service.response.time`)
2. Split by: **Service**
3. Optional second tile later for **percentile 99** if offered
4. Pin → `Response Time`

Place three tiles in one row.

---

## Row 6 — INFRASTRUCTURE STATUS (section title)

1. Add Header: `INFRASTRUCTURE STATUS`

---

## Row 7 — Windows CPU | Linux CPU | Memory

### 7A — Windows CPU

1. Data explorer → **CPU usage %** (`builtin:host.cpu.usage`)
2. Split by: **Host**
3. Filter (tile or explorer): OS / name contains Windows if available  
   (If no OS filter: pin all hosts, or filter by host group / name pattern)
4. Pin → `Windows CPU`

### 7B — Linux CPU

1. Same metric **CPU usage %**
2. Split by Host
3. Filter Linux hosts
4. Pin → `Linux CPU`

### 7C — Memory

1. Metric: **Memory used %** (`builtin:host.mem.usage`)
2. Split by: **Host**
3. Pin → `Memory`

Optional (from your earlier work): add **Disk used %** Split by Host + Disk with thresholds Red ≥ 90.

---

## Row 8 — LOGS & ERRORS (section title)

1. Add Header: `LOGS & ERRORS`

---

## Row 9 — Error Logs | Exception Traces

**Do this manually in UI (recommended first):**

### 9A — Error Logs (Logs app)

1. Keep dashboard timeframe in mind (e.g. Last 2h)
2. Open **Logs**
3. Same timeframe
4. Filter:

```
loglevel="ERROR" OR loglevel="FATAL"
```

5. Optional: filter by host / tag `app`
6. Bookmark or copy the query

### 9B — Exception Traces (Logs app)

```
content="Exception" OR content="Traceback"
```

### On the Classic board (reminder tiles only)

1. Add **Markdown** tile `Error Logs` with the filter text + “Open Logs”
2. Add **Markdown** tile `Exception Traces` with the Exception filter

### Better live tables (optional)

1. **Dashboards (new)** → Add **DQL** tile  
2. Paste ERROR/FATAL summarize or detail query (with host tag `app`)  
3. Keep Classic for metrics; new board (or section) for log tables

---

## Row 10 — DATABASE & DEPENDENCIES (section title)

1. Add Header: `DATABASE & DEPENDENCIES`

---

## Row 11 — DB Connections | Queries | External Services

### 11A — Database

1. Add tile → **Databases** (Classic DATABASE tile)  
   **or** Data explorer on DB-related service metrics
2. If UI says “Please pick a database” → select a DB **or** use Data explorer Split by Service and filter names with `sql` / `db` / `jdbc`
3. Pin / place as `DB Connections`

### 11B — Queries

1. Data explorer → Service **Response time** or DB statement metrics if available
2. Split by Service (DB services)
3. Pin → `Queries`

### 11C — External Services

1. Data explorer → Failure rate / request count
2. Split by Service
3. Focus on outbound / external-named services (or leave all and use `app` filter)
4. Pin → `External Services`

---

## After all rows — verify with app selector

| Test | Expected |
| --- | --- |
| Filter clear (All) | All apps’ problems/metrics |
| Filter `app:DYNATRACE` (or your value) | Only that app’s hosts/services |
| Problems click → Logs ERROR | Manual error identification works |
| Empty tile | Check metric name, timeframe, tags, OneAgent |

---

## Layout checklist (match the picture)

| Row | UI action | Done? |
| --- | --- | --- |
| 1 | Dashboard filter Tag `app` + optional Markdown | ☐ |
| 2 | Header CRITICAL ALERTS… | ☐ |
| 3 | Problems + Root Cause MD + Alert Summary MD | ☐ |
| 4 | Header APPLICATION PERFORMANCE… | ☐ |
| 5 | Requests / Errors / Response Time (Data explorer) | ☐ |
| 6 | Header INFRASTRUCTURE… | ☐ |
| 7 | Windows CPU / Linux CPU / Memory | ☐ |
| 8 | Header LOGS & ERRORS | ☐ |
| 9 | Logs app filters + Markdown (or new DQL) | ☐ |
| 10 | Header DATABASE… | ☐ |
| 11 | DB / Queries / External tiles | ☐ |

---

## Related

| Topic | Folder |
| --- | --- |
| Host `app` tag check | `16-check-host-app-tag` |
| Tags to use (`app`, `AGO_GLOBAL_APP`) | `18-what-can-be-used-for-app` |
| ERROR/FATAL DQL | `17-host-tags-usable-for-app` |
| Manual error logs | `8-manual-error-logs-from-dashboard` |
