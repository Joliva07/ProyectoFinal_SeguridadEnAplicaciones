# Clasificación CIA y criticidad

Dueño: **Javier** · Alimenta: `inventario-activos.md`, `dread.md`, `matriz-riesgos.md`

## 1. Escala

| Nivel | Confidencialidad | Integridad | Disponibilidad |
|---|---|---|---|
| **A** (alta) | Exposición causa daño legal, financiero o reputacional grave; dato secreto bancario o credencial | Alteración produce fraude o decisión errónea irreversible | Caída detiene la operación del negocio o el proceso crítico |
| **M** (media) | Exposición causa daño limitado o requiere contexto para ser útil | Alteración detectable y reversible | Degradación tolerable por horas |
| **B** (baja) | Dato público o sintético | Sin efecto material | Sin efecto material |

## 2. Cálculo de criticidad

Criticidad = mayor de las tres dimensiones, elevada un nivel si el activo es **accesible desde Internet** o si es **único** (sin repuesto). Se documenta la regla aplicada, no solo el resultado.

```
crudo = max(C, I, A)                      # A=3, M=2, B=1
ajuste = +1 si expuesto a Internet o sin redundancia
criticidad = min(3, crudo + ajuste)       # 3=Crítica, 2=Alta/Media...
```

Mapeo final: 3 → **Crítica**, 2 → **Alta**, 1.5 → **Media**, 1 → **Baja**.

## 3. Tabla

| Activo | C | I | A | Expuesto | Único | Puntaje | Criticidad | Justificación |
|---|---|---|---|---|---|---|---|---|
| A-01 Credenciales | A | A | M | No | No | 3 | Crítica | Secreto bancario + acceso a cuentas |
| A-02 Tokens | A | A | M | Vía API | No | 3 | Crítica | Suplantación directa |
| A-03 Cuentas y saldos | A | A | M | Vía API | No | 3 | Crítica | Secreto bancario |
| A-04 Movimientos | A | A | M | Vía API | No | 3 | Crítica | Integridad transaccional |
| A-05 APK | M | A | M | Sí (descarga) | Sí | 3 | Crítica | Único canal de distribución |
| A-06 Keystore | M | A | B | No | Sí | 3 | Crítica | Suplantación de app |
| A-07 Secretos backend | A | A | M | No | No | 3 | Crítica | Acceso total |
| A-08 Claves KMS | A | A | A | No | Sí | 3 | Crítica | Pérdida de datos y servicio |
| A-09 Red | M | A | A | No | No | 2 | Alta | Apertura = exposición |
| A-10 IAM | A | A | A | No | No | 3 | Crítica | Escalada total |
| A-11 Repo | M | A | M | Sí (privado) | No | 2.5 | Alta | Inyección de código |
| A-12 Pipeline | A | A | A | Sí (webhook) | Sí | 3 | Crítica | Despliegue malicioso |
| A-13 Logs | M | A | M | No | No | 2 | Alta | Evidencia forense |
| A-14 DNS/TLS | M | A | A | Sí | Sí | 3 | Crítica | Secuestro de tráfico |
| A-15 Backups | A | A | M | No | No | 3 | Crítica | Recuperación |
| A-16 API pública | M | A | A | Sí | No | 3 | Crítica | Superficie principal |
| A-17 Admin | A | A | M | Sí (+Access) | No | 3 | Crítica | Acceso privilegiado |
| A-18 Documentación | M | M | B | Sí (repo público) | No | 2 | Alta | Reconocimiento del atacante |
| A-19 Laptops | M | M | M | Sí | No | 2.5 | Alta | Credenciales en reposo |
| A-20 Demo | B | M | B | Sí | No | 1.5 | Media | Datos falsos |

## 4. Consecuencias para el diseño

Los 13 activos críticos justifican: MFA en identidad, CMEK, Secret Manager sin secretos en código, WAF en el borde, Access en admin, branch protection + WIF en CI, y Logpush retenido fuera del proyecto. Cualquier control que no proteja un activo crítico debe justificarse igual.

## 5. Regla de revisión

La clasificación se revisa cuando: (a) cambia el despliegue, (b) aparece un hallazgo que demuestra exposición inesperada, (c) se agrega un activo expuesto a Internet. Cada revisión se registra con fecha en el historial de cambios al final del archivo.
