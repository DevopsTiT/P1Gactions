# SILVA Verify Checklist

## Decision tree

```
PREVIEW says data is ready
  Step A (before POST): does every sys_id point at a real, active record?
    user / group / service / offering / host / company missing or inactive → fix the mapping or tag
    business service is actually an offering → offering-skip bug
    offering parent is not the business service → wrong offering
    offering environment differs from the incident environment → confirm fallback rule
  Step B (before POST): are the choice values valid?
    impact 4, urgency 4, contact_type event, category other not in the list → change the value
  Step C (before POST): is there already an open incident with this correlation_id?
    yes → OPEN would skip, which is correct
  Step D (after the first real POST on stg): read the incident back
    field empty → key dropped by the API (wrong key or no write access)
    field different → a SILVA business rule overwrote it (e.g. assignment rule)
    all same → mapping is proven end to end
```

## Short takeaway

| Question | Answer |
|---|---|
| What is "verify from SILVA"? | Ask SILVA itself whether the values the workflow prepared are real and accepted, instead of trusting the workflow output. |
| What is checked before posting? | Every sys_id exists and is active, the service and offering relationship is right, the choice values are valid, and there is no duplicate. |
| What is checked after posting? | Read the incident back and compare each field with what the workflow sent. |
| Which instance? | silvastg only. The account does not work on production. |

## Summary

The PREVIEW workflow only proves the payload is shaped correctly. SILVA silently drops unknown keys and accepts sys_ids that point at nothing, so you confirm each value directly in SILVA tables. Then, after one real test POST on stg, you read the incident back to prove nothing was dropped or overwritten.

## Step A — every reference value exists (before POST)

| # | Field in payload | Value (P-260916434) | SILVA table | What must be true |
|---|---|---|---|---|
| 1 | caller_id and u_on_behalf_of | 8ddef691fb34cf547b0dfe7b4eefdcbc | sys_user | One row returned, and active is true. |
| 2 | assignment_group | 5223d8c61b8f3c54688064e4604bcb12 | sys_user_group | Name is Database_AXAJP, and active is true. |
| 3 | u_business_service | 03bd24ce1b477c54688064e4604bcbd4 | cmdb_ci_service | sys_class_name is cmdb_ci_service, not service_offering. |
| 4 | cmdb_ci (offering) | 3d62b88e1b877c54688064e4604bcba5 | service_offering | parent equals 03bd24ce…cbd4. |
| 5 | cmdb_ci (offering) | same | service_offering | operational_status is Operational. |
| 6 | cmdb_ci (offering) | same | service_offering | The name contains the incident environment, or the team accepts the fallback. |
| 7 | u_configuration_item | 485b4cee1b4d811050b89863b24bcbeb | cmdb_ci | name or fqdn matches host deaa310b. |
| 8 | u_configuration_item | same | cmdb_ci | install_status is Installed, not Retired. |
| 9 | company | 3e731d56dba4f6c8a476f9f51d96193f | core_company | One row returned with the expected company name. |

Optional sanity check: the offering's support_group should be the same as, or compatible with, Database_AXAJP. If it differs, SILVA assignment rules may move the ticket after creation.

## Step B — choice values are valid (before POST)

| Field | Value sent | What must be true |
|---|---|---|
| impact | 4 | Value 4 exists in sys_choice for incident.impact. |
| urgency | 4 | Value 4 exists in sys_choice for incident.urgency. |
| contact_type | event | Value event exists for incident.contact_type. |
| category | other | Value other exists for incident.category. |
| subcategory | other | Value other exists for incident.subcategory. |

An invalid choice value is often saved as-is but shows blank or "invalid" on the form, so it does not fail loudly.

## Step C — no duplicate (before POST)

| Check | What must be true |
|---|---|
| incident with correlation_id=P-260916434 and active=true | Empty list before the first POST. After OPEN posts, exactly one row. |

## Step D — read back after one real POST on stg

Run OPEN v7 once on stg (or with DRY_RUN false on a test problem), then read the incident back with `sysparm_display_value=all`.

| What to compare | Good result | Bad result and meaning |
|---|---|---|
| Every field sent | Same value and display name as the payload | Empty means the key was dropped (wrong key name or no write ACL). |
| assignment_group | Database_AXAJP | Different group means an assignment rule overrode it. |
| priority | Calculated from impact 4 and urgency 4 (normally 5 - Planning) | Unexpected priority means the priority matrix differs. |
| u_environment | Same as the payload | Different means a business rule sets it from the CI. |
| correlation_id | P-260916434 | Missing means duplicate protection will not work. |

## Data flow

```
Dynatrace problem
  → PREVIEW builds payload (sys_ids)
      → Step A: sys_user, sys_user_group, cmdb_ci_service, service_offering, cmdb_ci, core_company
      → Step B: sys_choice
      → Step C: incident (correlation_id, active)
  → OPEN v7 POST on stg
      → Step D: incident read back → compare with payload
  → mapping proven → enable for real alerts
```

## Related files

| File | Purpose |
|---|---|
| `21.sh` | All verify queries, one per line, in the order of the steps above. |
| `20-check-preview-p260916434/` | The PREVIEW result being verified. |
| `18-preview-v7-no-post/` | PREVIEW workflow. |
| `17-open-v7-silva-pagerduty/` | OPEN workflow used for Step D. |

## Commands

See `21.sh`. Lines 1–7 are Step A, line 8 is Step B, line 9 is Step C, line 10 is Step D, and the last two lines mirror this folder.
