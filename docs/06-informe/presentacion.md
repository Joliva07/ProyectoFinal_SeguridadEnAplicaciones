<!-- Enlace público del diseño en Canva: https://canva.link/zndpx8rf8jmnwq3 -->

---
title: "AuroraShop"
subtitle: "Seguridad continua en un e-commerce WordPress/WooCommerce sobre Google Cloud. Equipo: Hector James Maradiaga López, Javier Oliva, Josue, Horacio, Arun"
author: ""
date: "Seguridad en Aplicaciones (093-013) · UMG 2026"

---

# Qué evaluamos

- Tienda WordPress + WooCommerce en GKE, con Cloudflare al frente
- Datos sintéticos: sin clientes ni pagos reales
- Evaluación ofensiva, arquitectura, pipeline y operación
- Todo con evidencia reproducible

::: notes
James, 1 minuto. Abrir con el problema: una tienda cloud-native expuesta a Internet. Aclarar que es un entorno de laboratorio con datos falsos y que cada afirmación tiene una prueba detrás.
:::

# Javier · Activos y riesgos

- 26 activos, 15 críticos, cada uno con dueño
- 56 amenazas STRIDE; 28 riesgos priorizados
- De 11 riesgos críticos a cero con controles probados
- Residual: 12 medios y 16 bajos

::: notes
Javier, 1.5 minutos. Explicar que el inventario se contrastó con el clúster real y ahí aparecieron brechas. Cerrar con el dato: ningún riesgo crítico o alto queda sin control.
:::

# Josue · Arquitectura y DevSecOps

- Tres planos: Cloudflare, Google Cloud y clúster
- Nada llega al pod sin pasar por el borde
- 9 jobs de integración: secretos, SAST, SCA, IaC e imagen
- Deploy solo desde main y por digest

::: notes
Josue, 1.5 minutos. Idea central: Zero Trust es diseño, no producto. Mencionar la debilidad honesta: el gate de WPScan falla abierto y quedó registrado como S-04.
:::

# Horacio · Ciberdefensa

- 38 pruebas ofensivas; 30 controles confirmados
- Sin IDOR, XSS, SQLi ni precio manipulado
- Una fuga real (descarga sin sesión): corregida
- OWASP: 6 mitigadas, 4 parciales, 0 abiertas

::: notes
Horacio, 1.5 minutos. Contar H-09 en una frase: el enlace de descarga servía sin sesión; se corrigió y se probó que un anónimo recibe 302 al login.
:::

# Arun · Operación y riesgo

- WAF en bloqueo, rate limit y Cloud Armor
- Access protege el panel; TLS 1.2 y HSTS
- 11 consultas y 8 alertas de SIEM definidas
- Pendiente: probar alertas y restauración

::: notes
Arun, 1.5 minutos. Lo probado: XML-RPC 403, login 429 al tercer intento, origen directo 403. Lo pendiente se dice sin adornos: las alertas aún no se dispararon en prueba.
:::

# James · Dictamen

- Demo académica lista, con evidencia
- Producción con pagos: todavía no
- Abiertos: CORS, scraping, red default, branch protection
- Siguiente paso: cerrarlos en 30 días

::: notes
James, 1.5 minutos. Tres mensajes: el perímetro aguantó, las brechas restantes son de proceso y un control sin prueba no existe. Cerrar con la hoja de ruta de 30 días y dar paso a preguntas.
:::
