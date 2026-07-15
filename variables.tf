variable "fastly_api_key" {
  description = "Fastly API token. Prefer the FASTLY_API_KEY env var so it is never written to disk."
  type        = string
  sensitive   = true
  default     = null # falls back to the FASTLY_API_KEY environment variable
}

# The X-Request-Auth secret is NOT a variable — it is read from GCP Secret Manager
# (SMARTTHINGS_REQUIRED_HEADER_VALUE), the same source the Cloud Function uses. See
# the google_secret_manager_secret_version data source in main.tf.
