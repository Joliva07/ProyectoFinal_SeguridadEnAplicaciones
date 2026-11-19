# Reparto de trabajo

## 1. Principio

La rúbrica son **5 componentes de 4 puntos**. Cada componente tiene **un responsable único (accountable)**: redacta, produce la evidencia y responde por ella. Los demás aportan piezas que ese responsable integra. Todos construyen una porción del sistema: sin tienda desplegada no hay evidencia de pentest ni de operación.

Regla de oro: **nadie documenta lo que no puede evidenciar.** Si un control no se implementó, se declara como propuesto y se justifica.

## 2. Resumen

| Integrante | Rol operativo | Componente de rúbrica (4 pts) | Construye |
|---|---|---|---|
| **James Maradiaga** | Security Engineer · borde y operaciones | 4. Implementación de ciberseguridad | WAF Cloudflare + Cloud Armor, SIEM/BigQuery, Falco e integridad, tratamiento del riesgo |
| **Javier Oliva** | Gobierno de activos y riesgo | 1. Análisis de riesgos y activos | Catálogo y pedidos sintéticos, cuentas demo, export de matrices |
| **Josue** | Cloud architecture & DevSecOps | 2. Arquitectura Cloud & DevSecOps | Terraform, GKE + manifiestos, imagen CI, pipeline, Cloud SQL, evaluación de contenedores |
| **Horacio** | Ciberdefensa y hardening del CMS | 3. Implementación de ciberdefensa | Imagen WordPress endurecida, configuración del CMS, pentest, revisión de plugins/temas |
| **Arun** | Informe técnico e integración | 5. Informe técnico & APA | Ensamblaje del informe, resumen ejecutivo, dictamen, roadmaps, control de formato UMG |

**Nota de asignación:** James no toma el informe; asume el componente con más dependencia de Cloudflare y de operación (WAF/SIEM/RASP), que es donde su acceso exclusivo a la zona aporta más. Arun pasa a integración documental: conoce el SIEM y ya redacta sus secciones, y puede empezar en paralelo sin bloquear la fase técnica.

## 3. Matriz RACI

R = ejecuta · A = responde · C = consultado · I = informado

| Actividad | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| Inventario de activos ISO 27001 + CIA | I | **A/R** | C | C | C |
| STRIDE / DREAD / matriz inicial | C | **A/R** | C | C | I |
| Arquitectura de seguridad objetivo | C | I | **A/R** | C | I |
| IAM de menor privilegio y cifrado | C | I | **A/R** | I | I |
| Terraform + Checkov/tfsec | I | I | **A/R** | I | I |
| Manifiestos K8s endurecidos | C | I | **A/R** | C | I |
| Pipeline SAST/SCA/WPScan/Trivy | C | I | **A/R** | C | I |
| Evaluación de contenedores y K8s | C | I | **A/R** | C | I |
| Imagen y configuración del CMS | C | I | C | **A/R** | I |
| Hardening del CMS y de plugins | C | I | I | **A/R** | I |
| Pentest caja negra | C | I | C | **A/R** | I |
| Pentest caja gris/blanca + OWASP Web Top 10 | C | I | C | **A/R** | I |
| Evaluación de plugins y temas | I | I | C | **A/R** | I |
| Casos de abuso y superficie de ataque | I | C | C | **A/R** | I |
| Reglas WAF Cloudflare / Cloud Armor | **A/R** | I | C | I | I |
| SIEM, Falco y dashboards | **A/R** | I | C | I | I |
| Tratamiento del riesgo y heatmap | **A/R** | R | C | C | I |
| Informe final, APA y dictamen | C | R | R | R | **A/R** |
| Presupuesto, accesos y teardown | **A/R** | I | C | I | I |

## 4. Fichas por integrante

### 4.1 James Maradiaga — Security Engineer (borde y operaciones)

**Componente:** 4. Implementación de ciberseguridad (4 pts).

**Construye**
- WAF: reglas custom Cloudflare para WordPress/WooCommerce (W-01..W-12), rate limiting, bot management, Turnstile, Access en `admin`/`staging`, Logpush. Es el único que aplica cambios en la zona.
- SIEM: sinks de Cloud Logging y Logpush a BigQuery, consultas de correlación, alertas AL-01..AL-08, dashboards.
- RASP: Falco, verificación de integridad del CMS (checksums + hash de plugins), monitoreo de REST/WooCommerce.
- Cloud Armor como segunda línea y plan de mitigación por hallazgo.

**Documenta**
- `docs/05-operaciones/waf-cloudflare.md`, `rasp-monitoreo.md`, `siem.md`, `tratamiento-riesgo.md`, `heatmap.md`.
- Secciones 4.2 y 5.1–5.6 del informe.

**Evidencia**
- Reglas con capturas de bloqueo antes/después, consultas BigQuery, alertas disparadas, dashboard exportado, matriz de tratamiento y heatmap residual.

