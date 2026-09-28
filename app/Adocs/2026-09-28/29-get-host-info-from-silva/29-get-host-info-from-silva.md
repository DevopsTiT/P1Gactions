# Get Host Info From SILVA

## Decision Tree

```
What do you need from SILVA?
 host record (CI)?               -> cmdb_ci / cmdb_ci_server   search by name (short or FQDN)
 business service of a host?     -> open the CI -> Related Items / svc_ci_assoc
 offering of that service?       -> service_offering where parent = business service
 which group supports it?        -> business service / CI field "Support group"
 is a group name valid?          -> sys_user_group
 valid environment labels?       -> sys_choice (incident, u_environment)
 what did an existing INC get?   -> incident by number or correlation_id
 all groups / all services list? -> seq 18 exports
Way to look
 UI  -> type "<table>.list" in the SILVA filter navigator, filter, open record
 API -> Table API with Tech_DynatraceJP_WS (29.sh)
 empty result but UI shows it -> API user lacks read access (ACL) -> ask SILVA admin
```

## Short Takeaway

| You want | SILVA table | UI shortcut | Key field |
|---|---|---|---|
| Host record | `cmdb_ci_server` (or `cmdb_ci`) | `cmdb_ci_server.list` | name, fqdn |
| Business service of the host | `svc_ci_assoc` | Open the CI, "Business Services" related list | service_id |
| Service offering | `service_offering` | `service_offering.list` | parent (business service) |
| Support group | `cmdb_ci_service` or the CI | Field "Support group" on the record | support_group |
| Group exists | `sys_user_group` | `sys_user_group.list` | name, active |
| Environment labels | `sys_choice` | Environment dropdown on an incident | label |
| Existing incident | `incident` | `incident.list` | number, correlation_id |

## Summary

Everything the workflow needs lives in a few SILVA tables. Start from the host: find its CI record, then follow its link to the business service and offering, and read the support group. You can do this in the SILVA web UI by typing a table name followed by `.list`, or with the Table API commands in `29.sh`.

## Method 1: SILVA UI (Easiest)

Log in to https://silvastg.service-now.com with your own account.

### Step A: Find the host (CI)

| Step | Action |
|---|---|
| 1 | In the left filter navigator type `cmdb_ci_server.list`, press Enter |
| 2 | Filter Name contains `ts12` (the short host name) |
| 3 | Open the record. Check Name, FQDN, Install Status (Installed = active) |
| 4 | Note the Support group and Environment fields if shown |

If nothing is found, try `cmdb_ci.list` (all CI types, not only servers).

### Step B: Find its business service

| Step | Action |
|---|---|
| 1 | On the CI record scroll to the related lists at the bottom |
| 2 | Look for "Business Services", "Services" or "Impacted Services" |
| 3 | Or type `svc_ci_assoc.list`, filter "Configuration item" is `ts12.hk.intraxa` |
| 4 | The "Service" column is the business service (e.g. Third Party Services Monitoring Application) |

### Step C: Find the offering and support group

| Step | Action |
|---|---|
| 1 | Click the business service to open it |
| 2 | Read "Support group", "Managed by group" and "Operational status" |
| 3 | Type `service_offering.list`, filter Parent is that business service |
| 4 | Note the full offering Name and its Environment |

### Step D: Check a group and environment labels

| Step | Action |
|---|---|
| 1 | Type `sys_user_group.list`, filter Name is `InfraSupport_Dist-WindowsHK_L2_ASIA`, check Active = true |
| 2 | Open any incident, click the Environment dropdown; those are the valid labels |

### Step E: See what an incident received

| Step | Action |
|---|---|
| 1 | Type `incident.list`, filter Number is `INC30339746` (or Correlation ID is the problem id) |
| 2 | Open it and read Configuration item, Business service, Service offering, Assignment group, Environment |

## Method 2: Table API (Scriptable)

All commands are one-liners in `29.sh`. Replace `__SNOW_PASSWORD__` and the host name. Example for the host:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci?sysparm_query=name=ts12.hk.intraxa%5EORname=ts12%5EORfqdn=ts12.hk.intraxa&sysparm_fields=sys_id,name,fqdn,sys_class_name,install_status,support_group&sysparm_display_value=true&sysparm_exclude_reference_link=true" | jq '.result'
```

| Command in 29.sh | Answers |
|---|---|
| 1 | Is the host in the CMDB, under which name and class |
| 2 | Which business service the host belongs to (svc_ci_assoc) |
| 3 | Business service details and support group |
| 4 | Offerings of that business service |
| 5 | Does the group exist and is it active |
| 6 | Valid Environment labels |
| 7 | What an existing incident received |

## Reading The API Result

| What you see | Meaning | Action |
|---|---|---|
| `"result": []` | No match, or no read access | Try the UI; if the UI shows it, ask the SILVA admin for read access for Tech_DynatraceJP_WS |
| HTTP 401 | Wrong password | Check the password |
| HTTP 403 | Table blocked for this user | Ask for read access (cmdb_ci, svc_ci_assoc, cmdb_ci_service, service_offering, sys_user_group, sys_choice) |
| Several rows | Same name in several classes | Use the one with install_status / operational_status 1 |

## How This Feeds The Workflow

| SILVA info | Where it goes |
|---|---|
| Host exists as CI | Workflow sends it as cmdb_ci, SILVA fills the service |
| Host linked to a service in svc_ci_assoc | Backup when SILVA does not fill it |
| Business service name + offering name | SYSTEM_MAP rows or defaults |
| Group name | SYSTEM_MAP l2Group or DEFAULT_GROUPS |
| Environment labels | ENVIRONMENT and SILVA_ENVIRONMENTS settings |

## Data Flow Map

```
host name (from Dynatrace)
   -> cmdb_ci (CI record: name, fqdn, support group)
   -> svc_ci_assoc (CI -> business service)
   -> cmdb_ci_service (business service: support group, status)
   -> service_offering (parent = business service: offering name, environment)
   -> sys_user_group (group valid?)   sys_choice (environment labels)
```

## Related Files

| File | Purpose |
|---|---|
| `29.sh` | All lookup commands |
| `../18-silva-export-groups-business-services/` | Export all groups and services to CSV |
| `../28-how-env-service-group-derived/` | How the workflow uses these values |

## Commands

See `29.sh` (not run by me).
