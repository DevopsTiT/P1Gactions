# SILVA Objects Explained

## Decision tree

```
Which SILVA thing am I looking at?
 32 hex characters (8ddef691fb34...)?         → a sys_id (record id) → which table? check the field it sits in
 Field on the incident form?
   Caller, On Behalf Of                       → sys_user record (a person or technical user)
   Company                                    → core_company record
   Assignment group                           → sys_user_group record (a team)
   Business service (u_business_service)      → cmdb_ci_service record (the service the business sees)
   Service Offering (cmdb_ci field)           → service_offering record (that service in one environment)
   Configuration item (u_configuration_item)  → cmdb_ci record (the server, DB, app...)
   Environment (u_environment)                → a choice value (Production, Pre-Production...)
   Incident State, Close code                 → choice values from sys_choice
   Correlation ID                             → plain text: our Dynatrace problem id
 Field shows WRONG in preview?                → a name was sent where a sys_id is needed
```

## Short takeaway

| Question | Answer |
|---|---|
| What is SILVA? | AXA's ServiceNow instance. We use the staging copy `silvastg.service-now.com`. |
| What is a sys_id? | The unique 32-character id of any record in ServiceNow. Like a primary key. |
| What is the CMDB? | The Configuration Management Database: SILVA's inventory of servers, apps and services. |
| What is a CI? | Configuration Item: one thing in the CMDB, for example the server `ts12.hk.intraxa`. |
| Why is "cmdb_ci" confusing? | It is both a table name (all CIs) and a field on the incident. In SILVA that incident field is labelled "Service Offering". |
| Where does the server go then? | The custom field `u_configuration_item` (form label "Configuration item"). |
| Why do we send sys_ids, not names? | Reference fields store a link to a record. Names can be duplicated or renamed; sys_ids never change. |

## Summary

An incident in SILVA is a record that points to other records: a caller, a company, a team, a business service, a service offering and a server. Each pointer is stored as the other record's sys_id. Task 2 of the OPEN workflow exists only to find those sys_ids, and the table in your question is what it hands to task 3.

---

## 1. ServiceNow basics you need first

| Concept | What it means | Example from our work |
|---|---|---|
| Instance | One ServiceNow website with its own data. | `silvastg.service-now.com` (staging). Production rejects our account. |
| Table | Like a database table. Every kind of record has one. | `incident`, `sys_user_group`, `cmdb_ci_service` |
| Record | One row in a table. | INC30341416 is one record in `incident`. |
| Field | One column. | `assignment_group`, `short_description` |
| sys_id | Hidden unique id of every record: 32 hex characters. | `8ddef691fb34cf547b0dfe7b4eefdcbc` = user Dynatrace JP |
| Reference field | A field that points to a record in another table, storing its sys_id. | `assignment_group` stores a group's sys_id. |
| Display value | The readable name SILVA shows for a reference. | `Ops_Middleware_Monitoring_AXAJP` |
| Choice field | A dropdown with fixed allowed values. | `incident_state`, `close_code`, `u_environment` |
| `u_` prefix | A custom field AXA added, not standard ServiceNow. | `u_business_service`, `u_configuration_item`, `u_environment`, `u_on_behalf_of` |
| Table inheritance | A table can extend another and share its fields. | `service_offering` extends `cmdb_ci_service`, which extends `cmdb_ci`. |
| `sys_class_name` | Tells which exact table (class) a record really belongs to. | `service_offering`, `cmdb_ci_win_server` |

### Value versus display value

When the workflow calls the API with `sysparm_display_value=all`, every reference comes back with both:

```json
"assignment_group": { "value": "a1b2c3...32 chars", "display_value": "Ops_Middleware_Monitoring_AXAJP" }
```

| Helper in the code | Returns | Used for |
|---|---|---|
| `val(row, "assignment_group")` | the sys_id (`value`) | Sending to SILVA in the incident body |
| `dv(row, "assignment_group")` | the name (`display_value`) | Showing you what was picked |

That is why each output row in your table has both a `name` and a `sys_id`.

---

## 2. How the SILVA objects fit together

```
core_company  (AXA XL)
   │ owns
cmdb_ci_service  "Business service"   (37273dbc...)
   │ parent of
service_offering "Service Offering"   (cfbf255f...)   one per environment: Production, Pre-Production...
   │ delivered by (svc_ci_assoc, cmdb_rel_ci)
cmdb_ci  "Configuration item"         (ts12.hk.intraxa, class cmdb_ci_win_server)
   │ supported by
sys_user_group "Assignment group"     (the team that fixes it)

incident INC30341416 points to all of them:
   company            → core_company
   u_business_service → cmdb_ci_service
   cmdb_ci            → service_offering   (SILVA labels this field "Service Offering")
   u_configuration_item → cmdb_ci (server)
   assignment_group   → sys_user_group
   caller_id, u_on_behalf_of → sys_user (Dynatrace JP)
   correlation_id     = "P-261090" (plain text)
```

