# Matriz de calor (heatmap) antes y después

Dueño: **Arun** con **Javier** · Componentes de rúbrica 1 y 4 · Issue #56 · Insumo: `docs/01-activos-riesgos/matriz-riesgos.md` y `tratamiento-riesgo.md` · Corte: 2026-11-27

## 1. Zonas

Probabilidad × Impacto (1–5).

| P × I | Zona | Color |
|---|---|---|
| 15–25 | Crítico | rojo |
| 10–14 | Alto | naranja |
| 5–9 | Medio | amarillo |
| 1–4 | Bajo | verde |

## 2. Puntos

- **Inicial:** matriz v1 del diseño.
- **Actual:** residual con los controles **probados** al 2026-11-26. Solo baja si hay evidencia (§6).
- **Objetivo:** residual esperado cuando se cierren los abiertos de `tratamiento-riesgo.md` §2.

| ID | Riesgo | P ini | I ini | Score | Zona | P act | I act | Score act | Zona act | Objetivo | Evidencia del residual actual |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R-01 | Plugin con CVE | 4 | 5 | 20 | Crítico | 2 | 4 | 8 | Medio | 6 | 0 CVE en versiones instaladas (#48); el gate de WPScan no bloquea (S-04) |
| R-02 | SQLi plugin propio | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo | 3 | Sin SQL propio; Semgrep 0 (#46 §3); A03 |
| R-03 | XSS almacenado | 4 | 3 | 12 | Alto | 2 | 2 | 4 | Bajo | 4 | `wp_kses` en reseñas (#46, prueba 13); A03 |
| R-04 | CSRF admin | 3 | 4 | 12 | Alto | 2 | 2 | 4 | Bajo | 4 | Nonce obligatorio (#46, prueba 10); H-10 aceptado; H-11 abierto, mitigado por nonce |
| R-05 | IDOR pedidos | 4 | 4 | 16 | Crítico | 2 | 3 | 6 | Medio | 6 | #46, pruebas 1–3; H-09 cerrado |
| R-06 | Fuerza bruta/XML-RPC | 5 | 3 | 15 | Crítico | 2 | 2 | 4 | Bajo | 4 | 429 al 3.er intento; XML-RPC 403; 2FA (#45, #44) |
| R-07 | Enumeración | 5 | 2 | 10 | Alto | 2 | 2 | 4 | Bajo | 4 | `?author=` 404, `wp/v2/users` 403/401 (#45, prueba 5) |
| R-08 | Upload PHP | 2 | 5 | 10 | Alto | 1 | 3 | 3 | Bajo | 3 | Ejecutables rechazados (#46, prueba 12) |
| R-09 | `wp-config`/backups | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo | 3 | 28 rutas sensibles 403/404 (#45, prueba 9) |
| R-10 | Escape de contenedor | 2 | 5 | 10 | Alto | 1 | 3 | 3 | Bajo | 3 | PSA rechaza `privileged` y `hostPath` en GKE (#49); UID 10001 |
| R-11 | Imagen con CVEs | 4 | 3 | 12 | Alto | 2 | 3 | 6 | Medio | 6 | Trivy: 0 vulnerabilidades en las dos imágenes (#50) |
| R-12 | K8s sin red/RBAC | 3 | 4 | 12 | Alto | 2 | 3 | 6 | Medio | 3 | NetworkPolicy y RBAC probados (#49); red `default` abierta (P-11, S-06) |
| R-13 | SQL accesible/root | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo | 3 | IP privada, IAM, CMEK, proxy mTLS (S-03) |
| R-14 | Bucket público | 2 | 5 | 10 | Alto | 1 | 3 | 3 | Bajo | 3 | Checkov 0; acceso uniforme, sin `allUsers` |
| R-15 | WAF débil | 4 | 4 | 16 | Crítico | 2 | 3 | 6 | Medio | 6 | WAF y Managed Ruleset en `block` (edge-tests 2026-11-25); límites del plan Free |
| R-16 | Sin rate limit/bot | 4 | 3 | 12 | Alto | 3 | 3 | 9 | Medio | 4 | Solo el login está limitado; `/shop/` sin límite (H-12); Turnstile pendiente (AC-01, AC-08) |
| R-17 | Origen directo | 3 | 4 | 12 | Alto | 1 | 3 | 3 | Bajo | 3 | Cloud Armor 403 al origen (P-01); P-10 sin impacto de datos |
| R-18 | TLS débil | 3 | 3 | 9 | Medio | 1 | 2 | 2 | Bajo | 2 | TLS 1.2 mínimo y HSTS activos (2026-11-27); 1.0/1.1 rechazados |
| R-19 | Secretos en repo/env | 4 | 5 | 20 | Crítico | 1 | 3 | 3 | Bajo | 3 | gitleaks 0; secretos por CSI (#46, prueba 18) |
| R-20 | Admin sin MFA | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo | 3 | Access en `admin-` con política Allow (2026-11-27) + 2FA obligatorio |
| R-21 | Sin auditoría | 5 | 3 | 15 | Crítico | 3 | 3 | 9 | Medio | 4 | Logs JSON centralizados; alertas sin probar (#54) |
| R-22 | Backups sin restore | 3 | 4 | 12 | Alto | 2 | 4 | 8 | Medio | 3 | Backups CMEK y PITR; restauración no probada |
| R-23 | Pipeline sin controles | 4 | 4 | 16 | Crítico | 3 | 3 | 9 | Medio | 4 | 9 jobs en verde; sin *branch protection* (P-13) y gate de WPScan que falla abierto (S-04) |
| R-24 | Sin Pod Security | 3 | 4 | 12 | Alto | 1 | 2 | 2 | Bajo | 2 | PSA `restricted` probado en GKE (#49, pruebas 5–6) |
| R-25 | Proveedor cloud | 1 | 5 | 5 | Medio | 1 | 5 | 5 | Medio | 5 | Transferido (SLA de Google Cloud) |
| R-26 | Phishing/agencia | 3 | 4 | 12 | Alto | 2 | 3 | 6 | Medio | 6 | 2FA obligatorio; Access pendiente |
| R-27 | Datos reales en capturas | 3 | 3 | 9 | Medio | 1 | 2 | 2 | Bajo | 2 | Evidencias redactadas (commit `89f2989`) |
| R-28 | Un operador de Cloudflare | 3 | 3 | 9 | Medio | 3 | 3 | 9 | Medio | 9 | Aceptado |

## 3. Antes

```mermaid
quadrantChart
    title Riesgo inicial (P × I)
    x-axis "Probabilidad baja" --> "Probabilidad alta"
    y-axis "Impacto bajo" --> "Impacto alto"
    quadrant-1 Crítico
    quadrant-2 Alto
    quadrant-3 Bajo
    quadrant-4 Medio
    R-01: [0.80, 1.00]
    R-02: [0.60, 1.00]
    R-05: [0.80, 0.80]
    R-06: [1.00, 0.60]
    R-09: [0.60, 1.00]
    R-13: [0.60, 1.00]
    R-15: [0.80, 0.80]
    R-19: [0.80, 1.00]
    R-20: [0.60, 1.00]
    R-21: [1.00, 0.60]
    R-23: [0.80, 0.80]
    R-08: [0.40, 1.00]
```

## 4. Después

### 4.1 Residual actual (2026-11-26)

Los 14 riesgos en Medio. Los que comparten coordenadas se desplazan ±0.02 para que se lean.

```mermaid
quadrantChart
    title Riesgo residual actual (P × I)
    x-axis "Probabilidad baja" --> "Probabilidad alta"
    y-axis "Impacto bajo" --> "Impacto alto"
    quadrant-1 Crítico
    quadrant-2 Alto
    quadrant-3 Bajo
    quadrant-4 Medio
    R-01: [0.38, 0.80]
    R-20: [0.20, 0.60]
    R-22: [0.42, 0.78]
    R-05: [0.36, 0.60]
    R-11: [0.38, 0.62]
    R-12: [0.40, 0.58]
    R-15: [0.42, 0.62]
    R-18: [0.20, 0.40]
    R-26: [0.40, 0.64]
    R-16: [0.58, 0.60]
    R-21: [0.60, 0.62]
    R-23: [0.62, 0.58]
    R-28: [0.60, 0.56]
    R-25: [0.20, 1.00]
```

### 4.2 Residual objetivo (al cerrar los abiertos)

```mermaid
quadrantChart
    title Riesgo residual objetivo (P × I)
    x-axis "Probabilidad baja" --> "Probabilidad alta"
    y-axis "Impacto bajo" --> "Impacto alto"
    quadrant-1 Crítico
    quadrant-2 Alto
    quadrant-3 Bajo
    quadrant-4 Medio
    R-01: [0.38, 0.60]
    R-05: [0.40, 0.62]
    R-11: [0.42, 0.58]
    R-15: [0.40, 0.58]
    R-25: [0.20, 1.00]
    R-26: [0.42, 0.62]
    R-28: [0.60, 0.60]
    R-03: [0.40, 0.40]
    R-06: [0.42, 0.42]
```

## 5. Lectura del cambio

| Zona | Inicial | Actual (27-nov) | Objetivo |
|---|---|---|---|
| Crítico | 11 | 0 | 0 |
| Alto | 13 | 0 | 0 |
| Medio | 4 | 12 | 7 |
| Bajo | 0 | 16 | 21 |

Hoy **no queda ningún riesgo crítico ni alto** con los controles probados: los 24 riesgos críticos o altos bajan al menos a Medio. Los 12 en Medio se dividen en dos grupos:

- **5 que bajan a Bajo** cuando se cierre su control pendiente: R-12 (red `default`), R-16 (scraping), R-21 (alertas), R-22 (restore) y R-23 (*branch protection* y gate de WPScan). Todos tienen responsable y fecha en `tratamiento-riesgo.md`.
- **7 que se quedan en Medio** como residual tolerable (≤ 9): R-25 y R-28 aceptados o transferidos, y riesgos donde el control reduce la probabilidad pero no el impacto: plugin con CVE (R-01), IDOR (R-05), imagen base (R-11), WAF (R-15) y phishing (R-26).

R-18 (TLS/HSTS) y R-20 (Access en `admin-`) bajaron a Bajo el 2026-11-27 con evidencia de borde.

Se declara explícitamente: **no queda riesgo crítico sin control**, y ningún residual supera 9.

## 6. Reglas de honestidad

1. El residual no mejora sin evidencia de la prueba del control.
2. Re-puntuar a la baja sin cambio técnico es un error, no una mejora.
3. La columna "Actual" usa los `H-NN`, `P-NN` y `S-NN` reales al 2026-11-27. La columna "Objetivo" es una proyección y solo pasa a "Actual" con la prueba de cierre de `tratamiento-riesgo.md` §5.
