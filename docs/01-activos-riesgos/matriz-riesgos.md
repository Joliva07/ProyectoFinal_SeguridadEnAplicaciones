# Matriz de riesgos inicial

Dueños: **Javier** (inicial) → **Arun** (residual) · Capas: las 7 de seguridad en profundidad

## 1. Escalas

**Probabilidad (P):** 1 rara · 2 improbable · 3 posible · 4 probable · 5 casi segura.
**Impacto (I):** 1 insignificante · 2 menor · 3 moderado · 4 mayor · 5 catastrófico.
**Riesgo = P × I.** 1–4 Bajo · 5–9 Medio · 10–14 Alto · 15–25 Crítico.

Las 7 capas: **1** Datos · **2a** Código · **2b** Aplicación · **2c** Implementación · **2d** Perímetro de aplicación · **3** Host · **4** Red interna · **5** Perímetro cloud/red · **6** Seguridad física · **7** Políticas y personas.

## 2. Matriz

| ID | Riesgo | Capa | Tipo | Amenaza | Activos | P | I | Riesgo | Nivel | Impacto de negocio | Tratamiento |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R-01 | IDOR/BOLA en consulta de cuentas | 2b | Software | T-15 | A-03, A-04 | 4 | 5 | 20 | Crítico | Financiero, legal, reputacional | Mitigar |
| R-02 | Transferencia ejecutada sin autorización de rol | 2b | Software | T-23 | A-04 | 3 | 5 | 15 | Crítico | Financiero, legal | Mitigar |
| R-03 | Algoritmo JWT débil o firma no verificada | 2a | Software | T-12 | A-02 | 3 | 5 | 15 | Crítico | Financiero, reputacional | Mitigar |
| R-04 | Credenciales con hash rápido o sin sal | 1 | Software | T-01 | A-01 | 4 | 4 | 16 | Crítico | Legal, reputacional | Mitigar |
| R-05 | Secreto de BD expuesto en código o env | 2c | Software | T-42 | A-07 | 4 | 5 | 20 | Crítico | Operacional, financiero | Mitigar |
| R-06 | Stack traces y errores verbosos en API | 2d | Software | T-36 | A-16 | 5 | 2 | 10 | Alto | Reputacional | Mitigar |
| R-07 | Falta de rate limiting en login y API | 2d | Seguridad | T-05, T-37 | A-16, A-02 | 4 | 4 | 16 | Crítico | Operacional | Mitigar |
| R-08 | Ausencia de WAF / protección de borde | 5 | Cloud | T-37, T-34 | A-14, A-16 | 3 | 4 | 12 | Alto | Operacional, reputacional | Mitigar |
| R-09 | Origen de GCP accesible saltando Cloudflare | 5 | Cloud | T-33 | A-16 | 3 | 4 | 12 | Alto | Operacional | Mitigar |
| R-10 | Bucket o Storage público | 5 | Cloud | T-26 | A-15 | 2 | 5 | 10 | Alto | Legal, reputacional | Mitigar |
| R-11 | Puerto 22/3389 abierto a Internet | 4 | Técnico | T-28 | A-09 | 2 | 5 | 10 | Alto | Operacional | Mitigar |
| R-12 | Base de datos con IP pública o usuario admin para la app | 4 | Técnico | T-26, T-28 | A-03 | 3 | 5 | 15 | Crítico | Legal, financiero | Mitigar |
| R-13 | Contenedor/base image sin parches | 3 | Software | T-30 | A-05, A-16 | 4 | 3 | 12 | Alto | Operacional | Mitigar |
| R-14 | APK sin ofuscación ni detección de root; pinning ausente | 2a | Software | T-29, T-30, T-32 | A-05 | 4 | 4 | 16 | Crítico | Financiero, reputacional | Mitigar |
| R-15 | Tokens y datos sensibles sin cifrar en el dispositivo | 1 | Software | T-31 | A-02, A-05 | 3 | 4 | 12 | Alto | Legal, reputacional | Mitigar |
| R-16 | Ejecución de funciones administrativas por el canal de clientes | 2b | Software | T-06, T-55 | A-17 | 2 | 5 | 10 | Alto | Financiero, operacional | Mitigar |
| R-17 | Pipeline sin SAST/SCA ni control de secretos | 7 | Proceso | T-50 | A-11, A-12 | 4 | 4 | 16 | Crítico | Operacional | Mitigar |
| R-18 | Sin MFA ni control de sesiones en identidad | 2b | Software | T-01, T-07 | A-01, A-02 | 4 | 4 | 16 | Crítico | Financiero, legal | Mitigar |
| R-19 | Logs insuficientes / sin centralización (no detección) | 7 | Proceso | T-47, T-53 | A-13 | 5 | 3 | 15 | Crítico | Operacional, legal | Mitigar |
| R-20 | Sin auditoría de cambios críticos (repudio) | 1 | Proceso | T-20, T-25 | A-04, A-13 | 4 | 4 | 16 | Crítico | Legal | Mitigar |
| R-21 | IAM con privilegios excesivos (humanos y SA) | 4 | Cloud | T-44, T-55 | A-10 | 3 | 5 | 15 | Crítico | Operacional, financiero | Mitigar |
| R-22 | Dependencia de un solo operador de Cloudflare | 7 | Proceso | — | A-14 | 3 | 3 | 9 | Medio | Operacional | Aceptar (temporal) + documentar |
| R-23 | Proveedor cloud: dependencia de su cumplimiento (SOC 2 / ISO 27001) | 6 | Cloud | — | A-08, A-15 | 1 | 5 | 5 | Medio | Legal | Transferir (SLA del proveedor) |
| R-24 | Phishing a administradores del proyecto | 7 | Personas | T-51 | A-17, A-19 | 3 | 4 | 12 | Alto | Operacional, reputacional | Mitigar |
| R-25 | Datos reales en capturas o datos sintéticos mal etiquetados | 7 | Proceso | T-54 | A-18 | 3 | 4 | 12 | Alto | Legal | Evitar (regla del repo) |

