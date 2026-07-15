# Fastly VCL service that fronts the GCP Cloud Functions telemetry API at
# cdn.christianbrown.uk. This models the EXISTING service (id below) — adopt it
# with `terraform import`, then `terraform plan` and reconcile until the plan is
# clean. Do NOT `apply` before the import, or Terraform will try to create a new
# service and orphan the live one.
#
#   terraform import fastly_service_vcl.cdn 7ieJm1LpaPnVCNb3tzURac
#
# Service id (for reference): 7ieJm1LpaPnVCNb3tzURac

resource "fastly_service_vcl" "cdn" {
  name = "GCP Cloud Functions API"

  domain {
    name = "cdn.christianbrown.uk"
  }

  backend {
    name              = "GCP Cloud functions"
    address           = "europe-west2-christianbrown.cloudfunctions.net"
    port              = 443
    use_ssl           = true
    ssl_check_cert    = true
    ssl_cert_hostname = "europe-west2-christianbrown.cloudfunctions.net"
    ssl_sni_hostname  = "europe-west2-christianbrown.cloudfunctions.net"
    override_host     = "europe-west2-christianbrown.cloudfunctions.net"
    shield            = "lon-london-uk"
    weight            = 100
  }

  # --- Active mitigation: collapse cache-busting query strings on the public
  # telemetry endpoints so query-varied floods can't miss to the 1-instance
  # origin. Currently live (was service version 15).
  snippet {
    name     = "strip_query_telemetry"
    type     = "recv"
    priority = 100
    content  = file("${path.module}/vcl/strip_query.vcl")
  }

  # --- Per-client rate limiter. REQUIRES Fastly to enable "VCL rate limiting"
  # on this service first (support/account request — it is not self-serve).
  # Until then, activating these snippets fails validation. Once enabled,
  # uncomment all three and `terraform apply`. (These were staged as the
  # never-activated service version 14.)
  #
  # snippet {
  #   name     = "rl_telemetry_init"
  #   type     = "init"
  #   priority = 100
  #   content  = file("${path.module}/vcl/rl_telemetry_init.vcl")
  # }
  # snippet {
  #   name     = "rl_telemetry_recv"
  #   type     = "recv"
  #   priority = 110 # after the query strip
  #   content  = file("${path.module}/vcl/rl_telemetry_recv.vcl")
  # }
  # snippet {
  #   name     = "rl_telemetry_error"
  #   type     = "error"
  #   priority = 100
  #   content  = file("${path.module}/vcl/rl_telemetry_error.vcl")
  # }

  # --- Auth header injection (X-Request-Auth). Fastly adds this secret so the
  # browser never has to. The live service already does this via some object
  # (a header{} or request_setting{}); `terraform plan` after import will show
  # exactly what to add here. Keep the value in var.request_auth_value — never
  # hardcode it. Example shape (reconcile against the plan before uncommenting):
  #
  # header {
  #   name        = "Inject X-Request-Auth"
  #   type        = "request"
  #   action      = "set"
  #   destination = "http.X-Request-Auth"
  #   source      = "\"${var.request_auth_value}\""
  #   ignore_if_set = false
  #   priority    = 10
  # }

  # Safety: never let a plan silently delete the live service.
  force_destroy = false
}
