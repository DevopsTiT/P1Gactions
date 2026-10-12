# AppEngine Usage And Smartscape Nodes

## Decision tree

```
Cell result?
 AppEngine daily invocations by type       → counts billable function runs per day: ad hoc, custom actions, app functions
 AppEngine users and apps, 0 records       → no "AppEngine Functions - Small" billing records in 30 days
     check first                           → list billing event types (A0)
     still none                            → functions are not billed separately, or not used
 CoPilot "couldn't generate a valid DQL"   → prompt too vague → name the data, the filter and the output
 smartscapeNodes("ACTIVE_GATE"), 0 records → ACTIVE_GATE is not a node type here (see the type list)
     need ActiveGates                      → Deployment Status page or the ActiveGate API
 smartscapeNodes("*") count by type        → inventory: 2,327 hosts, 2,327 OneAgents, 35,280 processes ...
     HOST == ONEAGENT                      → every host has an agent
     no AWS types                          → explains why "AWS*" earlier had nothing to count
```

## Short takeaway

| Cell | What it does | Result | Main point |
|---|---|---|---|
| Q | AppEngine invocations per day by function type | Not shown | Counts billable runs. `scanLimitGBytes:-1` removes the safety limit. |
| R | AppEngine invocations by user and calling app | 0 records over 30 days | No such billing records. Check event type names first. |
| S | CoPilot prompt | Error | CoPilot could not turn the sentence into DQL. |
| T | List ActiveGates from Smartscape | 0 records | `ACTIVE_GATE` is not one of the node types in this tenant. |
| U | Count all Smartscape nodes by type | 8 types | A quick inventory of the whole environment. |

## Summary

The AppEngine cells come from Dynatrace's billing notebook and count serverless function runs. The users-and-apps cell is empty because there are no billable AppEngine records in the window. The last cell is the most useful one here: one line gives a full inventory of the environment, and it also explains why the ActiveGate and AWS queries return nothing.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| AppEngine | Dynatrace's platform for running apps and code inside Dynatrace. | Its function runs can be billed. |
| AppEngine function | A small piece of code run on demand. | Counted as invocations. |
| Ad hoc function | Code you run directly, for example "Run JavaScript" in a notebook or workflow. | One type in the chart. |
| Custom action | A reusable step in a workflow, built by an app. | Another type. |
| App function | The backend code of a Dynatrace app. | The third type. |
| Invocation | One run of a function. | The billing unit. |
| `scanLimitGBytes` | The maximum data a query may read. `-1` means no limit. | No limit can mean slow and costly queries. |
| Smartscape | Dynatrace's live map of everything it monitors and how things connect. | `smartscapeNodes` reads it. |
| Node | One thing on that map: a host, a disk, a process. | Counted by type in cell U. |
| ActiveGate | A Dynatrace relay server that forwards agent traffic and runs cloud or remote checks. | Cell T tried to list them. |

### Cell Q: daily AppEngine invocations by function type

```
fetch dt.system.events, scanLimitGBytes: -1
| filter event.type == "AppEngine Functions - Small"
| filter event.kind == "BILLING_USAGE_EVENT"
| filter (billing_type == "BILLABLE" OR isNull(billing_type))
| fieldsAdd data = if(matchesPhrase(function.type, "AD_HOC"), "Ad hoc functions",
                 else: if(matchesPhrase(function.type, "ACTION"), "Custom actions",
                 else: if(matchesPhrase(function.type, "STANDARD"), "App functions")))
| summarize { billed_invocations = takeAny(billed_invocations) }, by:{ day = bin(timestamp, 1d), event.id, data }
| summarize { invocations = sum(if(billed_invocations, billed_invocations, else:1)) }, by:{ data, day }
| sort day desc, invocations desc
```

| Line | What it does |
|---|---|
| `scanLimitGBytes: -1` | Removes the default limit on how much data the query reads |
| `event.type == "AppEngine Functions - Small"` | Only the "Small" size of function billing |
| `billing_type == "BILLABLE" OR isNull(...)` | Skips free runs |
| `fieldsAdd data = if(...)` | Turns the technical type into a readable label |
| First `summarize ... by event.id` with `takeAny` | Keeps one value per billing record. Same idea as `dedup event.id`. |
| Second `summarize ... sum(if(billed_invocations, ..., else:1))` | Adds up invocations; a record with no number counts as one run |
| `sort` | Newest day first, biggest type first |

Points to note:

| Point | Explanation |
|---|---|
| No limit on scanning | Fine for billing events, which are small, but a bad habit on logs or spans |
| `if(billed_invocations, ...)` | Uses a number as a yes or no test. `coalesce(billed_invocations, 1)` says the same thing more clearly. |
| Types not matched | A function type outside the three becomes empty. The improved version labels it "Other". |

### Cell R: users and apps, 0 records

