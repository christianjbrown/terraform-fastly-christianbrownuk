# CLAUDE.md

Guidance for working in this repository. Match the existing conventions exactly — this is a small,
single-purpose Terraform config that models live infrastructure, so changes must stay tightly
reconciled with what's actually deployed.

## What this is

Terraform — the **source of truth** — for the single Fastly VCL service that fronts the GCP Cloud
Functions telemetry API at **`cdn.christianbrown.uk`** (service id `7ieJm1LpaPnVCNb3tzURac`). The
config was `import`ed from the pre-existing service and reconciled against `terraform plan` until the
plan was clean; nothing here is created from scratch.

The one resource, `fastly_service_vcl.cdn` in `main.tf`, manages:

- **Domains** — the real hostname plus its Fastly-managed TLS aliases, from `var.service_domains`
  via a `dynamic "domain"` block.
- **Backend** — the Cloud Functions origin (`{region}-{project}.cloudfunctions.net`, built in
  `locals.backend_host`), full-TLS with cert/SNI/override-host pinned to that host, routed through a
  London shield POP (`var.backend_shield`).
- **Force-TLS + HSTS** — a `request_setting` with `force_ssl` and a response `header` setting
  `Strict-Transport-Security`.
- **The `X-Request-Auth` gate header** — injected on the request to origin so the Cloud Function
  accepts it without the browser ever seeing the value. The value is read at plan/apply time from GCP
  Secret Manager (`data.google_secret_manager_secret_version.request_auth`) — the same secret the
  Cloud Functions read — and is **never hardcoded or committed**.
- **Query-string strip** — rewrites `url` to `req.url.path` to protect the single-instance origin
  from query-varied cache-busting.

## Commands

Terraform runs against live state — always `plan` before you `apply`, and let CI do the applying.

| Task | Command |
| --- | --- |
| Init (configures the GCS backend) | `terraform init` |
| Format check (CI gate) | `terraform fmt -check -recursive` |
| Auto-format | `terraform fmt -recursive` |
| Validate (CI gate) | `terraform validate` |
| Show the plan (should report **No changes**) | `terraform plan` |
| Apply | done by CI on merge to `main` — not locally |

Local runs need two credentials: a Fastly token via `export FASTLY_API_KEY="…"` (the `fastly`
provider reads the env var when `var.fastly_api_key` is null), and GCP auth for the `google` provider
and the GCS state backend via `export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"`
(or Application Default Credentials).

CI (`.github/workflows/terraform.yml`) runs `fmt -check` → `init` → `validate` → `plan` on every PR,
and `apply` on push to `main`. It authenticates to GCP with **Workload Identity Federation** (no JSON
key; `vars.GCP_WIF_PROVIDER` / `vars.GCP_SERVICE_ACCOUNT`) and reads the Fastly token from the
`FASTLY_API_KEY` repo secret. Note the `terraform` check is **required by branch protection**, so —
unlike the push trigger — the `pull_request` trigger has **no `paths-ignore`**: even a docs-only PR
runs the workflow (the plan just reports no changes) so the required check can report.

## Architecture

Flat root module, one file per concern:

- **`main.tf`** — the `fastly_service_vcl.cdn` resource, the `backend_host` local, and the Secret
  Manager data source for the gate value.
- **`variables.tf`** — all inputs, each with a sensible `default` describing the live service
  (`gcp_project`, `gcp_region`, `request_auth_secret_name`, `service_domains`, `backend_shield`), plus
  `fastly_api_key` (sensitive, defaults to null → env var).
- **`providers.tf`** — `fastly` (token) and `google` (only to read the gate secret).
- **`versions.tf`** — `required_version >= 1.6`; providers pinned `fastly ~> 9.0`, `google ~> 7.0`.
- **`backend.tf`** — remote state in the private, versioned `christianbrown-tf-state` GCS bucket under
  prefix `fastly/cdn`.
- **`terraform.tfvars.example`** — documents that the only real input is the Fastly token (best via
  env), and that no secret goes in a tfvars file.

State lives in GCS, not git, because it can hold sensitive values; the bucket has
public-access-prevention enforced and is access-controlled by GCP IAM.

## Conventions

- **The repo is the source of truth — never edit the service in the Fastly UI/CLI**, or you introduce
  drift. Every change is a PR (CI shows the plan) applied on merge.
- **Keep the plan clean.** The config mirrors the imported service; after any change, `terraform plan`
  should show exactly and only what you intended.
- **Secrets are never in code or state-in-git.** The `X-Request-Auth` value is read from Secret
  Manager at plan/apply time; the Fastly token comes from the environment / a repo secret. Real secret
  values live out-of-band (GCP Secret Manager, GitHub Actions secrets) — this public repo holds none.
- **Values default to the live config.** Inputs carry `default`s so a bare `terraform plan` reflects
  production; prefer parameterising over a variable (e.g. `backend_host` derived from project+region)
  to keep a single source of truth.
- `sensitive = true` on anything secret (e.g. `fastly_api_key`) so it is redacted in plan output —
  this is what makes plan logs safe for a public repo.
- Run `terraform fmt -recursive` before committing; the CI `fmt -check` gate will fail otherwise.

## Making a change

1. Branch off `main`. Edit the relevant `.tf` file (usually `main.tf`, or a `variables.tf` default).
2. `terraform fmt -recursive`, then `terraform validate`, then `terraform plan` locally and confirm
   the diff is exactly what you intend (ideally still **No changes** for non-functional edits).
3. Open a PR. CI posts the plan; review it there.
4. Merge to `main` — CI applies. This is the only sanctioned path for the live service to change.
5. If you add a new input, give it a `default` matching the live value and document any out-of-band
   setup (secrets, GCP grants) in `README.md` under "One-time setup that is NOT in code".
