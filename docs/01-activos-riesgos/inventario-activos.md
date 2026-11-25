# Inventario de activos (ISO/IEC 27001:2022, A.5.9)

Dueño: **Javier** · Revisión: James · Estado: plantilla con activos del diseño

## Cómo mantenerlo

- Un activo por fila, ID estable `A-NN`.
- **Valoración CIA**: A/M/B por dimensión; criticidad calculada (ver `clasificacion-cia.md`).
- **Tipo**: Información · Software · Físico · Personal · Servicios · Empresa.
- **Ubicación**: Local · Cloud · Contenedor · Repositorio · Proveedor.
- Propietario (decide), custodio (opera) y usuarios con acceso.

## Inventario

| ID | Activo | Proceso asociado | Descripción | Tipo | Ubicación | C | I | A | Criticidad | Justificación | Propietario | Custodio | Usuarios |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A-01 | Datos de clientes | Venta | Nombre, dirección, teléfono, correo de 40 clientes | Información | Cloud (Cloud SQL) | A | A | M | Crítica | PII; obligación legal de protección | Javier | Josue | App, admin |
| A-02 | Pedidos e historial | Venta | Órdenes, montos, estados, cupones usados | Información | Cloud (Cloud SQL) | A | A | M | Crítica | Integridad = fraude y contracargos | Javier | Josue | App, shop_manager |
| A-03 | Datos de pago | Checkout | Referencias tokenizadas de la pasarela sandbox | Información | Proveedor (pasarela) | A | A | M | Crítica | PCI-DSS; nunca almacenar PAN | James | James | Pasarela, backend |
| A-04 | Credenciales de administradores | Administración | Hashes de contraseña y secretos TOTP | Información | Cloud SQL + app 2FA | A | A | M | Crítica | Toma de control del CMS | Horacio | Horacio | 4 admins |
| A-05 | `wp-config.php` y sales | Operación | Credenciales de BD y claves de autenticación | Información | Secret Manager → pod | A | A | M | Crítica | Acceso total a la app | Josue | Josue | Nginx/PHP |
| A-06 | Código de plugins de terceros | Operación | WooCommerce, pagos, envíos, antispam | Software | Contenedor + repo | M | A | M | Alta | Superficie de RCE/SQLi | Horacio | Horacio | Equipo |
| A-07 | Tema y assets del storefront | Venta | Tema hijo propio (PHP/CSS/JS) | Software | Repositorio | M | A | M | Alta | XSS y defacement | Horacio | Horacio | Equipo |
| A-08 | Imagen del CMS | Despliegue | Imagen OCI PHP-FPM 8.3 + Nginx | Software | Artifact Registry | M | A | A | Alta | Suplantación del artefacto | Josue | Josue | CI, GKE |
| A-09 | Media y facturas | Venta | Imágenes de producto y PDFs en GCS | Información | Cloud (GCS) | M | A | M | Alta | Fuga de documentos y datos | Javier | Josue | App, admin |
| A-10 | Manifiestos K8s | Despliegue | Deployment, Ingress, NetworkPolicy, HPA | Configuración | Repositorio | M | A | A | Alta | Cambio de comportamiento del clúster | Josue | Josue | Equipo |
| A-11 | Terraform y estado | Despliegue | VPC, GKE, SQL, IAM, buckets | Configuración | Repositorio + GCS | M | A | A | Alta | Infraestructura reproducible | Josue | Josue | Equipo |
| A-12 | Pipeline CI/CD | Desarrollo | Workflows y credenciales WIF | Software/Servicios | GitHub Actions | A | A | A | Crítica | Compromiso = despliegue malicioso | Josue | Josue | Equipo |
| A-13 | Secretos de aplicación | Operación | Password BD, claves de auth, API sandbox | Información | Secret Manager | A | A | M | Crítica | Acceso total | Josue | Josue | Workload |
| A-14 | Claves CMEK | Cifrado | Claves de Cloud KMS | Información | Cloud KMS | A | A | A | Crítica | Pérdida de datos y servicio | James | James | Servicios |
| A-15 | Cuenta de servicio GKE | Identidad cloud | `sa-gke-workload` con Workload Identity | Información | GCP IAM | A | A | A | Crítica | Acceso a BD, GCS y secretos | Josue | Josue | Pods |
| A-16 | DNS y certificados | Exposición | Zona `ancordss.me.uk`, certs del borde | Configuración | Cloudflare | M | A | A | Crítica | Secuestro de tráfico | James | James | James |
| A-17 | Configuración Cloudflare | Borde | WAF, Access, rate limits, Logpush | Configuración | Cloudflare | A | A | A | Crítica | Debilitar el borde = exponer la tienda | James | James | James |
| A-18 | Logs y auditoría | Monitoreo | Ingress, app, Cloud SQL, WooCommerce, Cloudflare | Información | Cloud Logging + BigQuery | M | A | M | Alta | Detección y evidencia | Arun | Arun | Arun, James |
| A-19 | Backups de BD y media | Continuidad | Snapshots y exportaciones cifradas | Información | GCS | A | A | M | Crítica | Recuperación sin pérdida | Javier | Josue | James, Josue |
| A-20 | Panel administrativo | Administración | `admin-aurorashop...` + `wp-admin` | Servicios | Cloudflare Access → GKE | A | A | M | Crítica | Acceso privilegiado | James | Horacio | Admins |
| A-21 | Base de datos MySQL | Operación | Esquema WordPress/WooCommerce | Información | Cloud SQL | A | A | A | Crítica | Fuente de verdad del negocio | Josue | Josue | App |
| A-22 | Pasarela de pago sandbox | Cobro | Cuenta y claves API de prueba | Servicios | Proveedor | A | A | M | Crítica | Fraude y repudio | James | James | Backend |
| A-23 | Repositorio de código | Desarrollo | Código, IaC, docs | Información | GitHub | M | A | M | Alta | Inyección de código | James | James | Equipo |
| A-24 | Documentación de seguridad | Conocimiento | Este inventario, matrices, informe | Información | GitHub | M | M | B | Media | Reconocimiento si se filtra | James | James | Equipo |
| A-25 | Estaciones de trabajo | Desarrollo | Laptops con acceso a cloud y repo | Físico | Local | M | M | M | Alta | Punto de entrada a credenciales | Cada uno | Cada uno | Cada uno |
| A-26 | Cuentas demo y datos sintéticos | Pruebas | 4 cuentas y catálogo ficticio | Información | Cloud | B | M | B | Media | Ruido, no daño real | Javier | Javier | Equipo |

## Pendientes de verificación en la semana 2

- [ ] Confirmar que el bucket `aurorashop-media` no es público y que el pod no escribe directo (solo vía rol controlado).
- [ ] Confirmar que la API de GKE no tiene endpoint público.
- [ ] Agregar el proveedor de CDN/certificados como activo de disponibilidad.
- [ ] Agregar la cuenta de facturación y el dominio como activos de empresa.

## Nota de método

El inventario es de **diseño** en la semana 1 y se **verifica contra el clúster real** en la semana 2 (`kubectl get`, `terraform state list`, consola GCP). Toda diferencia se registra como hallazgo, no se corrige en silencio.
