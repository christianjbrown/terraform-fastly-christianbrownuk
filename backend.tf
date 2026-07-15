# Remote state. Terraform state can contain sensitive values (e.g. the injected
# X-Request-Auth secret), so it must NOT live in git. You are already on GCP, so
# a GCS bucket is the natural home.
#
# 1. Create a private, versioned bucket once (outside Terraform):
#      gcloud storage buckets create gs://christianbrown-tf-state \
#        --location=europe-west2 --uniform-bucket-level-access
#      gcloud storage buckets update gs://christianbrown-tf-state --versioning
# 2. Uncomment the block below and run `terraform init` to migrate state.
#
# Until then, Terraform uses local state (./terraform.tfstate) — which is
# gitignored. Do not commit it.

# terraform {
#   backend "gcs" {
#     bucket = "christianbrown-tf-state"
#     prefix = "fastly/cdn"
#   }
# }
