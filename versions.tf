terraform {
  required_version = ">= 1.6"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 5.0"
    }
  }
}
