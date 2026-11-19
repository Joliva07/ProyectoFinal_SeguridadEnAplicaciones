# Modelado de amenazas STRIDE

Dueño: **Javier** · Insumo: arquitectura de `docs/02-arquitectura/arquitectura-seguridad.md`

## 1. Método

1. Descomponer FinanciaWeb en componentes y flujos de datos (cliente móvil, Cloudflare, LB/API Gateway, identidad, servicios, base de datos, CI/CD, operación).
2. Aplicar las 6 categorías STRIDE a cada componente y a cada flujo entre componentes.
3. Convertir cada amenaza en un **caso de abuso** con pasos, precondición e impacto.
4. Asignar ID `T-NN`. Los que se materialicen en pruebas se enlazan con `H-NN` (hallazgo).

| Letra | Amenaza | Pregunta guía |
|---|---|---|
| S | Spoofing | ¿Puede alguien hacerse pasar por el cliente o por un servicio? |
| T | Tampering | ¿Puede modificar datos en tránsito, en reposo o el artefacto desplegado? |
| R | Repudiation | ¿Puede negar una operación por falta de evidencia? |
| I | Information disclosure | ¿Puede leer datos que no le corresponden? |
| D | Denial of service | ¿Puede agotar recursos del servicio o de una cuenta? |
| E | Elevation of privilege | ¿Puede obtener permisos que no tiene? |

## 2. Matriz por componente

| Componente / flujo | S | T | R | I | D | E |
|---|---|---|---|---|---|---|
| Login móvil (OAuth2/PKCE + biometría) | T-01 suplantación de cliente con credenciales robadas | T-02 manipulación de `redirect_uri` / code | T-03 login sin registro de autor | T-04 filtración de tokens en logs | T-05 bloqueo de cuenta por intentos | T-06 elevación a admin por claim falsificado |
| Token JWT / sesión | T-07 reutilización de refresh token | T-08 modificación de claims sin firma | T-09 acción sensible sin `sub` ni IP | T-10 exposición del token en el dispositivo | T-11 bombardeo de validaciones | T-12 `kid`/algoritmo débil (`none`, HS256) |
| API `accounts` | — | T-13 parámetros alterados (saldo, cuenta) | T-14 falta de traza de lectura | T-15 IDOR/BOLA: cuenta ajena | T-16 paginación masiva | T-17 acceso a otro cliente por `account_id` |
| API `transfers` | T-18 suplantación de origen | T-19 monto/beneficiario alterado | T-20 transferencia sin autor | T-21 enumeración de beneficiarios | T-22 repetición de operación (replay) | T-23 ejecutar transferencia con rol de solo lectura |
| Base de datos | — | T-24 SQLi / escritura no autorizada | T-25 sin auditoría de cambios | T-26 exfiltración masiva | T-27 agotamiento de conexiones | T-28 credenciales con privilegios de admin |
| Cliente móvil (APK) | T-29 repackaging / app falsa | T-30 parcheo del binario | — | T-31 datos en almacenamiento sin cifrar | — | T-32 root/hook para saltar controles |
| Cloudflare / borde | T-33 origen expuesto directamente | T-34 bypass de WAF por codificación | T-35 sin log de bloqueos | T-36 respuesta con stack traces | T-37 flood HTTP | T-38 regla mal configurada que abre admin |
| GCP (IAM, KMS, Secret Manager) | T-39 cuenta de servicio robada | T-40 cambio de política IAM | T-41 sin audit logs | T-42 secreto en variable de entorno | T-43 cuota agotada | T-44 SA con `roles/editor` |
| CI/CD (GitHub Actions) | T-45 commit con identidad ajena | T-46 modificación del workflow | T-47 deploy sin aprobación | T-48 secretos en logs | T-49 runner bloqueado | T-50 PR malicioso con `pull_request_target` |
| Operación / personas | T-51 phishing a administrador | T-52 cambio directo en consola | T-53 ausencia de bitácora | T-54 capturas con datos reales | — | T-55 exceso de privilegios humano |

## 3. Casos de abuso prioritarios

Se documentan completos en `docs/04-ciberdefensa/casos-abuso.md`. Los cuatro de mayor DREAD inicial:

| ID | Caso de abuso | STRIDE | Componente | Actor |
|---|---|---|---|---|
| T-15 | Cliente A solicita `/accounts/{id}` de cliente B variando el ID | I / E | API `accounts` | Usuario autenticado |
| T-23 | Usuario de solo lectura ejecuta `POST /transfers` con token manipulado | E | API `transfers` | Usuario con rol bajo |
| T-50 | PR desde fork modifica el workflow y exfiltra secretos | T / I | CI/CD | Colaborador o cuenta comprometida |
| T-44 | Cuenta de servicio con permisos excesivos permite leer toda la BD | E / I | GCP IAM | Atacante con acceso al runner |

## 4. Trazabilidad

Cada fila debe terminar en: riesgo `R-NN`, control propuesto, y (si se probó) hallazgo `H-NN`. La tabla de cierre se mantiene al final del archivo con el formato:

| T-NN | R-NN | Control | H-NN | Estado |
|---|---|---|---|---|
| T-15 | R-03 | Autorización por recurso + pruebas automatizadas de IDOR | H-02 | mitigado |
