# Cómo trabajar en este repositorio

## Flujo

1. Toma una issue asignada a tu etiqueta (`owner/javier`, `owner/josue`, `owner/horacio`, `owner/arun`, `owner/james`).
2. Crea rama: `fase<N>/<apellido>-<tema>` — ej. `fase1/javier-inventario-activos`.
3. Trabaja **solo en los archivos que te pertenecen** (tabla de propiedad en `docs/00-plan/reparto-trabajo.md`). Si necesitas tocar un archivo compartido, avisa en la issue.
4. PR a `main` con el título `[Fase N] tema` y enlace a la issue (`Closes #N`).
5. Revisión cruzada: la aprueba alguien distinto del autor. Para documentos del informe, el revisor es James.
6. Merge con squash. La issue se cierra sola.

## Convención de commits

`tipo(alcance): descripción` — `docs(fase1): inventario de activos ISO 27001`, `infra(fase5): reglas de seguridad en Terraform`, `ci(fase3): Semgrep en pull_request`, `fix(cms): verificación de propiedad del pedido`.

Tipos: `docs`, `ci`, `infra`, `app`, `fix`, `chore`.

## Evidencias

- Guardar en `evidencias/<fase>/<herramienta>-<AAAA-MM-DD>/`.
- Nunca subir binarios pesados ni capturas con datos personales. Redactar correos, tokens y números de cuenta.
- Cada evidencia debe ser reproducible: comando ejecutado, versión de la herramienta, fecha y salida.
- Formato de nombre: `fase3-sca-dependency-check-2026-11-26.txt`.

## Estilo de documentación

- Español técnico, sin emojis, con tablas para datos comparables.
- Toda tabla de hallazgos usa IDs estables (`H-01`, `R-07`, `A-12`) que se conservan entre documentos.
- Cada afirmación técnica va con su fuente o su evidencia en `evidencias/`.
- El informe final se redacta aparte, en formato UMG (Arial 12, 1.5, APA 7). Ver `docs/06-informe/formato-apa.md`.

## Prohibiciones

- Credenciales, claves privadas, `terraform.tfstate`, `.env`, claves de la pasarela de pago o `wp-config.php` reales.
- `git push --force` a `main`.
- Cambios en Cloudflare por alguien que no sea James (solicitar con issue + etiqueta `cloudflare`).
- Escaneos contra dominios de terceros o contra `ancordss.me.uk` fuera del host del proyecto.
