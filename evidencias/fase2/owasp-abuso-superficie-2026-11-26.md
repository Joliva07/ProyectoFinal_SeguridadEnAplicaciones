# Evidencia: OWASP Top 10, casos de abuso y superficie (#47)

Fecha: 2026-11-26 · Responsable: Horacio · Producción: `aurorashop.ancordss.me.uk` · Local: misma imagen (`cms/docker/compose.yaml`)

Las pruebas de lógica (IDOR, precio, cupones, inyección) se hicieron **en local** con usuarios y pedidos de prueba, para no crear datos falsos en la base de producción. Las de perímetro se hicieron contra **producción** con peticiones de solo lectura.

## 1. Rutas sensibles en producción (A05, P-02..P-04)

```text
/                                         200
/xmlrpc.php                               403
/readme.html                              403
/license.txt                              403
/wp-config.php                            403
/wp-config.php.bak                        403
/.git/config                              403
/.env                                     403
/debug.log                                403
/wp-content/debug.log                     403
/wp-admin/install.php                     403
/wp-admin/setup-config.php                403
/?author=1                                404
/author/<usuario-admin>/                  404
/wp-json/wp/v2/users                      403
/?rest_route=/wp/v2/users                 401
/wp-json/wc/v3/orders                     401
/wp-json/wc/v3/customers                  401
/wp-json/wc/store/v1/products             200
/wp-json/                                 200
/wp-content/plugins/woocommerce/readme.txt  403
/wp-content/uploads/                      403
/wp-content/uploads/shell.php             403
/wp-content/plugins/woocommerce/woocommerce.php  403
/wp-sitemap-users-1.xml                   404
/wp-cron.php                              200
/wp-admin/                                302
/wp-login.php                             200
OPTIONS /                                 405
TRACE /                                   405
```

Cabeceras de `GET /`: `x-content-type-options: nosniff`, `x-frame-options: SAMEORIGIN`, `referrer-policy`, `permissions-policy`, `content-security-policy`, `x-request-id`. **Sin `strict-transport-security`** (P-08). Sin `<meta name="generator">`; los `?ver=` son tokens opacos.

Cookie de `wp-login.php`: `wordpress_test_cookie=…; path=/; secure; HttpOnly`.

## 2. TLS en el borde (A02, P-07)

```text
openssl s_client -tls1   -cipher DEFAULT@SECLEVEL=0  ->  New, TLSv1.0, Cipher is ECDHE-ECDSA-AES128-SHA
openssl s_client -tls1_2                             ->  New, TLSv1.2, Cipher is ECDHE-ECDSA-CHACHA20-POLY1305
openssl s_client -tls1_3                             ->  New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
```

## 3. Rate limit de login (A07, AC-02)

15 GET seguidos a `/wp-login.php`:

```text
200 200 429 429 429 429 429 429 429 429 429 429 429 429 429
```

Los 200 traen `x-request-id` (pasaron por Nginx); los 429 no, así que los corta Cloudflare antes de llegar al pod.

## 4. Origen, clúster y red (P-01, P-06, P-09..P-11)

```text
https directo a la IP del balanceador (34.8.x.x) con Host  -> 403   (Cloud Armor)
https directo a la IP sin Host                             -> 404   (backend por defecto)
https://admin-aurorashop.../wp-admin/                      -> 302 a https://aurorashop.../wp-login.php (sin Cloudflare Access)
https://staging-aurorashop.../                             -> 502

Cloud Armor aurorashop-demo-edge:
  100  deny(403)  sqli-v33-stable
  110  deny(403)  xss-v33-stable
  120  deny(403)  cve-canary
  1000-1002 allow  rangos IPv4/IPv6 de Cloudflare
  2147483647 deny(403)  *   "Deniega tráfico fuera de Cloudflare"

gcloud container clusters describe aurorashop-gke:
  privateClusterConfig.enablePrivateNodes: true
  privateClusterConfig.enablePrivateEndpoint: true
  ipEndpointsConfig.enablePublicEndpoint: false
  masterAuthorizedNetworksConfig.enabled: true
  dnsEndpointConfig.allowExternalTraffic: false

Firewall (red "default", sin VMs): default-allow-ssh 0.0.0.0/0 tcp:22, default-allow-rdp 0.0.0.0/0 tcp:3389
Firewall (aurorashop-vpc): k8s-fw-l7 solo 130.211.0.0/22 y 35.191.0.0/16 a tcp:8080

Cloud SQL aurorashop-demo-mysql: CMEK aurorashop-demo-sql, ipv4Enabled false, sslMode ENCRYPTED_ONLY
```

