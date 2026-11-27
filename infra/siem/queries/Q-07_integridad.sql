-- Q-07 · Integridad del CMS (AL-05, RT-03, RT-04)
-- Requiere el chequeo de integridad de #55: compara el SHA-256 de núcleo, plugins y tema
-- contra el baseline de la imagen y emite aurora_event = "integrity_mismatch".
SELECT
  timestamp,
  resource.labels.pod_name AS pod,
  jsonPayload.path AS archivo,
  jsonPayload.expected AS sha256_esperado,
  jsonPayload.actual AS sha256_actual
FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.stderr_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND jsonPayload.aurora_event = "integrity_mismatch"
ORDER BY timestamp DESC;
