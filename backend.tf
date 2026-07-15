# Remote state in a private, versioned GCS bucket (public-access-prevention
# enforced). State can contain sensitive values, so it must never be committed —
# it lives here, access-controlled by GCP IAM, not in git.
#
# Bucket bootstrap (run once, already done):
#   gcloud storage buckets create gs://christianbrown-tf-state \
#     --project=christianbrown --location=europe-west2 \
#     --uniform-bucket-level-access --public-access-prevention
#   gcloud storage buckets update gs://christianbrown-tf-state --versioning
#
# Auth: uses Application Default Credentials, or GOOGLE_OAUTH_ACCESS_TOKEN
# (e.g. `export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)`).

terraform {
  backend "gcs" {
    bucket = "christianbrown-tf-state"
    prefix = "fastly/cdn"
  }
}
