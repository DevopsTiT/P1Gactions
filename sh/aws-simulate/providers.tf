variable "use_localstack" {
  type    = bool
  default = true
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

provider "aws" {
  region = var.aws_region

  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      s3  = "http://127.0.0.1:4566"
      sqs = "http://127.0.0.1:4566"
      iam = "http://127.0.0.1:4566"
      sts = "http://127.0.0.1:4566"
    }
  }
}
