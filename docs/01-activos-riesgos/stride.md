# Modelado de amenazas STRIDE

Dueño: **Javier** · Insumo: `docs/02-arquitectura/arquitectura-seguridad.md`

## 1. Método

1. Descomponer AuroraShop en componentes y flujos: navegador, Cloudflare, Ingress/LB, pods Nginx/PHP-FPM, núcleo WordPress, plugins/tema, WooCommerce (checkout y REST), MySQL, GCS, GKE, CI/CD, administración.
2. Aplicar las 6 categorías STRIDE a cada componente y a cada flujo.
3. Convertir cada amenaza en caso de abuso con pasos, precondición e impacto (detalle en `docs/04-ciberdefensa/casos-abuso.md`).
4. Asignar `T-NN`; los que se prueben se enlazan con `H-NN`.

| Letra | Amenaza | Pregunta guía |
|---|---|---|
| S | Spoofing | ¿Puede alguien hacerse pasar por cliente, admin o pasarela? |
| T | Tampering | ¿Puede modificar precios, pedidos, archivos o el artefacto desplegado? |
| R | Repudiation | ¿Puede negar una compra, un reembolso o un cambio? |
| I | Information disclosure | ¿Puede leer pedidos, clientes o configuración ajena? |
| D | Denial of service | ¿Puede tumbar la tienda o agotar recursos? |
| E | Elevation of privilege | ¿Puede obtener capacidades de admin o del clúster? |

## 2. Matriz por componente

| Componente / flujo | S | T | R | I | D | E |
|---|---|---|---|---|---|---|
| Login y cuentas | T-01 fuerza bruta | T-04 sesión sin expiración | T-26 sin log de acceso | T-06 enumeración de usuarios | T-05 XML-RPC amplificado | T-07 capability mal asignada |
| 2FA / admin | T-03 admin sin MFA | T-02 cookie de sesión reutilizada | T-27 borrado de logs | T-08 panel expuesto | — | T-08 plugin malicioso instalado |
| Núcleo WordPress | — | T-09 CSRF sin nonce | — | T-35 `wp-config` expuesto | T-46 DDoS | T-16 RCE por plugin |
| Plugins / tema | — | T-13 SQLi en plugin | — | T-14 LFI/RFI | — | T-15 deserialización PHP |
| Checkout WooCommerce | T-20 webhook sin firma | T-19 precio/cupón manipulado | T-21 replay de webhook | T-18 pedido ajeno por REST | T-22 card testing | T-25 export masivo |
| Media / uploads | — | T-11 PHP en uploads | — | T-17 path traversal en facturas | — | T-11 ejecución de shell |
| REST API (`/wp-json/*`) | — | T-19 carrito manipulado | — | T-18 IDOR/BOLA pedidos | T-23 scraping | T-07 endpoints sin capability |
| MySQL | — | T-12 SQLi búsqueda/plugin | T-26 sin auditoría | T-38 volcado masivo | T-46 agotamiento de conexiones | T-12 lectura de otras tablas |
| Contenedor / pod | — | T-29 token SA montado | — | T-33 secretos en env | T-46 pod sin límites | T-28 escape a nodo |
| GKE / K8s | — | T-30 NetworkPolicy ausente | — | T-32 API pública | T-46 nodos agotados | T-29 RBAC excesivo |
| Almacenamiento GCS | — | T-37 bucket público | — | T-37 listado de objetos | — | — |
| Cloudflare / borde | — | T-43 bypass de WAF | — | T-35 respuestas con trazas | T-46 flood | T-42 regla que abre admin |
| CI/CD | T-47 PR suplantado | T-48 dependencia comprometida | T-49 acción sin pin | T-47 secretos exfiltrados | T-46 runner caído | T-47 deploy malicioso |
| Identidad cloud (IAM) | T-51 cuenta dueño secuestrada | T-50 política IAM alterada | T-50 sin audit log | T-33 secreto en env | T-46 cuota agotada | T-50 SA con editor |
| Operación / personas | T-52 phishing admin | T-53 insider cambia prod | T-27 sin trazabilidad | T-54 datos reales en capturas | — | T-53 exceso de privilegios |
| Proveedor | — | — | — | T-56 incidente del proveedor | T-56 caída regional | — |

## 3. Amenazas priorizadas

| ID | Amenaza | Componente | Actor |
|---|---|---|---|
| T-18 | IDOR en pedidos vía `/wp-json/wc/v3/orders/{id}` | REST WooCommerce | Cliente autenticado |
| T-16 | RCE por plugin desactualizado | Plugins | Externo |
| T-11 | Carga de PHP en uploads y ejecución | Media/Uploads | Admin comprometido o editor |
| T-09 | CSRF en acción de administración sin nonce | Admin | Externo (víctima admin) |
| T-47 | PR malicioso que exfiltra secretos del pipeline | CI/CD | Colaborador o cuenta robada |
| T-50 | SA con `roles/editor` → control total del proyecto | IAM | Atacante con acceso al runner |
| T-01 | Fuerza bruta/credential stuffing en `wp-login` | Login | Externo |
| T-22 | Card testing en checkout | Checkout | Externo |

## 4. Trazabilidad

Cada amenaza termina en un riesgo `R-NN`, un control y, si se probó, un hallazgo `H-NN`:

| T-NN | R-NN | Control | H-NN | Estado |
|---|---|---|---|---|
| T-18 | R-05 | Verificación de propiedad del pedido (`current_user_can` + owner check) | — | pendiente |
| T-16 | R-01 | Plugins fijados, WPScan en CI, WAF de exploits conocidos | — | pendiente |
| T-47 | R-23 | Sin `pull_request_target`, WIF con condición, permisos mínimos | — | pendiente |