## 3. Cobertura por capa

| Capa | Riesgos | ¿Cubierta? |
|---|---|---|
| 1 Datos | R-04, R-15, R-20 | sí |
| 2a Código | R-03, R-14 | sí |
| 2b Aplicación | R-01, R-02, R-16, R-18 | sí |
| 2c Implementación | R-05 | sí |
| 2d Perímetro de aplicación | R-06, R-07 | sí |
| 3 Host | R-13 | sí |
| 4 Red interna | R-11, R-12, R-21 | sí |
| 5 Perímetro cloud | R-08, R-09, R-10 | sí |
| 6 Física | R-23 | sí |
| 7 Políticas/personas | R-17, R-19, R-22, R-24, R-25 | sí |

## 4. Tratamiento (detalle en `docs/05-operaciones/tratamiento-riesgo.md`)

| Riesgo | Decisión | Control principal | Responsable | Residual esperado |
|---|---|---|---|---|
| R-01, R-02 | Mitigar | Autorización por recurso + tests de IDOR + WAF | Josue / Horacio | 4 (Bajo) |
| R-03 | Mitigar | Verificación de firma RS256, `aud`, `iss`, expiración, sin `none` | Josue | 2 |
| R-04 | Mitigar | Argon2id con parámetros OWASP | Javier / Josue | 4 |
| R-05 | Mitigar | Secret Manager + gitleaks en CI | Josue | 2 |
| R-07, R-08 | Mitigar | Rate limiting Cloudflare + Cloud Armor | James / Arun | 6 |
| R-09 | Mitigar | Restricción del LB a rangos de Cloudflare (mTLS/Authenticated Origin Pull) | James | 4 |
| R-11, R-12 | Mitigar | Terraform con `authorized_networks` cerrado y usuario app de mínimo privilegio | Josue | 4 |
| R-13 | Mitigar | Trivy + imágenes distroless + rebuild programado | Josue | 4 |
| R-14, R-15 | Mitigar | R8, pinning, Keystore, root detection | Horacio | 8 |
| R-17 | Mitigar | Pipeline con SAST/SCA/secretos/IaC | Josue | 6 |
| R-18 | Mitigar | Identity Platform + MFA + refresh rotation | Josue | 6 |
| R-19, R-20 | Mitigar | Logs de auditoría, sink a BigQuery, alertas | Arun | 6 |
| R-21 | Mitigar | Roles mínimos + WIF con condición de repo | James | 4 |
| R-22 | Aceptar | Documentar el riesgo y el SLA de cambios | James | 9 |
| R-23 | Transferir | SLA/ISO del proveedor, cláusulas contractuales | James | 5 |
| R-24 | Mitigar | MFA, Access en admin, capacitación breve | James | 6 |
| R-25 | Evitar | Regla en `SECURITY.md` + revisión cruzada | Todos | 2 |

## 5. Historial

| Fecha | Versión | Cambio | Autor |
|---|---|---|---|
| 2026-11-19 | v1 | Matriz inicial de 25 riesgos | Javier |
