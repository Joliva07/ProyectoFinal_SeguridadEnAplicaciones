# Casos de abuso

Dueño: **Horacio** · Insumo: `docs/01-activos-riesgos/stride.md`

## 1. Formato de cada caso

```
AC-NN · <título>
Actor: <externo | autenticado | con rol bajo | insider | cadena de suministro>
Precondición: <qué necesita saber o tener>
Objetivo: <activo A-NN>
Pasos: 1..n
Impacto: <confidencialidad/integridad/disponibilidad + negocio>
Detección esperada: <log, alerta, regla WAF>
Control: <preventivo> / <detectivo>
Evidencia: <H-NN o captura>
```

## 2. Casos obligatorios

### AC-01 · Enumeración y exfiltración por paginación (API4/API6)
- **Actor:** cliente autenticado con cuenta demo.
- **Precondición:** token válido; endpoint de movimientos.
- **Pasos:** 1) consultar `/v1/accounts/{id}/movements?limit=50&offset=0`; 2) automatizar incremento de `offset`; 3) variar `account_id` con IDs predecibles.
- **Impacto:** exfiltración masiva de historial; incumplimiento de secreto bancario.
- **Detección:** tasa anómala por `sub`, 200s masivos, correlación en BigQuery.
- **Control:** tope de `limit`, IDs opacos (UUID), autorización por objeto, rate limit, alerta.

### AC-02 · Fuerza bruta y credential stuffing en login
- **Actor:** externo.
- **Pasos:** 1) lista de usuarios filtrada; 2) 5 req/s contra `/auth/login`; 3) observar códigos y tiempos.
- **Impacto:** toma de cuentas.
- **Detección:** 429 por Cloudflare, alerta de fallos por IP/ASN.
- **Control:** rate limit, MFA, bloqueo progresivo, Turnstile en web.

### AC-03 · Bypass de MFA por flujo incompleto
- **Actor:** atacante con contraseña válida.
- **Pasos:** 1) completar paso 1; 2) reutilizar el token parcial contra endpoints de negocio; 3) intentar `scope` elevado.
- **Impacto:** acceso sin segundo factor.
- **Detección:** token con `amr=password` usado en endpoints que exigen MFA.
- **Control:** scopes separados + verificación de `acr`/`amr` en el servicio.

### AC-04 · Transferencia fraudulenta con IDOR/BOLA
- **Actor:** cliente autenticado.
- **Pasos:** 1) obtener `account_id` ajeno (IDOR); 2) `POST /v1/transfers` con origen ajeno; 3) monto mínimo para no disparar límites.
- **Impacto:** pérdida financiera directa.
- **Detección:** origen ≠ `sub`, alerta de transferencia con cuenta no vinculada.
- **Control:** autorización por recurso + auditoría + límites.

### AC-05 · Robo de sesión desde el dispositivo
- **Actor:** malware local / dispositivo rooteado.
- **Pasos:** 1) leer almacenamiento de la app; 2) extraer refresh token; 3) usarlo desde otra IP.
- **Impacto:** suplantación persistente.
- **Detección:** refresh desde IP/dispositivo distinto; binding de dispositivo.
- **Control:** Keystore, rotación de refresh, detección de root, revocación por anomalía.

### AC-06 · Repackaging del APK
- **Actor:** externo.
- **Pasos:** 1) descargar APK; 2) decompilar, insertar override de host; 3) firmar y distribuir.
- **Impacto:** troyano bancario, fraude a clientes.
- **Detección:** Play Integrity / firma verificada en backend.
- **Control:** ofuscación, verificación de firma, pinning, detección de tampering.

### AC-07 · PR malicioso en el pipeline
- **Actor:** colaborador o cuenta comprometida.
- **Pasos:** 1) abrir PR que modifica workflow; 2) exfiltrar secretos vía `pull_request_target`; 3) desplegar imagen alterada.
- **Impacto:** compromiso total de la cadena de suministro.
- **Detección:** revisión obligatoria de `.github/`, diff de workflows, alerta de cambio de workflow.
- **Control:** permisos mínimos, sin `pull_request_target`, WIF con condición de repo/rama, branch protection.

### AC-08 · Abuso de función legítima de exportación
- **Actor:** insider con rol de operador.
- **Pasos:** 1) exportar estados de cuenta de 200 clientes; 2) descargar sin justificación.
- **Impacto:** fuga interna; repudio.
- **Detección:** regla de volumen por usuario (UEBA), log de exportación con autor.
- **Control:** límite de exportación, aprobación de segundo usuario, auditoría.

## 3. Tabla resumen para el informe

| ID | Caso | Actor | STRIDE | Activo | DREAD | Control | Detectado |
|---|---|---|---|---|---|---|---|
| AC-01 | Paginación abusiva | autenticado | I | A-04 | 7.8 | rate limit + tope | pendiente |
| AC-02 | Fuerza bruta | externo | S | A-01 | 7.4 | 429 + MFA | pendiente |
| AC-03 | Bypass MFA | externo | E | A-02 | 7.6 | scopes/amr | pendiente |
| AC-04 | Transferencia IDOR | autenticado | E | A-04 | 9.6 | authz objeto | pendiente |
| AC-05 | Robo de sesión | local | I | A-02 | 6.6 | Keystore + binding | pendiente |
| AC-06 | Repackaging | externo | S/T | A-05 | 7.2 | firma + pinning | pendiente |
| AC-07 | PR malicioso | insider | T/I | A-12 | 7.6 | WIF + permisos | pendiente |
| AC-08 | Exportación masiva | insider | R/I | A-03 | 6.0 | UEBA + límite | pendiente |
