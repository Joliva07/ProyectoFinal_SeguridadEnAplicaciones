# Diagramas de arquitectura

Fuentes editables de los diagramas C4 y de los flujos asignados a Josue:

| Archivo fuente | Contenido | Estado |
|---|---|---|
| [c4-contexto.mmd](c4-contexto.mmd) | Actores, AuroraShop, Cloudflare y servicios cloud | Diseño, pendiente de despliegue |
| [c4-contenedores.mmd](c4-contenedores.mmd) | Ingress, workload, base de datos, medios, secretos y CI | Diseño, pendiente de despliegue |
| [flujo-checkout.mmd](flujo-checkout.mmd) | Secuencia de checkout y límites de confianza | Flujo objetivo |
| [cadena-suministro.mmd](cadena-suministro.mmd) | PR, análisis, imagen por digest y despliegue WIF | Flujo objetivo |

Las fuentes están en Mermaid para revisión y cambios por PR. Las exportaciones PNG se generan cuando se disponga del renderizador del equipo; no se presentan como evidencia de un sistema desplegado.

Los diagramas de perímetro Cloudflare y SIEM/Falco corresponden a Horacio y Arun, respectivamente.
