# AuroraShop — Seguridad Continua Cloud-Native (Proyecto Final)

Proyecto de Fin de Curso — **Seguridad en Aplicaciones (093-013)**, Maestría en Seguridad Informática, Universidad Mariano Gálvez de Guatemala.

**Modalidad:** reto práctico en grupos · **Ponderación:** 20 puntos netos · **Opción elegida:** B — CMS / E-Commerce Web Enterprise Cloud-Native.

> Esta etapa es **coordinación y documentación**: alcance, reparto, plantillas de evidencia y esqueleto del informe. El código (imagen del CMS, Terraform, manifiestos, pipeline) se agrega después en `cms/` e `infra/` por los responsables definidos en [`docs/00-plan/reparto-trabajo.md`](docs/00-plan/reparto-trabajo.md).

## Escenario

AuroraShop es una tienda en línea (WordPress + WooCommerce) desplegada en contenedores sobre **GKE Autopilot**, con base de datos administrada en Cloud SQL MySQL, media en Cloud Storage y entrega a través de **Cloudflare**. Se evalúa como un CMS/e-commerce empresarial: superficie de plugins, WAF, hardening de contenedores, IaC y operación monitoreada.

| Elemento | Decisión |
|---|---|
| CMS / E-commerce | WordPress 6.x + WooCommerce (PHP 8.3, imagen propia multi-stage) |
| Cómputo | GKE Autopilot (namespace `aurorashop`), 2–6 pods de PHP-FPM + Nginx, HPA |
| Base de datos | Cloud SQL MySQL 8 con IP privada, CMEK y usuario de aplicación |
| Media / estáticos | Cloud Storage (bucket privado) + Cloudflare CDN |
| Borde | Cloudflare (DNS, WAF, rate limiting, bot management, Access en admin, Logpush) |
| Nube | GCP — GKE, Cloud SQL, Cloud KMS, Secret Manager, Artifact Registry, Cloud Logging/Monitoring, Cloud Armor |
| CI/CD | GitHub Actions — gitleaks, Semgrep, WPScan, composer/npm audit, Trivy, Checkov/tfsec, deploy por WIF |
| Código | GitHub — `Joliva07/ProyectoFinal_SeguridadEnAplicaciones` |
| Dominio | `ancordss.me.uk` (zona en Cloudflare) |

### Subdominios

| Host | Destino | Protección |
|---|---|---|
| `aurorashop.ancordss.me.uk` | Storefront + checkout (Ingress GKE) | WAF gestionado + CRS + rate limit + Turnstile |
| `admin.aurorashop.ancordss.me.uk` | `wp-admin` y REST de administración | Cloudflare Access (Zero Trust) + MFA |
| `staging.aurorashop.ancordss.me.uk` | Réplica de pruebas para pentest | Access + `noindex` |

> No hay subdominio de API separado: WooCommerce expone `/wp-json/wc/v3/*` en el mismo host y se protege con reglas propias.

## Equipo

| Integrante | Rol | Componente de rúbrica | Acceso exclusivo |
|---|---|---|---|
| James Maradiaga | Lead Security Architect · borde e integración | 5. Informe técnico & APA | Cloudflare (zona `ancordss.me.uk`) |
| Javier Oliva | Gobierno de activos y riesgo | 1. Análisis de riesgos y activos | Cuenta GCP y facturación |
| Josue | Cloud architecture & DevSecOps | 2. Arquitectura Cloud & DevSecOps | Repositorio GitHub (owner) |
| Horacio | Ciberdefensa y hardening del CMS | 3. Implementación de ciberdefensa | — |
| Arun | Operaciones de seguridad y mitigación | 4. Implementación de ciberseguridad | — |

Todos con acceso a Google Cloud y Claude. **James opera Cloudflare**, **Javier administra la cuenta GCP y los accesos** y **Josue es dueño del repositorio**. Los cambios de borde se piden por issue con etiqueta `cloudflare` (SLA 24 h).

## Mapa del repositorio

```
docs/00-plan/            plan de trabajo por persona, reparto, cronograma, rúbrica, accesos
docs/01-activos-riesgos/ inventario ISO 27001, CIA, STRIDE, DREAD, matriz
docs/02-arquitectura/    arquitectura de seguridad objetivo, diagramas
docs/03-devsecops/       pipeline, SAST/SCA, IaC, contenedores/K8s, plugins
docs/04-ciberdefensa/    pentest, OWASP Web Top 10, plugins, contenedores, abuso
docs/05-operaciones/     WAF, RASP/Falco, SIEM, tratamiento del riesgo, heatmap
docs/06-informe/         informe final (Opción B) y control de formato APA
evidencias/              capturas, reportes de herramientas, salidas de escaneo
cms/                     Dockerfile, configuración PHP/Nginx, plugin propio, tema
infra/                   Terraform + manifiestos Kubernetes (responsable: Josue)
```

## Estado

| Fase | Documento | Responsable | Estado |
|---|---|---|---|
| 1 Planificación y riesgos | `docs/01-activos-riesgos/` | Javier | pendiente |
| 2 Arquitectura cloud | `docs/02-arquitectura/` | Josue | pendiente |
| 3 DevSecOps | `docs/03-devsecops/` | Josue | pendiente |
| 4 Ciberdefensa | `docs/04-ciberdefensa/` | Horacio | pendiente |
| 5 Despliegue y contenedores | `docs/03-devsecops/contenedores-k8s.md` | Josue | pendiente |
| 6 Operaciones y monitoreo | `docs/05-operaciones/` | Arun / James | pendiente |
| Informe y dictamen | `docs/06-informe/` | James | pendiente |

## Backlog

Las tareas están en **Issues** de GitHub, en 3 hitos (Sprint 1 Fundaciones · Sprint 2 Evaluación · Sprint 3 Cierre), etiquetadas por dueño (`owner/*`), fase (`fase/*`), tipo (`infra`, `cloudflare`, `pentest`, `ops`, `informe`) y estado (`estado/en-curso`, `estado/bloqueado`, `estado/revision`).

**Empieza por [`docs/00-plan/plan-de-trabajo.md`](docs/00-plan/plan-de-trabajo.md)**: ahí está la lista ordenada de cada quien, con dependencias y criterio de cierre. Asignación en [`reparto-trabajo.md`](docs/00-plan/reparto-trabajo.md) y calendario en [`cronograma.md`](docs/00-plan/cronograma.md).

## Reglas del juego

1. **Nada de datos reales.** Catálogo, clientes y pedidos sintéticos; sin credenciales ni claves en el repo (`gitleaks` en CI).
2. **Pentesting solo contra infraestructura propia**, en ventana acordada con James. Sin DoS ni pruebas de pago reales.
3. **Producción se despliega por pipeline**, no desde laptop. Humanos con lectura; escritura vía CI y break-glass de James.
4. **Un dueño por archivo.** Se edita con PR y revisión cruzada.
5. **Presupuesto:** capa gratuita/trial, alertas de facturación y plan de teardown al cierre.

Ver [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SECURITY.md`](SECURITY.md) y [`docs/00-plan/alcance.md`](docs/00-plan/alcance.md).
