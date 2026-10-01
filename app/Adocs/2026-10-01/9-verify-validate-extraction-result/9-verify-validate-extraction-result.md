# Verify Validate Extraction Result

## Decision Tree

```
validate-extraction result for P-260916434 (Oracle DB DEA10B01 down, host deaa310b)
 │
 ├─ used_sample_event = false?             → YES, real event was used. Good.
 ├─ caller_id / u_on_behalf_of a sys_id?   → NO, "Dynatrace JP" (name) → WRONG. Fixed: 8ddef691fb34cf547b0dfe7b4eefdcbc
 ├─ business_service == service_offering?  → YES, both 02a238ce...cbf9 → WRONG. Fixed: offering records excluded from service search
 ├─ choice lists (impact, urgency, ...)?   → all [] → NOT VERIFIED (no read access to sys_choice)
 ├─ u_environment = Integration / Test?    → from tag ACCEPTANCE, but tenant/name say STG → CONFIRM with team
 ├─ assignment_group 5223d8c6...cb12?      → should be Database_AXAJP (tag) → CHECK name with Q1
 └─ reference incident mismatches?         → INC30340215 is a different app; only constant fields must match
```

## Short Takeaway

| Question | Answer |
|---|---|
| Is the result right? | Not fully. Most fields look right, but there are 2 real bugs and 2 things to confirm. |
| Bug 1 | `caller_id` and `u_on_behalf_of` are sent as the name "Dynatrace JP". SILVA needs the sys_id `8ddef691fb34cf547b0dfe7b4eefdcbc`. |
| Bug 2 | `business_service` and `service_offering` are the same sys_id `02a238ce1b877c54688064e4604bcbf9`. One record cannot be both. |
| Not verified | `impact`, `urgency`, `category`, `subcategory`, `contact_type`, `u_environment` choice lists came back empty. |
| To confirm | Whether tag value ACCEPTANCE should map to "Integration / Test" or "Pre-Production". |
| Workflow updated | Yes, `4-v7-test-extraction-validate.workflow.yaml`. Run it again. |

## Summary

The workflow read the real problem (not the sample), extracted the tags, and built a full payload. Two values would be wrong in a real incident: the caller fields hold a name instead of a sys_id, and the business service is really an offering record. Both are fixed in the workflow. The choice values and the environment mapping still need a human check.

## Field By Field

| Field | Value in result | Verdict | Why |
|---|---|---|---|
| used_sample_event | false | OK | The real Davis event was used. |
| correlation_id | P-260916434 | OK | Matches the problem display ID. |
| short_description | [DYNATRACE JAPAN][deaa310b.prprivmgmt.intraxa] - Oracle DB Instance down | OK | Prefix, host and title are correct. |
| contact_type | event | OK | Same as reference incident (same_value true). |
| category | other | Probably OK | Constant setting. Compare with reference row in the result. |
| subcategory | other | Probably OK | Constant setting. |
| impact | 4 | Not verified | sys_choice list empty, so value 4 could not be checked. |
| urgency | 4 | Not verified | Same reason as impact. |
| caller_id | Dynatrace JP | WRONG | Reference field. A name is ignored by the Table API. Reference value is `8ddef691fb34cf547b0dfe7b4eefdcbc`. |
| u_on_behalf_of | Dynatrace JP | WRONG | Same as caller_id. |
| u_environment | Integration / Test | Confirm | Came from tag `AGO_AXAPATCHENVIRONMENT_ORACLE:ACCEPTANCE`. The tenant is "AXA AS STG". In many teams Acceptance means Pre-Production. |
| assignment_group | 5223d8c61b8f3c54688064e4604bcb12 | Check | Tags say `Database_AXAJP`. Run Q1 to confirm the sys_id is that group. |
| company | 3e731d56dba4f6c8a476f9f51d96193f | Check | Different from reference, which is expected (different app). Run Q2 for the name. |
| cmdb_ci | 485b4cee1b4d811050b89863b24bcbeb | Check | Should be host deaa310b or the DB instance. Run Q3. |
| business_service | 02a238ce1b877c54688064e4604bcbf9 | WRONG | Same as service_offering. |
| service_offering | 02a238ce1b877c54688064e4604bcbf9 | WRONG | Same as business_service. |

