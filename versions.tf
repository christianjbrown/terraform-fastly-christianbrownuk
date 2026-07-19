terraform {
  required_version = ">= 1.6"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "~> 9.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