## 5. Pod y despliegue (A08)

```text
nginx:   .../wordpress-nginx@sha256:6dc69dce920e…
php-fpm: .../wordpress-php@sha256:2334fe78fe3b…
pod securityContext: runAsNonRoot, runAsUser 10001, seccomp RuntimeDefault
contenedor: allowPrivilegeEscalation false, capabilities drop ALL, readOnlyRootFilesystem true
automountServiceAccountToken: false
namespace: pod-security.kubernetes.io/enforce=restricted
workflows: todas las acciones fijadas por SHA, sin pull_request_target, permissions contents: read
```

Log de Nginx en Cloud Logging (A09), IP redactada:

```json
{"time":"2026-11-26T06:26:12+00:00","request_id":"57b679abf32303f899fe6936755fb748","remote_addr":"<redactada>","method":"GET","uri":"/wp-login.php","status":200,"bytes":7104,"duration":0.464,"host":"aurorashop.ancordss.me.uk"}
```

## 6. Pruebas de abuso en local (A01, A03, A04, AC-04, AC-06)

Usuarios `cliente-a` y `cliente-b`; pedido de A con dirección "Zona 10"; cupón `prueba10` (10 %, 1 uso). Script: peticiones HTTP con sesión real de cada cliente.

```text
setup  OK    login de cliente-a y cliente-b -> A=True B=True
A01-0  OK    dueno ve su pedido (control positivo) -> HTTP 200, direccion visible=True
A01-1  OK    cliente-b abre /my-account/view-order/<pedido de A>/ -> HTTP 200, direccion de A visible=False
A01-2  OK    cliente-b con la clave correcta del pedido de A -> HTTP 200, direccion de A visible=False
A01-3  OK    anonimo con clave falsa -> HTTP 200, visible=False
A01-4  OK    Store API pedido con clave falsa -> HTTP 403
A01-5  OK    cliente-b en REST wc/v3/orders/<id> (cookie sin nonce) -> HTTP 401
A01-6  OK    anonimo lista clientes en wc/v3 -> HTTP 401
A04-1  OK    agregar al carrito enviando precio manipulado (1.00) -> HTTP 201, total del servidor=32900 (precio real 329)
A04-2  OK    cantidad negativa -> HTTP 400 woocommerce_rest_product_invalid_quantity
A04-3  OK    aplicar el mismo cupon dos veces -> 1a HTTP 200, 2a HTTP 400 woocommerce_rest_cart_coupon_error
A04-4  OK    cupon inexistente -> HTTP 400 woocommerce_rest_cart_coupon_error
A04-5  OK    Store API sin nonce (CSRF) -> HTTP 401 woocommerce_rest_missing_nonce
A03-1  OK    XSS reflejado en busqueda -> HTTP 200, payload crudo en HTML=False
A03-2  OK    XSS reflejado en busqueda de productos -> HTTP 200, crudo=False
A03-3  OK    SQLi en Store API search: ' OR '1'='1 -> HTTP 200, error SQL o datos=False
A03-4  OK    SQLi en Store API search: 1' UNION SELECT user_login,u -> HTTP 200, error SQL o datos=False
A03-5  OK    SQLi en Store API search: 1 AND SLEEP(5) -> HTTP 200, error SQL o datos=False
A03-6  OK    SQLi en orderby -> HTTP 200
```

## 7. SSRF y subidas (A10, AC-05), dentro del contenedor PHP

```text
WP_HTTP_BLOCK_EXTERNAL=true  ACCESSIBLE_HOSTS=(ninguno)
http://169.254.169.254/computeMetadata/v1/  BLOQUEADO
http://metadata.google.internal/            BLOQUEADO
https://example.com/                        BLOQUEADO
http://127.0.0.1:9000/                      BLOQUEADO

Archivo con contenido "<?php system(...) ?>":
shell.php       rechazado
shell.php.jpg   rechazado
shell.phtml     rechazado
foto.jpg        rechazado   (se valida el contenido real, no solo la extensión)

Hash de contraseña de cliente: $wp$... (bcrypt de WordPress 6.8+)
```
