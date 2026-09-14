# CCI AWS Batch Time Out as Dynatrace metric_events (review before apply)
echo "Copy alerting_cci_aws_batch_timeout.tf into your dynatrace-terraform app stack (e.g. applications/cci/test/)"
echo "terraform plan — confirm log metric key log.cci.aws.batch.task_timed_out"
echo "PagerDuty: wire via Dynatrace Problem notification (not inside metric_events)"
echo "If aws.log_group missing, switch to looser query in the .tf comments"
