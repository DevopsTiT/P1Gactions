# ServiceNow All Functions

```
"SNOW function" can mean three things:
  1) Product / module   → what SNOW does for the business  (Incident, Change, CMDB, ...)
  2) Platform feature   → how admins build it               (Flow Designer, Business Rule, ACL, ...)
  3) Script function    → code developers call              (GlideRecord.query(), g_form.setValue(), ...)

As an SRE, what do I touch most?
  ticket from alert        → Incident + Event Management + Table API
  who is on call           → On-Call Scheduling (or PagerDuty)
  is this host real?       → CMDB + Discovery
  planned deploy           → Change Management
  postmortem / root cause  → Problem Management + Knowledge
  how fast we fix          → SLA + Performance Analytics
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What SNOW is | One platform with many products on top of one database |
| Biggest product for SRE | ITSM (Incident, Problem, Change) |
| Monitoring side | ITOM (Event Management, Discovery, CMDB) |
| Build tools | Flow Designer, IntegrationHub, Business Rules, Scripts |
| Code layer | Glide APIs (server) and g_form / g_user (browser) |
| Your touch points | Incident, CMDB, Table API, SILVA rules, Change |

## Summary

ServiceNow is one platform (the "Now Platform") with product families on top: IT service, IT operations, HR, customer service, security, and more. Each product is a set of tables, forms, and workflows. Admins build logic with no-code tools (Flow Designer) or scripts (Business Rules, Script Includes) that call Glide API functions. For an SRE, the parts that matter most are ITSM, ITOM, CMDB, and the APIs.

## Investigation

Built on `2026-09-17/28-snow-common-functions-how-to/`, `2026-09-27/1-servicenow-explained/`, `2-snow-priority-impact-urgency/`, and `3-snow-apis-in-detail/`. Grouped into products, ITSM modules, ITOM modules, platform features, and script functions.

## Result

Use part A for "what can SNOW do", part B and C for SRE daily work, part D for "how is it built", and part E when reading or writing SNOW scripts.

---

# Part A — Product families

| Product | What it means | Relevance for SRE |
| --- | --- | --- |
| ITSM (IT Service Management) | Incidents, problems, changes, requests | **High**: your tickets live here |
| ITOM (IT Operations Management) | Events, discovery, CMDB, service maps | **High**: alerts and host inventory |
| ITAM (IT Asset Management) | Hardware, software licenses, cloud cost | Medium: asset lifecycle |
| SPM (Strategic Portfolio Management) | Projects, demand, agile boards | Low |
| HRSD (HR Service Delivery) | HR cases, onboarding | Low |
| CSM (Customer Service Management) | External customer cases | Medium: customer impact of outages |
| FSM (Field Service Management) | Technicians sent on site | Low |
| SecOps (Security Operations) | Security incidents, vulnerability response | Medium: vulnerability tickets |
| IRM / GRC (Integrated Risk Management) | Policies, risks, audits, compliance | Medium: audit evidence |
| App Engine | Build your own custom apps | Medium: SILVA may be one |
| Now Assist (AI) | Generative AI summaries, search, agent help | Medium: incident summaries |
| Virtual Agent | Chatbot in portal, Teams, Slack | Low to medium |

---

# Part B — ITSM modules

| Module | What it does | Example |
| --- | --- | --- |
| Incident Management | Record and fix things broken now | `INC0012345` checkout down |
| Major Incident Management | Special flow for P1 outages with bridge and comms | War room, status updates |
| Problem Management | Find root cause of repeated incidents | `PRB0001234` DB pool too small |
| Change Management | Plan, approve, and record production changes | `CHG0005678` deploy v2.3 |
| Change Advisory Board (CAB) | Meeting and approval for risky changes | Weekly CAB |
| Release Management | Group changes into releases | Release 2026.10 |
| Request Management | Users ask for things through a catalog | New laptop, new access |
| Service Catalog | The menu of things users can request | "Request AWS account" |
| Knowledge Management | Articles, runbooks, known errors | `KB0010001` restart guide |
| Service Level Management (SLA) | Timers for response and fix | P1 must be resolved in 4 hours |
| On-Call Scheduling | Rotas and escalation inside SNOW | Alternative to PagerDuty |
| Service Portal / Employee Center | Self-service website for users | Submit and track tickets |
| Walk-up Experience | In-person IT desk queue | Office help desk |
| Surveys and Assessments | Feedback after ticket closes | "Rate our support" |

---

# Part C — ITOM modules

| Module | What it does | Relevance |
| --- | --- | --- |
| CMDB | Inventory of servers, apps, databases, and their links | **SILVA checks it** (retired host means skip) |
| Discovery | Scans the network and cloud to fill the CMDB | Keeps CMDB accurate |
| Service Mapping | Draws which CIs make up a business service | Impact of a host on a service |
| Event Management | Receives monitoring events, dedups, correlates, creates alerts | Where Dynatrace events can land (`em_event`) |
| Health Log Analytics | Log anomaly detection | Overlaps Dynatrace |
| Metric Intelligence | Metric anomaly detection | Overlaps Dynatrace |
| AIOps / Predictive Intelligence | Groups alerts, suggests assignment | Noise reduction |
| Cloud Management / Cloud Discovery | Discover and govern AWS, Azure, GCP resources | Cloud CIs in CMDB |
| Orchestration / Automation | Run scripts and actions on servers | Auto-remediation |
| MID Server | Small Java agent inside your network | Lets SNOW reach private systems |
| Certificate Management | Tracks TLS certificate expiry | Avoid cert outages |

### Event flow in ITOM

```
Monitoring tool (Dynatrace)
  → em_event (raw event)
  → Event rules (filter, transform, dedup)
  → em_alert (one alert per real issue)
  → Alert rules → create Incident (optional)
