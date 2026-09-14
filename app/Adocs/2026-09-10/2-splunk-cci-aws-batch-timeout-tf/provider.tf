terraform {
  required_providers {
    splunk = {
      source  = "splunk/splunk"
      version = "~> 1.4"
    }
  }
}

# Configure via env / tfvars, e.g.:
#   SPLUNK_URL, SPLUNK_USERNAME, SPLUNK_PASSWORD
# or provider block credentials per your org standard
provider "splunk" {
}
