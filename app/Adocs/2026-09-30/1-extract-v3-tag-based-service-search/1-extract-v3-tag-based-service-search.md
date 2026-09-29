# Extract v3 Tag Based Service Search

## Decision tree

```
Alert tags → search terms
   group   = AGO_DEFAULT_ASSIGNMENT_GROUP  (Database_AXAJP)
   dbType  = AGO_DB                        (ORACLE)
   envTag  = AGO_AXAPATCHENVIRONMENT_*     (ACCEPTANCE)
   region  = AGO_CSP_REGION_* minus "-1"   (AP-SOUTHEAST)
   trigram = AGO_AXAOPCOTRIGRAM_*          (ALJ)
   host    = host tag                      (deaa310b)
 │
 ├─ A SERVICE_MAP / service tag?  → exact service name → FOUND
 ├─ B host: name=deaa310b ^OR fqdn=deaa310b.<domain> (query.sh style)
 │      CI found → its business_service / service field → svc_ci_assoc → cmdb_rel_ci → FOUND
 ├─ C tag searches (your query.sh searches), results merged:
 │      1 assignment_group.nameLIKE Database_AXAJP
 │      2 nameLIKE ORACLE ^ nameLIKE ACCEPTANCE
 │      3 nameLIKE ORACLE ^ nameLIKE AP-SOUTHEAST
 │      4 nameLIKE ALJ
 │      5 technical services: nameLIKE ORACLE ^ nameLIKE ACCEPTANCE
 │    score each service → best ≥ 5 and clearly ahead → FOUND
 │                       → tie or low score → NOT FOUND, top 10 listed with scores
 ├─ D offering under the service for the environment
 └─ E group tag → sys_user_group
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from v2? | The lookup now uses the searches from your working `query.sh`, built automatically from the tags |
| Which searches? | Host by name or fqdn, services by assignment group, by DB type plus environment, by DB type plus region, by trigram, and technical services |
| How is one service chosen? | Every service found gets a score from how well it matches the tags. The best one wins if it has at least 5 points and is ahead of the second. |
| What if two services tie? | Nothing is picked. `lookup.service_candidates` shows the top 10 with scores and reasons, so you can put the right one in `SERVICE_MAP`. |
| Output format? | Same as v2: picture 5 layout plus decision, SNOW payload and PagerDuty payload. Nothing is sent. |

## Summary

Your queries work because they search SILVA with the values the tags already give: the group, the DB type, the environment and the region. They also look up the host with its full domain. v3 runs exactly those searches from the tag values, merges the results, and scores each service so one can be picked without you choosing by hand. File: `1-extract-v3-tag-based-service-search.workflow.yaml`.

## Your query.sh mapped to v3

| Your query | v3 search | Built from |
|---|---|---|
| `cmdb_ci name=WNDSQL11 ^OR fqdn=WNDSQL11.axa-id.intraxa`, fields include `service`, `business_service` | "host by name or fqdn" | host tag plus `AGO_DOMAIN` tag or the `DOMAINS` list |
| `cmdb_ci_service assignment_group.nameLIKE Database_AXAJP` | "search 1 by assignment group" (also checks support_group) | group tag |
| `cmdb_ci_service nameLIKE Oracle ^ nameLIKE Acceptance` | "search 2 by db type + environment" | `AGO_DB` plus environment tag |
| `cmdb_ci_service nameLIKE Oracle ^ nameLIKE AP-SOUTHEAST` | "search 3 by db type + region" | `AGO_DB` plus region tag without the trailing `-1` |
| `cmdb_ci_service_technical nameLIKE Infrastructure` | "search 5 technical by db type + environment" | `AGO_DB` plus environment tag |
| (new) | "search 4 by trigram" | trigram tag |

SILVA text search (`LIKE`) is not case sensitive, so `ORACLE` matches `Oracle`.

## How the score works

| Match | Points | Your Oracle example |
|---|---|---|
| Assignment group or support group equals the tag group | 3 | Database_AXAJP |
| Name contains the DB type | 2 | ORACLE |
| Name contains the environment tag | 2 | ACCEPTANCE |
| Name contains the region prefix | 1 | AP-SOUTHEAST |
| Name contains the trigram as a whole word | 2 | ALJ |
| Operational (status 1) | 1 | |
| Business service class, or classification is Business Service | 1 | |
| Found by more than one search | 1 per extra search | for example found by search 1 and 2 = +1 |

A service needs at least `MIN_SCORE` (5) and must be ahead of the second one. For example, "Oracle Acceptance AP-SOUTHEAST" owned by Database_AXAJP scores 3 + 2 + 2 + 1 + 1 + 2 extra searches = 11 or more.

## Where to look in the output

| Output field | What it tells you |
|---|---|
| `servicenow_enrichment` | The chosen service in the picture 5 layout (empty values when not found) |
| `servicenow_enrichment.match_method` | How it was found, for example `tag search (score 11: group Database_AXAJP, name has ORACLE, ...)` |
| `lookup.search_terms` | The values used in the searches (group, dbType, envTag, regionPrefix, trigram) |
| `lookup.service_candidates` | Top 10 services with score, found_by and reasons |
| `lookup.cis_found` | Host or DB CIs found, with fqdn |
| `lookup.steps` | Every SILVA GET with query, status and match count |
| `decision` | Create or skip (maintenance), group and environment |
| `snow_incident_payload` / `pagerduty_payload` | What OPEN would send |

## Settings to check

| Setting | Task | What to set |
|---|---|---|
| `DOMAINS` | lookup-silva | Your host domains, for example `axa-id.intraxa`. The `AGO_DOMAIN` tag is tried first. |
| `MIN_SCORE` | lookup-silva | Raise it if a wrong service is picked, lower it if nothing is picked |
| `SERVICE_MAP` | lookup-silva | Fixed answers, for example `ALJ: "<exact name>"`. Wins over every search. |
| `ENVIRONMENT` | extract-event-tags | Environment tag value to SILVA label (confirm ACCEPTANCE) |
| `SKIP_WHEN_MAINTENANCE` | display-result | `false` to always create the incident, even when `AGO_Maintenance` is True |

## Steps

1. Add `environment-api:problems:read` in the workflow Authorization settings (from the last run).
2. Import the v3 YAML and press Run.
3. Open `display-result` and read `match_method` and `service_candidates`.
4. If the right service is in the candidates but was not picked, add it to `SERVICE_MAP`, or adjust `MIN_SCORE`.
5. Once the result is right, reuse `snow_incident_payload` and `pagerduty_payload` in OPEN.

## Data flow map

```
tags ─► search terms (group, dbType, envTag, regionPrefix, trigram, host, domain)
            │
            ├─ A SERVICE_MAP / service tag ────────────► cmdb_ci_service (exact)
            ├─ B host name / fqdn.domain ─► cmdb_ci ─► business_service field
            │                                        ─► svc_ci_assoc ─► cmdb_rel_ci
            ├─ C search 1 group ─┐
            │   search 2 db+env ─┤
            │   search 3 db+reg ─┼─► merge by sys_id ─► score ─► best (≥5, clear) or candidates
            │   search 4 trigram┤
            │   search 5 technical┘
            ├─ D service_offering (env)
            └─ E sys_user_group (tag group)
                         ▼
     display-result: dynatrace_alert + servicenow_enrichment + decision
                     + snow_incident_payload + pagerduty_payload + lookup
```

## Related files

| File | Purpose |
|---|---|
| `1-extract-v3-tag-based-service-search.workflow.yaml` | The v3 workflow |
| `1.sh` | Your query.sh searches as safe one-liners for the Oracle example (not run) |
| `../../2026-09-29/3-extract-v2-snow-pd-ready-output/` | v2 |

## Commands

See `1.sh`. Example (search 2):

```bash
curl -s -G -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_service" --data-urlencode "sysparm_query=nameLIKEOracle^nameLIKEAcceptance" --data-urlencode "sysparm_fields=sys_id,name,number,assignment_group,support_group,operational_status,sys_class_name" --data-urlencode "sysparm_display_value=true" --data-urlencode "sysparm_limit=20" | jq -r '.result[] | [.name,.number,.assignment_group,.support_group] | @tsv'
```
