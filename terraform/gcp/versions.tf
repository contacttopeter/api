terraform {
  required_version = ">= 1.1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.1"
    }
  }
  backend "gcs" {
    bucket = "will_be_replaced"
    prefix = "will_be_replaced"
  }
}
