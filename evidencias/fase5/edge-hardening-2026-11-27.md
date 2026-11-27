# Endurecimiento del borde — 2026-11-27

Responsable: **James** · Zona `ancordss.me.uk` (plan Free) · Cuenta Cloudflare del operador de la zona

Objetivo: cerrar los hallazgos de perímetro de los que James es responsable (P-07, P-08, P-09/H-08, P-10) y dejar constancia verificable con `curl` y `dig`. No se modificaron registros de otros subdominios ni el origen GKE.

## 1. Cambios aplicados

| Control | Antes | Ahora | Evidencia |
|---|---|---|---|
| Minimum TLS Version | `TLS 1.0 (default)` | `TLS 1.2` | `PATCH /zones/…/settings/min_tls_version → 200`; handshakes TLS 1.0/1.1 fallan |
| HSTS | Ausente | `max-age=31536000`, sin `includeSubDomains`, sin preload | `PATCH /zones/…/settings/security_header → 200`; cabecera presente en demo y admin |
| DNS `staging-aurorashop` | A `136.68.90.143` proxied, respondía 502 | Registro eliminado | `DELETE /zones/…/dns_records/… → 200`; `dig` vacío |
| Cloudflare Access `admin-aurorashop` | 0 aplicaciones; respondía 200 | Aplicación self-hosted con política Allow | `POST /accounts/…/access/apps → 201`; 302 a `alzentis.cloudflareaccess.com` |
| Bot Fight Mode | Off | On | `PUT /zones/…/bot_management → 200` |

HSTS se configuró **sin** `includeSubDomains` por decisión del operador: la zona aloja otros subdominios ajenos al proyecto y no se quiso imponer HSTS a todos.

## 2. Política de Access

| Campo | Valor |
|---|---|
| Aplicación | `admin-aurorashop` (self-hosted, public DNS) |
| Destino | `admin-aurorashop.ancordss.me.uk` |
| Política | `Equipo AuroraShop - Allow`, acción Allow |
| Regla | Emails: `maradiaga.l.james@gmail.com`, `hmaradiagal@miumg.edu.gt` (OR) |
| Sesión | 8 horas |
| Proveedor de identidad | el disponible en la organización (`alzentis.cloudflareaccess.com`) |

Pendiente: agregar los correos de Horacio, Josue, Javier y Arun a la misma política cuando se confirmen; hoy solo el operador puede entrar a `wp-admin`.

## 3. Verificación (2026-11-27, 15:5x GMT-6)

```text
$ curl --tlsv1.0 --tls-max 1.0 -sI https://aurorashop.ancordss.me.uk/
exit=35                     # SSL connect error: el borde ya no negocia TLS 1.0

$ curl --tlsv1.1 --tls-max 1.1 -sI https://aurorashop.ancordss.me.uk/
exit=35

$ curl --tlsv1.2 --tls-max 1.2 -sI https://aurorashop.ancordss.me.uk/
HTTP/2 200

$ curl -sI https://aurorashop.ancordss.me.uk/ | grep -i strict-transport-security
strict-transport-security: max-age=31536000

$ dig +short staging-aurorashop.ancordss.me.uk
                            # sin respuesta

$ curl -sI https://staging-aurorashop.ancordss.me.uk/
exit=6                      # no resuelve

$ curl -sI https://admin-aurorashop.ancordss.me.uk/
HTTP/2 302
location: https://alzentis.cloudflareaccess.com/cdn-cgi/access/login/admin-aurorashop.ancordss.me.uk?…
```

## 4. Lo que no se cierra

- **H-12 (scraping).** Bot Fight Mode quedó activo, pero 10 GET seguidos a `/shop/` con User-Agent de bot y con `python-requests` devolvieron 200. El control no se pudo demostrar; H-12 sigue abierto. La cuota de rate limiting del plan Free sigue ocupada por el login.
- **P-13 (branch protection).** La cuenta que opera el repo no es admin; no se puede activar sin el dueño.
- **P-11/S-06 (red `default` de GCP).** Fuera del borde; responsable Josue.
- **Access en `staging`.** No se creó porque el registro DNS se eliminó mientras no exista réplica sana.

## 5. Conclusión

P-07, P-08, P-09 y P-10 quedan cerrados con prueba reproducible. H-08 se cierra por la vía de Access en `admin`. El sistema no acepta TLS anterior a 1.2, envía HSTS, no publica el host de staging y exige identidad de Access antes de llegar a WordPress en el panel.
