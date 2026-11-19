# Reparto de trabajo

## 1. Principio

La rúbrica son **5 componentes de 4 puntos**. Cada componente tiene **un responsable único (accountable)**: redacta, produce la evidencia y responde por ella. Los demás aportan piezas puntuales que ese responsable integra. Además del documento, todos construyen una porción del sistema —sin sistema desplegado no hay evidencia de pentest ni de operación.

Regla de oro: **nadie documenta lo que no puede evidenciar.** Si un control no se implementó, se declara como propuesto y se justifica.

## 2. Resumen

| Integrante | Rol operativo | Componente de rúbrica (4 pts) | Construye |
|---|---|---|---|
| **James Maradiaga** | Lead Security Architect · borde e integración | 5. Informe técnico & APA | Zona Cloudflare (DNS/TLS/WAF/Access), IAM base, ensamblaje del informe, dictamen |
| **Javier Oliva** | Gobierno de activos y riesgo | 1. Análisis de riesgos y activos | Modelo de datos, dataset sintético, cuentas demo |
| **Josue** | Cloud architecture & DevSecOps | 2. Arquitectura Cloud & DevSecOps | Terraform, pipeline CI/CD, backend Cloud Run + Cloud SQL |
| **Horacio** | Ciberdefensa y cliente móvil | 3. Implementación de ciberdefensa | APK Android endurecido, ejecución de pentest, casos de abuso |
| **Arun** | Operaciones de seguridad y mitigación | 4. Implementación de ciberseguridad | Reglas WAF (spec), SIEM, RASP/monitoreo, tratamiento del riesgo |

## 3. Matriz RACI

R = ejecuta · A = responde · C = consultado · I = informado

| Actividad | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| Inventario de activos ISO 27001 + CIA | C | **A/R** | C | C | I |
| STRIDE / DREAD / matriz inicial | I | **A/R** | C | C | C |
| Arquitectura de seguridad objetivo | **A** | I | **R** | C | C |
| IAM de menor privilegio y cifrado | C | I | **A/R** | I | C |
| Terraform + Checkov/tfsec | I | I | **A/R** | I | I |
| Pipeline SAST/SCA/secretos/contenedores | C | I | **A/R** | C | C |
| Backend Cloud Run + Cloud SQL | I | C | **A/R** | C | I |
| APK Android + hardening (MASVS) | C | I | I | **A/R** | I |
| Pentest caja negra | C | I | C | **A/R** | C |
| Pentest caja gris/blanca + OWASP API Top 10 | C | I | C | **A/R** | **R** |
| Casos de abuso y superficie de ataque | I | C | C | **A/R** | C |
| Reglas WAF Cloudflare / Cloud Armor | **A/R** | I | C | I | **R** |
| SIEM, RASP y dashboards | C | I | C | I | **A/R** |
| Tratamiento del riesgo y heatmap residual | C | **R** | C | C | **A** |
| Informe final, APA y dictamen | **A/R** | R | R | R | R |
| Presupuesto, accesos y teardown | **A/R** | I | C | I | I |

## 4. Fichas por integrante

### 4.1 James Maradiaga — Lead Security Architect (existente, sin componente nuevo)

**Componente:** 5. Informe técnico & formato APA (4 pts).

**Construye**
- Proyecto GCP, facturación, APIs habilitadas, IAM base y Workload Identity Federation para GitHub Actions.
- Zona Cloudflare: los 3 subdominios, TLS 1.3/Strict, HSTS, WAF gestionado + reglas custom (a partir de la spec de Arun), rate limiting, Bot Fight Mode, Cloudflare Access en `admin`, Turnstile en login, Logpush a GCS/BigQuery.
- Reglas de enfrentamiento, ventana de pentest, control de presupuesto y teardown.

**Documenta**
- `docs/06-informe/informe-final.md` (ensamblaje, no redacción de todo).
- `docs/00-plan/` — alcance, cronograma, accesos, rúbrica.
- Resumen ejecutivo, conclusiones, recomendaciones, roadmap, lecciones aprendidas, dictamen.

**Evidencia**
- Capturas de DNS/TLS/WAF/Access; `dig` y `curl -I` antes/después; alertas de presupuesto; matriz de cumplimiento de la rúbrica.

**Definición de terminado**
- 20/20 puntos mapeados a archivo y evidencia; documento en Arial 12/1.5/APA 7 con índice, tablas numeradas y referencias; revisión cruzada de los 4 informes parciales; PDF final generado.

**Depende de:** specs WAF de Arun, hallazgos de Horacio, arquitectura de Josue, riesgos de Javier.
**Riesgo propio:** cuello de botella de Cloudflare (mitigado con SLA 24 h) y ser el único con acceso de escritura a GCP de producción.

