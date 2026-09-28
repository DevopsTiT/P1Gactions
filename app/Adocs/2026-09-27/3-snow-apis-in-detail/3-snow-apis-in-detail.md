# ServiceNow APIs In Detail

```
What do I need to do in SNOW?
  create a ticket        → POST   /api/now/v2/table/incident
  find a ticket          → GET    /api/now/v2/table/incident?sysparm_query=...
  read one ticket        → GET    /api/now/v2/table/incident/{sys_id}
  update / resolve       → PATCH  /api/now/v2/table/incident/{sys_id}
  send raw monitor event → POST   /api/now/v2/table/em_event  (ITOM)
  SILVA custom endpoint  → POST   /api/<scope>/<api_name>/...  (Scripted REST)

Call failed?
  network error / timeout → Dynatrace allowlist (External requests)
  401                     → wrong user or password
  403                     → user lacks role or ACL on that table
  404                     → wrong table name or sys_id
  400                     → bad JSON or bad field value
  200 but empty result    → query matched nothing (check correlation_id)
```

## Short takeaway

| Question | Answer |
| --- | --- |
| Main API | Table API: read and write rows in any SNOW table over REST |
| URL shape | `https://<instance>/api/now/v2/table/<table>` |
| Auth | Basic auth (technical user) or OAuth bearer token |
| Format | JSON in, JSON out; the answer is inside `result` |
| Key id | `sys_id` (32 characters) identifies one record |
| Our sync key | `correlation_id` = Dynatrace problem id |

## Summary

ServiceNow stores everything as rows in tables, and the Table API lets you create, read, update, and delete those rows with normal HTTP calls. Our workflows use three calls: POST to create an incident, GET with a query to find it by `correlation_id`, and PATCH to resolve it. SILVA may also expose its own custom endpoint (Scripted REST API) that wraps these calls and adds the CMDB check.

## Investigation

Based on the OPEN and CLOSE workflows in `2026-09-24/1-silva-http-snow-pd-sync-workflows/`: POST `/api/now/v2/table/incident`, GET with `sysparm_query=correlation_id=...`, PATCH `state=6`. Auth is Basic with `Tech_DynatraceJP_WS`.

## Result

Learn the URL shape, the headers, the five `sysparm_` parameters, and the status codes. That covers almost every SNOW call you will write.

---

## 1) What an API call is made of

| Part | What it means | Example |
| --- | --- | --- |
| Method | The verb: what you want to do | `GET`, `POST`, `PATCH` |
| Instance | Your company's SNOW site | `https://silvastg.service-now.com` |
| Path | Which API and which table | `/api/now/v2/table/incident` |
| Query parameters | Filters and options after `?` | `?sysparm_limit=1` |
| Headers | Extra info about the request | `Content-Type: application/json` |
| Body | The JSON data you send (POST, PATCH) | `{"short_description":"..."}` |
| Response | What SNOW sends back | `{"result": {...}}` plus a status code |

---

## 2) The URL shape

```
https://silvastg.service-now.com/api/now/v2/table/incident/9d385017c611228701d22104cc95c371
└──────── instance ─────────┘└ api ┘└ver┘└ api ┘└ table ┘└──────── sys_id (optional) ───────┘
```

| Piece | Meaning |
| --- | --- |
| `/api/now` | ServiceNow's built-in ("now") APIs |
| `/v2` | API version; `v1` also works. Leaving it out uses the latest |
| `/table` | The Table API |
| `/incident` | Which table |
| `/{sys_id}` | One specific record (only for read one, update, delete) |

---

## 3) Authentication

| Method | How it works | When to use |
| --- | --- | --- |
| Basic auth | Username and password, base64 encoded in the `Authorization` header | Simple integrations; what our workflow uses |
| OAuth 2.0 | Get a token from `/oauth_token.do`, then send `Authorization: Bearer <token>` | Preferred for production; tokens expire and can be revoked |
| Mutual TLS | Client certificate | Very strict environments |

Basic auth header example:

```
Authorization: Basic base64("Tech_DynatraceJP_WS:password")
```

Rules:

| Rule | Why |
| --- | --- |
| Use a technical (integration) user, not a person | People leave; passwords get reset |
| Give only the roles needed (for example `itil` or a custom role) | Least privilege |
| Store the password in a Dynatrace credential vault, not in the YAML | Secrets must not sit in Git |

---

## 4) Headers

| Header | Value | Why |
| --- | --- | --- |
| `Accept` | `application/json` | Ask for JSON back (default can be XML) |
| `Content-Type` | `application/json` | Tell SNOW your body is JSON (POST, PATCH, PUT) |
| `Authorization` | `Basic ...` or `Bearer ...` | Login |

---

## 5) The five methods

### 5a) POST — create a record

