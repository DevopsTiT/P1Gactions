# How The Workflow Fills The SILVA Form

## Decision tree

```
Which box on the SILVA form am I filling?
 Configuration item  → start from the host name      → look up the server in SILVA
 Service Offering    → start from the server          → ask "which service does this server belong to?"
 Business service    → start from the offering        → read the offering's parent
 Company             → start from the business service → read its company
 Assignment group    → try in order: Dynatrace tag, service's team, server's team, default team
 Environment         → start from a Dynatrace tag     → translate PRE into "Pre-Production" (no lookup)
 Correlation ID      → just copy the problem id P-261090 (no lookup)
```

## Short takeaway

| Question | Answer |
|---|---|
| What is the map really saying? | Each line is one box on the SILVA incident form, and how the workflow finds what to put in it. |
| Why can't we just type names? | SILVA boxes need the record's id (sys_id), not its name. So the workflow must look each one up. |
| What does Dynatrace give us to start? | A host name (ts12.hk.intraxa), some tags (like env:PRE), and a problem id (P-261090). |
| Why is it a chain? | Each lookup uses the answer from the one before: server, then offering, then business service, then company. |
| Which boxes need no SILVA lookup? | Environment (translated from a tag) and Correlation ID (copied). |

## Summary

Think of filling a paper form for a broken machine. Dynatrace only tells you the machine's name and the problem number. To fill the form properly, you go to the company directory (SILVA) and look things up one by one: first the machine's record, then which service it belongs to, then which business that service is part of, then which company owns it, and which team fixes it. Each answer leads to the next. That is all the map shows.

---

## How to read one line of the map

```
Dynatrace tags + host ts12.hk.intraxa
  → cmdb_ci (find server)  → snow_required.cmdb_ci  → incident.u_configuration_item
    ───────────────────      ─────────────────────    ────────────────────────────
    1. WHERE we look         2. WHAT we keep           3. WHICH BOX on the form
       in SILVA                 in the workflow           it goes into
```

| Column | Plain meaning |
|---|---|
| First arrow | The SILVA table (like a phone book) we search, or the field we read. |
| Second arrow | The name of the answer inside the workflow output (what task 2 returns). |
| Third arrow | The box on the incident form where task 3 puts the answer. |

---

## What we start with (from Dynatrace)

| Dynatrace gives us | Example | Used for |
|---|---|---|
| Host name | ts12.hk.intraxa | Finding the server in SILVA |
| Tags | env:PRE, company:ALJ, maybe a group tag | Environment and team |
| Security context | ALJ_PRE | Environment backup |
| Problem id | P-261090 | Correlation ID |

---

## The seven boxes, one at a time

### Box 1: Configuration item (the server)

```
host ts12.hk.intraxa → search table cmdb_ci → found the server → put its id in u_configuration_item
```

| Step | What happens in plain words |
|---|---|
| Start | Dynatrace says the problem is on `ts12.hk.intraxa`. |
| Look up | The workflow asks SILVA's server list (table `cmdb_ci`): "Do you have a server called ts12 or ts12.hk.intraxa?" |
| Answer | SILVA returns one row: name ts12, class Windows server, and its id (sys_id), a 32-character code. |
| Keep | Saved in the workflow as `snow_required.cmdb_ci`. |
| Form box | That id goes into the form box "Configuration item" (field `u_configuration_item`). |

Analogy: you know a colleague's name, you look them up in the staff directory, and you write down their employee number.

### Box 2: Service Offering (which service this server runs)

```
server ts12 → ask 3 places "which service is this server part of?" → offering cfbf255f → put in cmdb_ci
```

| Step | What happens in plain words |
|---|---|
| Start | We now know the server's id. |
| Look up, place 1 | Table `svc_ci_assoc`: a list of "this server belongs to that service" links. |
| Look up, place 2 | Table `cmdb_rel_ci`: a list of "this thing depends on that thing" links. |
| Look up, place 3 | Past tickets: "On the last 20 tickets for ts12, which Service Offering did people choose?" |
| Answer for P-261090 | Place 3 won: all 20 of the last 20 tickets used offering `cfbf255f`. |
| Keep | `snow_required.service_offering`. |
| Form box | Goes into "Service Offering". The field's technical name is `cmdb_ci` (confusing, but that is how SILVA set it up). |

What a Service Offering is: one service in one environment. For example "Payments, Pre-Production" and "Payments, Production" are two offerings of the same service.

### Box 3: Business service (the bigger service the offering belongs to)

```
offering cfbf255f → read its "parent" field → business service 37273dbc → put in u_business_service
```

| Step | What happens in plain words |
|---|---|
| Start | We have the offering. |
| Look up | Every offering record has a field "parent" that names its business service. |
| Answer | Parent = business service `37273dbc`. |
| Keep | `snow_required.business_service`. |
| Form box | "Business service" (field `u_business_service`). |

Analogy: the offering is "Payments, Pre-Production", and its parent is simply "Payments".

### Box 4: Company

```
business service 37273dbc → read its "company" field → AXA XL → put in company
```