**Definición de terminado**
- Cada `H-NN` con control, responsable y estado; 4 categorías de impacto (reputacional, operacional, financiero, legal) presentes; ≥2 alertas críticas probadas en < 2 min; heatmap residual con reducción verificada; 0 críticos sin control.

**Depende de:** hallazgos de Horacio, logs y pipeline de Josue, riesgos de Javier.
**Riesgo propio:** ser el único operador de Cloudflare y, a la vez, el evaluador del borde. Mitigación: specs y resultados versionados en el repo, revisión cruzada de Arun y pruebas con `curl` reproducibles por cualquiera.

---

### 4.2 Javier Oliva — Gobierno de activos y riesgo

**Componente:** 1. Análisis de riesgos y activos (4 pts).

**Construye**
- Catálogo de 60 productos, 40 clientes, 150 pedidos y 30 cupones sintéticos; importador WooCommerce (CSV) y cuentas `demo-*`.

**Documenta**
- `docs/01-activos-riesgos/inventario-activos.md` — 26+ activos con los 7 campos ISO 27001.
- `clasificacion-cia.md`, `stride.md`, `dread.md`, `matriz-riesgos.md`.
- `docs/06-informe/` §1.4 y §6.6 — normativas y referencias APA.
- Coautoría del heatmap y del tratamiento (con James).

**Evidencia**
- Inventario exportado (CSV + MD), matriz v1 y v2, heatmap inicial; CSV de datos sintéticos en `evidencias/fase1/`.

**Definición de terminado**
- Cada activo con propietario, custodio y usuarios; cada riesgo con STRIDE, DREAD y capa; al menos 1 riesgo por cada una de las 7 capas; IDs estables reutilizados por todos.

**Depende de:** arquitectura de Josue (ubicación de activos), hallazgos de Horacio (matriz v2).
**Riesgo propio:** documentar antes de que exista el sistema; se mitiga con inventario de diseño + verificación en semana 2.

---

### 4.3 Josue — Cloud architecture & DevSecOps

**Componente:** 2. Arquitectura Cloud & DevSecOps (4 pts).

**Construye**
- Terraform: VPC/subred, GKE Autopilot privado, Cloud SQL MySQL con CMEK, Artifact Registry, Secret Manager, GCS, Cloud Armor, sinks de logs, estado remoto.
- Manifiestos Kubernetes: Deployment PHP-FPM + Nginx, Service, Ingress, HPA, PDB, NetworkPolicy, PSA `restricted`, Workload Identity, read-only root FS, seccomp `RuntimeDefault`.
- Pipeline GitHub Actions: gitleaks, Semgrep (PHP), WPScan, composer/npm audit, Trivy, Checkov/tfsec (Terraform y K8s), build/push, deploy por WIF.

**Documenta**
- `docs/02-arquitectura/arquitectura-seguridad.md`.
- `docs/03-devsecops/pipeline.md`, `sast-sca.md`, `iac-hardening.md`, `contenedores-k8s.md`.
- `docs/04-ciberdefensa/evaluacion-contenedores.md` — 3.7 del informe.
- Secciones 3.5–3.7, 4.1, 4.5–4.7 del informe.

**Evidencia**
- `terraform plan` redactado, Checkov/tfsec antes/después, `kubectl get` del namespace, reportes Trivy, ejecuciones de Actions, URL de la tienda.

**Definición de terminado**
- `terraform apply` reproducible desde cero; GKE privado; PSA `restricted`; 0 CRITICAL con fix en Trivy; pipeline bloquea secretos y despliega por WIF; tienda responde por `aurorashop.ancordss.me.uk`.

**Depende de:** proyecto GCP (bootstrap de James), imagen y configuración de Horacio.
**Riesgo propio:** ruta crítica; plan B es Cloud Run para la demo, declarando la diferencia.

---

### 4.4 Horacio — Ciberdefensa y cliente CMS

**Componente:** 3. Implementación de ciberdefensa (4 pts).

**Construye**
- Imagen Docker multi-stage de WordPress + WooCommerce: `php.ini` endurecido, Nginx con reglas, usuario no root, plugins fijados, `wp-config.php` desde Secret Manager, `DISALLOW_FILE_EDIT`, XML-RPC deshabilitado, uploads sin ejecución PHP.
- Configuración del CMS: roles y capacidades mínimas, MFA (TOTP), límites de intentos, versiones ocultas.
- Pentest: WPScan, ZAP, Nmap, Burp, pruebas manuales de IDOR/BOLA en pedidos y REST, nonces/CSRF, capacidades, upload y SQLi en el plugin propio.

