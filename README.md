# fastly-terraform-christianbrown

Terraform for the Fastly VCL service that fronts the GCP Cloud Functions
telemetry API at **`cdn.christianbrown.uk`** (service id `7ieJm1LpaPnVCNb3tzURac`).

It codifies what was previously hand-configured: the domain, the Cloud Functions
backend, and the custom VCL — the live **query-strip** mitigation plus the staged
(not-yet-enabled) **per-client rate limiter**.

## Layout

| File | Purpose |
| --- | --- |
| `main.tf` | The `fastly_service_vcl` resource (domain, backend, VCL snippets) |
| `providers.tf` / `versions.tf` | Provider + version pins |
| `backend.tf` | GCS remote-state config (commented until you create the bucket) |
| `variables.tf` / `terraform.tfvars.example` | Inputs, incl. the secret auth-header value |
| `vcl/strip_query.vcl` | **Live** — collapses cache-busting query strings to protect the 1-instance origin |
| `vcl/rl_telemetry_*.vcl` | Staged rate limiter — needs Fastly to enable VCL rate limiting first |

## Prerequisites

```sh
brew install terraform            # not installed yet
export FASTLY_API_KEY="<token>"   # same token the fastly CLI uses
export TF_VAR_request_auth_value="<the X-Request-Auth secret>"
```

## Adopt the existing service (import first — do NOT apply blind)

This service is **already live**. Terraform must *import* it, not recreate it.

```sh
terraform init
terraform import fastly_service_vcl.cdn 7ieJm1LpaPnVCNb3tzURac
terraform plan     # expect a diff — reconcile main.tf until the plan is clean
```

The first `plan` will surface anything this scaffold doesn't yet model — most
importantly **how `X-Request-Auth` is injected** (a `header` or `request_setting`
block) and service defaults (`default_ttl`, gzip, etc.). Add those to `main.tf`,
parameterising the secret via `var.request_auth_value`, and re-plan until it
reports **no changes**. Only then are you safely in control.

> ⚠️ Import is all-or-nothing: once Terraform manages the service, anything not
> represented in `main.tf` is removed on the next `apply`. Get to a clean plan
> before applying.

## Enabling the rate limiter later

`ratecounter`/`penaltybox` need Fastly to switch on **VCL rate limiting** for the
service (a support/account-team request — not self-serve, and NGWAF/ERL isn't
subscribed). Once enabled: uncomment the three `rl_telemetry_*` snippet blocks in
`main.tf` and `terraform apply`. Thresholds: 429 + 5-min penalty above 10 req/s
(1s) or 2 req/s (60s), per client IP, on the two telemetry paths.

## Secrets & state

- **Never commit** `*.tfstate` or real `*.tfvars` (both gitignored). State can
  contain the injected auth secret.
- Move state to the **GCS backend** in `backend.tf` as soon as practical.
- The Fastly token and `request_auth_value` come from env vars, not the repo.
