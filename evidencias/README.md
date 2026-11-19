# Evidencias

Cada carpeta corresponde a una fase del ciclo y a una fecha de ejecución. Sin evidencia, el control no existe para efectos de la rúbrica.

## Estructura

```
evidencias/
  fase1/   inventario exportado, matrices en CSV, heatmap
  fase2/   diagramas, matriz IAM/RBAC, `terraform plan` y `kubectl get` redactados
  fase3/   semgrep/, wpscan/, composer-audit/, gitleaks/, trivy/, checkov/, actions/
  fase4/   zap-<fecha>/, wpscan/, nmap/, burp/, idor-orders/, k8s-tests/
  fase5/   waf-<fecha>/, siem/, alertas/, dashboards/
  fase6/   ... (si aplica)
```

## Reglas

1. Nombre: `<herramienta>-<AAAA-MM-DD>.<ext>`; si hay varias corridas, sufijo `-run2`.
2. Todo reporte incluye versión de la herramienta y comando ejecutado en un `README.md` de la carpeta.
3. Redactar: correos, tokens, cookies, números de cuenta, IPs internas (dejar dos octetos), rutas absolutas del usuario.
4. Nada de binarios > 10 MB; subir capturas comprimidas o enlazar el artifact de Actions.
5. Un `README.md` por carpeta con: objetivo, fecha, autor, comando, resultado y conclusión de una línea.

## Índice de evidencias

| Fase | Carpeta | Autor | Estado |
|---|---|---|---|
| 1 | `fase1/` | Javier | pendiente |
| 2 | `fase2/` | Josue | pendiente |
| 3 | `fase3/` | Josue | pendiente |
| 4 | `fase4/` | Horacio | pendiente |
| 5 | `fase5/` | Arun / James | pendiente |
