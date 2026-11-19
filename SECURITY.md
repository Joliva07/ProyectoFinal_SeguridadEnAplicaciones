# Política de seguridad del proyecto

## Datos

- Solo datos sintéticos generados para la demo. Prohibido usar datos de clientes, compañeros o cualquier persona real.
- Los números de cuenta, identificadores y correos de las capturas se redactan antes de commitear.
- Las claves de firma del APK de demo se generan por integrante y nunca se suben.

## Reglas de enfrentamiento (pentesting)

Aplican a todo escaneo o prueba de explotación de las fases 4 y 5:

1. Objetivo permitido: únicamente los hosts del proyecto (`financiaweb.ancordss.me.uk`, `api.financiaweb.ancordss.me.uk`, `admin.financiaweb.ancordss.me.uk`), el proyecto GCP del curso y el APK construido por el equipo.
2. Ventana: anunciada en la issue de pentest y aprobada por James. Fuera de ventana, solo escaneos pasivos.
3. Prohibido: pruebas de denegación de servicio, fuerza bruta sin límite de tasa, explotación de terceros, persistencia, exfiltración real de datos, modificación de datos que no sean de la cuenta de prueba.
4. Límites de tasa: máximo 5 req/s en pruebas autenticadas; ZAP en modo `-l` (low) para escaneo activo.
5. Toda explotación exitosa se documenta y se detiene en el punto de prueba de concepto (sin escalar más de lo necesario para demostrar el impacto).
6. Credenciales de prueba: cuentas `demo-*` creadas por Javier; rotación después de la fase 4.

## Reporte de hallazgos

Cada hallazgo se registra como issue con la plantilla `hallazgo` y un ID (`H-NN`) que se usa en la matriz de riesgos, el plan de mitigación y el informe. Incluye: capa afectada (7 capas), STRIDE, DREAD, severidad CVSS 4.0, evidencia, control propuesto y responsable.

## Controles del propio repositorio

- Repo privado; acceso por invitación.
- `gitleaks` en CI bloquea secretos; `CODEOWNERS` no se usa para no frenar al equipo, pero la revisión cruzada es obligatoria.
- 2FA obligatorio en GitHub, GCP y Cloudflare.
- Cloudflare: tokens API con alcance mínimo, sin claves globales. Cambios solo por James.
- GCP: sin claves de cuenta de servicio en disco; CI usa Workload Identity Federation.

## Incidentes del proyecto

Si se detecta exposición accidental (clave, archivo, dato): avisar de inmediato en la issue `incidente`, rotar la credencial, purgar el historial con `git filter-repo` (solo James) y documentar en `docs/05-operaciones/tratamiento-riesgo.md`.
