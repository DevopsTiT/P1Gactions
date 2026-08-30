locals {
  name = "p1gactions-sim"
}

# LocalStack Community–safe only (no ECR — free LocalStack returns 501)
resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name}-artifacts"

  tags = {
    Project = "P1Gactions"
    Purpose = "simulate-terraform-aws-build"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sqs_queue" "build_events" {
  name = "${local.name}-build-events"

  tags = {
    Project = "P1Gactions"
    Purpose = "simulate-terraform-aws-build"
  }
}
