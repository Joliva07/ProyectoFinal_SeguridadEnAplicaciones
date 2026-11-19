# app/ — Aplicación

| Ruta | Contenido | Responsable |
|---|---|---|
| `app/android/` | Cliente Android (Kotlin): OAuth2 + PKCE, biometría, Keystore, pinning, R8 | Horacio |
| `app/backend/accounts/` | Microservicio de cuentas (JWT, autorización por objeto) | Josue |
| `app/backend/transfers/` | Microservicio de transferencias (idempotencia, auditoría) | Josue |

Aún sin código: se construye en la fase 2 y se endurece en la fase 3.

Reglas mínimas para cualquier PR de código:

- Sin secretos, sin claves, sin `.env`.
- Validación de entrada en el borde del servicio y consultas parametrizadas.
- Autorización por objeto en cada endpoint que reciba un identificador.
- Logs estructurados sin PII; `request_id` en cada operación.
- Errores genéricos al cliente, detalle solo en el log.
- Código generado con asistencia de IA se revisa igual que el escrito a mano.
