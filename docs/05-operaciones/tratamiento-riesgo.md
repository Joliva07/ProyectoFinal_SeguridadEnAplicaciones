# Tratamiento formal del riesgo

Dueño: **Arun** · Coautor: **Javier** · Componentes de rúbrica 1 y 4 · Issue #56 · Corte: 2026-11-27

Insumos: pentest de caja negra (#45) y caja gris (#46), OWASP, abuso y superficie (#47), plugins (#48), triaje SAST/SCA (#50, `docs/03-devsecops/sast-sca.md` sección 3), una verificación pasiva del borde el 2026-11-26 (`evidencias/fase3/triaje-sast-sca-2026-11-26.md` sección 4) y el endurecimiento del borde aplicado el 2026-11-27 (`evidencias/fase5/edge-hardening-2026-11-27.md`).

## 1. Criterios de decisión

| Decisión | Cuándo | Requisito |
|---|---|---|
| **Mitigar** | Existe control razonable en el alcance | Implementado y probado |
| **Evitar** | La actividad que genera el riesgo se elimina | Cambio de diseño documentado |
| **Transferir** | Otro puede asumirlo mejor | Contrato/SLA citado |
| **Aceptar** | Costo del control > impacto, o residual tolerable | Aprobación de James + fecha de revisión |
| **Eliminar** | El activo o función deja de existir | Registro de baja |

Residual aceptable: **≤ 9 (Medio)**. Todo residual ≥ 10 exige control compensatorio o justificación del grupo.

## 2. Tratamiento por hallazgo

Estados: **cerrado** (control probado, con regresión), **no reproducido** (la hipótesis del diseño se probó y el control ya la bloquea), **abierto** (falta el control), **aceptado** (requiere aprobación de James). Residual = P × I tras el tratamiento; se marca ★ cuando es el residual **actual verificado** y aún falta aplicar el control.

### 2.1 Hipótesis del diseño (H-01..H-08)

| Hallazgo | Riesgo | Descripción | Tipo | Impacto | Decisión | Control | Responsable | Plazo | Estado | Residual |
|---|---|---|---|---|---|---|---|---|---|---|
| H-01 | R-01 | Plugin desactualizado con CVE de SQLi | Software | Legal, reputacional | Mitigar | Versiones + SHA-256 fijados, `DISALLOW_FILE_MODS`, WPScan y Trivy en CI | Horacio | — | **No reproducido**: 0 CVE en las versiones instaladas (#48) | 6 |
| H-02 | R-05 | Pedido ajeno por IDOR en REST | Software | Legal, reputacional | Mitigar | Autorización por objeto de WooCommerce | Horacio | — | **No reproducido**: 403 en `wc/v3/orders/{id}` y sin datos ajenos en `view-order` (#46, pruebas 1-2) | 6 |
| H-03 | R-06 | Sin límite en `wp-login` | Seguridad | Operacional | Mitigar | W-02 (rate limit) + Nginx + 2FA + bloqueo | James | — | **No reproducido**: 429 desde el 3.er intento (#45, prueba 6) | 4 |
| H-04 | R-08 | Upload permite extensión ejecutable | Software | Operacional | Mitigar | `upload_mimes`, Nginx sin PHP en uploads, W-05 | Horacio | — | **No reproducido**: `.php`, `.php.png`, `.phtml` y `.zip` rechazados (#46, prueba 12) | 3 |
| H-05 | R-09 | `wp-config.php.bak` accesible | Técnico | Legal, financiero | Mitigar | W-04 + Nginx | Josue | — | **No reproducido**: 28 rutas sensibles 403/404 (#45, prueba 9; #47 A05) | 3 |
| H-06 | R-15 | CRS en modo log no bloquea SQLi | Cloud | Operacional | Mitigar | Managed Free Ruleset en block + Cloud Armor `sqli-v33` | James | — | **No reproducido**: WAF en `block` desde el 2026-11-25; SQLi sin efecto (#47 A03) | 6 |
| H-07 | R-19 | Secreto en variable de entorno del pod | Técnico | Operacional | Mitigar | Secret Manager por CSI, IAM para la BD | Josue | — | **No reproducido**: `DB_PASSWORD` vacía y secretos como archivos CSI (#46, prueba 18); gitleaks 0 | 3 |
| H-08 | R-20 | `wp-admin` y `admin-aurorashop` sin Cloudflare Access (P-09) | Cloud | Financiero, legal | Mitigar | Cloudflare Access (W-09) con política Allow; 2FA del IdP | James | — | **Cerrado** (2026-11-27): `admin-` responde 302 a `alzentis.cloudflareaccess.com` | 3 |

### 2.2 Hallazgos del pentest (H-09..H-12)

| Hallazgo | Riesgo | Descripción | Tipo | Impacto | Decisión | Control | Responsable | Plazo | Estado | Residual |
|---|---|---|---|---|---|---|---|---|---|---|
| H-09 | R-05 | El enlace de descarga funcionaba sin sesión | Software | Legal | Mitigar | `woocommerce_downloads_require_login` forzado en el mu-plugin | Horacio | — | **Cerrado**: anónimo 302 y cliente B 403 (#46 sección 5) | 6 |
| H-10 | R-04 | Cookies sin `SameSite` explícito | Software | Operacional | Aceptar | `Lax` por defecto en los navegadores + nonce en acciones y Store API | Horacio | revisión 9-dic | **Aceptado** (pendiente de aprobación de James) | 4 |
| H-11 | R-04 | REST refleja cualquier `Origin` con `credentials: true` | Software | Reputacional | Mitigar | Filtro de orígenes permitidos en el mu-plugin (`rest_pre_serve_request`), o regla de cabecera en Cloudflare | Horacio | 2-dic | **Abierto**: reproducido el 2026-11-26 | 4 |
| H-12 | R-16 | Catálogo sin límite de tasa (scraping) | Seguridad | Financiero | Mitigar | Turnstile/Bot Fight Mode en `/shop/` y en la Store API; `limit_req` de Nginx para `/shop/` porque la cuota Free de rate limit ya se usa en el login | James / Horacio | 2-dic | **Abierto**: 25 × 200 sin reto (2026-11-26) | ★ 9 → 4 |

### 2.3 Perímetro (P-NN) y cadena de suministro (S-NN)

| Hallazgo | Riesgo | Descripción | Tipo | Impacto | Decisión | Control | Responsable | Plazo | Estado | Residual |
|---|---|---|---|---|---|---|---|---|---|---|
| P-07 | R-18 | El borde acepta TLS 1.0 y 1.1 | Técnico | Reputacional | Mitigar | Cloudflare → *Minimum TLS Version* 1.2 | James | — | **Cerrado** (2026-11-27): TLS 1.0/1.1 fallan (`curl` exit 35), TLS 1.2 responde 200 | 2 |
| P-08 | R-18 | Sin HSTS | Técnico | Reputacional | Mitigar | HSTS `max-age=31536000` en Cloudflare | James | — | **Cerrado** (2026-11-27): cabecera presente, sin `includeSubDomains` | (en P-07) |
| P-10 | R-17 | `staging-aurorashop` con DNS que responde 502 | Cloud | Reputacional | Eliminar | Borrar el registro DNS mientras no exista réplica | James | — | **Cerrado** (2026-11-27): registro eliminado, el host no resuelve | 3 |
| P-11 | R-12 | Red `default` de GCP con SSH/RDP abiertos a `0.0.0.0/0` (sin VMs) | Cloud | Operacional | Eliminar | Borrar la red `default` y sus reglas | Josue | 30-nov | **Abierto** | ★ 6 → 3 |
| P-12 | R-16 | `wp-cron.php` público | Técnico | Operacional | Aceptar (temporal) | CronJob de K8s + `DISABLE_WP_CRON` | Horacio | revisión 9-dic | **Aceptado temporal** | (en H-12) |
| P-13 | R-23 | `main` sin *branch protection* | Proceso | Operacional | Mitigar | Regla de rama: PR + 1 revisión + checks obligatorios | Josue | 28-nov | **Abierto** | ★ 9 → 4 |
| S-03 | R-13 | `nosemgrep` de Cloud SQL sin motivo | Proceso | — | Aceptar | Añadir el motivo en línea (proxy mTLS, IP privada, IAM) | Josue | 30-nov | **Aceptado**; falta el comentario | 3 |
| S-04 | R-23, R-01 | El gate de WPScan falla abierto (la API free no da CVSS) | Proceso | Operacional, legal | Mitigar | Comparar `fixed_in` con la versión fijada en el `Dockerfile` y fallar si es mayor | Josue | 30-nov | **Abierto** | (en P-13 / R-01 ★ 8 → 6) |
| S-06 | R-12 | La supresión `CKV2_GCP_18` oculta P-11 | Proceso | Operacional | Mitigar | Corregir el comentario y retirar la supresión al borrar la red `default` | Josue | 30-nov | **Abierto** | (en P-11) |
| S-07 | R-23 | Binary Authorization desactivado | Proceso | Operacional | Aceptar | Deploy por digest verificado (PR #67) + WIF limitado a `main` | Josue | revisión 9-dic | **Aceptado** (pendiente de aprobación de James) | (en P-13) |

### 2.4 Riesgos sin hallazgo con control pendiente de prueba

| Riesgo | Brecha | Control | Responsable | Plazo | Residual |
|---|---|---|---|---|---|
| R-21 | Logs JSON en Cloud Logging, pero las alertas AL-01..AL-08 no se han disparado (#47 A09) | Sinks, alertas y prueba de detección < 2 min (#54) | Arun | 4-dic | ★ 9 → 4 |
| R-22 | Backups CMEK con PITR y 7 copias, pero **sin restauración probada** | Restaurar un backup en una instancia temporal y medir el RTO | Arun / Josue | 4-dic | ★ 8 → 3 |

## 3. Categorización

| Tipo | N.º | Decisión dominante |
|---|---|---|
| Software | 8 | Mitigar |
| Seguridad | 3 | Mitigar |
| Técnico | 4 | Mitigar |
| Cloud | 7 | Mitigar / Transferir |
| Proceso | 5 | Mitigar / Evitar / Aceptar |
| Personas | 1 | Mitigar |

| Hallazgos | Total | Cerrados / no reproducidos | Abiertos | Aceptados |
|---|---|---|---|---|
| H-NN | 12 | 9 (H-01..H-09) | 2 (H-11, H-12) | 1 (H-10) |
| P-NN abiertos o aceptados | 3 | — | 2 (P-11, P-13) | 1 (P-12) |
| S-NN reales | 4 | — | 2 (S-04, S-06) | 2 (S-03, S-07) |

Los `S-01`, `S-02`, `S-05` y `S-08` son falsos positivos o recomendaciones y no generan tratamiento (ver `sast-sca.md` sección 3).

| Impacto de negocio | Riesgos |
|---|---|
| Reputacional | R-01, R-03, R-05, R-07, R-14, R-15, R-18, R-26 |
| Operacional | R-04, R-06, R-10, R-11, R-12, R-21, R-23, R-24, R-28 |
| Financiero | R-01, R-02, R-05, R-08, R-09, R-13, R-16, R-19, R-20, R-26 |
| Legal | R-01, R-02, R-05, R-09, R-14, R-20, R-21, R-22, R-25, R-27 |

## 4. Riesgos aceptados (justificación)

Todos requieren la aprobación de James (sección 1) antes del cierre de #56.

| Riesgo / hallazgo | Motivo | Revisión |
|---|---|---|
| R-25 Cumplimiento del proveedor | Se transfiere: certificaciones y SLA de Google Cloud; no es mitigable en el curso | 9-dic |
| R-28 Un solo operador de Cloudflare | El acceso lo define el dueño de la zona; con un SLA de 24 h es operable | 9-dic |
| Cobertura parcial de Cloudflare Free | W-07, W-08 y W-10 requieren plan pago o más cuota; se compensan con Nginx `limit_req`, Cloud Armor y la lógica de la app | 9-dic |
| H-10 `SameSite` | Los navegadores aplican `Lax` por defecto y toda acción exige nonce | 9-dic |
| P-12 `wp-cron.php` | Carga baja; se reemplaza por un CronJob antes del cierre | 9-dic |
| S-03 Cloud SQL `ENCRYPTED_ONLY` | El conector usa mTLS; `TRUSTED_CLIENT_CERTIFICATE_REQUIRED` no añade protección detrás del proxy | 9-dic |
| S-07 Binary Authorization | Exige política y rompe el bootstrap; se compensa con el deploy por digest y WIF limitado a `main` | 9-dic |

## 5. Verificación de cierre

Un control se cierra cuando: (a) está implementado, (b) existe prueba de que bloquea el ataque original, (c) el residual está recalculado y (d) otra persona revisó la evidencia. La tabla se actualiza en el mismo commit que la evidencia.

Pruebas de cierre para los abiertos:

| Hallazgo | Prueba que lo cierra |
|---|---|
| H-11 | `curl -H "Origin: https://evil.test" .../wp-json/` → sin `access-control-allow-origin: https://evil.test` |
| H-12 | 40 × GET a `/shop/` → challenge o 429 antes de terminar |
| P-11/S-06 | `gcloud compute networks list` sin `default`; Checkov en verde sin `CKV2_GCP_18` |
| P-13 | Un push directo a `main` es rechazado |
| S-04 | PR de prueba con `WOOCOMMERCE_VERSION` antigua → el job de WPScan falla |

Cerrados el 2026-11-27 con evidencia en `evidencias/fase5/edge-hardening-2026-11-27.md`: H-08/P-09, P-07, P-08 y P-10.

## 6. Relación con el heatmap

Cada fila cerrada mueve su punto en `heatmap.md`. Si el residual no baja, el control no sirvió y se replantea.