```

---

# Part D — Platform features (how it is built)

## D1) No-code and low-code

| Feature | What it does | Example |
| --- | --- | --- |
| Flow Designer | Visual workflows: trigger, then actions | When P1 incident created, notify Teams |
| IntegrationHub | Ready-made connectors (spokes) for other systems | Slack, Teams, Jira, AWS spokes |
| Workflow Editor (legacy) | Older visual workflows | Old change approvals |
| Process Automation Designer | Multi-step case processes | Onboarding lanes |
| App Engine Studio | Build custom apps without much code | Custom request app |
| UI Builder | Build modern pages (Next Experience) | Custom dashboards |
| Decision Tables | Rules as a table instead of code | Priority mapping |

## D2) Logic and scripts

| Feature | Where it runs | What it does |
| --- | --- | --- |
| Business Rule | Server | Runs when a record is inserted, updated, deleted, or queried |
| Client Script | Browser | Runs on form load, field change, or submit |
| UI Policy | Browser | Makes fields mandatory, read-only, or hidden without code |
| UI Action | Both | Buttons and links on forms (for example "Resolve") |
| Script Include | Server | Reusable function library |
| Scheduled Job | Server | Runs on a timer (cron-like) |
| Fix Script | Server | One-off data fix |
| Scripted REST API | Server | Custom API endpoint (likely how SILVA works) |
| Transform Map | Server | Maps Import Set staging data to real tables |
| Data Policy | Server | Enforces mandatory fields for API and import too |

## D3) Security

| Feature | What it does |
| --- | --- |
| Roles | Groups of permissions (for example `itil`, `admin`) |
| Groups | Teams of users; tickets are assigned to groups |
| ACL (Access Control List) | Rules for who can read, write, create, delete a table or field |
| Domain Separation | Split data between companies or regions |
| SSO (SAML, OIDC) | Login with the company identity provider |
| OAuth / API credentials | Secure machine access |
| Audit history | Every field change is recorded |

## D4) Notifications and communication

| Feature | What it does |
| --- | --- |
| Email Notifications | Send email on record events |
| Inbound Email Actions | Create or update records from incoming email |
| Notify (SMS, voice) | Call or text on-call people |
| Teams / Slack integration | Post and act on tickets from chat |
| Connect Chat | Chat inside the ticket |

## D5) Reporting

| Feature | What it does |
| --- | --- |
| Reports | Charts and lists from any table |
| Dashboards | Pages of reports |
| Performance Analytics | Trends over time (MTTR, backlog) |
| Platform Analytics | Newer combined analytics workspace |

## D6) Admin and delivery

| Feature | What it does |
| --- | --- |
| Update Sets | Package config changes to move from dev to test to prod |
| Application Repository / Scoped Apps | Versioned custom apps |
| Instance Clone | Copy prod to a lower environment |
| ATF (Automated Test Framework) | Automated tests for forms and flows |
| System Logs | Debug script and integration errors |
| REST API Explorer | Try any API inside SNOW |
| Instance Scan | Check config for bad practices |

---

# Part E — Script functions (Glide APIs)

## E1) GlideRecord — read and write records (server side)

| Function | What it does | Example |
| --- | --- | --- |
| `new GlideRecord('incident')` | Open a table | `var gr = new GlideRecord('incident');` |
| `addQuery(field, value)` | Add a filter | `gr.addQuery('priority', 1);` |
| `addQuery(field, op, value)` | Filter with operator | `gr.addQuery('sys_created_on', '>', gs.daysAgo(7));` |
| `addEncodedQuery(q)` | Filter with an encoded query string | `gr.addEncodedQuery('active=true^priority=1');` |
| `addActiveQuery()` | Only active records | `gr.addActiveQuery();` |
| `addNullQuery(field)` | Field is empty | `gr.addNullQuery('assigned_to');` |
| `orderBy(field)` | Sort ascending | `gr.orderBy('number');` |
| `orderByDesc(field)` | Sort descending | `gr.orderByDesc('sys_created_on');` |
| `setLimit(n)` | Max rows | `gr.setLimit(10);` |
| `query()` | Run the query | `gr.query();` |
| `next()` | Move to next row | `while (gr.next()) {}` |
| `hasNext()` | Is there a next row? | `if (gr.hasNext())` |
| `get(sys_id)` | Load one record by sys_id | `gr.get('9d38...');` |
| `get(field, value)` | Load one record by field | `gr.get('number', 'INC0012345');` |
| `getValue(field)` | Raw value as string | `gr.getValue('state');` |
| `getDisplayValue(field)` | Label value | `gr.getDisplayValue('state');` → "Resolved" |
| `setValue(field, value)` | Set a field | `gr.setValue('state', 6);` |
| `initialize()` | Start a new empty record | `gr.initialize();` |
| `insert()` | Save new record, returns sys_id | `var id = gr.insert();` |
| `update()` | Save changes | `gr.update();` |
| `deleteRecord()` | Delete one record | Avoid for incidents |
| `deleteMultiple()` | Delete all matching | Dangerous |
| `updateMultiple()` | Update all matching | Bulk changes |
| `getRowCount()` | Number of rows | Slow on big tables |
| `isValidRecord()` | Did `get()` find something? | Guard check |
| `canRead()` / `canWrite()` | ACL check | Respect permissions |
| `setWorkflow(false)` | Skip business rules on save | Use carefully |
| `autoSysFields(false)` | Do not update system fields | Data fixes only |

## E2) GlideAggregate — counts and sums

| Function | What it does |
| --- | --- |
| `new GlideAggregate('incident')` | Open a table for aggregation |
| `addAggregate('COUNT')` | Count rows |
| `groupBy('priority')` | Group results |
| `getAggregate('COUNT')` | Read the count |

## E3) GlideSystem (`gs`) — server helpers

| Function | What it does |
| --- | --- |
| `gs.info(msg)` / `gs.warn()` / `gs.error()` | Write to system log |
| `gs.getUserID()` | Current user sys_id |
| `gs.getUserName()` | Current username |
| `gs.hasRole('itil')` | Role check |
| `gs.nowDateTime()` | Current date and time |
| `gs.daysAgo(n)` | Date n days ago for queries |
| `gs.getProperty(name)` | Read a system property |
| `gs.addInfoMessage(msg)` | Show a message on the form |
| `gs.eventQueue(name, gr)` | Fire an event (for notifications) |

## E4) Other server APIs

| API | What it does |
| --- | --- |
| `GlideDateTime` | Date and time math |
| `GlideDuration` | Time spans |
| `sn_ws.RESTMessageV2` | Call external REST APIs (for example PagerDuty) |
| `sn_ws.SOAPMessageV2` | Call SOAP APIs |
| `GlideAjax` (with Script Include) | Browser asks server for data |
| `JSON.parse` / `JSON.stringify` | Handle JSON |
| `current` | The record in a Business Rule |
| `previous` | The record before the update |

Example: call PagerDuty from SNOW:

```javascript
var r = new sn_ws.RESTMessageV2();
r.setEndpoint('https://events.pagerduty.com/v2/enqueue');
r.setHttpMethod('post');
r.setRequestHeader('Content-Type', 'application/json');
r.setRequestBody(JSON.stringify({ routing_key: gs.getProperty('pd.routing_key'), event_action: 'trigger', dedup_key: current.correlation_id + '', payload: { summary: current.short_description + '', source: 'servicenow', severity: 'critical' } }));
var res = r.execute();
gs.info('PD status ' + res.getStatusCode());
```

## E5) Client side (browser)

| Function | What it does |
| --- | --- |
| `g_form.getValue(field)` | Read a field on the form |
| `g_form.setValue(field, value)` | Set a field |
| `g_form.setMandatory(field, true)` | Make required |
| `g_form.setReadOnly(field, true)` | Lock a field |
| `g_form.setVisible(field, false)` | Hide a field |
| `g_form.addInfoMessage(msg)` | Show info banner |
| `g_form.showFieldMsg(field, msg, 'error')` | Message under a field |
| `g_form.clearValue(field)` | Empty a field |
| `g_user.userID` | Current user id |
| `g_user.hasRole('itil')` | Role check in browser |

## E6) Client script types

| Type | When it runs |
| --- | --- |
| onLoad | Form opens |
| onChange | A field changes |
| onSubmit | Form is saved (return false to block) |
| onCellEdit | Edit in list view |

---

# Part F — How it maps to your work

| Your need | SNOW function |
| --- | --- |
| Dynatrace problem becomes a ticket | Table API or SILVA Scripted REST → Incident |
| Skip retired hosts | CMDB check in SILVA |
| Set priority | impact + urgency → priority lookup |
| Resolve on Dynatrace close | Table API PATCH `state=6` |
| Link PagerDuty | `correlation_id` / `dedup_key`, or RESTMessageV2 from SNOW |
| Deploy approvals | Change Management |
| Postmortem | Problem + Knowledge article |
| MTTR report | SLA + Performance Analytics |

---

## Data flow map

```
Dynatrace ─HTTP─► SILVA (Scripted REST) ─► CMDB check ─► Incident (ITSM)
                                                     │
                                  Business Rule / Flow Designer
                                                     │
                     ┌───────────────┬───────────────┼───────────────┐
                     ▼               ▼               ▼               ▼
                 SLA timer      Notify / Teams   PagerDuty (REST)  Reports / PA
                                                     │
                                         Problem ◄── repeated incidents
                                                     │
                                               Knowledge article
```

## Related files

| File | Role |
| --- | --- |
| `2026-09-17/28-snow-common-functions-how-to/` | Earlier common functions |
| `2026-09-27/1-servicenow-explained/` | Overview |
| `2026-09-27/2-snow-priority-impact-urgency/` | Priority matrix |
| `2026-09-27/3-snow-apis-in-detail/` | Table API detail |
| `4.sh` | API calls to explore modules (you run) |

## Commands

See `4.sh`.