---

### 4.2 Javier Oliva — Gobierno de activos y riesgo

**Componente:** 1. Análisis de riesgos y activos (4 pts).

**Construye**
- Modelo de datos de FinanciaWeb (clientes, cuentas, movimientos, sesiones, auditoría) y script de datos sintéticos.
- Cuentas `demo-cliente-01..05`, `demo-admin-01` y rotación tras la fase 4.

**Documenta**
- `docs/01-activos-riesgos/inventario-activos.md` — 30–40 activos con los 7 campos ISO 27001 exigidos.
- `clasificacion-cia.md` — A/M/B por dimensión, criticidad calculada y justificación.
- `stride.md` — STRIDE por componente y caso de abuso; `dread.md` — scoring con desglose.
- `matriz-riesgos.md` — matriz inicial con ID `R-NN`, tipo, impacto, propietario y capa de las 7.

**Evidencia**
- Inventario exportado (CSV/MD), matriz con al menos 18 riesgos que cubran las 7 capas, heatmap inicial.

**Definición de terminado**
- Cada activo tiene propietario, custodio y usuarios con acceso; cada riesgo tiene STRIDE y DREAD; las 7 capas están explícitamente cubiertas con al menos 1 riesgo cada una; IDs estables reutilizados por los demás documentos.

**Depende de:** arquitectura de Josue (para ubicación de activos), hallazgos de Horacio (para actualizar la matriz al cierre).
**Riesgo propio:** documentar sin sistema construido; se mitiga con inventario de diseño + actualización en la semana 2.

---

### 4.3 Josue — Cloud architecture & DevSecOps

**Componente:** 2. Arquitectura Cloud & DevSecOps (4 pts).

**Construye**
- Terraform: VPC/subredes, Cloud SQL PostgreSQL privado con CMEK, Cloud Run (`accounts`, `transfers`), Artifact Registry, Secret Manager, Cloud Armor, API Gateway/LB, buckets con uniform access, sinks de logs.
- Backend de los 2 microservicios (Python/FastAPI o Node), con validación de JWT de Identity Platform, consultas parametrizadas y autorización por recurso.
- GitHub Actions: Semgrep, OWASP Dependency-Check o Snyk, gitleaks, Trivy (imagen), Checkov/tfsec (IaC), build del APK, deploy por WIF.

**Documenta**
- `docs/02-arquitectura/arquitectura-seguridad.md` — C4 + flujo de datos + controles por capa.
- `docs/03-devsecops/pipeline.md`, `sast-sca.md`, `iac-hardening.md`.

**Evidencia**
- `terraform plan` y reportes Checkov/tfsec; ejecuciones de Actions en verde/rojo controlado; reportes Semgrep/SCA/Trivy; URL de los servicios desplegados.

**Definición de terminado**
- `terraform apply` reproducible desde cero; ningún puerto 22/3389 abierto; bucket sin acceso público; pipeline corre en cada PR y bloquea secretos; los 2 servicios responden por `api.financiaweb.ancordss.me.uk` solo con JWT válido.

**Depende de:** proyecto GCP de James (día 1), modelo de datos de Javier.
**Riesgo propio:** es la ruta crítica; si se atrasa el backend, se bloquean las fases 4 y 6. Plan B: Cloud Run con SQLite/Cloud SQL mínimo el 25-nov y refinar después.

---

### 4.4 Horacio — Ciberdefensa y cliente móvil

**Componente:** 3. Implementación de ciberdefensa (4 pts).

**Construye**
- APK Android (Kotlin) o Flutter con: OAuth2 + PKCE contra Identity Platform, biometría (`BiometricPrompt`), tokens en Keystore/EncryptedSharedPreferences, certificate pinning, R8/obfuscación, detección de root/emulador, sin logs sensibles.
- Ejecución de pentest: ZAP (baseline + activo), Nmap, Burp Community (manual), pruebas de BOLA/IDOR con dos cuentas, manipulación de JWT, bypass de MFA y paginación abusiva.

**Documenta**
- `docs/04-ciberdefensa/pentest-caja-negra.md`, `pentest-caja-gris.md`, `casos-abuso.md`, `superficie-ataque.md`.
- Checklist MASVS en `docs/06-informe/informe-final.md` (anexo).

**Evidencia**
- Reportes ZAP (HTML), capturas Burp redactadas, `nmap -sV`, PoC de IDOR con dos cuentas, `apktool`/`jadx` mostrando ofuscación, video/captura de biometría y pinning fallando ante proxy (mitmproxy).

**Definición de terminado**
- Al menos 8 hallazgos con ID `H-NN`, severidad CVSS 4.0, capa, STRIDE y evidencia reproducible; superficie de ataque mapeada con puertos/endpoints; casos de abuso con pasos y control de detección.

