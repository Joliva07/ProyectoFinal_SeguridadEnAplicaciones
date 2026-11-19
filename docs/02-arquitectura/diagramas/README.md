# Diagramas

Guardar aquí los diagramas editables y sus exportaciones:

| Archivo | Contenido | Herramienta | Responsable |
|---|---|---|---|
| `c4-contexto.drawio` | Contexto C4: clientes, admin, Cloudflare, GCP | draw.io | Josue |
| `c4-contenedores.drawio` | Ingress, pods, MySQL, GCS, KMS, registry | draw.io | Josue |
| `flujo-checkout.png` | Secuencia de compra con controles | draw.io / mermaid | Josue |
| `perimetro.png` | Superficie expuesta, zonas y bloqueo del origen | draw.io | Horacio |
| `siem-arquitectura.png` | Recolección, correlación y alertas | draw.io | Arun |
| `cadena-suministro.png` | Repo → CI → Artifact Registry → GKE | draw.io | Josue |

Reglas: exportar PNG ≤ 1 MB, nombrar `fase<NN>-<tema>`, referenciar desde el documento que la usa y commitear también la fuente editable (`.drawio`, `.mmd`).