## Why Bug 2 Happens

| Fact | What it means |
|---|---|
| `service_offering` extends `cmdb_ci_service` in ServiceNow | A query on `cmdb_ci_service` also returns offering records. |
| The search by group/db type hit an offering | The workflow took it as the business service. |
| The offering lookup then found the same record | So both fields got one sys_id. |

Fix applied in task 2 `resolve-snow-values`:

| Change | Effect |
|---|---|
| `NOT_OFFERING = "^sys_class_name!=service_offering"` added to every business-service query | The service search returns only real services. |
| Guard: if the found service is an offering, use its `parent` as business service | Keeps the offering as `service_offering`. |
| `parent` added to `SERVICE_FIELDS` | Needed for the guard. |

Fix applied in task 3 `build-payload`:

| Setting | New value |
|---|---|
| CALLER_SYS_ID | 8ddef691fb34cf547b0dfe7b4eefdcbc |
| ON_BEHALF_OF_SYS_ID | 8ddef691fb34cf547b0dfe7b4eefdcbc |

## About The Reference Comparison

INC30340215 was created for the AGPO nginx problem, not this Oracle problem. So `same_value: false` for company, assignment_group, business_service, service_offering and environment is expected. Only the constant fields must match: caller_id, u_on_behalf_of, contact_type, category, subcategory.

## Empty Choice Lists

All six choice arrays are `[]`. The workflow then marks them WARN. Usual cause: the service account `Tech_DynatraceJP_WS` cannot read `sys_choice`. Two ways forward:

| Option | What to do |
|---|---|
| Ask the SILVA admin | Grant read on `sys_choice` to the service account. |
| Use the reference incident | Run Q4; if INC30340215 shows impact 4 and urgency 4 with the right labels, the values are valid. |

## Check Queries

Q1 assignment group name:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/sys_user_group" --data-urlencode "sysparm_query=sys_id=5223d8c61b8f3c54688064e4604bcb12" --data-urlencode "sysparm_fields=sys_id,name,active"
```

Q2 company name:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/core_company" --data-urlencode "sysparm_query=sys_id=3e731d56dba4f6c8a476f9f51d96193f" --data-urlencode "sysparm_fields=sys_id,name"
```

Q3 CI name:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/cmdb_ci" --data-urlencode "sysparm_query=sys_id=485b4cee1b4d811050b89863b24bcbeb" --data-urlencode "sysparm_fields=sys_id,name,fqdn,sys_class_name"
```

Q4 reference incident with labels:

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/incident" --data-urlencode "sysparm_query=number=INC30340215" --data-urlencode "sysparm_display_value=all" --data-urlencode "sysparm_fields=caller_id,u_on_behalf_of,impact,urgency,category,subcategory,contact_type,u_environment"
```

Q5 what is 02a238ce...cbf9 (expect class service_offering):

```bash
curl -s -u 'Tech_DynatraceJP_WS:<password>' -G "https://silvastg.service-now.com/api/now/table/cmdb_ci_service" --data-urlencode "sysparm_query=sys_id=02a238ce1b877c54688064e4604bcbf9" --data-urlencode "sysparm_display_value=all" --data-urlencode "sysparm_fields=sys_id,name,sys_class_name,parent,u_environment"
```

## Data Flow

```
Davis event P-260916434
  → extract-event-tags (env ACCEPTANCE → Integration / Test, group Database_AXAJP)
  → resolve-snow-values
       before: cmdb_ci_service search → offering 02a238ce → used as service AND offering
       after : search excludes offerings → real service → its offering for the environment
  → build-payload (caller now sys_id 8ddef691...)
  → validate-extraction (GET only) → verdict
```

## Related Files

| File | What it is |
|---|---|
| `../4-v7-test-extraction-validate/4-v7-test-extraction-validate.workflow.yaml` | Updated TEST workflow |
| `../7-query-silva-payload-values/7.sh` | Earlier SILVA queries |
| `9.sh` | Q1 to Q5 one-liners |