**Depende de:** API desplegada (Josue, 25-nov), WAF base activo (James), cuentas demo (Javier).
**Riesgo propio:** poca experiencia Android; plan B APK mínimo con WebView endurecido para conservar la evidencia de pinning/Keystore.

---

### 4.5 Arun — Operaciones de seguridad y mitigación

**Componente:** 4. Implementación de ciberseguridad (4 pts).

**Construye**
- Spec de reglas WAF (Cloudflare + Cloud Armor) mapeadas a OWASP Top 10 y API Top 10; James las aplica (SLA 24 h).
- SIEM: sinks de Cloud Logging a BigQuery, consultas de correlación, alertas (login fallido masivo, 403/429 anómalos, acceso a recursos ajenos), dashboards.
- Monitoreo de APIs/RASP: métricas de Cloud Run + Cloud Armor + Cloudflare Analytics; reglas de detección de paginación abusiva y enumeración.
- Plan de mitigación por hallazgo (de Horacio y de SAST/SCA) y tratamiento formal del riesgo.

**Documenta**
- `docs/05-operaciones/waf-cloudflare.md`, `rasp-monitoreo.md`, `siem.md`, `tratamiento-riesgo.md`, `heatmap.md`.
- Evaluación OWASP API Top 10 en `docs/04-ciberdefensa/pentest-caja-gris.md` (sección API).

**Evidencia**
- Reglas WAF con capturas de bloqueo (antes/después), consultas BigQuery ejecutadas, alertas disparadas en prueba controlada, dashboard exportado, matriz aceptar/mitigar/transferir/evitar con heatmap antes-después.

**Definición de terminado**
- Cada hallazgo `H-NN` tiene control compensatorio, responsable y estado; las 4 categorías de impacto (reputacional, operacional, financiero, legal) aparecen en la matriz; el heatmap residual muestra la reducción.

**Depende de:** WAF base (James), hallazgos (Horacio), pipeline (Josue).
**Riesgo propio:** sin acceso a Cloudflare, depende del ciclo de issues; se mitiga entregando specs completas (regla, expresión, acción) en lugar de instrucciones vagas.

## 5. Accesos

| Recurso | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| GitHub | admin (Ancordss) | admin (Joliva07, owner) | write (pendiente) | write (Horacio935) | write (pendiente) |
| GCP `financiaweb-sec-umg` | Owner + billing | Viewer + BigQuery Viewer | Viewer + Logs Viewer (deploy vía CI) | Viewer + Artifact Reader | Viewer + Logs/Monitoring Viewer |
| Cloudflare | **Admin (único)** | — | — | — | — |
| Claude | sí | sí | sí | sí | sí |

Pendiente: confirmar usuarios de GitHub de **Josue** y **Arun**, y correos para las cuentas GCP. Sin nombres de usuario no se les puede asignar issues.

## 6. Coordinación

1. **Un dueño por archivo.** La tabla de la sección 4 define quién edita qué. Cambios ajenos: PR + aviso en la issue.
2. **Cloudflare:** issue con etiqueta `cloudflare`, plantilla "solicitud de borde" (host, regla, expresión, acción, evidencia esperada). SLA 24 h. James aplica y comenta la evidencia.
3. **GCP de escritura:** solo pipeline y James. Nadie crea recursos a mano en `demo`; si hace falta, se abre issue.
4. **Cadencia:** checkpoint escrito los martes en la issue de fase; demo de 15 min los viernes. Quien no llega avisa el lunes, no el viernes.
5. **Revisión cruzada obligatoria:** Javier↔Josue (riesgos vs arquitectura), Horacio↔Arun (hallazgos vs mitigación), James revisa todo el informe.
6. **Congelamiento documental:** 9-dic. Después de esa fecha solo se corrigen formato y erratas.

## 7. Balance de carga

| Integrante | Carga | Piezas | Nota |
|---|---|---|---|
| James | Alta | Informe completo + Cloudflare + IAM + integración | Su ventaja es que ya tiene el caso y el formato de semanas previas |
| Javier | Media | 5 documentos + datos | Arranca sin dependencias, buen punto de partida |
| Josue | Alta | Terraform + backend + CI | Ruta crítica; se le libera la parte móvil |
| Horacio | Alta | APK + 4 documentos de pentest | Mayor incertidumbre técnica; respaldo definido |
| Arun | Media | Specs WAF + SIEM + matriz | Depende de insumos, pero puede adelantar plantillas y consultas |

Nadie queda con dos componentes de rúbrica. Si alguien se cae, el respaldo es: Javier→activos/riesgo (James), Josue→IaC/pipeline (Horacio + James), Horacio→pentest (Arun), Arun→SIEM (James).
