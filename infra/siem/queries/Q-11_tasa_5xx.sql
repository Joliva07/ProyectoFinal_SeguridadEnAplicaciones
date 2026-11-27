-- Q-11 · Tasa de errores 5xx (AL-08)
-- > 5 % de 5xx en 5 min, con al menos 20 peticiones en la ventana.
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
  TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(timestamp), 300) * 300) AS ventana_5min,
  COUNT(*) AS peticiones,
  COUNTIF(status >= 500) AS errores_5xx,
  ROUND(100 * COUNTIF(status >= 500) / COUNT(*), 2) AS porcentaje_5xx
FROM nginx
GROUP BY ventana_5min
HAVING peticiones >= 20 AND porcentaje_5xx > 5
ORDER BY ventana_5min DESC;
