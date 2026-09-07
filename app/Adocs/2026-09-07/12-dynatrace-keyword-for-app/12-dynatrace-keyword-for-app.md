# Dynatrace Keyword For App

```
Is there a built-in DQL keyword "app"?
  → NO (not on every log line by default)

What people use instead
  → Tag key: app  (value e.g. eip, api, payment)
  → Or web Application entity (RUM)
  → Or service / process / host name
```

| Key point | Detail |
| --- | --- |
| Built-in field named `app`? | **No** — not standard on all logs |
| Usual custom keyword | **Tag key** `app` → `app:eip`, `app:api`, … |
| Your dashboard `$app` | **Dashboard variable name** you created — not a Dynatrace log field |

## Summary

In Dynatrace, **“app” is almost always a tag you define**, not a reserved log keyword like `loglevel` or `host.name`. Put tag `app:<name>` on hosts and services, then use that tag in filters / DQL enrichment.

## What “app” can mean in Dynatrace

| Meaning | Dynatrace thing | Typical use |
| --- | --- | --- |
| Custom label (recommended for you) | Tag **`app`** = `eip` / `claims` / … | Multi-app dashboard filter |
| RUM / web app | Entity **Application** (`dt.entity.application`) | Browser / frontend monitoring |
| Backend “app” | **Service** / process group name | Auto-detected services |
| Your DQL variable | `$app` | Only exists if you add a dashboard variable |

## Tag to create (do this once)

| Action | Example |
| --- | --- |
| On each host + service | Tag key `app`, value `eip` (or any app name) |
| Result | `app:eip`, `app:api`, `app:payment`, … |

Any monitored app can get its own value — not limited to three names.

## How to use in your ERROR/FATAL summarize DQL

**1) Prefer after tags exist** (field names vary by tenant; try in Notebooks):

```dql
fetch logs
| filter loglevel == "ERROR" or loglevel == "FATAL"
| fieldsAdd host = coalesce(host.name, "unknown-host")
| fieldsAdd source = coalesce(toString(dt.source_entity), "unknown-source")
| fieldsAdd entity = coalesce(toString(dt.source_entity), "unknown-entity")
| fieldsAdd status = coalesce(loglevel, status, "UNKNOWN")
| fieldsAdd app = coalesce(
    toString(entityAttr(dt.entity.host, "tags[app]")),
    "unknown-app"
  )
| summarize error_fatal_count = count(), by: { app, entity, host, source, status }
| sort error_fatal_count desc
| limit 200
```

If `entityAttr(... tags[app])` fails in your tenant, open one log record in Logs UI and check **which attribute** holds the app tag, then use that field name.

**2) Until tags exist** — no real `app` keyword; approximate from host name (temporary only).

## Classic dashboard filter

| UI | What to pick |
| --- | --- |
| Dashboard filter → Tag | Key **`app`**, value = any app |

That is the same “keyword”: tag key **`app`**.

## Short answer

| Question | Answer |
| --- | --- |
| Dynatrace keyword for app? | **Tag key `app`** (you create it) |
| Built-in on every log? | **No** |
| Related built-ins | `host.name`, `dt.source_entity`, `loglevel` / `status`, service/application **entities** |
