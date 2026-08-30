output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "build_events_queue_url" {
  value = aws_sqs_queue.build_events.url
}

output "next_hint" {
  value = "LocalStack free supports S3+SQS here. Use real AWS later for ECR."
}
