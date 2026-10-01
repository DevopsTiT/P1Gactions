# SILVA Table Versus Incident Field

## Decision tree

```
Looking at the cheat sheet row?
 Left column  "SILVA table"    → the LIST in SILVA where the real thing is stored
 Right column "Incident field" → the BOX on the ticket that points to one item in that list
 Box holds a 32-character code? → that is the item's id (sys_id) from the left-column list
 Left says "choice list"?       → no list of records; the box just holds a dropdown word
```

## Short takeaway

| Question | Answer |
|---|---|
| What is this table? | A cheat sheet: for each box on a SILVA ticket, which SILVA list the value comes from. |
| Left column | The SILVA table (think: one spreadsheet) that holds those things. |
| Right column | The field name (box) on the incident ticket. |
| What is stored in the box? | The id of one row from the left-column table, not its name. |
| Why does it matter? | The workflow must search the left table to get the id, then put it in the right box. |

## Summary

SILVA keeps teams, services, servers and companies in separate lists (tables). A ticket does not copy their details; each box on the ticket just points to one row in one of those lists. This cheat sheet tells you which list each box points to.

## Analogy

Think of a school:

| School thing | SILVA thing |
|---|---|
| Student list, teacher list, class list | Tables (`sys_user_group`, `cmdb_ci_service`, ...) |
| A homework sheet with boxes "Teacher" and "Class" | The incident ticket with its fields |
| Writing the teacher's staff number in the "Teacher" box | Writing a team's sys_id in `assignment_group` |

## Each row, in plain words

| Ticket box (right) | SILVA list it points to (left) | What that list contains | Example for INC30341416 |
|---|---|---|---|
| `assignment_group` | `sys_user_group` | Teams | The team that works the ticket |
| `u_business_service` | `cmdb_ci_service` | Business services (what the business uses) | Business service 37273dbc |
| `cmdb_ci` | `service_offering` | Service offerings (one service in one environment) | Offering cfbf255f |
| `u_configuration_item` | `cmdb_ci` | All configuration items: servers, databases, apps | Server ts12.hk.intraxa |
| `company` | `core_company` | Companies | AXA XL |
| `u_environment` | choice list | Not a list of records, just allowed words | Pre-Production |

## Two things that confuse everyone

| Confusing point | Plain answer |
|---|---|
| `cmdb_ci` appears in both columns | Left: `cmdb_ci` is the table of all servers and other items. Right: `cmdb_ci` is a box on the ticket that SILVA uses for the Service Offering. Same name, different meaning. |
| Fields starting with `u_` | `u_` means AXA added that box themselves. It is not in standard ServiceNow. |

## What it looks like inside the ticket

```
INC30341416
  assignment_group     = 7f3a...   ──► row in sys_user_group     (team name)
  u_business_service   = 37273dbc  ──► row in cmdb_ci_service    (business service)
  cmdb_ci              = cfbf255f  ──► row in service_offering   (offering)
  u_configuration_item = a91c...   ──► row in cmdb_ci            (server ts12)
  company              = 5e02...   ──► row in core_company       (AXA XL)
  u_environment        = Pre-Production  (just a word)
```

The ids `7f3a...`, `a91c...` and `5e02...` above are placeholders to show the shape.

## Data flow map

```
workflow searches LEFT table → gets the row's id → writes id into RIGHT box → SILVA shows the name on the form
```

## Investigation

| Source | Note |
|---|---|
| Seq 50 result table | This is the same table, shown in your screenshot. |
| OPEN task 3 (lines 828 to 849) | Where each id is written into the incident body. |

## Result

Read each row as: "this ticket box points to one item in that SILVA list".

## Related files

| File | What it is |
|---|---|
| `50-silva-cmdb-ci-sysid-explained/` | Full explanation of tables and ids |
| `52-silva-field-mapping-plain-explained/` | How the workflow finds each value |
| `53.sh` | Curl to see the boxes and their names on INC30341416 |

## Commands

See [`53.sh`](53.sh).
