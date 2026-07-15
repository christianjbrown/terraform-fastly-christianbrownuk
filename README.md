# Terraform configuration for christianbrown.uk APIs

Terraform — the **source of truth** — for the Fastly VCL service that fronts the
GCP Cloud Functions telemetry API at **`cdn.christianbrown.uk`**
(service id `7ieJm1LpaPnVCNb3tzURac`).

It manages the domains, the Cloud Functions backend, HSTS + force-TLS, the
query-string strip that protects the single-instance origin, and the injected
`X-Request-Auth` gate header (value read from Secret Manager, never stored here).

## How it fits together

- **State** lives in a private, versioned GCS bucket (`christianbrown-tf-state`,
  public-access-prevention enforced) — never on disk in CI, never in git.
- **The gate secret** is read at plan/apply time from GCP Secret Manager
  (`SMARTTHINGS_REQUIRED_HEADER_VALUE`) — the same secret the Cloud Function
  uses. It is `sensitive`, so it is redacted in plan output.
- **CI** (`.github/workflows/terraform.yml`) runs `fmt`/`validate`/`plan` on every
  PR and `apply` on merge to `main`. It authenticates to GCP via **Workload
  Identity Federation** (no JSON keys) using a dedicated, least-privilege service
  account (`fastly-tf@…`) that can only touch the state bucket and that one secret.

## Repo layout

| File | Purpose |
| --- | --- |
| `main.tf` | The `fastly_service_vcl` resource + the Secret Manager data source |
| `providers.tf` / `versions.tf` | fastly + google providers, pinned |
| `backend.tf` | GCS remote-state config |
| `variables.tf` | Only `fastly_api_key` (via env/secret) |
| `.github/workflows/terraform.yml` | plan-on-PR / apply-on-main CI |
| `vcl/rl_telemetry_*.vcl` | Staged rate limiter (needs Fastly to enable VCL rate limiting) |

## Local use

```sh
export FASTLY_API_KEY="…"                                   # a Fastly token
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"  # GCP auth
terraform init
terraform plan     # should report: No changes
```

Changes flow through a **PR** (CI shows the plan) and apply on merge — do not edit
the service in the Fastly UI/CLI, or you introduce drift.

## One-time setup that is NOT in code

- **`FASTLY_API_KEY` repo secret** — create a dedicated Fastly **automation token**
  with write access to this service (Fastly UI → Account → API tokens) and set it:
  `gh secret set FASTLY_API_KEY --repo christianjbrown/terraform-christian-fastly`.
  (Don't reuse a personal/SSO token for CI.)
- GCP resources already provisioned: the state bucket, the `fastly-tf` service
  account + its bucket/secret grants, and the `fastly-terraform` WIF provider
  (scoped to this repo). Repo variables `GCP_WIF_PROVIDER` / `GCP_SERVICE_ACCOUNT`
  point CI at them.

## Enabling the rate limiter later

`ratecounter`/`penaltybox` need Fastly to switch on **VCL rate limiting** for the
service (a support/account request — not self-serve). Once enabled, add the three
`rl_telemetry_*` snippet blocks (commented in `main.tf`) and open a PR. Thresholds:
429 + 5-min penalty above 10 req/s (1s) or 2 req/s (60s), per client IP.

## Public-repo notes

Everything here is safe to be public: no secret is committed, and state + CI
credentials live in access-controlled GCP/GitHub, not the repo. The `GCS` bucket,
GitHub Actions secrets, and Fastly token stay private even though the code is open.
