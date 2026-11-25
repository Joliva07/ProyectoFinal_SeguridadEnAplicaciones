"""Fail when a discovered, installed WordPress component has CVSS >= 7.0."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def score_of(value: object) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return None
    if isinstance(value, dict):
        for key in ("score", "base_score", "cvss_score"):
            result = score_of(value.get(key))
            if result is not None:
                return result
    return None


def find_high_findings(value: object, path: str = "root") -> list[tuple[str, str, float]]:
    findings: list[tuple[str, str, float]] = []
    if isinstance(value, dict):
        cvss = value.get("cvss")
        score = score_of(cvss)
        if score is None:
            score = score_of(value.get("cvss_score"))
        if score is not None and score >= 7.0:
            title = str(value.get("title") or value.get("name") or "vulnerabilidad sin título")
            findings.append((path, title, score))
        for key, child in value.items():
            if isinstance(child, (dict, list)):
                findings.extend(find_high_findings(child, f"{path}.{key}"))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            findings.extend(find_high_findings(child, f"{path}[{index}]"))
    return findings


def main() -> int:
    if len(sys.argv) != 2:
        print("Uso: wpscan-threshold.py reporte.json", file=sys.stderr)
        return 2
    report_path = Path(sys.argv[1])
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"No se pudo leer el reporte WPScan: {error}", file=sys.stderr)
        return 2

    # Falla cerrado: un escaneo abortado (token invalido, cuota agotada, WAF) no prueba nada.
    if not isinstance(report, dict) or report.get("scan_aborted"):
        reason = report.get("scan_aborted") if isinstance(report, dict) else "reporte inesperado"
        print(f"WPScan no completó el escaneo: {reason}", file=sys.stderr)
        return 1

    findings = find_high_findings(report)
    if findings:
        print("WPScan encontró vulnerabilidades con CVSS >= 7.0:")
        for location, title, score in findings:
            print(f"- {score:.1f} {title} ({location})")
        return 1
    print("WPScan no encontró vulnerabilidades con CVSS >= 7.0 en el reporte.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
