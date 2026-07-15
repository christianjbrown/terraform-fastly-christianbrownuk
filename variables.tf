variable "fastly_api_key" {
  description = "Fastly API token. Prefer the FASTLY_API_KEY env var so it is never written to disk."
  type        = string
  sensitive   = true
  default     = null # falls back to the FASTLY_API_KEY environment variable
}

variable "request_auth_value" {
  description = <<-EOT
    Secret value Fastly injects as the X-Request-Auth request header so the
    origin Cloud Function's header gate is satisfied without the browser ever
    seeing it. Supply via TF_VAR_request_auth_value (or a secret manager) —
    never hardcode it or commit it. Must equal the SMARTTHINGS_REQUIRED_HEADER_VALUE
    secret the function reads from Secret Manager.
  EOT
  type        = string
  sensitive   = true
}
