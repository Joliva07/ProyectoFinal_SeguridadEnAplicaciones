# Clasificación de riesgos DREAD

Dueño: **Javier** · Insumo: `stride.md` · Salida: severidad inicial para `matriz-riesgos.md`

## 1. Escala (1–10)

| Dimensión | 1–3 | 4–6 | 7–10 |
|---|---|---|---|
| **D** Damage | Cosmético o interno | Pérdida limitada | Financiero, legal o total |
| **R** Reproducibility | Condiciones raras | Repetible con esfuerzo | Siempre, con un clic |
| **E** Exploitability | Cadena compleja | Herramienta pública | Público y sin autenticación |
| **A** Affected users | Un usuario | Un segmento | Toda la base o la tienda |
| **D** Discoverability | Requiere acceso interno | Fuzzing/revisión guiada | Visible en la primera petición |

`DREAD = (D + R + E + A + D) / 5`

| Rango | Severidad | Tratamiento esperado |
|---|---|---|
| 8.0–10 | Crítica | Mitigar antes de exponer; bloquea release |
| 6.0–7.9 | Alta | Mitigar en el sprint; compensatorio mientras |
| 4.0–5.9 | Media | Planificar y monitorear |
| 1.0–3.9 | Baja | Aceptar y documentar |

## 2. Puntuación

| ID | Amenaza | D | R | E | A | D | DREAD | Severidad |
|---|---|---|---|---|---|---|---|---|
| T-16 | RCE por plugin desactualizado | 10 | 8 | 7 | 10 | 6 | 8.2 | Crítica |
| T-11 | Upload de PHP y ejecución | 10 | 7 | 7 | 9 | 5 | 7.6 | Alta |
| T-18 | IDOR en pedidos (REST) | 8 | 10 | 9 | 8 | 10 | 9.0 | Crítica |
| T-09 | CSRF en acción admin | 9 | 6 | 6 | 6 | 4 | 6.2 | Alta |
| T-12 | SQLi en búsqueda/plugin propio | 10 | 8 | 7 | 10 | 6 | 8.2 | Crítica |
| T-13 | SQLi en plugin de terceros | 10 | 7 | 6 | 9 | 5 | 7.4 | Alta |
| T-01 | Fuerza bruta en `wp-login` | 9 | 10 | 9 | 6 | 10 | 8.8 | Crítica |
| T-05 | Amplificación XML-RPC | 7 | 9 | 9 | 8 | 9 | 8.4 | Crítica |
| T-19 | Manipulación de precio/cupón | 8 | 8 | 7 | 7 | 6 | 7.2 | Alta |
| T-22 | Card testing | 8 | 9 | 8 | 6 | 7 | 7.6 | Alta |
| T-47 | PR malicioso (secretos) | 10 | 7 | 6 | 10 | 5 | 7.6 | Alta |
| T-50 | SA con `editor` | 10 | 6 | 6 | 10 | 4 | 7.2 | Alta |
| T-37 | Bucket público | 9 | 8 | 7 | 9 | 8 | 8.2 | Crítica |
| T-35 | `wp-config` expuesto | 10 | 8 | 7 | 10 | 7 | 8.4 | Crítica |
| T-28 | Escape de contenedor | 10 | 4 | 4 | 10 | 3 | 6.2 | Alta |
| T-30 | Sin NetworkPolicy | 9 | 6 | 5 | 9 | 4 | 6.6 | Alta |
| T-43 | Bypass de WAF | 8 | 7 | 6 | 8 | 5 | 6.8 | Alta |
| T-44 | Origen accesible sin Cloudflare | 7 | 8 | 8 | 8 | 7 | 7.6 | Alta |
| T-23 | Scraping de precios | 4 | 10 | 9 | 5 | 10 | 7.6 | Alta |
| T-25 | Export masivo de clientes | 9 | 6 | 4 | 9 | 4 | 6.4 | Alta |
| T-26 | Sin auditoría de pedidos | 9 | 6 | 4 | 10 | 3 | 6.4 | Alta |
| T-32 | GKE API pública | 10 | 5 | 5 | 10 | 4 | 6.8 | Alta |
| T-46 | DDoS volumétrico | 6 | 7 | 8 | 9 | 9 | 7.8 | Alta |
| T-54 | Datos reales en capturas | 8 | 8 | 9 | 8 | 8 | 8.2 | Crítica |

## 3. Cómo puntuar en equipo

1. Puntuación individual en silencio, promedio y discusión solo de desviaciones > 2 puntos.
2. Toda `Exploitability ≥ 7` exige evidencia (herramienta, versión, comando) o baja a 6.
3. El DREAD no sustituye a CVSS: cuando exista CVE o PoC, se registra CVSS 4.0 y se conserva DREAD para prioridad de negocio.

## 4. Re-puntuación

Tras la fase 4 se vuelve a puntuar con los `H-NN` reales y se registra la variación. La tabla final se copia al informe §2.4 y alimenta el heatmap residual.
