# Render a clean JSON 429 for rate-limited telemetry requests
if (obj.status == 429 && obj.response == "Too Many Requests") {
  set obj.http.Content-Type = "application/json";
  set obj.http.Retry-After = "300";
  set obj.http.Cache-Control = "no-store";
  synthetic {"{"error":"Too Many Requests" }"};
  return(deliver);
}
