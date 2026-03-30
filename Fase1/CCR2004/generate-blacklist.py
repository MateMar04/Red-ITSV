#!/usr/bin/env python3
"""
Genera un archivo .rsc para MikroTik con entradas DNS estáticas (NXDOMAIN)
a partir de las blacklists de ut1-blacklists (Universidad de Toulouse).

Uso:
    python3 generate-blacklist.py
    python3 generate-blacklist.py --output /ruta/blacklist-dns.rsc
    python3 generate-blacklist.py --serve 8080  # Sirve el archivo en HTTP
    python3 generate-blacklist.py --max-domains 50000  # Limitar cantidad

IMPORTANTE: La categoría "adult" tiene ~2M de dominios. Por defecto se limita
el total a 100.000 entradas (priorizando malware/phishing sobre el resto).
Ajuste --max-domains según la capacidad de RAM de su equipo.

El CCR2004 con 4GB de RAM puede manejar aprox 100k-150k entradas DNS estáticas.
Para bloqueo masivo de adult/porn se recomienda complementar con DNS filtrado
(ver firewall-blacklist.rsc).
"""

import argparse
import http.server
import os
import sys
import urllib.request
from datetime import datetime

BASE_URL = "https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists"

# Categorías ordenadas por PRIORIDAD (las primeras se incluyen primero)
# Si se alcanza --max-domains, las categorías de menor prioridad se truncan.
CATEGORIES = [
    # Prioridad alta: seguridad
    ("malware",             "alta"),
    ("phishing",            "alta"),
    ("cryptojacking",       "alta"),
    # Prioridad media: contenido inapropiado para colegio
    ("dangerous_material",  "media"),
    ("agressif",            "media"),   # violence (symlink)
    ("hacking",             "media"),
    ("mixed_adult",         "media"),
    ("gambling",            "media"),
    ("dating",              "media"),
    # Prioridad normal: entretenimiento/distracción
    ("games",               "normal"),
    ("social_networks",     "normal"),
    # adult/porn: NO incluido porque CleanBrowsing Family Filter
    # ya bloquea ~2M de dominios adult/porn a nivel DNS.
    # Si no usa CleanBrowsing, descomente la siguiente línea:
    # ("adult",             "baja"),
]

DEFAULT_MAX_DOMAINS = 100_000

# Dominios que NUNCA deben bloquearse (falsos positivos comunes)
WHITELIST = {
    "google.com",
    "google.com.ar",
    "youtube.com",
    "wikipedia.org",
    "github.com",
    "microsoft.com",
    "live.com",
    "office.com",
    "office365.com",
    "outlook.com",
    "itsv.edu.ar",
    "edu.ar",
    "whatsapp.com",
    "zoom.us",
    "meet.google.com",
}


def download_category(category: str) -> set[str]:
    """Descarga la lista de dominios de una categoría."""
    filenames = ["domains", "domains.24733", "domains.9309"]
    print(f"  Descargando {category}...", end=" ", flush=True)

    for filename in filenames:
        url = f"{BASE_URL}/{category}/{filename}"
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "MikroTik-Blacklist-Generator/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = resp.read().decode("utf-8", errors="ignore")
                domains = set()
                for line in data.splitlines():
                    line = line.strip().lower()
                    if line and not line.startswith("#"):
                        domains.add(line)
                print(f"{len(domains)} dominios", end="")
                if filename != "domains":
                    print(f" ({filename})", end="")
                print()
                return domains
        except urllib.error.HTTPError:
            continue
        except Exception as e:
            print(f"ERROR: {e}")
            return set()

    print("ERROR: no se encontró archivo de dominios")
    return set()


def apply_whitelist(domains: set[str]) -> set[str]:
    """Remueve dominios de la whitelist y sus subdominios."""
    return {
        d for d in domains
        if not any(d == w or d.endswith(f".{w}") for w in WHITELIST)
    }


