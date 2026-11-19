# Reparto de trabajo

## 1. Principio

La rúbrica son **5 componentes de 4 puntos**. Cada componente tiene **un responsable único (accountable)**: redacta, produce la evidencia y responde por ella. Los demás aportan piezas que ese responsable integra. Todos construyen una porción del sistema: sin tienda desplegada no hay evidencia de pentest ni de operación.

Regla de oro: **nadie documenta lo que no puede evidenciar.** Si un control no se implementó, se declara como propuesto y se justifica.

## 2. Resumen

| Integrante | Rol operativo | Componente de rúbrica (4 pts) | Construye |
|---|---|---|---|
| **James Maradiaga** | Lead Security Architect · borde e integración | 5. Informe técnico & APA | Zona Cloudflare (DNS/TLS/WAF/Access/Logpush), ensamblaje del informe, dictamen |
| **Javier Oliva** | Gobierno de activos y riesgo | 1. Análisis de riesgos y activos | Catálogo y pedidos sintéticos, cuentas demo, export de matrices |
| **Josue** | Cloud architecture & DevSecOps | 2. Arquitectura Cloud & DevSecOps | Terraform, GKE + manifiestos, imagen CI, pipeline, Cloud SQL, evaluación de contenedores |
| **Horacio** | Ciberdefensa y hardening del CMS | 3. Implementación de ciberdefensa | Imagen WordPress endurecida, configuración del CMS, pentest, revisión de plugins/temas |
| **Arun** | Operaciones de seguridad y mitigación | 4. Implementación de ciberseguridad | Spec WAF, SIEM, Falco/integridad, tratamiento y heatmap residual |

## 3. Matriz RACI

R = ejecuta · A = responde · C = consultado · I = informado

| Actividad | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| Inventario de activos ISO 27001 + CIA | C | **A/R** | C | C | I |
| STRIDE / DREAD / matriz inicial | I | **A/R** | C | C | C |
| Arquitectura de seguridad objetivo | **A** | I | **R** | C | C |
| IAM de menor privilegio y cifrado | C | I | **A/R** | I | C |
| Terraform + Checkov/tfsec | I | I | **A/R** | I | I |
| Manifiestos K8s endurecidos | C | I | **A/R** | C | C |
| Pipeline SAST/SCA/WPScan/Trivy | C | I | **A/R** | C | C |
| Evaluación de contenedores y K8s | I | I | **A/R** | C | C |
| Imagen y configuración del CMS | C | I | C | **A/R** | I |
| Hardening del CMS y de plugins | C | I | I | **A/R** | C |
| Pentest caja negra | C | I | C | **A/R** | C |
| Pentest caja gris/blanca + OWASP Web Top 10 | C | I | C | **A/R** | **R** |
| Evaluación de plugins y temas | I | I | C | **A/R** | C |
| Casos de abuso y superficie de ataque | I | C | C | **A/R** | C |
| Reglas WAF Cloudflare / Cloud Armor | **A/R** | I | C | I | **R** |
| SIEM, Falco y dashboards | C | I | C | I | **A/R** |
| Tratamiento del riesgo y heatmap residual | C | **R** | C | C | **A** |
| Informe final, APA y dictamen | **A/R** | R | R | R | R |
| Presupuesto, accesos y teardown | **A/R** | I | C | I | I |

## 4. Fichas por integrante

### 4.1 James Maradiaga — Lead Security Architect

**Componente:** 5. Informe técnico & formato APA (4 pts).

**Construye**
- Zona Cloudflare completa: DNS de los 3 hosts, TLS, WAF, rate limiting, Access, Turnstile, Logpush.
- Reglas de enfrentamiento, ventana de pentest y verificación técnica del borde.
- **No** administra la cuenta GCP: eso es de Javier.
- Zona Cloudflare: los 3 subdominios, TLS 1.3/Strict, HSTS, WAF gestionado + reglas custom (spec de Arun), rate limiting, bot management, Access en `admin` y `staging`, Turnstile en login/checkout, Logpush a GCS/BigQuery.
- Reglas de enfrentamiento, ventana de pentest, presupuesto y teardown.

**Documenta**
- `docs/00-plan/` — alcance, cronograma, accesos, rúbrica, este reparto.
- `docs/06-informe/informe-final.md` — ensamblaje, resumen ejecutivo, conclusiones, recomendaciones, roadmap, lecciones aprendidas, dictamen.

**Evidencia**
- Capturas DNS/TLS/WAF/Access; `dig` y `curl -I` antes/después; alertas de presupuesto; matriz de la rúbrica.

**Definición de terminado**
- 20/20 puntos mapeados a archivo y evidencia; documento Arial 12/1.5/APA 7 con índice, tablas numeradas y ≥15 referencias; PDF final.

**Depende de:** specs WAF de Arun, hallazgos de Horacio, arquitectura y evaluación de contenedores de Josue, riesgos de Javier.
**Riesgo propio:** cuello de botella de Cloudflare y ser el único con escritura manual en GCP.

