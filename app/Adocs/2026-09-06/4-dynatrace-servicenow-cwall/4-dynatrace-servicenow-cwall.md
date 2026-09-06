# Dynatrace ServiceNow And CWall

```
What did you mean by “CWall”?
  │
  ├─ Most likely typo / shorthand → ServiceNow CMDB (config DB)
  ├─ Or “wall” = NOC / war-room wallboard showing Dynatrace + SNOW tickets
  ├─ Or internal project code → ask team for exact name
  └─ Standard product stack → Dynatrace ↔ ServiceNow (Incident + CMDB/Service Graph)
```

| Question | Answer |
| --- | --- |
| Is there a product named CWall? | **No** public Dynatrace/ServiceNow product by that name |
| Best guess | **CMDB** (or a **wallboard** that shows tickets + health) |
| What Dynatrace + ServiceNow usually means | Problems → tickets; topology → CMDB; optional auto-remediation |
| Why SRE cares | One place for “what broke” (Dynatrace) and “who owns / what CI / ticket” (ServiceNow) |

## Summary

**Dynatrace** finds and explains problems (Davis AI, Smartscape). **ServiceNow** is the ITSM/CMDB system (incidents, changes, configuration items). Together they close the loop: detect in Dynatrace → open/update a ServiceNow incident tied to the right CI → humans or workflows remediate → ticket closes. **“CWall”** is not an official connector name; treat it as either **CMDB**, a **display wall**, or an **internal label** until your team confirms.

---

## What each system is (beginner)

| System | Plain English | Job |
| --- | --- | --- |
| **Dynatrace** | Observability / APM | Sees hosts, services, problems, root cause, metrics, logs |
| **ServiceNow** | IT service management | Incidents, changes, CMDB (inventory of CIs), workflows |
| **CMDB** | Configuration Management Database | “What servers/apps exist and how they relate” inside ServiceNow |
| **Service Graph** | Modern CMDB + relationships | ServiceNow’s richer topology store; Dynatrace can feed it |

---

## How Dynatrace and ServiceNow connect

Three common integration lanes (you may have one or all):

| Lane | Direction | What happens |
| --- | --- | --- |
| **Incident / Problem notification** | Dynatrace → ServiceNow | Davis **Problem** opens → ServiceNow **Incident** (or Event) with severity, title, URL, impacted entities |
| **Event Management** | Dynatrace → ServiceNow ITOM | Individual events land in `em_event`; correlated to incidents/CIs |
| **CMDB / Service Graph** | Dynatrace → ServiceNow (pull or connector) | Hosts, services, process groups sync as **CIs** so tickets attach to the right config item |

Official Dynatrace doc: [Send notifications to ServiceNow](https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/servicenow-integration).

ServiceNow side often uses **Service Graph Connector for Observability – Dynatrace** (CMDB ingest) — different from some Dynatrace-branded connectors; check which app your org installed.

---

## Happy-path story (on-call)

```
1. App slows / errors
2. Dynatrace Davis opens a Problem (+ root cause entity)
3. Problem notification fires to ServiceNow
4. ServiceNow creates/updates Incident
5. Incident linked to CMDB CI (host/service) if sync is healthy
6. Assignee works ticket; may open Dynatrace Problem URL for RCA
7. Fix → Dynatrace Problem closes → ticket can auto-resolve/update
```

| Step | Dynatrace | ServiceNow |
| --- | --- | --- |
| Detect | Problem + Davis RCA | — |
| Record | Problem ID / URL in payload | Incident number |
| Context | Smartscape topology | CI in CMDB |
| Act | Optional Workflows | Assignment, change, runbook |
| Close | Problem closed | Incident resolved |

---

## If “CWall” means CMDB

Then “Dynatrace ServiceNow CMDB” means:

| Topic | Meaning |
| --- | --- |
| Goal | Keep ServiceNow’s inventory aligned with what Dynatrace actually sees |
| Typical CIs | Servers (Windows/Linux), applications/services, process groups, sometimes DBs |
| Why it matters | Incident lands on the **correct CI**; impact and ownership are clearer |
| Failure mode | Ticket with no CI / wrong CI → slow routing, bad audits |

---

## If “CWall” means a wallboard

Some NOCs call a big screen a “wall”:

| Tile idea | Source |
| --- | --- |
| Open Dynatrace problems | Dynatrace dashboard |
| Open P1/P2 incidents | ServiceNow report / Performance Analytics |
| Same incident ID / Problem URL | Integration payload |

That is a **display**, not a separate product named CWall.

---

## Common mistakes

| Mistake | What goes wrong |
| --- | --- |
| Dual connectors fighting | Duplicate incidents or duplicate CIs |
| No CI sync | Incidents without ownership / impact |
| Alerting everything to SNOW | Ticket flood; use alerting profiles / severity filters |
| Ignoring Problem close | Tickets stay open after Dynatrace recovers |
| Mixing STG and prod MZ into one SNOW assignment group | Wrong team paged |

---

## Investigation

No match for product name **CWall** in Dynatrace docs, ServiceNow store naming, or your CursorFiles. Explained the standard **Dynatrace ↔ ServiceNow** stack and mapped **CWall → CMDB / wallboard / internal code** as hypotheses.

---

## Result

Treat the question as: **how Dynatrace and ServiceNow work together** (problems → incidents, topology → CMDB). Confirm with your team what **CWall** labels in your org. If you meant **CMDB**, the Service Graph / CMDB connector path is the piece to learn next.

---

## Data flow map

```
Dynatrace Davis Problem
        │
        ├─► Problem notification / webhook
        │         │
        │         ▼
        │   ServiceNow Incident / Event
        │         │
        │         ▼
        │   Linked CMDB CI (if synced)
        │
        └─► Service Graph / CMDB sync (hosts, services)
                  │
                  ▼
            Accurate CI for tickets & impact
```

---

## Related files

| File | Purpose |
| --- | --- |
| This note | Explanation |
| Dynatrace ServiceNow docs | https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/servicenow-integration |

## Commands

None required for this concept answer.
