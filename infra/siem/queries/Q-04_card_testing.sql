-- Q-04 · Card testing en checkout (AL-03, RT-07, R-16, AC-01)
-- Proxy: > 10 checkouts con error en la Store API por IP en 1 hora.
-- La variante con monto (< 5) requiere el evento "checkout_failed" de #55.
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
  TIMESTAMP_TRUNC(timestamp, HOUR) AS hora,
  ip,
  COUNTIF(status >= 400) AS checkouts_fallidos,
  COUNTIF(status < 400) AS checkouts_ok
FROM nginx
WHERE method = "POST" AND STARTS_WITH(uri, "/wp-json/wc/store/v1/checkout")
GROUP BY hora, ip
HAVING checkouts_fallidos > 10
ORDER BY checkouts_fallidos DESC;

-- Variante con monto (requiere aurora_event = "checkout_failed" con total e ip_hash):
-- SELECT TIMESTAMP_TRUNC(timestamp, HOUR) AS hora, jsonPayload.ip_hash AS ip, COUNT(*) AS fallidos
-- FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.stderr_*`
-- WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
--   AND jsonPayload.aurora_event = "checkout_failed"
--   AND SAFE_CAST(jsonPayload.total AS FLOAT64) < 5
-- GROUP BY hora, ip
-- HAVING fallidos > 10;
