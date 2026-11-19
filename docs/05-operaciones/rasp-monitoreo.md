# RASP y monitoreo de APIs en tiempo de ejecución

Dueño: **Arun** · Componente de rúbrica 4

## 1. Alcance

Detección de comportamiento anómalo en la API y en el cliente, no solo bloqueo perimetral. Cubre: autenticación anómala, acceso a objetos ajenos, abuso de paginación, cambios de patrón de consumo y señales del APK.

## 2. Señales y reglas

| ID | Señal | Fuente | Umbral | Acción |
|---|---|---|---|---|
| RT-01 | Fallos de login por `sub`/IP | Identity Platform + Logging | > 10 en 5 min | alerta + bloqueo temporal |
| RT-02 | Uso de token con `amr=password` en endpoint que exige MFA | logs del servicio | 1 evento | alerta crítica |
| RT-03 | Peticiones 403 por objeto ajeno | logs API | > 5 en 10 min por `sub` | alerta + revisión |
| RT-04 | `offset` creciente sistemático | logs API | > 100 páginas/hora | alerta + rate limit |
| RT-05 | Transferencias con monto atípico | logs de negocio | 3σ sobre el histórico del usuario | alerta |
| RT-06 | Cambio de IP/dispositivo en refresh | Identity + claim `device_id` | 1 evento | revocación de sesión |
| RT-07 | Errores 5xx en aumento | Cloud Run metrics | > 5% en 5 min | alerta |
| RT-08 | Latencia p95 anómala | Cloud Run metrics | > 2× baseline | alerta (posible ataque) |
| RT-09 | Ejecuciones de la app en emulador/root | señal del cliente | 1 sesión | marcar riesgo, step-up auth |
| RT-10 | Volumen de exportaciones por usuario | logs admin | > 2/hora | bloqueo + revisión |

## 3. Implementación

- **Cloud Run + Cloud Logging:** logs estructurados con `request_id`, `sub`, `route`, `status`, `latency_ms`, `account_id_hash`. Sin PII.
- **Log-based metrics** para RT-01..RT-10 y alert policies de Cloud Monitoring con notificación por correo del grupo.
- **Cloud Armor:** reglas de tasa por backend y `deny` por reputación/geo cuando aplique.
- **Cloudflare Analytics:** tasa de bloqueos, países, ASN, bots.
- **Cliente móvil:** Play Integrity (o verificación de firma) reportada al backend; si falla, la sesión se marca y se exige MFA de nuevo.
- **RASP:** en el alcance de este proyecto se implementa como verificación de integridad y detección de entorno (root/emulador/hook) más validación del lado servidor; se declara que un RASP comercial (p. ej. inyección de código ofuscado) queda fuera de alcance.

## 4. Tabla de efectividad

| Regla | Prueba controlada | Resultado esperado | Evidencia |
|---|---|---|---|
| RT-01 | 15 logins fallidos | alerta en < 2 min | captura de alerta |
| RT-03 | 6 intentos de IDOR | alerta + bloqueo | log + alerta |
| RT-04 | script de paginación | alerta + 429 | log |
| RT-06 | refresh desde otra IP | sesión revocada | log de revocación |
| RT-09 | APK en emulador root | step-up auth | captura de pantalla |

## 5. Límites y riesgos

- Sin UEBA real (no hay volumen histórico): los umbrales son de laboratorio y se declaran como tales.
- Alertas ruidosas: se calibra una semana en modo `log` antes de activar notificaciones.
- El RASP no sustituye controles del servidor: toda decisión de seguridad se revalida en el backend.
