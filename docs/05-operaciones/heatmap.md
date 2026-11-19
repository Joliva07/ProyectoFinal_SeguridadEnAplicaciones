# Matriz de calor (heatmap) antes y después

Dueño: **Arun** con **Javier** · Componentes de rúbrica 1 y 4 · Insumo: `docs/01-activos-riesgos/matriz-riesgos.md`

## 1. Zonas

Probabilidad × Impacto (1–5).

| P × I | Zona | Color |
|---|---|---|
| 15–25 | Crítico | rojo |
| 10–14 | Alto | naranja |
| 5–9 | Medio | amarillo |
| 1–4 | Bajo | verde |

## 2. Puntos

| ID | Riesgo | P ini | I ini | Score | Zona | P res | I res | Score res | Zona res |
|---|---|---|---|---|---|---|---|---|---|
| R-01 | Plugin con CVE | 4 | 5 | 20 | Crítico | 2 | 3 | 6 | Medio |
| R-02 | SQLi plugin propio | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo |
| R-03 | XSS almacenado | 4 | 3 | 12 | Alto | 2 | 2 | 4 | Bajo |
| R-04 | CSRF admin | 3 | 4 | 12 | Alto | 2 | 2 | 4 | Bajo |
| R-05 | IDOR pedidos | 4 | 4 | 16 | Crítico | 2 | 3 | 6 | Medio |
| R-06 | Fuerza bruta/XML-RPC | 5 | 3 | 15 | Crítico | 2 | 2 | 4 | Bajo |
| R-07 | Enumeración | 5 | 2 | 10 | Alto | 2 | 2 | 4 | Bajo |
| R-08 | Upload PHP | 2 | 5 | 10 | Alto | 1 | 3 | 3 | Bajo |
| R-09 | `wp-config`/backups | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo |
| R-10 | Escape de contenedor | 2 | 5 | 10 | Alto | 1 | 3 | 3 | Bajo |
| R-11 | Imagen con CVEs | 4 | 3 | 12 | Alto | 2 | 3 | 6 | Medio |
| R-12 | K8s sin red/RBAC | 3 | 4 | 12 | Alto | 1 | 3 | 3 | Bajo |
| R-13 | SQL accesible/root | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo |
| R-14 | Bucket público | 2 | 5 | 10 | Alto | 1 | 3 | 3 | Bajo |
| R-15 | WAF débil | 4 | 4 | 16 | Crítico | 2 | 3 | 6 | Medio |
| R-16 | Sin rate limit/bot | 4 | 3 | 12 | Alto | 2 | 2 | 4 | Bajo |
| R-17 | Origen directo | 3 | 4 | 12 | Alto | 1 | 3 | 3 | Bajo |
| R-18 | TLS débil | 3 | 3 | 9 | Medio | 1 | 2 | 2 | Bajo |
| R-19 | Secretos en repo/env | 4 | 5 | 20 | Crítico | 1 | 3 | 3 | Bajo |
| R-20 | Admin sin MFA | 3 | 5 | 15 | Crítico | 1 | 3 | 3 | Bajo |
| R-21 | Sin auditoría | 5 | 3 | 15 | Crítico | 2 | 2 | 4 | Bajo |
| R-22 | Backups sin restore | 3 | 4 | 12 | Alto | 1 | 3 | 3 | Bajo |
| R-23 | Pipeline sin controles | 4 | 4 | 16 | Crítico | 2 | 2 | 4 | Bajo |
| R-24 | Sin Pod Security | 3 | 4 | 12 | Alto | 1 | 2 | 2 | Bajo |
| R-25 | Proveedor cloud | 1 | 5 | 5 | Medio | 1 | 5 | 5 | Medio |
| R-26 | Phishing/agencia | 3 | 4 | 12 | Alto | 2 | 3 | 6 | Medio |
| R-27 | Datos reales en capturas | 3 | 3 | 9 | Medio | 1 | 2 | 2 | Bajo |
| R-28 | Un operador de Cloudflare | 3 | 3 | 9 | Medio | 3 | 3 | 9 | Medio |

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

```mermaid
quadrantChart
    title Riesgo residual (P × I)
    x-axis "Probabilidad baja" --> "Probabilidad alta"
    y-axis "Impacto bajo" --> "Impacto alto"
    quadrant-1 Crítico
    quadrant-2 Alto
    quadrant-3 Bajo
    quadrant-4 Medio
    R-01: [0.40, 0.60]
    R-05: [0.40, 0.60]
    R-11: [0.40, 0.60]
    R-15: [0.40, 0.60]
    R-25: [0.20, 1.00]
    R-26: [0.40, 0.60]
    R-28: [0.60, 0.60]
    R-03: [0.40, 0.40]
    R-06: [0.40, 0.40]
```

## 5. Lectura del cambio

| Zona | Inicial | Residual |
|---|---|---|
| Crítico | 11 | 0 |
| Alto | 13 | 0 |
| Medio | 4 | 7 |
| Bajo | 0 | 21 |

Lo que queda en Medio son riesgos aceptados (R-25, R-28) y riesgos donde el control reduce probabilidad pero no impacto: plugin con CVE (R-01), IDOR (R-05), imagen base (R-11), WAF (R-15) y phishing (R-26). Se declara explícitamente: **no queda riesgo crítico sin control**.

## 6. Reglas de honestidad

1. El residual no mejora sin evidencia de la prueba del control.
2. Re-puntuar a la baja sin cambio técnico es un error, no una mejora.
3. Las cifras finales se recalculan con los `H-NN` reales; las de aquí son la proyección del diseño.