Simple analogy: the **company** is the shop owner, the **business service** is a product line ("Online Payments"), the **service offering** is that product in one market ("Online Payments, Pre-Production"), the **CI** is the machine in the back room that runs it, and the **assignment group** is the repair team.

### Table inheritance (why the code excludes offerings)

```
cmdb_ci                         every CI
 ├─ cmdb_ci_service             business services
 │    └─ service_offering       offerings (also live inside cmdb_ci_service)
 └─ cmdb_ci_computer
      └─ cmdb_ci_server
           └─ cmdb_ci_win_server   e.g. ts12.hk.intraxa
```

Because offerings extend `cmdb_ci_service`, a search on `cmdb_ci_service` also returns offerings. The workflow adds `^sys_class_name!=service_offering` (the `NOT_OFFERING` setting) so a business service search returns only real business services.

Because everything extends `cmdb_ci`, the incident field `cmdb_ci` can legally hold an offering's sys_id. SILVA chose to use it for the offering, and added `u_configuration_item` for the actual server.

---

## 3. Each row of your table, explained

### `snow_required.assignment_group`

| Part | What it means | Example |
|---|---|---|
| Table | `sys_user_group`: teams in SILVA. | |
| name | The team name. | `Ops_Middleware_Monitoring_AXAJP` (the default) |
| sys_id | That team's record id; goes into the incident field `assignment_group`. | 32 hex characters |
| source | Where the workflow got it, by `GROUP_ORDER`. | "tag ago_axa_supportgroup", "servicenow_enrichment.assignment_group", "CI support group", "default (DEFAULT_GROUP)" |
| Why you care | Decides which team's queue the ticket lands in and who gets paged in SILVA. | |

Order the workflow tries (first hit wins):

| Order | Source | What it means |
|---|---|---|
| 1 | tag | A group tag on the Dynatrace entity, checked to exist in SILVA. |
| 2 | enrichment | The `assignment_group` field of the business service. |
| 3 | enrichment_support | The `support_group` field of the business service. |
| 4 | ci | The `support_group` of the server CI. |
| 5 | default | `Ops_Middleware_Monitoring_AXAJP`. |

### `snow_required.business_service`

| Part | What it means | Example |
|---|---|---|
| Table | `cmdb_ci_service` (without offerings). | |
| name | Business service name. | the parent of offering cfbf255f |
| sys_id | Goes into incident field `u_business_service` (form label "Business service"). | `37273dbc...` |
| method | How it was found. | "SERVICE_MAP", "tag snow-service", "CI ts12 -> svc_ci_assoc", "search (score 7 ...)", "replaced by ... (business service of the history offering)" |
| Watch out | The standard field `business_service` is labelled "ZZZ-Do-not-use" in SILVA. Always use `u_business_service`. | |

### `snow_required.service_offering`

| Part | What it means | Example |
|---|---|---|
| Table | `service_offering`. | |
| name | Offering name, usually service name plus environment or company. | |
| sys_id | Goes into incident field `cmdb_ci` (form label "Service Offering"). | `cfbf255f...` |
| environment | The offering's `u_environment`. | Pre-Production |
| source | How it was chosen. | "incident history on host CI (20 of 20 recent incidents)" for P-261090 |
| parent | The business service it belongs to. | `37273dbc...` |
| Why you care | Mandatory on the form. Wrong environment means wrong SLA and reporting. | |

### `snow_required.cmdb_ci` (the host CI)

| Part | What it means | Example |
|---|---|---|
| Table | `cmdb_ci` (base table; the real class is in `sys_class_name`). | |
| name | CI name. | `ts12` or `ts12.hk.intraxa` |
| sys_id | Goes into incident field `u_configuration_item` (form label "Configuration item"). | |
| class | Exact type. | `cmdb_ci_win_server` |
| fqdn | Fully qualified domain name. | `ts12.hk.intraxa` |
| Why you care | Links the ticket to the server. It is also the key used to find the offering from incident history. | |

Name clash to remember:

| Name | Meaning in our output | Meaning on the incident |
|---|---|---|
| `snow_required.cmdb_ci` | The **server** CI. | Sent as `u_configuration_item`. |
| incident field `cmdb_ci` | Not this object. | Holds the **Service Offering** sys_id. |

### `snow_required.company`

| Part | What it means | Example |
|---|---|---|
| Table | `core_company`. | |
| name | Company. | AXA XL |
| sys_id | Goes into incident field `company`. | |
| source | First found of: business service company, CI company, group company. Else the text `AXA GROUP OPERATIONS`. | "servicenow_enrichment.company" |
| Why you care | Mandatory. Controls which company's support model and reports apply. | |

### `snow_required.environment`

| Part | What it means | Example |
|---|---|---|
| Type | Choice value, not a reference. | |
| label | SILVA environment label. | Pre-Production, Production, Development, Integration / Test |
| from | Where it came from. | "tag env", "dt.security_context ALJ_PRE", "default" |
| Goes into | Incident field `u_environment`. Also used to pick the matching offering. | |

