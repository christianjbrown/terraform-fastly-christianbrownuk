# Collapse cache-busting query strings on the public telemetry endpoints so every
# request maps to a single cached object, protecting the (1-instance) origin from
# query-varied cache-miss floods. The origin function ignores query params.
if (req.method == "GET" && req.url.path ~ "^/(get-smart-home-temps|get-met-office-temps)/?$") {
  set req.url = req.url.path;
}