def generate_rsc(domains: list[str], output_path: str, stats: dict):
    """Genera el archivo .rsc con las entradas DNS estáticas."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")

    with open(output_path, "w") as f:
        f.write(f"# Blacklist DNS para MikroTik - ITS Villada\n")
        f.write(f"# Generada: {timestamp}\n")
        f.write(f"# Total dominios: {len(domains)}\n")
        f.write(f"# Fuente: https://github.com/olbat/ut1-blacklists\n")
        for cat, count in stats.items():
            f.write(f"#   {cat}: {count}\n")
        f.write(f"\n")

        # Limpiar entradas anteriores
        f.write(":log info \"Blacklist: Limpiando entradas anteriores...\"\n")
        f.write("/ip dns static remove [find comment=\"blacklist-ut1\"]\n")
        f.write(":delay 1s\n\n")

        # Agregar en bloques con log de progreso
        block_size = 5000
        for i, domain in enumerate(domains):
            if i % block_size == 0 and i > 0:
                f.write(f":log info \"Blacklist: {i}/{len(domains)} entradas procesadas...\"\n")
            f.write(
                f"/ip dns static add name=\"{domain}\" type=NXDOMAIN "
                f"match-subdomain=yes ttl=1h comment=\"blacklist-ut1\"\n"
            )

        f.write(f"\n:log info \"Blacklist: Importacion completa. {len(domains)} dominios bloqueados.\"\n")

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"\nArchivo generado: {output_path}")
    print(f"Total de entradas: {len(domains)}")
    print(f"Tamaño: {size_mb:.1f} MB")


def serve_file(output_path: str, port: int):
    """Sirve el archivo via HTTP para que el MikroTik lo descargue."""
    directory = os.path.dirname(os.path.abspath(output_path))

    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=directory, **kwargs)

    server = http.server.HTTPServer(("0.0.0.0", port), Handler)
    filename = os.path.basename(output_path)
    print(f"\nSirviendo en http://0.0.0.0:{port}/{filename}")
    print("El MikroTik puede descargar desde esta URL.")
    print("Ctrl+C para detener.\n")
    server.serve_forever()


def main():
    parser = argparse.ArgumentParser(description="Genera blacklist DNS para MikroTik")
    parser.add_argument("--output", "-o", default="blacklist-dns.rsc",
                        help="Ruta del archivo .rsc (default: blacklist-dns.rsc)")
    parser.add_argument("--serve", "-s", type=int, metavar="PORT",
                        help="Servir el archivo via HTTP en este puerto")
    parser.add_argument("--max-domains", "-m", type=int, default=DEFAULT_MAX_DOMAINS,
                        help=f"Máximo de dominios a incluir (default: {DEFAULT_MAX_DOMAINS})")
    parser.add_argument("--no-limit", action="store_true",
                        help="Sin límite de dominios (cuidado con la RAM del MikroTik)")
    args = parser.parse_args()

    max_domains = None if args.no_limit else args.max_domains

    print("=== Generador de Blacklist DNS para MikroTik ===\n")
    if max_domains:
        print(f"Límite: {max_domains:,} dominios (ajustar con --max-domains)\n")

    # Descargar por prioridad
    category_domains: dict[str, set[str]] = {}
    for cat, priority in CATEGORIES:
        domains = download_category(cat)
        domains = apply_whitelist(domains)
        category_domains[cat] = domains

    # Construir lista final.
    # Estrategia: primero incluir completas las categorías que caben,
    # luego llenar el espacio restante con las categorías más grandes.
    final_domains: list[str] = []
    seen: set[str] = set()
    stats: dict[str, int] = {}

    # Paso 1: categorías que caben completas (ordenadas por prioridad)
    large_cats = []  # categorías que no caben completas, para el paso 2
    for cat, _ in CATEGORIES:
        unique = category_domains[cat] - seen
        if not max_domains or (len(final_domains) + len(unique)) <= max_domains:
            for domain in sorted(unique):
                final_domains.append(domain)
                seen.add(domain)
            stats[cat] = len(unique)
        else:
            large_cats.append(cat)

    # Paso 2: repartir el espacio restante proporcionalmente entre las grandes
    if large_cats and max_domains:
        remaining_space = max_domains - len(final_domains)
        total_large = sum(len(category_domains[c] - seen) for c in large_cats)
        for cat in large_cats:
            unique = category_domains[cat] - seen
            # Proporción del espacio restante según tamaño relativo
            share = int(remaining_space * len(unique) / total_large) if total_large > 0 else 0
            added = 0
            for domain in sorted(unique):
                if added >= share:
                    break
                final_domains.append(domain)
                seen.add(domain)
                added += 1
            stats[cat] = added
    elif large_cats:
        # Sin límite, incluir todo
        for cat in large_cats:
            unique = category_domains[cat] - seen
            for domain in sorted(unique):
                final_domains.append(domain)
                seen.add(domain)
            stats[cat] = len(unique)

    if max_domains and len(final_domains) >= max_domains:
        print(f"\n  Límite de {max_domains:,} dominios alcanzado.")

    print(f"\nResumen por categoría:")
    for cat, count in stats.items():
        total = len(category_domains.get(cat, set()))
        if count < total:
            print(f"  {cat}: {count:,} / {total:,} (truncada)")
        else:
            print(f"  {cat}: {count:,}")

    generate_rsc(final_domains, args.output, stats)

    if args.serve:
        serve_file(args.output, args.serve)


if __name__ == "__main__":
    main()
