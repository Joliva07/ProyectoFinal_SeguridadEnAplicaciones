# SAST y SCA

Dueño: **Josue** · Revisión: Arun (triaje) · Componente de rúbrica 2

## 1. SAST — Semgrep

| Aspecto | Definición |
|---|---|
| Alcance | `app/backend/**`, `app/android/**`, `infra/**` (reglas de Terraform) |
| Rulesets | `p/owasp-top-ten`, `p/secrets`, `p/python` o `p/javascript`, `p/dockerfile` |
| Umbral de bloqueo | `ERROR` en PR; `WARNING` solo reporta |
| Supresiones | `# nosemgrep: <regla> — <justificación>` con enlace a la issue |
| Evidencia | SARIF + `evidencias/fase3/sast-semgrep-<fecha>/` |

Hallazgos esperados y qué demostrar:

| Regla | Riesgo | Demostración requerida |
|---|---|---|
| Concatenación SQL | R-01/R-02 | antes: query con f-string; después: consulta parametrizada + test |
| `verify=False` / pinning desactivado | R-14 | antes: `OkHttpClient` sin pinner; después: `CertificatePinner` |
| `alg=none` / sin verificación de firma | R-03 | antes: decode sin verificar; después: JWKS + `algorithms=["RS256"]` |
| Secreto hardcodeado | R-05 | antes: password en código; después: Secret Manager |
| Log de datos sensibles | R-15 | antes: `log(token)`; después: log con ID de correlación |

## 2. SCA — OWASP Dependency-Check / Snyk

| Aspecto | Definición |
|---|---|
| Alcance | `requirements.txt`/`package-lock.json`, `build.gradle`, imagen base |
| Fuentes | NVD + GitHub Advisory; actualizar base local antes de correr |
| Umbral | CVSS ≥ 7 con versión corregida disponible = falla |
| Excepciones | CVE sin fix + no alcanzable = aceptar con justificación y fecha de revisión |
| Evidencia | HTML/JSON con CVE, CVSS, dependencia y ruta de introducción |

Tabla de triaje (obligatoria para el informe):

| CVE | Paquete | Versión actual | Versión corregida | CVSS | ¿Alcanzable? | Decisión | Responsable |
|---|---|---|---|---|---|---|---|
| CVE-2024-XXXX | ejemplo | 1.2.3 | 1.2.4 | 7.5 | sí | actualizar | Josue |

## 3. Secretos

`gitleaks` en cada PR y en el historial completo (`gitleaks detect --log-opts=--all`) una vez por semana. Si aparece un secreto: rotar primero, purgar después, documentar en `tratamiento-riesgo.md`.

## 4. Coordinación con la fase 4

- Arun recibe la lista de hallazgos SAST/SCA con ID `H-NN` y decide si son verdaderos positivos (triaje), con evidencia de código o de ejecución.
- Horacio verifica en el APK compilado los hallazgos de código móvil (p. ej. que el pinning realmente se aplique).
- Un hallazgo SAST que no se puede demostrar en ejecución se documenta como "revisión de código" y no como vulnerabilidad explotada.
