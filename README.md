# FinanciaWeb — Seguridad Continua Cloud-Native (Proyecto Final)

Proyecto de Fin de Curso — **Seguridad en Aplicaciones (093-013)**, Maestría en Seguridad Informática, Universidad Mariano Gálvez de Guatemala.

**Modalidad:** reto práctico en grupos · **Ponderación:** 20 puntos netos · **Opción elegida:** A — Aplicación Móvil Banking / Fintech Cloud.

> Este repositorio es, en esta etapa, **coordinación y documentación**: alcance, reparto de trabajo, plantillas de evidencia y esqueleto del informe. El código (app móvil, backend, Terraform, pipeline) se agrega después en `app/` e `infra/` por los responsables definidos en [`docs/00-plan/reparto-trabajo.md`](docs/00-plan/reparto-trabajo.md).

## Escenario

FinanciaWeb es la app de banca en línea usada como caso en las semanas previas del curso (rediseño seguro con OWASP ASVS 5.0.0). El proyecto final la lleva de caso de diseño a **sistema desplegado y evaluado**: cliente móvil Android + backend de microservicios en Google Cloud, expuesto detrás de Cloudflare, con ciclo DevSecOps y operación monitoreada.

| Elemento | Decisión |
|---|---|
| Superficie móvil | Android (Kotlin/Flutter) con Keystore, biometría, OAuth2 + PKCE y TLS pinning |
| Backend | 2 microservicios en Cloud Run (`accounts`, `transfers`) sobre Cloud SQL PostgreSQL privado |
| Borde | Cloudflare (DNS, WAF, rate limiting, bot management, Zero Trust) |
| Nube | Google Cloud — API Gateway/LB, Cloud Armor, Identity Platform, KMS, Secret Manager, Cloud Logging/Monitoring |
| CI/CD | GitHub Actions — Semgrep, OWASP Dependency-Check/Snyk, Trivy, Checkov/tfsec, gitleaks |
| Código | GitHub — `Joliva07/ProyectoFinal_SeguridadEnAplicaciones` (público) |
| Dominio | `ancordss.me.uk` (zona en Cloudflare) |

### Subdominios

| Host | Destino | Protección |
|---|---|---|
| `financiaweb.ancordss.me.uk` | Web corporativa / portal de clientes (Cloud Run) | WAF + Managed Rules + rate limit |
| `api.financiaweb.ancordss.me.uk` | API Gateway → microservicios | WAF estricto + API Shield + JWT |
| `admin.financiaweb.ancordss.me.uk` | Consola administrativa | Cloudflare Access (Zero Trust) |

## Equipo

| Integrante | Rol | Componente de rúbrica que lidera | Acceso exclusivo |
|---|---|---|---|
| James Maradiaga | Lead Security Architect · integración y borde | 5. Informe técnico & APA | Cloudflare (zona `ancordss.me.uk`) |
| Javier | Gobierno de activos y riesgo | 1. Análisis de riesgos y activos | — |
| Josue | Cloud architecture & DevSecOps | 2. Arquitectura Cloud & DevSecOps | — |
| Horacio | Ciberdefensa y cliente móvil | 3. Implementación de ciberdefensa | — |
| Arun | Operaciones de seguridad y mitigación | 4. Implementación de ciberseguridad | — |

Todos tienen acceso a Google Cloud y a Claude. **Solo James tiene acceso a la cuenta de Cloudflare**; cualquier cambio de DNS/WAF se solicita como issue con la etiqueta `cloudflare` y lo aplica él.

## Mapa del repositorio

```
docs/00-plan/            alcance, reparto de trabajo, cronograma, rúbrica, accesos
docs/01-activos-riesgos/ inventario ISO 27001, CIA, STRIDE, DREAD, matriz de riesgos
docs/02-arquitectura/    arquitectura de seguridad objetivo, diagramas
docs/03-devsecops/       pipeline, SAST/SCA, hardening de IaC
docs/04-ciberdefensa/    pentest caja negra / gris-blanca, casos de abuso, superficie
docs/05-operaciones/     WAF, RASP/monitoreo, SIEM, tratamiento del riesgo, heatmap
docs/06-informe/         informe final (estructura Opción A) y control de formato APA
evidencias/              capturas, reportes de herramientas, salidas de escaneo
infra/                   Terraform (responsable: Josue) — aún sin código
app/                     cliente Android + microservicios (responsables: Horacio / Josue)
```

## Estado

| Fase | Documento | Responsable | Estado |
|---|---|---|---|
| 1 Planificación y riesgos | `docs/01-activos-riesgos/` | Javier | pendiente |
| 2 Arquitectura cloud | `docs/02-arquitectura/` | Josue | pendiente |
| 3 DevSecOps | `docs/03-devsecops/` | Josue | pendiente |
| 4 Ciberdefensa | `docs/04-ciberdefensa/` | Horacio | pendiente |
| 5 Despliegue y contenedores | `docs/03-devsecops/iac-hardening.md` | Josue | pendiente |
| 6 Operaciones y monitoreo | `docs/05-operaciones/` | Arun / James | pendiente |
| Informe y dictamen | `docs/06-informe/` | James | pendiente |

## Backlog

Las 28 tareas están en **Issues** de GitHub, agrupadas en 3 hitos (Sprint 1 Fundaciones · Sprint 2 Evaluación · Sprint 3 Cierre) y etiquetadas por dueño (`owner/*`), fase (`fase/*`) y tipo (`infra`, `cloudflare`, `pentest`, `ops`, `informe`). El detalle de cada asignación está en [`docs/00-plan/reparto-trabajo.md`](docs/00-plan/reparto-trabajo.md) y el calendario en [`cronograma.md`](docs/00-plan/cronograma.md).

## Reglas del juego

1. **Nada de datos reales.** Solo datos sintéticos; sin credenciales, tokens ni claves en el repo (`gitleaks` en CI).
2. **Pentesting solo contra infraestructura propia** del proyecto, en ventana acordada con James. Sin pruebas de DoS/volumétricas.
3. **Producción se despliega por pipeline**, no desde laptop. Accesos humanos = lectura; escritura solo vía CI y break-glass de James.
4. **Un dueño por archivo.** Se edita con PR; revisión cruzada obligatoria de otra persona.
5. **Presupuesto:** todo en capa gratuita/trial, con alertas de facturación y plan de teardown al cierre.

Ver [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SECURITY.md`](SECURITY.md) y [`docs/00-plan/alcance.md`](docs/00-plan/alcance.md).
