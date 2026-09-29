# Investigation

## What the step-1 result showed

| Item | Value seen | Comment |
|---|---|---|
| Problem | P-260916434, Oracle DB Instance down | Real event |
| DB name | DEA10B01 | From the Oracle instance entity field |
| Host | deaa310b | From the `host` tag |
| Tag count | 13 | All parsed |
| Group tag used | AGO_DEFAULT_ASSIGNMENT_GROUP | A specific Oracle group tag also exists |
| Oracle group tag | AGO_ORACLE_ASSIGNMENT_GROUP:Database_AXAJP | Same value today, but it could differ on other hosts |
| Business service tag | none | A search is the only option |
| Domain tag | none | The workflow tries the DOMAINS list |
| Environment source | AGO_AXAPATCHENVIRONMENT_ORACLE:ACCEPTANCE | A patch tag, so used only as a fallback now |
| Maintenance | event field and AGO_Maintenance tag | The event field is now read first |
| Problems API | failed, missing scope | `environment-api:problems:read` still needs adding |

## Checks done

| Check | Result |
|---|---|
| Compared the v3 group order with the tags | The default tag won over the specific tag |
| Checked whether v3 confirms the group in SILVA | It did not; only the name was used |
| Checked the v3 search 1 query | It used a name LIKE; v4 uses the exact group sys_id |
| Checked the event fields for maintenance | `maintenance.is_under_maintenance` exists |
