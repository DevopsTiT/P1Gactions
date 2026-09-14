#!/usr/bin/env python3
"""Generate Splunk Task Timed Out alerts — same settings as CCI_AWS_Batch Time Out."""

from pathlib import Path

# Yellow-highlighted indexes from migration sheet (+ CCI reference already done)
INDEXES = [
    ("axa-li-jp-ccifa-commission", "AXA_LI_JP_CCIFA_Commission_AWS_Batch Time Out", "/aws/lambda/axa-li-jp-ccifa-commission-code-prod-ServicesHealthCheck", 7),
    ("b2b-auth0", "B2B_Auth0_AWS_Batch Time Out", "/aws/events/b2b-auth0-prod", 180),
    ("biloss-jyusei-ika-matching-check", "BILOSS_jyusei_ika_matching_check_AWS_Batch Time Out", "/aws/lambda/BILoss-jyusei-ika-matching-check-prod", 90),
    ("biloss-link-data-to-cc", "BILOSS_link_data_to_cc_AWS_Batch Time Out", "/aws/lambda/BILoss-link-data-to-cc-prod", 90),
    ("biloss-pre-processing", "BILOSS_pre_processing_AWS_Batch Time Out", "/aws/lambda/BILoss-pre-processing-prod", 90),
    ("biloss-processing", "BILOSS_processing_AWS_Batch Time Out", "/aws/lambda/BILoss-processing-prod", 90),
    ("biloss-retrieve-files-cmx", "BILOSS_retrieve_files_cmx_AWS_Batch Time Out", "/aws/lambda/BILoss-retrieve-files-cmx-prod", 90),
    ("biloss-upload-to-cmx", "BILOSS_upload_to_cmx_AWS_Batch Time Out", "/aws/lambda/BILoss-upload-to-cmx-prod", 90),
    # Same sheet, not yellow — include as siblings of CCI
    ("ccifa-commission-glue-etl", "CCIFA_commission_glue_etl_AWS_Batch Time Out", "/aws-glue/jobs/custom/ccifa-commission-glue-etl", 100),
    ("cloudfront", "CloudFront_AWS_Batch Time Out", "s3://alj-prod-cloudfront-singapore", 100),
]


def tf_resource(index: str, alert_name: str, source: str, retention: int) -> str:
    res = "alert_" + index.replace("-", "_")
    return f'''# Index: {index} | Source: {source} | Retention: {retention}d
resource "splunk_saved_searches" "{res}" {{
  name        = "{alert_name}"
  description = "Task timed out on index {index} (source: {source})"

  search = "index=\\"{index}\\" \\"Task timed out\\" | search message!=\\"*DEBUG*\\""

  is_scheduled           = true
  cron_schedule          = "*/5 * * * *"
  dispatch_earliest_time = "-5m"
  dispatch_latest_time   = "now"

  alert_type        = "number of events"
  alert_comparator  = "greater than"
  alert_threshold   = "0"
  alert_digest_mode = true
  alert_expires     = "24h"
  alert_track       = true
  alert_suppress    = false

  actions                          = "pagerduty"
  action_pagerduty_integration_key = var.pagerduty_integration_key
  action_pagerduty_custom_details  = jsonencode({{ job_label = "$job.label$" }})

  acl {{
    owner   = var.splunk_alert_owner
    sharing = var.splunk_alert_sharing
    app     = var.splunk_alert_app
  }}
}}
'''


def main():
    here = Path(__file__).resolve().parent
    alerts_dir = here / "alerts"
    alerts_dir.mkdir(parents=True, exist_ok=True)

    parts = [
        "# Auto-generated: same settings as CCI_AWS_Batch Time Out",
        "# Schedule */5, window -5m, results > 0 once, PagerDuty",
        "",
    ]
    for index, name, source, retention in INDEXES:
        block = tf_resource(index, name, source, retention)
        parts.append(block)
        (alerts_dir / f"alerting_{index.replace('-', '_')}_task_timed_out.tf").write_text(
            "# Same settings as CCI_AWS_Batch Time Out\n" + block, encoding="utf-8"
        )

    (here / "alerting_task_timed_out_all.tf").write_text("\n".join(parts), encoding="utf-8")
    print(f"wrote {len(INDEXES)} individual alerts + alerting_task_timed_out_all.tf")


if __name__ == "__main__":
    main()
