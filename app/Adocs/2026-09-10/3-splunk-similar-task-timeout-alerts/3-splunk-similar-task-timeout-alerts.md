# Similar Splunk Task Timeout Alerts

```
CCI_AWS_Batch Time Out settings
  → same cron / window / trigger / PagerDuty
  → one alert per migration-sheet index (yellow + CCI siblings)
```

| Key point | Detail |
| --- | --- |
| Template | Seq 2 `CCI_AWS_Batch Time Out` |
| Same settings | Cron `*/5`, `-5m`→`now`, results > 0 once, PagerDuty |
| Same SPL shape | `index="<name>" "Task timed out" \| search message!="*DEBUG*"` |
| Count | 10 alerts (8 yellow + glue-etl + cloudfront) |

## Summary

Cloned the CCI Splunk alert Terraform settings onto the other indexes from your Excel sheet. Use either the single combined file or the per-index files under `alerts/`.

## Indexes covered

| Index | Alert name | Retention |
| --- | --- | --- |
| axa-li-jp-ccifa-commission | AXA_LI_JP_CCIFA_Commission_AWS_Batch Time Out | 7 |
| b2b-auth0 | B2B_Auth0_AWS_Batch Time Out | 180 |
| biloss-jyusei-ika-matching-check | BILOSS_jyusei_ika_matching_check_AWS_Batch Time Out | 90 |
| biloss-link-data-to-cc | BILOSS_link_data_to_cc_AWS_Batch Time Out | 90 |
| biloss-pre-processing | BILOSS_pre_processing_AWS_Batch Time Out | 90 |
| biloss-processing | BILOSS_processing_AWS_Batch Time Out | 90 |
| biloss-retrieve-files-cmx | BILOSS_retrieve_files_cmx_AWS_Batch Time Out | 90 |
| biloss-upload-to-cmx | BILOSS_upload_to_cmx_AWS_Batch Time Out | 90 |
| ccifa-commission-glue-etl | CCIFA_commission_glue_etl_AWS_Batch Time Out | 100 |
| cloudfront | CloudFront_AWS_Batch Time Out | 100 |

`cci-fa-comm-calc` stays in seq **2** (original).

## Files

| Path | Purpose |
| --- | --- |
| `alerting_task_timed_out_all.tf` | All 10 resources in one file |
| `alerts/*.tf` | One file per index (same content) |
| `variables.tf` / `provider.tf` | Shared PD key + Splunk provider |
| `terraform.tfvars.example` | Secret placeholder |
| `3_generate_similar_alerts.py` | Regenerate |

## Note

Search string is the **same pattern** as CCI (Task timed out). If an index needs a different keyword, edit that one resource’s `search` only.

## Data flow

```
Sheet index → Splunk search every 5m
  → "Task timed out" (non-DEBUG)
  → count > 0 → PagerDuty
```

## Commands

See `3.sh`.
