-- Q-10 · Petición servida con un Host ajeno (AL-07, R-17)
-- Cloud Armor solo admite IPs de Cloudflare. Un 2xx/3xx con Host fuera de la lista
-- indica bypass del borde o Host header injection.
-- Access log de Nginx del namespace aurorashop, últimas 24 h.
WITH nginx AS (
  SELECT
    timestamp,
    jsonPayload.remote_addr AS ip,
    jsonPayload.method AS method,
    jsonPayload.uri AS uri,
    SAFE_CAST(jsonPayload.status AS INT64) AS status,
    jsonPayload.host AS host,
    jsonPayload.user_agent AS user_agent,
    jsonPayload.request_id AS request_id
  FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.stdout_*`
  WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
    AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND resource.labels.namespace_name = "aurorashop"
    AND resource.labels.container_name = "nginx"
)
SELECT
  timestamp, ip, host, method, uri, status, request_id
FROM nginx
WHERE status < 400
  AND host NOT IN (
    "aurorashop.ancordss.me.uk",
    "admin-aurorashop.ancordss.me.uk",
    "staging-aurorashop.ancordss.me.uk"
  )
ORDER BY timestamp DESC
LIMIT 500;
