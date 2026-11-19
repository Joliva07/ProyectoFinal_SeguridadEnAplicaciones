# Casos de abuso

Dueño: **Horacio** · Insumo: `docs/01-activos-riesgos/stride.md`

## 1. Formato

```
AC-NN · <título>
Actor: <externo | cliente | editor | shop_manager | insider | cadena de suministro>
Precondición:
Objetivo: <activo A-NN>
Pasos: 1..n
Impacto:
Detección esperada:
Control: preventivo / detectivo
Evidencia: <H-NN o captura>
```

## 2. Casos obligatorios

### AC-01 · Card testing en checkout
- **Actor:** externo con bots.
- **Precondición:** checkout sin captcha ni límite.
- **Pasos:** 1) automatizar checkout con montos mínimos; 2) variar correo y tarjeta; 3) observar respuestas de la pasarela.
- **Impacto:** comisiones, bloqueo de la cuenta de la pasarela, reputación.
- **Detección:** tasa de pedidos fallidos por IP/ASN; alerta AL-03.
- **Control:** Turnstile, rate limit 5/min en checkout, 3DS sandbox, alerta.

### AC-02 · Fuerza bruta y XML-RPC amplificado
- **Actor:** externo.
- **Pasos:** 1) enumerar usuarios (`?author=1`); 2) `wp-login` a 5 req/s; 3) usar `system.multicall` en `xmlrpc.php` para multiplicar intentos.
- **Impacto:** toma de cuentas; degradación del servicio.
- **Detección:** 429, picos de 401/403, alerta AL-01.
- **Control:** WAF (xmlrpc bloqueado), rate limit, 2FA, bloqueo progresivo.

### AC-03 · Explotación de plugin vulnerable
- **Actor:** externo.
- **Precondición:** plugin con CVE pública sin actualizar.
- **Pasos:** 1) identificar versión; 2) enviar payload del CVE (SQLi/RCE/upload); 3) obtener dato o ejecución.
- **Impacto:** exfiltración total o RCE en el pod.
- **Detección:** WAF (firma de exploit), Falco (proceso inesperado), integridad de archivos.
- **Control:** plugins fijados, WPScan en CI, WAF, Falco, PSA/NetworkPolicy como contención.

### AC-04 · Pedido ajeno por IDOR
- **Actor:** cliente autenticado.
- **Pasos:** 1) crear pedido propio; 2) cambiar el ID en REST o enlace de cuenta; 3) leer o descargar factura.
- **Impacto:** fuga de PII y direcciones; fraude.
- **Detección:** 403 repetidos por usuario; alerta AL-02.
- **Control:** comprobación de propiedad + tests de regresión.

### AC-05 · Shell subido vía media/editor
- **Actor:** editor o admin comprometido.
- **Pasos:** 1) subir `shell.php` como avatar/adjunto; 2) acceder a `/wp-content/uploads/shell.php`; 3) ejecutar comandos.
- **Impacto:** RCE en el contenedor; movimiento lateral.
- **Detección:** Falco (shell spawn), integridad de archivos, WAF.
- **Control:** subidas sin ejecución, validación MIME, `DISALLOW_FILE_EDIT`, PSA/read-only FS.

### AC-06 · Manipulación de precio y cupones
- **Actor:** cliente.
- **Pasos:** 1) interceptar el checkout; 2) reducir el total o aplicar cupón dos veces en paralelo; 3) pagar menos.
- **Impacto:** pérdida directa.
- **Detección:** pedidos con total ≠ cálculo del servidor; alerta de anomalía.
- **Control:** recálculo en servidor, cupón validado en transacción, idempotencia.

### AC-07 · Cadena de suministro: PR o plugin comprometido
- **Actor:** colaborador o cuenta robada.
- **Pasos:** 1) PR que modifica el workflow o un plugin; 2) exfiltra secretos o introduce backdoor; 3) se despliega por pipeline.
- **Impacto:** compromiso total y persistente.
- **Detección:** revisión obligatoria, diff de workflows, gitleaks, integridad de plugins.
- **Control:** permisos mínimos, sin `pull_request_target`, acciones pinneadas, WIF condicionado.

### AC-08 · Scraping y exportación masiva
- **Actor:** competidor o insider.
- **Pasos:** 1) recorrer catálogo y precios con 200 req/min; 2) exportar clientes desde admin; 3) descargar sin justificación.
- **Impacto:** pérdida de ventaja competitiva, fuga de PII.
- **Detección:** alerta por volumen y ASN; log de exportación con autor.
- **Control:** bot management, límite de exportación, aprobación de segundo usuario, auditoría.

## 3. Resumen para el informe

| ID | Caso | Actor | STRIDE | Activo | DREAD | Control | Detectado |
|---|---|---|---|---|---|---|---|
| AC-01 | Card testing | externo | D | A-22 | 7.6 | Turnstile + rate limit | pendiente |
| AC-02 | Fuerza bruta/XML-RPC | externo | S | A-04 | 8.8 | WAF + 2FA | pendiente |
| AC-03 | Plugin vulnerable | externo | E | A-06 | 8.2 | WPScan + WAF + Falco | pendiente |
| AC-04 | Pedido ajeno | cliente | I/E | A-02 | 9.0 | autorización por objeto | pendiente |
| AC-05 | Shell en uploads | insider | E | A-09 | 7.6 | uploads sin ejecución | pendiente |
| AC-06 | Precio/cupón | cliente | T | A-02 | 7.2 | recálculo servidor | pendiente |
| AC-07 | Cadena de suministro | insider | T/I | A-12 | 7.6 | WIF + permisos | pendiente |
| AC-08 | Scraping/export | competidor | I | A-01 | 7.6 | bot mgmt + límites | pendiente |
