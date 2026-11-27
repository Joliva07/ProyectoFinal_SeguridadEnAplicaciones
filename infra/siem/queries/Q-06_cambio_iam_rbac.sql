-- Q-06 · Cambio de IAM o RBAC fuera del CI (AL-06, R-12, R-23)
-- Cambios de IAM y de RBAC de Kubernetes. Se excluye la cuenta del pipeline (sa-gh-deployer).
-- Cualquier fila se revisa a mano.
SELECT
  timestamp,
  protopayload_auditlog.authenticationInfo.principalEmail AS principal,
  protopayload_auditlog.serviceName AS servicio,
  protopayload_auditlog.methodName AS metodo,
  protopayload_auditlog.resourceName AS recurso,
  protopayload_auditlog.requestMetadata.callerIp AS ip_origen
FROM `aurorashop-sec-umg.aurorashop_demo_security_logs.cloudaudit_googleapis_com_activity_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND (
    protopayload_auditlog.methodName LIKE "%SetIamPolicy"
    OR REGEXP_CONTAINS(protopayload_auditlog.methodName,
         r"^io\.k8s\.authorization\.rbac\.v1\.(cluster)?role(binding)?s\.(create|update|patch|delete)$")
  )
  AND NOT STARTS_WITH(IFNULL(protopayload_auditlog.authenticationInfo.principalEmail, ""), "sa-gh-deployer@")
ORDER BY timestamp DESC;
