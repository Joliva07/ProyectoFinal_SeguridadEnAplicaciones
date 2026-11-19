# Evaluación de plugins y temas (3.4)

Dueño: **Horacio** · Insumo: `docs/03-devsecops/plugins-temas.md`

## 1. Método

1. Inventario real con `wp plugin list` y `wp theme list` (versión, estado, actualización disponible).
2. WPScan con enumeración de plugins vulnerables y temas (`--enumerate vp,vt`), con token API.
3. Correlación manual con NVD/GitHub Advisory para lo que WPScan no cubra.
4. Revisión de código de los plugins propios y del tema hijo (Semgrep + lectura dirigida).
5. Prueba de explotación controlada solo si el CVE es alcanzable y está en la ventana.
6. Decisión por plugin: mantener, actualizar, reemplazar o eliminar.

## 2. Tabla de resultados

| Plugin / tema | Versión | CVE / hallazgo | CVSS | Alcanzable | Prueba | Decisión | Evidencia |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |

## 3. Revisión de código del plugin propio

| Punto | Qué se busca | Resultado |
|---|---|---|
| Registro de endpoints | `register_rest_route` con `permission_callback` | |
| Capacidades | `current_user_can` antes de mutar datos | |
| Nonces | `wp_verify_nonce` en formularios y AJAX | |
| SQL | `$wpdb->prepare` en toda consulta | |
| Salida | `esc_html`/`esc_attr`/`wp_kses_post` | |
| Subidas | validación MIME, tamaño y destino | |
| Serialización | sin `unserialize` de entrada de usuario | |

## 4. Riesgo de cadena de suministro

- Los plugins se instalan desde un repositorio fijado por versión, no desde el panel en producción.
- Cada actualización pasa por WPScan y Trivy antes de llegar a `demo`.
- Un plugin abandonado es un riesgo aceptado solo si es imprescindible y está cubierto por WAF y monitoreo; se documenta la fecha de revisión.

## 5. Salida para el informe

Tabla de plugins con versión, CVE, decisión y evidencia; lista de plugins eliminados y por qué; conclusión sobre la superficie de terceros (cuántos plugins, cuántos con CVE, cuántos actualizados).
