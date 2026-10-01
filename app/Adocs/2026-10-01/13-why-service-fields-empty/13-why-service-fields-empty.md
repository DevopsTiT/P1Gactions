# Why Service Fields Are Empty

## Decision Tree

```
API says business_service = "" and service_offering = "", but the form shows values
 │
 ├─ u_so_display_name missing from output?   → that key does not exist (or is hidden). Expected.
 │
 ├─ Cause 1: form uses DIFFERENT keys         → e.g. u_business_service, u_service_offering
 │     check: C1 (list keys with "service") and C3 (dictionary by label)
 │
 ├─ Cause 2: field-level read ACL             → account can read the incident but not these fields → ""
 │     check: C2 shows other fields filled, only service fields empty
 │
 └─ Cause 3: different instance               → form was on silva (prod), API is silvastg
       check: browser URL of the form; C5 queries prod
```

## Short Takeaway

| Question | Answer |
|---|---|
| What the API returned | `business_service: ""`, `service_offering: ""`, and no `u_so_display_name` at all |
| What it means | The standard fields exist but are empty for this incident, or your account cannot read them |
| Missing `u_so_display_name` | Key does not exist under that name (unknown keys are silently dropped) |
| Most likely cause | SILVA stores the form's "Business service" and "Service Offering" in custom fields with different keys, or an ACL hides them |
| How to know | Run C1 and C2 in `13.sh` |
| Why it matters | If the real keys differ, our payload keys `business_service` and `service_offering` would be ignored |

## Summary

The Table API returns `""` when a field exists but has no value you are allowed to see. The form clearly shows "Third Party Services Monitoring Application", so either the form label points at a different key, your service account is blocked from reading those two fields, or the form you looked at is on a different instance. One or two queries tell which.

## The Three Causes

| Cause | What it means | How it looks in the API | Check |
|---|---|---|---|
| Different key | The form label "Business service" is bound to a custom field, not the standard `business_service` | Standard key is `""`; a key like `u_business_service` has the value | C1, C3 |
| Field ACL | The account may read the incident row but not those fields | Other fields filled; only these are `""` | C2 |
| Different instance | Form screenshot from `silva.service-now.com` (prod); API is `silvastg` | The whole incident may differ (other short_description) | Browser URL, C4 vs C5 |

## Also Check The First Command

Your first command (`keys[]`) printed nothing visible. That list is the best evidence. Run it again with the `grep` filter in C1 so it is short enough to read.

## Check Queries

C1 which keys on this incident mention service, offering or CI:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" | jq -r '.result[0] | keys[]' | grep -i -E "service|offering|so_|cmdb|ci"
```

C2 values and labels of those keys:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all" | jq '.result[0] | with_entries(select(.key | test("service|offering|so_|cmdb_ci"; "i")))'
```

C3 which field has the label "service" or "offering":

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/sys_dictionary" -H 'Accept: application/json' --data-urlencode "sysparm_query=nameINincident,task^column_labelLIKEservice^ORcolumn_labelLIKEoffering" --data-urlencode "sysparm_fields=name,element,column_label,internal_type,reference" | jq '.result'
```

C4 same incident on stg, other fields for comparison:

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silvastg.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_fields=number,sys_id,short_description,cmdb_ci,assignment_group,u_environment,business_service,service_offering" --data-urlencode "sysparm_display_value=all" | jq '.result[0]'
```

C5 only if the form was on prod (the account may not exist there):

```bash
curl -s -u 'Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}' -G "https://silva.service-now.com/api/now/v2/table/incident" -H 'Accept: application/json' --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_fields=number,short_description,business_service,service_offering" | jq '.'
```

## How To Read The Answers

| You see | Cause | What to do |
|---|---|---|
| C1 shows `u_business_service` or similar, and C2 shows the name there | Different key | Change the payload keys to those names |
| C2 shows `cmdb_ci` and `assignment_group` filled, service fields `""`, and C1 lists no other service key | Field ACL | Ask the SILVA admin to grant read on `incident.business_service` and `incident.service_offering` to `Tech_DynatraceJP_WS` |
| C4 short_description is not "EPAS Filter Error" | Different instance | Use the incident on the same instance as the workflow |
| C4 everything empty except number | Row-level ACL or data not copied to stg | Pick a newer incident created on stg |

## Impact On The Workflow

| Finding | Workflow change |
|---|---|
| Different key | Rename `business_service` and `service_offering` in build-payload to the real keys |
| ACL | Writing may still work; reading back (validate task) will show `""` until access is granted |
| Same sys_id question (bug 2) | Cannot be answered from this incident until C2 shows real values |

## Data Flow

```
form label "Business service" ──► real key? (C1 / C3)
                                     ├─ business_service    → "" here (empty or ACL)
                                     └─ u_... custom key    → value? (C2)
API account ──► field ACL ──► allowed → value | denied → ""
```

## Related Files

| File | What it is |
|---|---|
| `13.sh` | C1 to C5 |
| `../12-verify-keys-queries-with-creds/` | Queries that produced this result |
| `../9-verify-validate-extraction-result/` | Bug 2 (service == offering) that this question decides |