```
POST /api/now/v2/table/incident
```

Body:

```json
{
  "short_description": "[Dynatrace] Checkout latency high",
  "description": "Problem P-12345\nhttps://<tenant>/ui/apps/dynatrace.davis.problems/problem/P-12345",
  "correlation_id": "P-12345",
  "impact": "1",
  "urgency": "1",
  "caller_id": "Tech_DynatraceJP_WS",
  "cmdb_ci": "host-app-01"
}
```

Response (status 201 Created):

```json
{
  "result": {
    "sys_id": "9d385017c611228701d22104cc95c371",
    "number": "INC0012345",
    "state": "1",
    "priority": "1",
    "correlation_id": "P-12345"
  }
}
```

| Tip | Why |
| --- | --- |
| Save the returned `sys_id` and `number` | Needed later to update or to show in PagerDuty |
| Values are strings (`"1"`, not `1`) | SNOW fields are string based |
| Unknown field names are silently ignored | Typos do not fail, they just do nothing |

### 5b) GET — find records with a query

```
GET /api/now/v2/table/incident?sysparm_query=correlation_id=P-12345^active=true&sysparm_fields=sys_id,number,state&sysparm_limit=1
```

Response (status 200):

```json
{
  "result": [
    { "sys_id": "9d38...c371", "number": "INC0012345", "state": "2" }
  ]
}
```

| Tip | Why |
| --- | --- |
| `result` is a **list** for a query | Empty list `[]` means nothing matched; it is still 200, not 404 |
| Always set `sysparm_limit` | Without it you may pull thousands of rows |
| Always set `sysparm_fields` | Smaller, faster responses |

### 5c) GET one — read by sys_id

```
GET /api/now/v2/table/incident/9d385017c611228701d22104cc95c371
```

Returns one object in `result` (not a list). Returns 404 if the sys_id does not exist.

### 5d) PATCH — update some fields

```
PATCH /api/now/v2/table/incident/9d385017c611228701d22104cc95c371
```

Body (resolve):

```json
{
  "state": "6",
  "close_code": "Solved (Permanently)",
  "close_notes": "Dynatrace problem P-12345 closed automatically"
}
```

| Tip | Why |
| --- | --- |
| PATCH changes only the fields you send | Everything else stays |
| Resolving often **requires** `close_code` and `close_notes` | Otherwise a business rule may reject or ignore the change |
| You need the `sys_id`, not the INC number | So do a GET first (that is what our CLOSE workflow does) |

### 5e) PUT and DELETE

| Method | What it does | Use it? |
| --- | --- | --- |
| PUT | Same as PATCH in SNOW Table API (updates fields you send) | Fine, but PATCH is clearer |
| DELETE | Removes the record | Almost never for incidents; breaks the audit trail |

---

## 6) Query parameters (`sysparm_*`)

| Parameter | What it does | Example |
| --- | --- | --- |
| `sysparm_query` | Filter (encoded query) | `correlation_id=P-12345^active=true` |
| `sysparm_fields` | Which columns to return | `sys_id,number,state` |
| `sysparm_limit` | Max rows returned | `1` |
| `sysparm_offset` | Skip rows (for paging) | `100` |
| `sysparm_display_value` | Return labels instead of raw values | `true` gives "Resolved" instead of "6" |
| `sysparm_exclude_reference_link` | Drop extra link objects on reference fields | `true` makes JSON cleaner |
| `sysparm_input_display_value` | Let you send labels instead of raw values | `true` lets you send `"assignment_group":"SRE Team"` |

### Encoded query cheat sheet

| Operator | Meaning | Example |
| --- | --- | --- |
| `=` | equals | `state=6` |
| `!=` | not equal | `state!=7` |
| `^` | AND | `active=true^priority=1` |
| `^OR` | OR | `priority=1^ORpriority=2` |
| `LIKE` | contains | `short_descriptionLIKEDynatrace` |
| `STARTSWITH` | starts with | `numberSTARTSWITHINC00` |
| `IN` | one of a list | `stateIN1,2,3` |
| `ISEMPTY` | field is empty | `assigned_toISEMPTY` |
| `ORDERBYDESC` | sort newest first | `^ORDERBYDESCsys_created_on` |

Tip: build the filter in the SNOW list view, right click the breadcrumb, and choose "Copy query". Paste it into `sysparm_query`. Remember to URL-encode it (`encodeURIComponent` in JavaScript).

---

## 7) Status codes

