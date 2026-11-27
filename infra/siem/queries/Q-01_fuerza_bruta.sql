-- Q-01 · Fuerza bruta en wp-login.php (AL-01, RT-05, R-06)
-- WordPress responde 200 (vuelve a mostrar el formulario) a un login fallido y 302 a uno exitoso.
-- Umbral: > 20 fallos por IP en 5 min. El rate limit de Cloudflare (2 req/10 s) deja pasar
-- como máximo ~60 en 5 min; superar el umbral indica rotación de IP o bypass del borde.
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
  ip,
  COUNTIF(status = 200) AS fallos,
  COUNTIF(status = 302) AS exitos,
  COUNT(DISTINCT user_agent) AS user_agents
FROM nginx
WHERE method = "POST" AND uri = "/wp-login.php"
GROUP BY ventana_5min, ip
HAVING fallos > 20
ORDER BY fallos DESC;
