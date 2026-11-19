# Clasificación CIA y criticidad

Dueño: **Javier** · Alimenta: `inventario-activos.md`, `dread.md`, `matriz-riesgos.md`

## 1. Escala

| Nivel | Confidencialidad | Integridad | Disponibilidad |
|---|---|---|---|
| **A** | Exposición causa daño legal, financiero o reputacional grave; PII, credenciales, datos de pago | Alteración produce fraude, cobro indebido o decisión irreversible | Caída detiene ventas o administración |
| **M** | Daño limitado o requiere contexto para ser útil | Alteración detectable y reversible | Degradación tolerable por horas |
| **B** | Público o sintético | Sin efecto material | Sin efecto material |

## 2. Cálculo

```
crudo  = max(C, I, A)                    # A=3, M=2, B=1
ajuste = +1 si está expuesto a Internet o no tiene repuesto
crítica = min(3, crudo + ajuste)         # 3=Crítica, 2=Alta, 1.5=Media, 1=Baja
```

## 3. Tabla

| Activo | C | I | A | Expuesto | Único | Puntaje | Criticidad | Justificación |
|---|---|---|---|---|---|---|---|---|
| A-01 Clientes | A | A | M | Vía API | No | 3 | Crítica | PII protegida por ley |
| A-02 Pedidos | A | A | M | Vía API | No | 3 | Crítica | Integridad comercial |
| A-03 Datos de pago | A | A | M | Vía pasarela | No | 3 | Crítica | PCI-DSS |
| A-04 Credenciales admin | A | A | M | Vía Access | No | 3 | Crítica | Toma del CMS |
| A-05 `wp-config`/sales | A | A | M | No | No | 3 | Crítica | Acceso total |
| A-06 Plugins | M | A | M | Sí | No | 2.5 | Alta | Superficie de RCE |
| A-07 Tema | M | A | M | Sí | No | 2.5 | Alta | XSS/Defacement |
| A-08 Imagen CMS | M | A | A | Sí (pull) | No | 2.5 | Alta | Artefacto desplegado |
| A-09 Media | M | A | M | Sí (CDN) | No | 2.5 | Alta | Fuga documental |
| A-10 Manifiestos | M | A | A | Repo | No | 2.5 | Alta | Cambio de clúster |
| A-11 Terraform | M | A | A | Repo | No | 2.5 | Alta | Infraestructura |
| A-12 Pipeline | A | A | A | Webhook | Sí | 3 | Crítica | Despliegue malicioso |
| A-13 Secretos | A | A | M | No | No | 3 | Crítica | Acceso total |
| A-14 CMEK | A | A | A | No | Sí | 3 | Crítica | Datos irrecuperables |
| A-15 SA GKE | A | A | A | No | No | 3 | Crítica | Identidad del pod |
| A-16 DNS/TLS | M | A | A | Sí | Sí | 3 | Crítica | Secuestro de tráfico |
| A-17 Config Cloudflare | A | A | A | Panel | Sí | 3 | Crítica | Borde completo |
| A-18 Logs | M | A | M | No | No | 2 | Alta | Evidencia |
| A-19 Backups | A | A | M | No | No | 3 | Crítica | Recuperación |
| A-20 Admin | A | A | M | Sí + Access | No | 3 | Crítica | Privilegios |
| A-21 MySQL | A | A | A | No | Sí | 3 | Crítica | Negocio completo |
| A-22 Pasarela | A | A | M | Vía API | No | 3 | Crítica | Fraude |
| A-23 Repo | M | A | M | Sí (privado/público) | No | 2.5 | Alta | Cadena de suministro |
| A-24 Documentación | M | M | B | Sí | No | 2 | Alta | Reconocimiento |
| A-25 Laptops | M | M | M | Sí | No | 2.5 | Alta | Credenciales |
| A-26 Demo | B | M | B | Sí | No | 1.5 | Media | Datos falsos |

## 4. Consecuencias para el diseño

Los 14 activos críticos justifican: WAF y Access en el borde, MFA en admin, CMEK y Secret Manager, Pod Security `restricted`, NetworkPolicy, CI con WIF y condición de repo, backups cifrados con prueba de restauración y Logpush fuera del proyecto. Cualquier control que no proteja un activo crítico debe justificarse.

## 5. Historial

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-11-18 | v1 (Opción B, 26 activos) | Javier |
