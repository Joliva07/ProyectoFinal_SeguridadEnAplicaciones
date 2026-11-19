# Tratamiento formal del riesgo

Dueño: **Arun** · Coautor: **Javier** · Componentes de rúbrica 1 y 4

## 1. Criterios de decisión

| Decisión | Cuándo | Requisito |
|---|---|---|
| **Mitigar** | Existe control razonable en el alcance | Implementado y probado |
| **Evitar** | La actividad que genera el riesgo se elimina | Cambio de diseño documentado |
| **Transferir** | Otro puede asumirlo mejor | Contrato/SLA citado |
| **Aceptar** | Costo del control > impacto, o residual tolerable | Aprobación de James + fecha de revisión |
| **Eliminar** | El activo o función deja de existir | Registro de baja |

Residual aceptable: **≤ 9 (Medio)**. Todo residual ≥ 10 exige control compensatorio o justificación del grupo.

## 2. Tratamiento por hallazgo

Se completa al cierre de la fase 4. Un hallazgo sin control mantiene el riesgo abierto.

| Hallazgo | Riesgo | Descripción | Tipo | Impacto | Decisión | Control | Responsable | Plazo | Estado | Residual |
|---|---|---|---|---|---|---|---|---|---|---|
| H-01 | R-01 | Plugin desactualizado con CVE de SQLi | Software | Legal, reputacional | Mitigar | Actualizar + WPScan en CI | Horacio | 27-nov | pendiente | 6 |
| H-02 | R-05 | Pedido ajeno por IDOR en REST | Software | Legal, reputacional | Mitigar | Comprobación de propiedad + test | Horacio | 28-nov | pendiente | 6 |
| H-03 | R-06 | Sin límite en `wp-login` | Seguridad | Operacional | Mitigar | W-02 + 2FA | James | 28-nov | pendiente | 4 |
| H-04 | R-08 | Upload permite extensión ejecutable | Software | Operacional | Mitigar | Validación + regla Nginx/WAF | Horacio | 29-nov | pendiente | 3 |
| H-05 | R-09 | `wp-config.php.bak` accesible | Técnico | Legal, financiero | Mitigar | Limpieza + W-04 | Josue | 27-nov | pendiente | 3 |
| H-06 | R-15 | CRS en modo log no bloquea SQLi | Cloud | Operacional | Mitigar | Pasar a block + probar | James | 1-dic | pendiente | 6 |
| H-07 | R-19 | Secreto en variable de entorno del pod | Técnico | Operacional | Mitigar | Secret Manager + CSI + rotar | Josue | 28-nov | pendiente | 3 |
| H-08 | R-20 | `wp-admin` accesible sin Access | Cloud | Financiero, legal | Mitigar | Access + regla W-09 | James | 1-dic | pendiente | 3 |

## 3. Categorización

| Tipo | N.º | Decisión dominante |
|---|---|---|
| Software | 8 | Mitigar |
| Seguridad | 2 | Mitigar |
| Técnico | 4 | Mitigar |
| Cloud | 6 | Mitigar / Transferir |
| Proceso | 6 | Mitigar / Evitar |
| Personas | 2 | Mitigar |

| Impacto de negocio | Riesgos |
|---|---|
| Reputacional | R-01, R-03, R-05, R-07, R-14, R-15, R-18, R-26 |
| Operacional | R-04, R-06, R-10, R-11, R-12, R-21, R-23, R-24, R-28 |
| Financiero | R-01, R-02, R-05, R-08, R-09, R-13, R-16, R-19, R-20, R-26 |
| Legal | R-01, R-02, R-05, R-09, R-14, R-20, R-21, R-22, R-25, R-27 |

## 4. Riesgos aceptados (justificación)

| Riesgo | Motivo | Revisión |
|---|---|---|
| R-25 Cumplimiento del proveedor | Se apoya en certificaciones y SLA de Google Cloud; no es mitigable en el curso | 9-dic |
| R-28 Un solo operador de Cloudflare | El acceso lo define el dueño de la zona; SLA de 24 h lo hace operable | 9-dic |
| Cobertura parcial de Cloudflare Free | Reglas avanzadas requieren plan pago; se documentan como propuesta | 9-dic |

## 5. Verificación de cierre

Un control se cierra cuando: (a) está implementado, (b) existe prueba de que bloquea el ataque original, (c) el residual está recalculado y (d) otra persona revisó la evidencia. La tabla se actualiza en el mismo commit que la evidencia.

## 6. Relación con el heatmap

Cada fila cerrada mueve su punto en `heatmap.md`. Si el residual no baja, el control no sirvió y se replantea.
