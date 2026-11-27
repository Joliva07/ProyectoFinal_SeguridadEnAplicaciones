-- Q-08 · Egreso anómalo desde el pod (R-12)
-- Fuente: Falco, regla "Aurora - salida de red no permitida" (infra/falco/aurora_rules.yaml).
-- Requiere añadir el namespace "falco" al filtro del sink (hoy solo exporta aurorashop, dev y staging).
SELECT
  timestamp,
  jsonPayload.priority AS prioridad,
  jsonPayload.rule AS regla,
  jsonPayload.output AS detalle
FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.stdout_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND resource.labels.namespace_name = "falco"
  AND jsonPayload.rule = "Aurora - salida de red no permitida"
ORDER BY timestamp DESC;