---

### 4.2 Javier Oliva — Gobierno de activos y riesgo

**Componente:** 1. Análisis de riesgos y activos (4 pts).

**Construye**
- Catálogo de 60 productos, 40 clientes, 150 pedidos y 30 cupones sintéticos; importador WooCommerce (CSV) y cuentas `demo-*`.

**Documenta**
- `docs/01-activos-riesgos/inventario-activos.md` — 26+ activos con los 7 campos ISO 27001.
- `clasificacion-cia.md` — A/M/B, criticidad calculada y justificación.
- `stride.md` — STRIDE por componente y flujo; `dread.md` — scoring con desglose.
- `matriz-riesgos.md` — 28 riesgos con ID `R-NN`, tipo, impacto, capa y tratamiento.
- `docs/06-informe/` §1.4 y §6.6 — normativas y referencias APA.

**Evidencia**
- Inventario exportado (CSV + MD), matriz v1 y v2, heatmap inicial; CSV de datos sintéticos en `evidencias/fase1/`.

**Definición de terminado**
- Cada activo con propietario, custodio y usuarios; cada riesgo con STRIDE, DREAD y capa; al menos 1 riesgo por cada una de las 7 capas; IDs estables usados por los demás documentos.

**Depende de:** arquitectura de Josue (ubicación de activos), hallazgos de Horacio (matriz v2).
**Riesgo propio:** documentar antes de que exista el sistema; se mitiga con inventario de diseño + verificación en semana 2.

---

### 4.3 Josue — Cloud architecture & DevSecOps

**Componente:** 2. Arquitectura Cloud & DevSecOps (4 pts).

**Construye**
- Terraform: VPC/subred, GKE Autopilot privado, Cloud SQL MySQL con CMEK, Artifact Registry, Secret Manager, GCS, Cloud Armor, sinks de logs, estado remoto.
- Manifiestos Kubernetes: Deployment PHP-FPM + Nginx, Service, Ingress, HPA, PDB, NetworkPolicy, Pod Security `restricted`, Workload Identity, read-only root FS, seccomp `RuntimeDefault`, límites de recursos.
- Pipeline GitHub Actions: gitleaks, Semgrep (PHP), WPScan, composer/npm audit, Trivy, Checkov/tfsec (Terraform y K8s), build/push de imagen, deploy por WIF.

**Documenta**
- `docs/02-arquitectura/arquitectura-seguridad.md` — C4, flujo de checkout, IAM, cifrado, decisiones.
- `docs/03-devsecops/pipeline.md`, `sast-sca.md`, `iac-hardening.md`, `contenedores-k8s.md`.
- `docs/04-ciberdefensa/evaluacion-contenedores.md` — 3.7 del informe.
- Secciones 4.5, 4.6 y 4.7 del informe.

**Evidencia**
- `terraform plan` redactado, Checkov/tfsec antes/después, `kubectl get` del namespace, reportes Trivy, ejecuciones de Actions, URL de la tienda.

**Definición de terminado**
- `terraform apply` reproducible desde cero; GKE privado sin API pública; Pod Security `restricted` aplicado; 0 CRITICAL con fix en Trivy; pipeline bloquea secretos y despliega por WIF; tienda responde por `aurorashop.ancordss.me.uk`.

**Depende de:** proyecto GCP y accesos otorgados por Javier (día 1; el primer `terraform apply` del bootstrap lo ejecuta él), imagen y configuración de Horacio.
**Riesgo propio:** es la ruta crítica; si GKE se atrasa, plan B es Cloud Run para la demo (se documenta la diferencia).

---

### 4.4 Horacio — Ciberdefensa y cliente CMS

**Componente:** 3. Implementación de ciberdefensa (4 pts).

**Construye**
- Imagen Docker multi-stage de WordPress + WooCommerce: `php.ini` endurecido, Nginx con reglas de bloqueo, usuario no root, sin herramientas de build, plugins fijados por versión, `wp-config.php` generado desde Secret Manager, `DISALLOW_FILE_EDIT`, XML-RPC deshabilitado, uploads sin ejecución PHP.
- Configuración del CMS: roles y capacidades mínimas, MFA (TOTP), 2FA en admin, límites de intentos, `wp-cron` por sistema, versiones ocultas.
- Ejecución de pentest: WPScan, ZAP (baseline + activo), Nmap, Burp Community, pruebas manuales de IDOR/BOLA en pedidos y REST, nonces/CSRF, capacidades, upload y SQLi en el plugin propio.

**Documenta**
- `docs/04-ciberdefensa/pentest-caja-negra.md`, `pentest-caja-gris.md`, `owasp-web-top10.md`, `evaluacion-plugins.md`, `casos-abuso.md`, `superficie-ataque.md`.
- Secciones 3.1–3.4, 4.3 y 4.4 del informe.

