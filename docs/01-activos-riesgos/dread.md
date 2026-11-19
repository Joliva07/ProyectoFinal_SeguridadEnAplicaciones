# Clasificación de riesgos DREAD

Dueño: **Javier** · Insumo: `stride.md` · Salida: severidad inicial para `matriz-riesgos.md`

## 1. Escala (1–10 por dimensión)

| Dimensión | 1–3 | 4–6 | 7–10 |
|---|---|---|---|
| **D** Damage (daño) | Cosmético o interno | Pérdida de datos limitada | Pérdida financiera, legal o total |
| **R** Reproducibility (reproducibilidad) | Requiere condiciones raras | Repetible con esfuerzo | Siempre, con un clic |
| **E** Exploitability (explotabilidad) | Requiere cadena compleja | Herramienta pública + conocimiento | Script trivial / sin autenticación |
| **A** Affected users (usuarios afectados) | Un usuario | Un segmento | Todos los clientes |
| **D** Discoverability (descubribilidad) | Requiere acceso interno | Fuzzing o revisión guiada | Visible en la primera petición |

`DREAD = (D + R + E + A + D) / 5`, redondeado a un decimal.

| Rango | Severidad | Tratamiento esperado |
|---|---|---|
| 8.0–10 | Crítica | Mitigar antes de exponer; bloquea el release |
| 6.0–7.9 | Alta | Mitigar en el sprint; control compensatorio mientras |
| 4.0–5.9 | Media | Planificar; monitorear |
| 1.0–3.9 | Baja | Aceptar o documentar |

## 2. Puntuación de amenazas

| ID | Amenaza | D | R | E | A | D | DREAD | Severidad |
|---|---|---|---|---|---|---|---|---|
| T-15 | IDOR en `/accounts/{id}` | 9 | 10 | 9 | 10 | 10 | 9.6 | Crítica |
| T-23 | Transferencia con rol de solo lectura | 10 | 8 | 7 | 9 | 6 | 8.0 | Crítica |
| T-44 | Cuenta de servicio con permisos excesivos | 10 | 6 | 6 | 10 | 4 | 7.2 | Alta |
| T-50 | PR malicioso con `pull_request_target` | 10 | 7 | 6 | 10 | 5 | 7.6 | Alta |
| T-30 | Parcheo del APK / repackaging | 9 | 7 | 7 | 8 | 5 | 7.2 | Alta |
| T-27 | Agotamiento de conexiones de BD | 7 | 8 | 8 | 9 | 7 | 7.8 | Alta |
| T-12 | Algoritmo `none`/HS256 en JWT | 10 | 6 | 5 | 10 | 4 | 7.0 | Alta |
| T-36 | Stack traces en respuestas | 6 | 10 | 9 | 8 | 10 | 8.6 | Crítica |
| T-49 | Runner bloqueado / pipeline caído | 6 | 5 | 6 | 5 | 4 | 5.2 | Media |
| T-55 | Exceso de privilegios humano | 8 | 5 | 5 | 6 | 4 | 5.6 | Media |
| T-42 | Secreto en variable de entorno | 9 | 7 | 6 | 8 | 5 | 7.0 | Alta |
| T-04 | Tokens en logs | 9 | 6 | 5 | 8 | 4 | 6.4 | Alta |
| T-31 | Datos sin cifrar en el dispositivo | 8 | 7 | 6 | 7 | 5 | 6.6 | Alta |
| T-05 | Bloqueo de cuenta por intentos | 4 | 9 | 9 | 6 | 9 | 7.4 | Alta |
| T-37 | Flood HTTP contra el borde | 5 | 8 | 7 | 9 | 8 | 7.4 | Alta |
| T-01 | Suplantación con credenciales robadas | 9 | 6 | 5 | 8 | 4 | 6.4 | Alta |
| T-19 | Monto alterado en transferencia | 10 | 6 | 5 | 8 | 4 | 6.6 | Alta |
| T-54 | Capturas con datos reales | 8 | 8 | 9 | 8 | 8 | 8.2 | Crítica |

## 3. Cómo puntuar en equipo

1. Cada integrante puntúa en silencio (sin anclaje), se promedia y se discute solo la desviación > 2 puntos.
2. Toda puntuación ≥ 7 en Exploitability exige evidencia (herramienta, versión, comando) o se baja a 6.
3. El DREAD no sustituye a CVSS: cuando exista CVE o prueba de concepto, se registra CVSS 4.0 y se conserva DREAD para la priorización de negocio.

## 4. Re-puntuación

Tras la fase 4 se vuelve a puntuar con los hallazgos reales (`H-NN`) y se registra la variación. La tabla final se copia al informe (sección 2.4) y alimenta el heatmap residual.