**Documenta**
- `docs/04-ciberdefensa/pentest-caja-negra.md`, `pentest-caja-gris.md`, `owasp-web-top10.md`, `evaluacion-plugins.md`, `casos-abuso.md`, `superficie-ataque.md`.
- `docs/03-devsecops/plugins-temas.md`.
- Secciones 3.1–3.4, 4.3 y 4.4 del informe.

**Evidencia**
- Reportes WPScan y ZAP, `nmap -sV`, capturas Burp redactadas, PoC de IDOR con dos cuentas, Trivy de la imagen, `curl` a `xmlrpc.php`, prueba de upload rechazado.

**Definición de terminado**
- ≥8 hallazgos `H-NN` con CVSS 4.0, capa, STRIDE y evidencia reproducible; plugins evaluados con versión, CVE y decisión; superficie mapeada con origen bloqueado verificado.

**Depende de:** tienda desplegada (Josue), WAF base (James), catálogo (Javier).
**Riesgo propio:** WooCommerce + GKE en 6 días; plan B es la misma imagen en Cloud Run para conservar evidencia.

---

### 4.5 Arun — Informe técnico e integración

**Componente:** 5. Informe técnico & formato APA (4 pts).

**Construye**
- Ninguna pieza de infraestructura: su trabajo es integrar, verificar y sostener la trazabilidad rúbrica→evidencia.
- Plantillas de captura de evidencia y control de calidad documental.
- Coordinación del checklist previo a entrega (formato, tablas, referencias, anexos).

**Documenta**
- `docs/06-informe/informe-final.md` — ensamblaje completo, resumen ejecutivo, 1.2, 1.3, 6.1–6.5.
- `docs/06-informe/formato-apa.md` — verificación final y checklist.
- `docs/00-plan/rubrica-trazabilidad.md` — estado semanal de cada criterio.

**Evidencia**
- PDF final en Arial 12 / 1.5 / APA 7, índice actualizado, 10 tablas y 4 figuras citadas, ≥15 referencias, anexos, dictamen.

**Definición de terminado**
- 20/20 puntos mapeados a archivo y evidencia con enlace; ninguna sección sin autor ni evidencia; PDF revisado en segundo dispositivo; control de cambios al día.

**Depende de:** todos. Es el único que **no** puede terminar antes que los demás, así que arranca temprano con estructura, referencias y la trazabilidad.
**Riesgo propio:** convertirse en cuello de botella al final. Mitigación: cada dueño entrega su sección en markdown dentro de su propio documento; Arun solo integra y corrige formato, no reescribe contenido técnico.

## 5. Accesos

| Recurso | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| GitHub | admin (Ancordss) | admin (Joliva07) | write (pendiente) | write (Horacio935) | write (pendiente) |
| GCP `aurorashop-sec-umg` | Owner + billing | Viewer + BigQuery Viewer | Viewer + Logs Viewer (deploy vía CI) | Viewer + Artifact Reader | Viewer + Logs/Monitoring Viewer |
| Cloudflare | **Admin (único)** | — | — | — | — |
| Claude | sí | sí | sí | sí | sí |

Pendiente: usuarios de GitHub de **Josue** y **Arun**, y correos para sus cuentas GCP.

## 6. Coordinación

1. **Un dueño por archivo.** Cambios ajenos: PR + aviso en la issue.
2. **Cloudflare:** issue con etiqueta `cloudflare` y plantilla de borde (host, regla, expresión, acción, evidencia). SLA 24 h; lo aplica James y comenta evidencia. Como ahora también es dueño del componente 4, las reglas se revisan con Horacio antes de pasar a `block`.
3. **GCP de escritura:** solo pipeline y James. Nadie crea recursos a mano en `demo`.
4. **Cadencia:** checkpoint escrito los martes en la issue de fase; demo de 15 min los viernes. Retrasos se avisan el lunes.
5. **Revisión cruzada:** Javier↔Josue (riesgos vs arquitectura), Horacio↔James (hallazgos vs mitigación), Arun↔todos (informe y evidencias).
6. **Congelamiento documental:** 9-dic; después solo formato y erratas.

## 7. Balance de carga

| Integrante | Carga | Piezas | Nota |
|---|---|---|---|
| James | Alta | WAF + SIEM + Falco + tratamiento + Cloudflare | Tiene el acceso exclusivo al borde y experiencia en operación |
| Javier | Media | 5 documentos + datos + coautoría | Arranca sin dependencias |
| Josue | Alta | Terraform + GKE + pipeline + contenedores | Ruta crítica; sin trabajo de CMS |
| Horacio | Alta | Imagen/CMS + 6 documentos de evaluación | Mayor incertidumbre; plan B definido |
| Arun | Media-alta | Informe completo + trazabilidad | Depende de todos; arranca primero con estructura |

Respaldo si alguien se cae: Javier→riesgos (James), Josue→infra/pipeline (James + Horacio), Horacio→pentest (James), James→SIEM/WAF (Josue), Arun→informe (Javier).