**Evidencia**
- Reportes WPScan y ZAP, `nmap -sV`, capturas Burp redactadas, PoC de IDOR con dos cuentas, `docker history`/Trivy de la imagen, `curl` a `xmlrpc.php` (405/403), prueba de upload rechazado.

**Definición de terminado**
- ≥8 hallazgos `H-NN` con CVSS 4.0, capa, STRIDE y evidencia reproducible; tabla API/REST completa; plugins evaluados con versión, CVE y decisión; superficie mapeada con bloqueo del origen verificado.

**Depende de:** tienda desplegada (Josue, 25-nov), WAF base (James), catálogo (Javier).
**Riesgo propio:** WooCommerce + GKE en 6 días; el plan B es la misma imagen en Cloud Run para conservar evidencia de WAF y pentest, declarando la diferencia.

---

### 4.5 Arun — Operaciones de seguridad y mitigación

**Componente:** 4. Implementación de ciberseguridad (4 pts).

**Construye**
- Spec de reglas WAF (Cloudflare + Cloud Armor) específicas de WordPress/WooCommerce, mapeadas a OWASP Top 10; James las aplica (SLA 24 h).
- SIEM: sinks de Cloud Logging y Logpush a BigQuery, consultas de correlación, alertas (exploit de plugin, fuerza bruta, card testing, cambios de archivos, `kubectl exec`), dashboards.
- RASP/monitoreo: Falco en GKE, verificación de integridad del CMS (checksums de núcleo + hash de plugins), monitoreo de `/wp-json/wc/v3/*`.
- Plan de mitigación por hallazgo y tratamiento formal del riesgo.

**Documenta**
- `docs/05-operaciones/waf-cloudflare.md`, `rasp-monitoreo.md`, `siem.md`, `tratamiento-riesgo.md`, `heatmap.md`.
- Verificación de OWASP Web Top 10 en `docs/04-ciberdefensa/owasp-web-top10.md` (co-ejecución con Horacio).
- Sección 4.2 y 5.1–5.6 del informe.

**Evidencia**
- Reglas WAF con capturas de bloqueo, consultas BigQuery, alertas disparadas, dashboard exportado, matriz de tratamiento y heatmap residual.

**Definición de terminado**
- Cada `H-NN` con control, responsable y estado; 4 categorías de impacto (reputacional, operacional, financiero, legal) presentes; ≥2 alertas críticas probadas; heatmap residual con reducción verificada.

**Depende de:** WAF base (James), hallazgos (Horacio), pipeline y logs (Josue).
**Riesgo propio:** sin acceso a Cloudflare depende del ciclo de issues; se mitiga entregando reglas con expresión exacta y caso de prueba.

## 5. Accesos

| Recurso | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| GitHub | write (Ancordss) | write (pendiente) | **owner (Joliva07)** | write (Horacio935) | write (pendiente) |
| GCP `aurorashop-sec-umg` | Viewer + break-glass temporal | **Owner + billing (cuenta GCP)** | Viewer + Logs Viewer (deploy vía CI) | Viewer + Artifact Reader | Viewer + Logs/Monitoring Viewer |
| Cloudflare | **Admin (único)** | — | — | — | — |
| Claude | sí | sí | sí | sí | sí |

Pendiente: usuarios de GitHub de **Javier** y **Arun**. La cuenta GCP y los accesos ya los administra Javier.

## 6. Coordinación

1. **Un dueño por archivo.** Cambios ajenos: PR + aviso en la issue.
2. **Cloudflare:** issue con etiqueta `cloudflare` y plantilla de borde (host, regla, expresión, acción, evidencia esperada). SLA 24 h. James aplica y comenta evidencia.
3. **GCP de escritura:** solo pipeline y James. Nadie crea recursos a mano en `demo`.
4. **Cadencia:** checkpoint escrito los martes en la issue de fase; demo de 15 min los viernes. Retrasos se avisan el lunes.
5. **Revisión cruzada:** Javier↔Josue (riesgos vs arquitectura), Horacio↔Arun (hallazgos vs mitigación), James revisa todo el informe.
6. **Congelamiento documental:** 9-dic; después solo formato y erratas.

## 7. Balance de carga

| Integrante | Carga | Piezas | Nota |
|---|---|---|---|
| James | Alta | Informe + Cloudflare + IAM + integración | Ya tiene práctica con el formato APA del curso |
| Javier | Media | 5 documentos + datos | Arranca sin dependencias |
| Josue | Alta | Terraform + GKE + pipeline + contenedores | Ruta crítica; sin trabajo de CMS |
| Horacio | Alta | Imagen/CMS + 6 documentos de evaluación | Mayor incertidumbre; plan B definido |
| Arun | Media | WAF + SIEM + Falco + matriz | Puede adelantar consultas y plantillas |

Nadie con dos componentes de rúbrica. Respaldo si alguien se cae: Javier→riesgos (James), Josue→infra/pipeline (Horacio + James), Horacio→pentest (Arun), Arun→SIEM (James).
