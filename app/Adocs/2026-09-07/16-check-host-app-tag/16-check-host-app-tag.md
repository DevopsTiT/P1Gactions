# Check If Host Has App Tag

```
Need to know: does this host have tag app?
  │
  ├─ UI (easiest)
  │     Hosts → open host → Properties / Tags → look for app:…
  └─ DQL / filter (many hosts)
        fetch dt.entity.host → tags contain app
```

| Key point | Detail |
| --- | --- |
| Tag to look for | Key **`app`**, value any name (`eip`, `compass`, …) |
| Where | Host entity page in Dynatrace |
| If missing | Add tag, then log DQL can use it |

## Summary

Open the **host** page and check **Tags** for `app:<value>`. You can also filter the Hosts list by tag, or query hosts with DQL. If the tag is not there, your log “application” column from `tags[app]` will be empty/`unknown`.

---

## Method 1 — One host (manual UI)

1. Dynatrace → **Hosts** (Infrastructure Observability → Hosts)
2. Search / click the host name (same as in your ERROR log, e.g. `sgkpw01a…`)
3. On the host page open **Properties and tags** (or **Tags** / metadata — wording varies)
4. Look for:

| What you want | Example |
| --- | --- |
| Key | `app` |
| Value | `eip` or `compass-pbco-tst` or any app name |
| Shown as | `app:eip` |

**Pass:** you see `app:…`  
**Fail:** no `app` key → tag is not set

---

## Method 2 — Hosts list filter

1. Dynatrace → **Hosts**
2. Use filter **Tags**
3. Choose key **`app`** (and optionally a value)
4. List shows only hosts that have that tag

If key `app` does not appear in the tag filter list, **no hosts** (or almost none) have that tag yet.

---

## Method 3 — From the ERROR log row

1. In Logs, click the host name (or open `source` HOST-…)
2. Jump to the **Host** entity
3. Check **Tags** for `app:…` (same as Method 1)

---

## Method 4 — DQL (many hosts at once)

Try in **Notebooks** (entity query; exact field names can vary by tenant):

```dql
fetch dt.entity.host
| fields id, entity.name, tags
| filter contains(toString(tags), "app:")
| limit 100
```

Or list hosts **without** app tag (to find gaps):

```dql
fetch dt.entity.host
| fields id, entity.name, tags
| filter not contains(toString(tags), "app:")
| limit 100
```

If `tags` is empty or the filter never matches, confirm tag format on one known host in the UI first.

---

## How to add the tag if missing

1. Host page → **Tags** → Add tag  
2. Key: `app`  
3. Value: your app name (any monitored app)  
4. Save  
5. Wait a short time, then re-check  
6. Re-run log DQL that uses `` `dt.entity.host.tags[app]` ``

---

## Quick checklist

| Check | Result |
| --- | --- |
| Host Tags shows `app:…` | Ready for application column in log DQL |
| Tag filter `app` returns hosts | At least some hosts tagged |
| Log DQL `application` = unknown-application | Host likely **not** tagged (or wrong tag field name) |
