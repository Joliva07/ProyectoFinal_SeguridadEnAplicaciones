-- Q-09 · kubectl exec / attach / port-forward en producción (AL-04, RT-10)
-- Sale de los Admin Activity audit logs de GKE: funciona aunque Falco no esté instalado.
SELECT
  timestamp,
  protopayload_auditlog.authenticationInfo.principalEmail AS principal,
  protopayload_auditlog.methodName AS metodo,
  protopayload_auditlog.resourceName AS recurso,
  protopayload_auditlog.requestMetadata.callerIp AS ip_origen
FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.cloudaudit_googleapis_com_activity_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND protopayload_auditlog.methodName IN (
    "io.k8s.core.v1.pods.exec.create",
    "io.k8s.core.v1.pods.attach.create",
    "io.k8s.core.v1.pods.portforward.create"
  )
  AND REGEXP_CONTAINS(protopayload_auditlog.resourceName, r"namespaces/aurorashop/")
ORDER BY timestamp DESC;