| Code | Meaning | Usual cause in our setup |
| --- | --- | --- |
| 200 OK | Read or update worked | GET, PATCH |
| 201 Created | Record created | POST |
| 204 No Content | Deleted | DELETE |
| 400 Bad Request | Bad JSON or bad value | Missing quote, wrong field type |
| 401 Unauthorized | Login failed | Wrong password, locked user |
| 403 Forbidden | Logged in but not allowed | Missing role or table ACL |
| 404 Not Found | Wrong table or sys_id | Typo in table name, record deleted |
| 429 Too Many Requests | Rate limit hit | Too many calls per hour from this user |
| 500 or 503 | SNOW side error | Retry later, tell SNOW admins |
| Network error | Never reached SNOW | Dynatrace External requests allowlist missing the host |

Error body example:

```json
{ "error": { "message": "User Not Authenticated", "detail": "Required to provide Auth information" }, "status": "failure" }
```

---

## 8) Other SNOW APIs you may meet

| API | Path | What it is for |
| --- | --- | --- |
| Event API (ITOM) | `POST /api/now/v2/table/em_event` or `/api/global/em/jsonv2` | Send raw monitoring events; Event Management turns them into alerts and incidents |
| Import Set API | `POST /api/now/import/<staging_table>` | Load data into a staging table; transform maps copy it to real tables with rules |
| Scripted REST API | `/api/<scope>/<api_id>/<path>` | Custom endpoint written by SNOW developers; **SILVA likely sits here** |
| Aggregate API | `GET /api/now/stats/incident?sysparm_count=true` | Counts and sums without pulling rows |
| Attachment API | `POST /api/now/attachment/file` | Attach files to a record |
| CMDB Instance API | `/api/now/cmdb/instance/<class>` | Read or write CIs with CMDB rules |

### Why SILVA matters here

| Direct Table API | Through SILVA (Scripted REST or Import Set) |
| --- | --- |
| You create the incident yourself | SILVA decides whether to create it |
| No CMDB check unless you do it | SILVA checks CMDB (retired host means skip) |
| Needs write roles on `incident` | Needs access only to SILVA's endpoint |
| Response always shows the new INC | Response may be 200 with no INC (skipped) |

So when a call "worked" (200) but no incident appeared, SILVA's rules are the first place to look.

---

## 9) How our workflows use the API

| Workflow step | Call | Why |
| --- | --- | --- |
| OPEN: create | `POST /incident` with `correlation_id=P-12345` | Open ticket, tagged with Dynatrace id |
| CLOSE: find | `GET /incident?sysparm_query=correlation_id=P-12345^active=true&sysparm_limit=1` | Get the `sys_id` |
| CLOSE: soft miss | Empty result → return `found:false` | SILVA may have skipped the ticket; not an error |
| CLOSE: resolve | `PATCH /incident/{sys_id}` with `state=6`, `close_code`, `close_notes` | Resolve ticket |

JavaScript pattern used in the workflow:

```javascript
const auth = "Basic " + btoa(user + ":" + password);
const q = encodeURIComponent(`correlation_id=${problemId}^active=true`);
const r = await fetch(`${base}/api/now/v2/table/incident?sysparm_query=${q}&sysparm_fields=sys_id,number&sysparm_limit=1`, {
  headers: { Accept: "application/json", Authorization: auth }
});
if (!r.ok) throw new Error(`SNOW GET ${r.status}: ${await r.text()}`);
const rows = (await r.json()).result;
if (rows.length === 0) return { found: false };
```

---

## 10) Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Forget `Content-Type` on POST | 400 or empty record | Add `application/json` |
| Query not URL-encoded | `^` or spaces break the URL | Use `encodeURIComponent` |
| Using INC number in PATCH URL | 404 | GET the `sys_id` first |
| No `sysparm_limit` | Slow, huge response | Always limit |
| Treat empty list as error | CLOSE fails for skipped tickets | Treat as soft miss |
| Resolve without `close_code` | State does not change | Send `close_code` and `close_notes` |
| Password in YAML | Secret leaks to Git | Use credential vault |

---

## Data flow map

```
Dynatrace Problem OPEN
  → run-javascript
  → POST https://silvastg.service-now.com/api/now/v2/table/incident   (or SILVA endpoint)
       Authorization: Basic ...   Content-Type: application/json
  → 201 { result: { sys_id, number } }

Dynatrace Problem CLOSED
  → GET  .../incident?sysparm_query=correlation_id=P-12345^active=true&sysparm_limit=1
       → [] → found:false (stop, no error)
       → [ { sys_id } ]
  → PATCH .../incident/{sys_id}  { state:"6", close_code, close_notes }
  → 200 resolved
```

## Related files

| File | Role |
| --- | --- |
| `2026-09-27/1-servicenow-explained/` | SNOW overview |
| `2026-09-27/2-snow-priority-impact-urgency/` | Priority matrix |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | Workflows that call these APIs |
| `3.sh` | curl examples for every call (you run) |

## Commands

See `3.sh`. Replace `__SNOW_PASSWORD__` and `__SYS_ID__` before running. Use STG only.
