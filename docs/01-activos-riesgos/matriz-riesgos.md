# Matriz de riesgos

Dueños: **Javier** (v1) → **Arun** (residual) · Capas: las 7 de seguridad en profundidad

## 1. Escalas

**Probabilidad:** 1 rara · 2 improbable · 3 posible · 4 probable · 5 casi segura.
**Impacto:** 1 insignificante · 2 menor · 3 moderado · 4 mayor · 5 catastrófico.
**Riesgo = P × I.** 1–4 Bajo · 5–9 Medio · 10–14 Alto · 15–25 Crítico.

Capas: **1** Datos · **2a** Código · **2b** Aplicación · **2c** Implementación · **2d** Perímetro de aplicación · **3** Host · **4** Red interna · **5** Perímetro cloud/red · **6** Física · **7** Políticas y personas.

## 2. Matriz (v1 del diseño)

| ID | Riesgo | Capa | Tipo | Amenaza | Activos | P | I | R | Nivel | Impacto de negocio | Tratamiento |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R-01 | Plugin o tema con CVE explotable (RCE/SQLi) | 2c | Software | T-16 | A-06, A-21 | 4 | 5 | 20 | Crítico | Financiero, legal, reputacional | Mitigar |
| R-02 | SQLi en plugin propio o búsqueda | 2a | Software | T-12 | A-21, A-01 | 3 | 5 | 15 | Crítico | Legal, financiero | Mitigar |
| R-03 | XSS almacenado en reseñas/perfil | 2a | Software | T-10 | A-04, A-20 | 4 | 3 | 12 | Alto | Reputacional, operacional | Mitigar |
| R-04 | CSRF en acción de admin o checkout | 2b | Software | T-09 | A-20, A-02 | 3 | 4 | 12 | Alto | Operacional | Mitigar |
| R-05 | IDOR/BOLA en pedidos vía REST | 2b | Software | T-18 | A-02, A-01 | 4 | 4 | 16 | Crítico | Legal, reputacional | Mitigar |
| R-06 | Fuerza bruta / credential stuffing (wp-login, XML-RPC) | 2d | Seguridad | T-01, T-05 | A-04 | 5 | 3 | 15 | Crítico | Operacional | Mitigar |
| R-07 | Enumeración de usuarios y versiones | 2d | Seguridad | T-06 | A-04, A-06 | 5 | 2 | 10 | Alto | Reputacional | Mitigar |
| R-08 | Upload de PHP ejecutable en media | 2d | Software | T-11 | A-09, A-08 | 2 | 5 | 10 | Alto | Financiero, operacional | Mitigar |
| R-09 | `wp-config.php` o backups SQL en webroot | 3 | Técnico | T-35, T-36 | A-05, A-19 | 3 | 5 | 15 | Crítico | Legal, financiero | Mitigar |
| R-10 | Contenedor privilegiado/root → escape al nodo | 3 | Técnico | T-28, T-29 | A-08, A-10 | 2 | 5 | 10 | Alto | Operacional, financiero | Mitigar |
| R-11 | Imagen base con CVEs sin parchear | 3 | Software | T-34 | A-08 | 4 | 3 | 12 | Alto | Operacional | Mitigar |
| R-12 | K8s sin NetworkPolicy ni RBAC mínimo | 4 | Cloud | T-30, T-29 | A-10, A-15 | 3 | 4 | 12 | Alto | Operacional | Mitigar |
| R-13 | Cloud SQL con IP pública o usuario root para la app | 4 | Técnico | T-12 | A-21 | 3 | 5 | 15 | Crítico | Legal, financiero | Mitigar |
| R-14 | Bucket GCS público (media/backups) | 5 | Cloud | T-37 | A-09, A-19 | 2 | 5 | 10 | Alto | Legal, reputacional | Mitigar |
| R-15 | WAF ausente o con reglas débiles | 5 | Cloud | T-41, T-43 | A-17 | 4 | 4 | 16 | Crítico | Operacional, reputacional | Mitigar |
| R-16 | Sin rate limiting ni bot management (card testing, scraping) | 5 | Cloud | T-22, T-23 | A-16, A-22 | 4 | 3 | 12 | Alto | Financiero | Mitigar |
| R-17 | Origen accesible saltando Cloudflare | 5 | Cloud | T-44 | A-16, A-20 | 3 | 4 | 12 | Alto | Operacional | Mitigar |
| R-18 | TLS débil o contenido mixto | 1 | Técnico | T-40 | A-16 | 3 | 3 | 9 | Medio | Reputacional | Mitigar |
| R-19 | Secretos en repo o variables de entorno | 1 | Software | T-33, T-47 | A-13, A-05 | 4 | 5 | 20 | Crítico | Operacional, financiero | Mitigar |
| R-20 | Admin sin MFA ni restricción de acceso | 2b | Seguridad | T-03 | A-20 | 3 | 5 | 15 | Crítico | Financiero, legal | Mitigar |
| R-21 | Sin auditoría centralizada ni retención | 7 | Proceso | T-26, T-27 | A-18 | 5 | 3 | 15 | Crítico | Legal, operacional | Mitigar |
| R-22 | Backups sin cifrar o sin restauración probada | 1 | Proceso | T-55 | A-19 | 3 | 4 | 12 | Alto | Operacional, legal | Mitigar |
| R-23 | Pipeline sin SAST/SCA/IaC/secretos | 7 | Proceso | T-47, T-48 | A-12, A-08 | 4 | 4 | 16 | Crítico | Operacional | Mitigar |
| R-24 | Sin Pod Security Admission ni control de admisión | 3 | Cloud | T-28 | A-10 | 3 | 4 | 12 | Alto | Operacional | Mitigar |
| R-25 | Dependencia del cumplimiento del proveedor cloud | 6 | Cloud | T-56 | A-21, A-14 | 1 | 5 | 5 | Medio | Legal | Transferir |
| R-26 | Phishing a administrador o cuenta de agencia | 7 | Personas | T-52 | A-20, A-25 | 3 | 4 | 12 | Alto | Financiero, reputacional | Mitigar |
| R-27 | Datos reales en capturas o evidencias | 7 | Proceso | T-54 | A-24 | 3 | 3 | 9 | Medio | Legal | Evitar |
| R-28 | Un solo operador de Cloudflare | 7 | Proceso | — | A-17 | 3 | 3 | 9 | Medio | Operacional | Aceptar (temporal) |

