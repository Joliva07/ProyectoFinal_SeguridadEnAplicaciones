# Falco

Dueño: **Arun** · Plantillas: #41 · Despliegue y pruebas: #55

`aurora_rules.yaml` define las reglas propias de AuroraShop:

| Regla | ID | Prioridad | Prueba controlada (#55) |
|---|---|---|---|
| Aurora - shell en pod | RT-01 | CRITICAL | `kubectl exec -n aurorashop deploy/aurorashop -c php-fpm -- sh -c id` |
| Aurora - proceso inesperado | RT-01 | WARNING | `kubectl exec ... -c php-fpm -- ls /` |
| Aurora - escritura en codigo del CMS | RT-02 | ERROR | `kubectl exec ... -c php-fpm -- sh -c 'echo x > /var/www/html/x.php'` (falla por el FS de solo lectura; Falco registra el intento) |
| Aurora - PHP en uploads | RT-04 | CRITICAL | `kubectl exec ... -c php-fpm -- sh -c 'echo "<?php" > /var/www/html/wp-content/uploads/t.php'` y borrar el archivo al terminar |
| Aurora - salida de red no permitida | Q-08 | ERROR | `kubectl exec ... -c php-fpm -- php -r 'fsockopen("1.1.1.1", 80);'` (la NetworkPolicy la corta; Falco ve el intento) |

## Instalación prevista

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace \
  --set driver.kind=modern_ebpf \
  --set falco.json_output=true \
  --set-file "customRules.aurora_rules\.yaml=infra/falco/aurora_rules.yaml"
```

Con `json_output=true`, cada alerta sale como una línea JSON en el stdout del pod de Falco. Cloud Logging la guarda como `jsonPayload` (`rule`, `priority`, `output`).

## Limitaciones que hay que verificar antes de la #55

1. **GKE Autopilot** no admite DaemonSets privilegiados salvo las cargas de socios que Google tenga en su allowlist. Antes de instalar hay que confirmar si la versión del clúster admite Falco (`kubectl get allowlistedv2workloads` o la documentación de *Autopilot partner workloads*). Si no la admite, se declara la limitación (`rasp-monitoreo.md` sección 5) y RT-01 se cubre con el audit log de `pods/exec` (Q-09, AL-04). En ese caso RT-02, RT-04 y Q-08 se cubren con el chequeo de integridad y la NetworkPolicy.
2. El sink a BigQuery solo exporta los namespaces `aurorashop`, `dev` y `staging`. Para Q-08 hay que añadir `falco` al filtro en `infra/modules/observability/main.tf`.
3. **Validación de sintaxis (2026-11-26):** `falcosecurity/falco:0.41.3` acepta las reglas cargadas junto con las por defecto (`falco -V /etc/falco/falco_rules.yaml -V /rules/aurora_rules.yaml` → `/rules/aurora_rules.yaml: Ok`). Esto prueba la sintaxis y los campos, no que las reglas disparen: eso se demuestra con las pruebas controladas de la tabla en la #55.