```
fetch dt.system.events, scanLimitGBytes: -1
| filter event.type == "AppEngine Functions - Small"
| filter event.kind == "BILLING_USAGE_EVENT"
| filter (billing_type == "BILLABLE" OR isNull(billing_type))
| summarize { billed_invocations = takeAny(billed_invocations) },
    by:{ startHour = bin(timestamp, 1h), event.id, user.email, caller.app.id }
| summarize { invocations = sum(if(billed_invocations, billed_invocations, else:1)) },
    by:{ {user.email, alias:User}, {caller.app.id, alias:Calling_App} }
| sort invocations desc
```

| Part | What it does |
|---|---|
| Group by `user.email` and `caller.app.id` | Who ran the functions and from which app |
| `{user.email, alias:User}` | Groups by the field and names the column `User` |

Why 0 records over 4/8 to 5/8:

| Possible cause | How likely | How to check |
|---|---|---|
| No billable AppEngine "Small" runs in those 30 days | Most likely | Query A0 lists every billing event type that exists |
| The event type has a different name in this tenant | Possible | A0 shows the exact names |
| No permission to read system events | Unlikely | The earlier billing cells returned data, so access works |

### Cell S: CoPilot error

"I'm sorry, but I couldn't generate a valid DQL query from your request." The prompt itself is not visible. CoPilot works best when the sentence names three things: the data (logs, hosts, spans), the filter (which host, which status), and the output (a list, a count, a chart).

### Cell T: ActiveGates from Smartscape, 0 records

```
smartscapeNodes("ACTIVE_GATE")
| fields entity.name, type, properties
| sort entity.name asc
```

| Point | Explanation |
|---|---|
| Why 0 | Cell U lists every node type in this tenant, and `ACTIVE_GATE` is not among them |
| Field names | Smartscape nodes may use different field names from the classic entity tables. Look at one node first with query T2. |
| Where to find ActiveGates | Deployment Status, then ActiveGates in the Dynatrace UI, or the ActiveGate API (command in `9.sh`) |

### Cell U: Smartscape node count by type

```
smartscapeNodes("*")
| summarize count(), by:{type}
```

| type | count | What it means |
|---|---|---|
| PROCESS | 35,280 | Monitored processes, about 15 per host |
| DISK | 7,543 | Disks, about 3 per host |
| NETWORK_INTERFACE | 3,138 | Network cards, a bit more than 1 per host |
| HOST | 2,327 | Servers, VMs and Kubernetes nodes |
| ONEAGENT | 2,327 | Installed OneAgents |
| SERVICE | 1,942 | Detected services |
| CONTAINER | 1,089 | Containers |
| FRONTEND | 14 | Real User Monitoring frontends, such as web or mobile apps |

What it tells you:

| Observation | Meaning |
|---|---|
| HOST and ONEAGENT are both 2,327 | Every host has exactly one agent. No orphan agents or agentless hosts. |
| 2,327 hosts | Confirms why host lists stopped at the 1,000-row limit in earlier cells |
| No AWS types | AWS resources are not in this Smartscape yet, which is why `smartscapeNodes "AWS*"` earlier had nothing to count |
| No ACTIVE_GATE type | Explains cell T |
| Window is one hour (5/15 23:30 to 5/16 00:30) | Counts are what was seen in that hour. A longer window can include hosts that were removed. |

## Result

| Cell | Verdict | Fix or use |
|---|---|---|
| Q | Works | Use `coalesce(..., 1)`; avoid `scanLimitGBytes:-1` on large data |
| R | Empty | Run A0 to confirm the billing event names |
| S | CoPilot failed | Rewrite the prompt with data, filter and output |
| T | Type does not exist | Use Deployment Status or the ActiveGate API |
| U | Works, very useful | Keep it as the environment inventory |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Guessing a node type or event type name | List what exists first (T1, A0) |
| Removing the scan limit by habit | Only on small data like billing events |
| Vague CoPilot prompts | Name data, filter and output |
| Comparing counts from different windows | Use the same timeframe |

## Data flow map

```
AppEngine billing
  function runs (ad hoc, custom actions, app functions)
    → dt.system.events (BILLING_USAGE_EVENT, "AppEngine Functions - Small")
    → dedup per event.id → sum invocations
    ├─ by day and type → cell Q
    └─ by user and calling app → cell R (0 records: no such records)

Smartscape
  OneAgent and integrations → Smartscape nodes
    → smartscapeNodes("*") count by type → cell U (inventory)
    → smartscapeNodes("ACTIVE_GATE") → cell T (type not present)
    → smartscapeNodes("AWS*") → earlier cell (type not present)
```

## Related files

| File | What it is |
|---|---|
| `9-dynatrace-appengine-smartscape-explain-improved.dql` | Billing type check, clearer AppEngine queries, node inventory with ratios |
| `6-dynatrace-billed-hosts-smartscape-processes-explain/` | The earlier `smartscapeNodes "AWS*"` error |
| `3-glossary.md` | Terms |
| `9.sh` | ActiveGate API call and git one-liners |

## Commands

These are in `9.sh`. Nothing has been run. Set `DT_ENV_URL` to your environment URL and `DT_API_TOKEN` to a token with the `activeGates.read` scope first.

```bash
curl -s -H "Authorization: Api-Token $DT_API_TOKEN" "$DT_ENV_URL/api/v2/activeGates"
```