## 3. Cobertura por capa

| Capa | Riesgos | ¿Cubierta? |
|---|---|---|
| 1 Datos | R-18, R-19, R-22 | sí |
| 2a Código | R-02, R-03 | sí |
| 2b Aplicación | R-04, R-05, R-20 | sí |
| 2c Implementación | R-01 | sí |
| 2d Perímetro de aplicación | R-06, R-07, R-08 | sí |
| 3 Host | R-09, R-10, R-11, R-24 | sí |
| 4 Red interna | R-12, R-13 | sí |
| 5 Perímetro cloud | R-14, R-15, R-16, R-17 | sí |
| 6 Física | R-25 | sí |
| 7 Políticas/personas | R-21, R-23, R-26, R-27, R-28 | sí |

## 4. Tratamiento (detalle en `docs/05-operaciones/tratamiento-riesgo.md`)

| Riesgo | Decisión | Control principal | Responsable | Residual |
|---|---|---|---|---|
| R-01, R-11 | Mitigar | Plugins fijados por versión, WPScan en CI, Trivy, rebuild programado | Horacio / Josue | 6 |
| R-02 | Mitigar | `$wpdb->prepare`, validación y escape; revisión de código | Horacio | 3 |
| R-03 | Mitigar | Escape en salida, CSP, sanitización de entrada | Horacio | 4 |
| R-04 | Mitigar | Nonces, `SameSite`, verificación de referer | Horacio | 4 |
| R-05 | Mitigar | Comprobación de propiedad en pedidos + tests de regresión | Horacio | 6 |
| R-06, R-07 | Mitigar | Rate limit en borde, 2FA, XML-RPC cerrado, versiones ocultas | James / Arun | 4 |
| R-08 | Mitigar | Uploads sin ejecución, validación MIME, `.htaccess`/Nginx rule | Horacio | 3 |
| R-09 | Mitigar | Document root limpio, secretos fuera del FS, backups fuera de webroot | Josue | 3 |
| R-10, R-24 | Mitigar | PSA `restricted`, non-root, drop caps, seccomp, read-only FS | Josue | 2 |
| R-12 | Mitigar | NetworkPolicy deny-all + allow DB/GCS, RBAC por namespace | Josue | 3 |
| R-13 | Mitigar | IP privada, usuario app sin privilegios, CMEK | Josue | 3 |
| R-14 | Mitigar | Uniform access, sin `allUsers`, IAM por SA | Josue | 3 |
| R-15, R-16, R-17 | Mitigar | WAF CRS + reglas WP, rate limit, Access, origen restringido | Arun / James | 6 |
| R-18 | Mitigar | Full strict, TLS 1.3, HSTS, evitar contenido mixto | James | 2 |
| R-19 | Mitigar | Secret Manager, gitleaks, CSI driver | Josue | 3 |
| R-20 | Mitigar | Access + MFA obligatorio + IP allowlist | James / Horacio | 3 |
| R-21, R-22 | Mitigar | Sinks a BigQuery, retención 90 días, restore probado | Arun | 4 |
| R-23 | Mitigar | Pipeline con SAST/SCA/WPScan/Trivy/Checkov/gitleaks | Josue | 4 |
| R-25 | Transferir | SLA y certificaciones del proveedor | James | 5 |
| R-26 | Mitigar | MFA, Access, capacitación, revisión de accesos | James | 6 |
| R-27 | Evitar | Regla en `SECURITY.md` + revisión cruzada | Todos | 2 |
| R-28 | Aceptar | Documentar SLA de cambios y respaldo | James | 9 |

## 5. Historial

| Fecha | Versión | Cambio | Autor |
|---|---|---|---|
| 2026-11-18 | v1 | Matriz inicial de 28 riesgos (Opción B) | Javier |
