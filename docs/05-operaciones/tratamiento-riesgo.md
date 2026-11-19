# Tratamiento formal del riesgo

Dueño: **Arun** · Coautor: **Javier** · Componente de rúbrica 1 y 4

## 1. Criterios de decisión

| Decisión | Cuándo aplica | Requisito |
|---|---|---|
| **Mitigar** | Existe control razonable dentro del alcance | Control implementado y probado |
| **Evitar** | La actividad que genera el riesgo se elimina | Cambio de diseño documentado |
| **Transferir** | Otro puede asumirlo mejor (proveedor, seguro, SLA) | Contrato/SLA citado |
| **Aceptar** | Costo del control > impacto, o residual tolerable | Aprobación de James + fecha de revisión |
| **Eliminar** | El activo o función deja de existir | Registro de baja |

Riesgo residual aceptable para este proyecto: **≤ 9 (Medio)**. Todo residual ≥ 10 debe tener control compensatorio o justificación explícita del grupo.

## 2. Tabla de tratamiento por hallazgo

Se llena al cierre de la fase 4. Un hallazgo sin control asignado mantiene el riesgo abierto.

| Hallazgo | Riesgo | Descripción | Tipo | Impacto de negocio | Decisión | Control | Responsable | Plazo | Estado | Residual |
|---|---|---|---|---|---|---|---|---|---|---|
| H-01 | R-01 | IDOR en `/v1/accounts/{id}` | Software | Legal, reputacional | Mitigar | Autorización por objeto + test de regresión | Josue | 29-nov | pendiente | 4 |
| H-02 | R-07 | Sin rate limit en login | Seguridad | Operacional | Mitigar | Regla Cloudflare W-04 + Cloud Armor | James | 30-nov | pendiente | 6 |
| H-03 | R-14 | APK sin pinning | Software | Financiero | Mitigar | `CertificatePinner` + backup pin | Horacio | 29-nov | pendiente | 8 |
| H-04 | R-05 | Secreto en variable de entorno | Técnico | Operacional | Mitigar | Secret Manager + rotación | Josue | 28-nov | pendiente | 2 |
| H-05 | R-19 | Sin centralización de logs | Cloud | Legal | Mitigar | Sink a BigQuery + alertas | Arun | 5-dic | pendiente | 6 |
| H-06 | R-09 | Origen GCP accesible directo | Cloud | Operacional | Mitigar | Authenticated Origin Pull | James | 1-dic | pendiente | 4 |

## 3. Categorización

Cada riesgo se clasifica además por **tipo** (Software, Seguridad, Técnico, Cloud, Proceso, Personas) y por **impacto** (Reputacional, Operacional, Financiero, Legal). La matriz inicial ya trae ambas columnas; esta tabla las hereda y agrega la decisión.

| Tipo | N.º de riesgos | Decisión dominante |
|---|---|---|
| Software | 8 | Mitigar |
| Seguridad | 1 | Mitigar |
| Técnico | 3 | Mitigar |
| Cloud | 5 | Mitigar / Transferir |
| Proceso | 6 | Mitigar / Evitar |
| Personas | 2 | Mitigar |

## 4. Riesgos aceptados (con justificación)

| Riesgo | Motivo | Revisión |
|---|---|---|
| R-22 Un solo operador de Cloudflare | El acceso lo define el dueño de la zona; el SLA de 24 h lo hace operable | 9-dic |
| R-23 Dependencia del proveedor cloud | Se apoya en certificaciones y SLA de Google Cloud; no es mitigable en el curso | 9-dic |
| Cobertura parcial de Cloudflare Free | Reglas avanzadas requieren plan pago; se documentan como propuesta | 9-dic |

## 5. Verificación de cierre

Un control se considera cerrado cuando: (a) está implementado, (b) existe una prueba que demuestra que bloquea el ataque original, (c) el riesgo residual está recalculado y (d) otra persona revisó la evidencia. La tabla anterior se actualiza en el mismo commit que la evidencia.

## 6. Relación con el heatmap

Cada fila cerrada se refleja en `heatmap.md` moviendo el punto de la probabilidad/impacto inicial al residual. Si el residual no baja, el control no sirvió y se replantea.