| Step | What happens in plain words |
|---|---|
| Start | We have the business service record. |
| Look up | It has a field "company". |
| Answer | AXA XL (with its id). |
| Backup | If the service has no company, use the server's company, then the team's company, then the text "AXA GROUP OPERATIONS". |
| Form box | "Company" (field `company`). |

### Box 5: Assignment group (which team gets the ticket)

```
try 1: group tag in Dynatrace?          → yes: use it (if it exists in SILVA)
try 2: business service's assignment group?
try 3: business service's support group?
try 4: server's support group?
try 5: default team Ops_Middleware_Monitoring_AXAJP
→ first one found goes into assignment_group
```

| Try | Where the team name comes from | Plain meaning |
|---|---|---|
| 1 | A tag on the Dynatrace entity, like `ago_axa_supportgroup:<team>` | The app team said who owns it. |
| 2 | Business service record, "Assignment group" | The service's official team. |
| 3 | Business service record, "Support group" | The service's support team. |
| 4 | Server record, "Support group" | The team that looks after the server. |
| 5 | Setting `DEFAULT_GROUP` | Nobody found, so the monitoring team takes it. |

Form box: "Assignment group" (field `assignment_group`), stored as the team's id from table `sys_user_group`.

### Box 6: Environment

```
tag env:PRE (or security context ALJ_PRE) → translate PRE → "Pre-Production" → put in u_environment
```

| Step | What happens in plain words |
|---|---|
| Start | Dynatrace tag `env:PRE`. If missing, the security context `ALJ_PRE`. |
| Translate | A small dictionary in the workflow: PRE, stg, staging become "Pre-Production"; prd becomes "Production"; and so on. |
| No SILVA lookup | It is a dropdown value, not a record, so no id is needed. |
| Form box | "Environment" (field `u_environment`). |
| Also used | To pick the offering that matches this environment. |

### Box 7: Correlation ID

```
problem id P-261090 → copy as is → correlation_id
```

| Step | What happens in plain words |
|---|---|
| Start | Dynatrace problem number P-261090. |
| No lookup | Just copied. |
| Form box | "Correlation ID" (field `correlation_id`). |
| Why it matters | When the problem closes, the CLOSE workflow searches SILVA for "the ticket with Correlation ID P-261090" to resolve it. |

---

## The whole thing as one chain

```
Dynatrace says: "problem P-261090 on ts12.hk.intraxa, tag env:PRE"
        │
        ├─ host name ──► [SILVA server list] ──► server ts12 (id) ─────────► Configuration item
        │                      │
        │                      ▼
        │              [links + past tickets] ──► offering cfbf255f ──────► Service Offering
        │                      │
        │                      ▼ (offering's parent)
        │              business service 37273dbc ─────────────────────────► Business service
        │                      │
        │                      ▼ (service's company)
        │              AXA XL ─────────────────────────────────────────────► Company
        │
        ├─ group tag, or service team, or server team, or default ─────────► Assignment group
        ├─ env:PRE ──► dictionary ──► "Pre-Production" ────────────────────► Environment
        └─ P-261090 ──► copy ───────────────────────────────────────────────► Correlation ID
```

## The filled form for P-261090

| Form box | Field name | What goes in | Where it came from |
|---|---|---|---|
| Configuration item | `u_configuration_item` | id of server ts12 | Search by host name |
| Service Offering | `cmdb_ci` | cfbf255f... | Past 20 tickets on ts12 |
| Business service | `u_business_service` | 37273dbc... | Offering's parent |
| Company | `company` | id of AXA XL | Business service's company |
| Assignment group | `assignment_group` | id of the team | First of: tag, service, server, default |
| Environment | `u_environment` | Pre-Production | Tag translated |
| Correlation ID | `correlation_id` | P-261090 | Copied |

Result: ticket INC30341416 with all boxes filled.

## Common confusions

| Confusion | Plain answer |
|---|---|
| "cmdb_ci" appears twice | As a **table** it is the server list. As a **form field** it is the Service Offering box. |
| Why not put the server in `cmdb_ci`? | SILVA uses `cmdb_ci` for the offering, and added its own box `u_configuration_item` for the server. |
| Why look at past tickets? | Some servers have no direct link to an offering. Past tickets show what people picked by hand. |
| Why ids, not names? | Names can repeat or change. The id always points to exactly one record. |

## Data flow map

```
host → server → offering → business service → company
tag/service/server → team
env tag → environment
problem id → correlation id
```

## Investigation

| Source | Used for |
|---|---|
| OPEN task 2 code (seq 36, lines 460 to 719) | Order of lookups and fallbacks |
| P-261090 results (seq 35) | Real offering, business service and company |

## Result

Read the map as "for each form box: where we look, what we keep, where it goes". The first four boxes are a chain; the last three are independent.

## Related files

| File | What it is |
|---|---|
| `50-silva-cmdb-ci-sysid-explained/` | What each SILVA table and id means |
| `51-workflows-functions-api-traces/` | Exact API calls for these lookups |
| `52.sh` | Curl lines to check each box for INC30341416 |

## Commands

See [`52.sh`](52.sh).
