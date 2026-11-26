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
- **Resultado (2026-11-26):** **Parcial.** La demo no tiene pasarela de pago real, así que no hay respuestas de tarjeta que explotar. La Store API exige nonce (A04-5: 401 sin nonce) y Cloudflare limita la tasa. Turnstile en el checkout y la alerta AL-03 siguen pendientes (James / Arun).

### AC-02 · Fuerza bruta y XML-RPC amplificado
- **Actor:** externo.
- **Pasos:** 1) enumerar usuarios (`?author=1`); 2) `wp-login` a 5 req/s; 3) usar `system.multicall` en `xmlrpc.php` para multiplicar intentos.
- **Impacto:** toma de cuentas; degradación del servicio.
- **Detección:** 429, picos de 401/403, alerta AL-01.
- **Control:** WAF (xmlrpc bloqueado), rate limit, 2FA, bloqueo progresivo.
- **Resultado (2026-11-26):** **Bloqueado.** Paso 1: `?author=1`, `/author/<slug>/` y el sitemap de usuarios dan 404, y `/wp/v2/users` responde 401/403 por cualquier ruta. Paso 2: Cloudflare responde 429 desde el tercer GET seguido a `wp-login.php`. Paso 3: `xmlrpc.php` da 403 en Nginx y WordPress lo apaga. Además, bloqueo de 15 min tras 5 fallos y 2FA obligatorio para el personal (#44).

### AC-03 · Explotación de plugin vulnerable
- **Actor:** externo.
- **Precondición:** plugin con CVE pública sin actualizar.
- **Pasos:** 1) identificar versión; 2) enviar payload del CVE (SQLi/RCE/upload); 3) obtener dato o ejecución.
- **Impacto:** exfiltración total o RCE en el pod.
- **Detección:** WAF (firma de exploit), Falco (proceso inesperado), integridad de archivos.
- **Control:** plugins fijados, WPScan en CI, WAF, Falco, PSA/NetworkPolicy como contención.
- **Resultado (2026-11-26):** **Bloqueado.** No hay CVE que afecten a las versiones instaladas (#48) y no se pueden instalar plugins desde el panel. Contención si ocurriera: FS de solo lectura, `runAsNonRoot`, `capabilities: drop ALL`, PSA `restricted` y NetworkPolicy *default-deny*. Falco: pendiente (`rasp-monitoreo.md`).

### AC-04 · Pedido ajeno por IDOR
- **Actor:** cliente autenticado.
- **Pasos:** 1) crear pedido propio; 2) cambiar el ID en REST o enlace de cuenta; 3) leer o descargar factura.
- **Impacto:** fuga de PII y direcciones; fraude.
- **Detección:** 403 repetidos por usuario; alerta AL-02.
- **Control:** comprobación de propiedad + tests de regresión.
- **Resultado (2026-11-26):** **Bloqueado.** Con dos clientes reales (A01-0..6): B no ve el pedido de A ni por `view-order`, ni por la URL de confirmación con la clave correcta, ni por la Store API (403), ni por REST `wc/v3` (401). El dueño sí lo ve (control positivo).

### AC-05 · Shell subido vía media/editor
- **Actor:** editor o admin comprometido.
- **Pasos:** 1) subir `shell.php` como avatar/adjunto; 2) acceder a `/wp-content/uploads/shell.php`; 3) ejecutar comandos.
- **Impacto:** RCE en el contenedor; movimiento lateral.
- **Detección:** Falco (shell spawn), integridad de archivos, WAF.
- **Control:** subidas sin ejecución, validación MIME, `DISALLOW_FILE_EDIT`, PSA/read-only FS.
- **Resultado (2026-11-26):** **Bloqueado.** `wp_check_filetype_and_ext` rechaza `shell.php`, `shell.phtml` y `shell.php.jpg`, y también un `.jpg` cuyo contenido es PHP (valida el contenido real). `uploads/*.php` da 403 en producción, el código del pod es de solo lectura y `DISALLOW_FILE_EDIT` quita el editor.

