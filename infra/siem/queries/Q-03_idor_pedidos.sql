-- Q-03 · Acceso a pedido ajeno / IDOR (AL-02, RT-06, R-05, AC-04)
-- Proxy por IP: el access log de Nginx no trae el usuario. > 5 respuestas 401/403/404
-- a rutas de pedidos en 10 min desde una IP.
-- Cuando exista el evento "order_access_denied" (#55), usar la variante por usuario del final.
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
  TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(timestamp), 600) * 600) AS ventana_10min,
  ip,
  COUNT(*) AS rechazos,
  COUNT(DISTINCT uri) AS pedidos_distintos,
  ARRAY_AGG(DISTINCT uri LIMIT 5) AS muestra
FROM nginx
WHERE status IN (401, 403, 404)
  AND (REGEXP_CONTAINS(uri, r"^/wp-json/wc/(v3|store/v1)/orders")
       OR STARTS_WITH(uri, "/my-account/view-order/")
       OR STARTS_WITH(uri, "/checkout/order-received/"))
GROUP BY ventana_10min, ip
HAVING rechazos > 5
ORDER BY rechazos DESC;

-- Variante por usuario (requiere aurora_event del mu-plugin de #55):
-- SELECT
--   TIMESTAMP_SECONDS(DIV(UNIX_SECONDS(timestamp), 600) * 600) AS ventana_10min,
--   jsonPayload.user_hash AS usuario,
--   COUNT(*) AS rechazos,
--   COUNT(DISTINCT jsonPayload.item_id) AS pedidos_distintos
-- FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.stderr_*`
-- WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
--   AND jsonPayload.aurora_event = "order_access_denied"
-- GROUP BY ventana_10min, usuario
-- HAVING rechazos > 5;
