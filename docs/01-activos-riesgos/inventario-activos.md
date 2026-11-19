# Inventario de activos (ISO/IEC 27001:2022, A.5.9)

Dueño: **Javier** · Revisión: James · Estado: plantilla

## Cómo llenar

- Un activo por fila. ID estable `A-NN` que no cambia entre versiones.
- **Valoración CIA**: A (alta), M (media), B (baja) por cada dimensión. La criticidad se calcula, no se estima: ver `clasificacion-cia.md`.
- **Tipo**: Información · Software · Físico · Personal · Servicios · Empresa (Hardware/Infraestructura).
- **Ubicación**: Local · Cloud · Dispositivo móvil · Repositorio · Proveedor.
- Cada activo necesita propietario (quien decide), custodio (quien lo opera) y usuarios con acceso.

Meta: 30–40 activos que cubran cliente móvil, backend, datos, identidad, borde, CI/CD, nube y personas.

## Inventario

| ID | Activo | Proceso asociado | Descripción | Tipo | Ubicación | C | I | A | Criticidad | Justificación | Propietario | Custodio | Usuarios con acceso |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A-01 | Credenciales de clientes (hash) | Autenticación | Contraseñas derivadas con Argon2id y sal | Información | Cloud (Cloud SQL) | A | A | M | Crítica | Compromiso = toma de cuentas y fraude | Javier | Josue | Backend `accounts` |
| A-02 | Tokens de sesión / refresh | Autenticación | JWT firmados y refresh tokens | Información | Cloud + móvil | A | A | M | Crítica | Reutilización = suplantación | Josue | Josue | Identity Platform, `accounts` |
| A-03 | Datos de cuentas y saldos | Operación bancaria | Números de cuenta, saldos, titular | Información | Cloud (Cloud SQL) | A | A | M | Crítica | Secreto bancario | Javier | Josue | `accounts`, `transfers`, admin |
| A-04 | Movimientos / transferencias | Operación bancaria | Historial transaccional | Información | Cloud (Cloud SQL) | A | A | M | Crítica | Integridad = fraude | Javier | Josue | `transfers`, admin |
| A-05 | APK de producción | Distribución | Binario firmado para clientes | Software | Repositorio + artifact | M | A | M | Alta | Alteración = troyano bancario | Horacio | Horacio | CI, testers |
| A-06 | Keystore de firma | Distribución | Clave de firma del APK | Información | Gestor de secretos | M | A | B | Crítica | Suplantación de la app | Horacio | Horacio | Horacio, James |
| A-07 | Secretos de backend | Operación | Password de BD, claves JWT, API keys | Información | Secret Manager | A | A | M | Crítica | Acceso total al backend | Josue | Josue | `sa-deployer`, servicios |
| A-08 | Claves CMEK | Cifrado | Claves de Cloud KMS por servicio | Información | Cloud KMS | A | A | A | Crítica | Pérdida = indisponibilidad + exposición | James | James | Servicios autorizados |
| A-09 | Configuración de red (VPC, SG) | Conectividad | Subredes, firewall rules, conector | Configuración | Cloud (Terraform) | M | A | A | Alta | Apertura = exposición | Josue | Josue | James, Josue |
| A-10 | Roles y cuentas IAM | Identidad cloud | Identidades humanas y de servicio | Información | Cloud IAM | A | A | A | Crítica | Escalada de privilegios | James | James | Todos (lectura) |
| A-11 | Repositorio de código | Desarrollo | Código móvil, backend, IaC | Información | GitHub | M | A | M | Alta | Inyección de código malicioso | James | James | Todo el equipo |
| A-12 | Pipeline CI/CD | Desarrollo | Workflows y credenciales WIF | Software | GitHub Actions | A | A | A | Crítica | Compromiso = despliegue malicioso | Josue | Josue | Todo el equipo |
| A-13 | Logs de aplicación y auditoría | Monitoreo | Access logs, auth logs, Cloudflare Logpush | Información | Cloud (Logging/BigQuery) | M | A | M | Alta | Evidencia y detección | Arun | Arun | Arun, James |
| A-14 | Registro DNS y certificados | Exposición | Zona `ancordss.me.uk`, certs del borde | Configuración | Cloudflare | M | A | A | Crítica | Secuestro de tráfico | James | James | James |
| A-15 | Backups de base de datos | Continuidad | Snapshots cifrados | Información | Cloud Storage | A | A | M | Alta | Pérdida sin recuperación | Javier | Josue | James, Josue |
| A-16 | Endpoint público de API | Servicio expuesto | `api.financiaweb.ancordss.me.uk` | Servicios | Cloudflare → GCP | M | A | A | Alta | Superficie principal de ataque | Josue | James | Público autenticado |
| A-17 | Consola administrativa | Servicio | `admin.financiaweb...` | Servicios | Cloudflare Access → GCP | A | A | M | Crítica | Acceso privilegiado | James | James | Admin del grupo |
| A-18 | Documentación de seguridad | Conocimiento | Inventario, matrices, informe | Información | GitHub | M | M | B | Media | Ayuda al atacante si es pública | James | James | Equipo |
| A-19 | Estaciones de trabajo | Desarrollo | Laptops del equipo con acceso a cloud | Físico | Local | M | M | M | Alta | Punto de entrada a credenciales | Cada uno | Cada uno | Cada uno |
| A-20 | Cuentas de prueba demo | Operación | Usuarios sintéticos | Información | Cloud | B | M | B | Baja | Impacto limitado por datos falsos | Javier | Javier | Equipo |
| A-21 | … | | | | | | | | | | | | |

## Pendientes por cubrir

- [ ] Servicio de identidad (Identity Platform) como activo propio.
- [ ] Artefact Registry y buckets de artefactos.
- [ ] WAF/Cloudflare como servicio crítico de disponibilidad.
- [ ] Proveedor cloud y su cadena de suministro (seguridad física).
- [ ] Personas con privilegios (administradores del grupo).
- [ ] Servidores de correo/notificación si se simulan.

## Nota de método

El inventario es de **diseño** en la semana 1 y se **verifica contra el sistema real** en la semana 2 (cuando Terraform ya define recursos). Toda diferencia entre lo documentado y lo desplegado se registra como hallazgo, no se corrige en silencio.