### AC-06 · Manipulación de precio y cupones
- **Actor:** cliente.
- **Pasos:** 1) interceptar el checkout; 2) reducir el total o aplicar cupón dos veces en paralelo; 3) pagar menos.
- **Impacto:** pérdida directa.
- **Detección:** pedidos con total ≠ cálculo del servidor; alerta de anomalía.
- **Control:** recálculo en servidor, cupón validado en transacción, idempotencia.
- **Resultado (2026-11-26):** **Bloqueado.** `add-item` con `price` y `prices` manipulados: el servidor mantiene el total en 329.00. Cantidad negativa: 400. Mismo cupón dos veces: 400 en la segunda. Cupón inventado: 400.

### AC-07 · Cadena de suministro: PR o plugin comprometido
- **Actor:** colaborador o cuenta robada.
- **Pasos:** 1) PR que modifica el workflow o un plugin; 2) exfiltra secretos o introduce backdoor; 3) se despliega por pipeline.
- **Impacto:** compromiso total y persistente.
- **Detección:** revisión obligatoria, diff de workflows, gitleaks, integridad de plugins.
- **Control:** permisos mínimos, sin `pull_request_target`, acciones pinneadas, WIF condicionado.
- **Resultado (2026-11-26):** **Parcial.** Correcto: WIF solo para este repo y `main`, todas las acciones fijadas por SHA, sin `pull_request_target`, `permissions: contents: read` y gitleaks en CI. Brecha **P-13**: `main` no tiene *branch protection*, así que un push directo (o una cuenta robada) despliega sin revisión.

### AC-08 · Scraping y exportación masiva
- **Actor:** competidor o insider.
- **Pasos:** 1) recorrer catálogo y precios con 200 req/min; 2) exportar clientes desde admin; 3) descargar sin justificación.
- **Impacto:** pérdida de ventaja competitiva, fuga de PII.
- **Detección:** alerta por volumen y ASN; log de exportación con autor.
- **Control:** bot management, límite de exportación, aprobación de segundo usuario, auditoría.
- **Resultado (2026-11-26):** **Parcial.** La exportación de clientes exige admin + 2FA. El catálogo es público por diseño (`/wc/store/v1/products` 200); el control de volumen depende del rate limit y del bot management de Cloudflare, no probado con 200 req/min para no cargar la demo.

## 3. Resumen para el informe

| ID | Caso | Actor | STRIDE | Activo | DREAD | Control | Resultado |
|---|---|---|---|---|---|---|---|
| AC-01 | Card testing | externo | D | A-22 | 7.6 | Nonce + rate limit; Turnstile pendiente | parcial |
| AC-02 | Fuerza bruta/XML-RPC | externo | S | A-04 | 8.8 | WAF + 2FA + bloqueo + sin enumeración | bloqueado |
| AC-03 | Plugin vulnerable | externo | E | A-06 | 8.2 | Versiones fijadas + WPScan + contención del pod | bloqueado |
| AC-04 | Pedido ajeno | cliente | I/E | A-02 | 9.0 | Autorización por objeto | bloqueado |
| AC-05 | Shell en uploads | insider | E | A-09 | 7.6 | Validación de contenido + uploads sin ejecución | bloqueado |
| AC-06 | Precio/cupón | cliente | T | A-02 | 7.2 | Recálculo en servidor | bloqueado |
| AC-07 | Cadena de suministro | insider | T/I | A-12 | 7.6 | WIF + acciones fijadas; falta *branch protection* | parcial |
| AC-08 | Scraping/export | competidor | I | A-01 | 7.6 | Export con 2FA; bot management en el borde | parcial |

**5 bloqueados, 3 parciales, 0 explotados.** Los parciales dependen de controles del borde (Turnstile, bot management) y de GitHub (*branch protection*), no del código de la tienda.

Pruebas y salidas: `evidencias/fase2/owasp-abuso-superficie-2026-11-26.md`.
