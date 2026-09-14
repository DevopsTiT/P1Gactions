terraform {
  required_providers {
    dynatrace = {
      source  = "dynatrace-oss/dynatrace"
      version = "~> 1.30.0"
    }
  }

  backend "s3" {
    bucket       = "axa-li-jp-dynatrace-as-code-dev"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
    key          = "applications/billingcenter/test/terraform.tfstate"
  }
}

provider "dynatrace" {
}
