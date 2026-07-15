# Rate-limit the public telemetry endpoints (edge only, GET only).
# Burst: >10 req/s over 1s; Sustained: >2 req/s over 60s. 5-minute penalty box.
if (fastly.ff.visits_this_service == 0 && req.method == "GET" && req.url.path ~ "^/(get-smart-home-temps|get-met-office-temps)/?$") {
  if (ratelimit.penaltybox_has(pb_telemetry, client.ip)) {
    error 429 "Too Many Requests";
  }
  if (ratelimit.check_rates(client.ip, rc_telemetry, 1, 1, 10, 60, 2, pb_telemetry, 5m)) {
    error 429 "Too Many Requests";
  }
}
