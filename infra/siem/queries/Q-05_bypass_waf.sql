-- Q-05 · Payload que llegó al pod y no fue rechazado (R-15)
-- Sin logs de Cloudflare (Logpush no existe en el plan Free) no se puede cruzar con la acción del WAF.
-- Se buscan firmas en la ruta normalizada que el pod respondió con < 400.
-- Limitación: $uri no incluye el query string; los payloads en parámetros no se ven.
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
  timestamp, ip, method, uri, status, request_id
FROM nginx
WHERE status < 400
  AND REGEXP_CONTAINS(LOWER(uri),
        r"(\.\./|/etc/passwd|union[^a-z]+select|<script|%3cscript|\.php\.(bak|old|swp)|/\.git/|/\.env|base64_decode|eval\()")
ORDER BY timestamp DESC
LIMIT 500;
