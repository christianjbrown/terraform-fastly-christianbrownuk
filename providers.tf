provider "fastly" {
  # Reads the FASTLY_API_KEY environment variable when api_key is null.
  api_key = var.fastly_api_key
}

provider "google" {
  # Used only to read the X-Request-Auth secret from Secret Manager.
  # Auth via Application Default Credentials, GOOGLE_OAUTH_ACCESS_TOKEN, or (in CI)
  # Workload Identity Federation.
  project = "christianbrown"
}