### `servicenow_enrichment`

The full business service record, flattened:

| Field | What it means |
|---|---|
| found | true if a business service was found. |
| match_method | Same as `business_service.method`. |
| sys_id, business_service, number | Id, name and CMDB number of the service. |
| category, service_classification | What kind of service it is. |
| assignment_group, support_group (and their ids) | The teams the service record names. Used as group sources 2 and 3. |
| company, company_id | Company of the service. Used for the incident company. |
| managed_by | Person responsible for the service. |
| u_bbsa_id, u_business_range, business_criticality | AXA custom ids and how critical the service is. |

### `steps`

One row per SILVA call task 2 made:

| Column | What it means | Example |
|---|---|---|
| step | Plain label. | "host by name or fqdn" |
| table | Table queried. | `cmdb_ci` |
| query | Encoded query sent. | `name=ts12^ORfqdn=ts12.hk.intraxa` |
| status | HTTP status. | 200 OK, 401 bad login, 403 no rights |
| matches | Rows returned. | 1 |
| error | First 200 characters of an error. | |

When a value looks wrong, read `steps` top to bottom: you see exactly which query found (or missed) it.

---

## 4. Other SILVA pieces used in both workflows

| Object | Table or field | What it is | Used where |
|---|---|---|---|
| Caller | `caller_id` → `sys_user` | Who reported the incident. Ours is the technical user Dynatrace JP. | OPEN body |
| On Behalf Of | `u_on_behalf_of` → `sys_user` | Who it is raised for. Same user. | OPEN body |
| Contact type | `contact_type` choice | How it was raised. We use `event`. | OPEN body |
| Category, Subcategory | choice fields | Classification. We send `other`. | OPEN body |
| Impact, Urgency | choice fields 1 to 4 | Together they give the Priority. We send 4 and 4 (lowest). | OPEN body |
| Short description | text, 160 characters max | Ticket title. | OPEN body |
| Description | long text | Event text plus Additional Information. | OPEN body |
| Correlation ID | `correlation_id` text | Id from an outside system. Ours is the Dynatrace display id. | OPEN writes, CLOSE searches |
| Incident number | `number` | Human id like INC30341416. | Output only |
| State | `state` choice | Standard state field. | CLOSE sends it |
| Incident State | `incident_state` choice | The field SILVA's form really uses. | CLOSE must set it to Resolved |
| Close code | `close_code` choice | Why it was resolved. We use "Solved (Permanently)". | CLOSE |
| Close notes | `close_notes` text | Resolution text, required to resolve. | CLOSE |
| Work notes | `work_notes` journal | Internal notes in Activities. | CLOSE |
| Allowed dropdown values | table `sys_choice` | Lists value and label for each choice field. | CLOSE checks before sending |
| CI to service link | table `svc_ci_assoc` | Says "this CI belongs to this service". | OPEN task 2 |
| CI relationships | table `cmdb_rel_ci` | Parent and child links between CIs, such as "Depends on". | OPEN task 2 |
| Field definitions | table `sys_dictionary` | Which fields exist, their labels and types. | Discovery (seq 41) |

---

## Data flow map

```
Dynatrace tags + host ts12.hk.intraxa
  → cmdb_ci (find server)                       → snow_required.cmdb_ci        → incident.u_configuration_item
  → svc_ci_assoc, cmdb_rel_ci, incident history → service_offering             → incident.cmdb_ci
  → offering.parent                             → cmdb_ci_service              → incident.u_business_service
  → service.company                             → core_company                 → incident.company
  → tag or service or CI group                  → sys_user_group               → incident.assignment_group
  → env tag or security context                 → environment label            → incident.u_environment
  → display_id                                                                  → incident.correlation_id
```

## Investigation

| Source | What it showed |
|---|---|
| OPEN task 2 and task 3 code (seq 36) | Which tables are queried and which incident field each value goes into. |
| SILVA form and sys_dictionary checks earlier today | `u_business_service` is the real Business service; `business_service` is ZZZ-Do-not-use; `cmdb_ci` is labelled Service Offering. |
| P-261090 preview and INC30341416 | Real ids: offering cfbf255f, business service 37273dbc, company AXA XL, caller 8ddef691. |

## Result

When you read task 2 output, map each object like this:

| Output object | SILVA table | Incident field |
|---|---|---|
| assignment_group | sys_user_group | assignment_group |
| business_service | cmdb_ci_service | u_business_service |
| service_offering | service_offering | cmdb_ci |
| cmdb_ci (server) | cmdb_ci | u_configuration_item |
| company | core_company | company |
| environment | choice list | u_environment |

## Related files

| File | What it is |
|---|---|
| `47-open-close-e2e-api-data-flow/` | Every API call |
| `41-how-to-build-workflows-apis-discovery/41.sh` | Discovery queries for these tables |
| `50.sh` | Curl one-liners to look at each object for a ticket |

## Commands

See [`50.sh`](50.sh).
