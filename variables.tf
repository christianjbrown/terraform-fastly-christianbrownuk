variable "fastly_api_key" {
  description = "Fastly API token. Prefer the FASTLY_API_KEY env var so it is never written to disk."
  type        = string
  sensitive   = true
  default     = null # falls back to the FASTLY_API_KEY environment variable
}

variable "gcp_project" {
  description = "GCP project that owns the Cloud Functions backend and the Secret Manager secret."
  type        = string
  default     = "christianbrown"
}

variable "gcp_region" {
  description = "GCP region the Cloud Functions run in; combined with the project to form the backend host."
  type        = string
  default     = "europe-west2"
}

variable "request_auth_secret_name" {
  description = "Secret Manager secret holding the shared X-Request-Auth gate value (the same secret the Cloud Functions read)."
  type        = string
  default     = "FASTLY_REQUIRED_HEADER_VALUE"
}

variable "service_domains" {
  description = "Domains served by the Fastly service: the real hostname plus its Fastly-managed TLS aliases."
  type        = list(string)
  default = [
    "cdn.christianbrown.uk",
    "cb-api.global.ssl.fastly.net",
    "christianbrown.global.ssl.fastly.net",
  ]
}

variable "backend_shield" {
  description = "Fastly shield POP that origin fetches are routed through."
  type        = string
  default     = "lon-london-uk"
}

# The X-Request-Auth secret value is NOT a variable — it is read from GCP Secret
# Manager (var.request_auth_secret_name), the same source the Cloud Functions use.
# See the google_secret_manager_secret_version data source in main.tf.
