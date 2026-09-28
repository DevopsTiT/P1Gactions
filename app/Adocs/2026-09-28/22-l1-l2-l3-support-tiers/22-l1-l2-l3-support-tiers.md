# L1 L2 L3 Support Tiers

## Decision Tree

```
Alert / incident arrives
 L1 (first line) can fix with a runbook? (restart, known workaround, check dashboard)
   yes -> fix, resolve, done
   no  -> escalate to L2
 L2 (application / platform team) can fix? (config, logs, deploy rollback, DB query)
   yes -> fix, resolve, write notes
   no  -> escalate to L3
 L3 (developers / vendor / architects) -> code fix, bug patch, vendor ticket, design change
 Production outage (impact 1)? -> skip L1, go straight to L2 (our workflow does this)
```

## Short Takeaway

| Tier | Who | What they do |
|---|---|---|
| L1 | Service desk or monitoring / NOC team | Receive the ticket, check it, apply known fixes, escalate |
| L2 | The team that runs the application or platform | Investigate deeper and fix most real problems |
| L3 | Developers, architects or the vendor | Fix code bugs and design issues nobody else can fix |
| Our workflow | Sends to L2 by default | Per Abhay, the ticket goes straight to the L2 SILVA group |

## Summary

L1, L2 and L3 are levels of support. Each level has more knowledge and more access than the one before. A ticket starts at the lowest level that can handle it and moves up (escalates) only when that level cannot fix it. Think of a hospital: the nurse at reception (L1), the general doctor (L2), then the specialist surgeon (L3).

## Each Tier In Detail

### L1: First line

| Aspect | Detail |
|---|---|
| Who | Service desk, NOC (network operations center) or monitoring team |
| Typical work | Read the alert, check whether it is real, follow a runbook |
| Examples | Restart a service, clear disk space, check if a known issue is already open |
| Access | Limited: dashboards, runbooks, basic tools |
| Goal | Fix fast or pass on quickly with good notes |

### L2: Second line

| Aspect | Detail |
|---|---|
| Who | The application support or platform team that owns the system (for EIP, the EIP support team) |
| Typical work | Read logs, check configuration, look at Dynatrace traces, roll back a deploy |
| Examples | Fix a wrong config value, scale a pod, tune a database connection pool |
| Access | Servers, Kubernetes, application logs, deployment tools |
| Goal | Find the cause and fix most incidents |

### L3: Third line

| Aspect | Detail |
|---|---|
| Who | Developers, architects, or the software vendor |
| Typical work | Debug code, write a patch, change the design, open a vendor case |
| Examples | Fix a memory leak in the code, patch a library bug |
| Access | Source code, build pipelines, vendor support |
| Goal | Permanent fix for problems L2 cannot solve |

## Why Teams Use Tiers

| Reason | What it means |
|---|---|
| Protects expert time | Developers are not woken up for a disk-full alert. |
| Faster simple fixes | L1 handles common issues in minutes with runbooks. |
| Clear ownership | Everyone knows who owns the ticket at each moment. |
| Better notes | Each escalation carries what was already tried. |

## How It Maps To Our Workflow

| Workflow setting | Meaning |
|---|---|
| `DEFAULT_GROUPS.L1` = "Dynatrace Support" | First-line group, used only if `DEFAULT_TIER` is "L1" |
| `DEFAULT_GROUPS.L2` = "Ops_Middleware_Monitoring_AXAJP" | Default L2 group for systems not in the map |
| `DEFAULT_GROUPS.L3` = placeholder | Only printed in the "Escalation path" line of the notes |
| `SYSTEM_MAP.<system>.l1Group` / `l2Group` | Per-system groups, for example the EIP L2 team |
| `DEFAULT_TIER = "L2"` | Abhay's rule: pass the L2 group by default |
| Impact 1 in Production | Always L2, even if `DEFAULT_TIER` is "L1" |

The workflow only sets the **first** group. Moving the ticket to L3 is done by people in SILVA (they change the assignment group), not by the workflow.

## Common Mistakes

| Mistake | What happens | Better |
|---|---|---|
| Sending everything to L3 | Developers get flooded and ignore alerts | Start at L1 or L2 |
| Escalating without notes | The next tier repeats the same checks | Write what was checked and the result |
| No L1 runbooks | L1 escalates everything, so L1 adds no value | Write runbooks for the top alerts |
| Using a group name that does not exist in SILVA | The group field is left blank | Copy the exact name from `sys_user_group` |

## Data Flow Map

```
Dynatrace problem -> workflow -> SILVA INC
   assignment_group = L2 group (map or default)
        |
        | L2 cannot fix
        v
   people change assignment_group to L3 in SILVA
        |
        v
   L3 fixes code / vendor -> INC resolved (or Dynatrace closes it -> CLOSE workflow)
```

## Related Files

| File | Purpose |
|---|---|
| `../20-silva-system-data-map/` | YAMLs with DEFAULT_GROUPS and DEFAULT_TIER |
| `../21-next-steps-two-yamls/` | What to fill in next |
| `22.sh` | Command to find group names in SILVA |

## Commands

See `22.sh` (not run by me).
