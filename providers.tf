provider "fastly" {
  # Reads the FASTLY_API_KEY environment variable when api_key is null.
  api_key = var.fastly_api_key
}
