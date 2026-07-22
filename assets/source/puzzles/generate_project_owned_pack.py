#!/usr/bin/env python3
"""Generate Puzzle Kids PROJECT-OWNED starter puzzle art.

No network, no external image sources, no third-party rendering dependencies.
The SVG files are editable source art; the PNG files are deterministic raster
exports produced with Python stdlib only.
"""

from __future__ import annotations

import hashlib
import json
import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
FULL_SIZE = 512
THUMB_SIZE = 256
APPROVED_AT = "2026-07-22T00:00:00Z"
APPROVED_BY = "Puzzle Kids project owner"
ATTRIBUTION = "Puzzle Kids PROJECT-OWNED original local vector artwork."


PACK = [
    ("castle-bright", "Castillo brillante", "castles", "Castillo con torres redondas", 2, "castle"),
    ("princess-crown", "Corona de princesa", "princesses", "Corona amable de princesa", 2, "crown"),
    ("unicorn-cloud", "Unicornio nube", "unicorns", "Unicornio sobre una nube", 2, "unicorn"),
    ("dragon-kite", "Dragón barrilete", "dinosaurs", "Dragón bebé con barrilete", 4, "dragon"),
    ("mermaid-lagoon", "Laguna sirena", "ocean", "Sirena entre olas suaves", 2, "mermaid"),
    ("rocket-moon", "Cohete lunar", "space", "Cohete feliz rumbo a la luna", 4, "rocket"),
    ("fox-forest", "Zorro del bosque", "animals", "Zorro naranja entre hojas", 2, "fox"),
    ("rainbow-bus", "Colectivo arcoíris", "vehicles", "Colectivo escolar de colores", 2, "bus"),
    ("berry-cupcake", "Cupcake de frutillas", "fruits", "Cupcake frutal con sonrisa", 2, "cupcake"),
]


PALETTES = {
    "castle": ("#9fd7ff", "#7c5cff", "#ffd166", "#ef476f", "#4cc9f0"),
    "crown": ("#ffe5f1", "#ffafcc", "#ffd166", "#b5179e", "#80ed99"),
    "unicorn": ("#e7f7ff", "#ffffff", "#c77dff", "#ffcad4", "#ffd166"),
    "dragon": ("#e8ffe8", "#57cc99", "#22577a", "#ff9f1c", "#f72585"),
    "mermaid": ("#dff8ff", "#00b4d8", "#48cae4", "#ffafcc", "#ffd166"),
    "rocket": ("#eee8ff", "#4361ee", "#f72585", "#ffd166", "#4cc9f0"),
    "fox": ("#fff1d6", "#f77f00", "#6d4c41", "#80ed99", "#ffd166"),
    "bus": ("#e6fbff", "#ffd166", "#ef476f", "#118ab2", "#80ed99"),
    "cupcake": ("#fff0f5", "#ffafcc", "#f28482", "#ffd166", "#80ed99"),
}


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def blend(canvas, x: int, y: int, color: tuple[int, int, int], alpha: float = 1.0):
    if x < 0 or y < 0 or y >= len(canvas) or x >= len(canvas[0]):
        return
    r, g, b = canvas[y][x]
    cr, cg, cb = color
    canvas[y][x] = (
        int(r * (1 - alpha) + cr * alpha),
        int(g * (1 - alpha) + cg * alpha),
        int(b * (1 - alpha) + cb * alpha),
    )


def rect(canvas, x0, y0, x1, y1, color):
    for y in range(max(0, y0), min(len(canvas), y1)):
        for x in range(max(0, x0), min(len(canvas[0]), x1)):
            canvas[y][x] = color


def circle(canvas, cx, cy, radius, color, alpha=1.0):
    r2 = radius * radius
    for y in range(max(0, cy - radius), min(len(canvas), cy + radius + 1)):
        for x in range(max(0, cx - radius), min(len(canvas[0]), cx + radius + 1)):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                blend(canvas, x, y, color, alpha)


def polygon(canvas, points, color):
    min_y = max(0, min(y for _, y in points))
    max_y = min(len(canvas) - 1, max(y for _, y in points))
    for y in range(min_y, max_y + 1):
        nodes = []
        j = len(points) - 1
        for i, (xi, yi) in enumerate(points):
            xj, yj = points[j]
            if (yi < y and yj >= y) or (yj < y and yi >= y):
                nodes.append(int(xi + (y - yi) / (yj - yi) * (xj - xi)))
            j = i
        nodes.sort()
        for i in range(0, len(nodes), 2):
            if i + 1 >= len(nodes):
                break
            rect(canvas, nodes[i], y, nodes[i + 1], y + 1, color)


def star(canvas, cx, cy, radius, color):
    points = []
    for i in range(10):
        angle = -math.pi / 2 + i * math.pi / 5
        r = radius if i % 2 == 0 else radius // 2
        points.append((int(cx + math.cos(angle) * r), int(cy + math.sin(angle) * r)))
    polygon(canvas, points, color)


def draw_art(kind: str, size: int):
    bg, primary, secondary, accent, extra = [hex_rgb(c) for c in PALETTES[kind]]
    c = [[bg for _ in range(size)] for _ in range(size)]
    s = size / 512
    S = lambda v: int(v * s)

    # shared sky/sparkle composition
    circle(c, S(430), S(78), S(54), secondary, 0.45)
    circle(c, S(92), S(92), S(28), (255, 255, 255), 0.75)
    circle(c, S(130), S(90), S(36), (255, 255, 255), 0.75)
    circle(c, S(170), S(98), S(28), (255, 255, 255), 0.75)
    for x, y in [(70, 380), (390, 160), (438, 342), (110, 202)]:
        star(c, S(x), S(y), S(16), secondary)

    if kind == "castle":
        rect(c, S(150), S(214), S(362), S(408), primary)
        rect(c, S(104), S(170), S(170), S(408), primary)
        rect(c, S(342), S(170), S(408), S(408), primary)
        polygon(c, [(S(96), S(170)), (S(137), S(106)), (S(178), S(170))], accent)
        polygon(c, [(S(334), S(170)), (S(375), S(106)), (S(416), S(170))], accent)
        polygon(c, [(S(150), S(214)), (S(256), S(132)), (S(362), S(214))], secondary)
        rect(c, S(224), S(308), S(288), S(408), accent)
        circle(c, S(256), S(308), S(32), accent)
    elif kind == "crown":
        polygon(c, [(S(104), S(344)), (S(152), S(162)), (S(232), S(284)), (S(256), S(128)), (S(300), S(284)), (S(384), S(162)), (S(408), S(344))], secondary)
        rect(c, S(120), S(328), S(392), S(386), secondary)
        for x in [152, 256, 384]:
            circle(c, S(x), S(160 if x != 256 else 126), S(28), accent)
        circle(c, S(256), S(286), S(34), primary)
    elif kind == "unicorn":
        circle(c, S(250), S(268), S(106), primary)
        polygon(c, [(S(250), S(128)), (S(288), S(224)), (S(218), S(224))], secondary)
        circle(c, S(188), S(216), S(36), primary)
        circle(c, S(322), S(216), S(36), primary)
        rect(c, S(188), S(350), S(224), S(420), primary)
        rect(c, S(292), S(350), S(328), S(420), primary)
        circle(c, S(294), S(274), S(14), (30, 30, 30))
        rect(c, S(330), S(256), S(420), S(286), accent)
    elif kind == "dragon":
        circle(c, S(256), S(278), S(104), primary)
        circle(c, S(330), S(216), S(58), primary)
        polygon(c, [(S(160), S(274)), (S(70), S(210)), (S(114), S(334))], extra)
        polygon(c, [(S(180), S(180)), (S(220), S(108)), (S(250), S(192))], accent)
        circle(c, S(350), S(202), S(10), (30, 30, 30))
        polygon(c, [(S(388), S(226)), (S(438), S(244)), (S(388), S(262))], secondary)
    elif kind == "mermaid":
        circle(c, S(256), S(176), S(54), accent)
        rect(c, S(224), S(228), S(288), S(324), secondary)
        polygon(c, [(S(256), S(318)), (S(140), S(426)), (S(238), S(388))], primary)
        polygon(c, [(S(256), S(318)), (S(372), S(426)), (S(274), S(388))], primary)
        for x in [96, 170, 342, 416]:
            circle(c, S(x), S(390), S(34), extra, 0.75)
    elif kind == "rocket":
        polygon(c, [(S(256), S(92)), (S(326), S(320)), (S(186), S(320))], primary)
        circle(c, S(256), S(204), S(36), extra)
        polygon(c, [(S(186), S(290)), (S(118), S(386)), (S(210), S(350))], accent)
        polygon(c, [(S(326), S(290)), (S(394), S(386)), (S(302), S(350))], accent)
        polygon(c, [(S(220), S(320)), (S(256), S(430)), (S(292), S(320))], secondary)
    elif kind == "fox":
        circle(c, S(256), S(278), S(100), primary)
        polygon(c, [(S(170), S(214)), (S(128), S(104)), (S(230), S(176))], primary)
        polygon(c, [(S(342), S(214)), (S(384), S(104)), (S(282), S(176))], primary)
        polygon(c, [(S(210), S(290)), (S(256), S(370)), (S(302), S(290))], (255, 255, 255))
        circle(c, S(222), S(262), S(12), (30, 30, 30))
        circle(c, S(290), S(262), S(12), (30, 30, 30))
        circle(c, S(256), S(302), S(10), (30, 30, 30))
    elif kind == "bus":
        rect(c, S(104), S(190), S(408), S(338), secondary)
        rect(c, S(136), S(224), S(212), S(282), extra)
        rect(c, S(236), S(224), S(312), S(282), extra)
        rect(c, S(324), S(224), S(380), S(282), extra)
        circle(c, S(174), S(350), S(34), accent)
        circle(c, S(338), S(350), S(34), accent)
        for i, col in enumerate([primary, accent, extra, (255, 255, 255)]):
            rect(c, S(104 + i * 76), S(176), S(180 + i * 76), S(198), col)
    elif kind == "cupcake":
        polygon(c, [(S(152), S(260)), (S(360), S(260)), (S(328), S(420)), (S(184), S(420))], secondary)
        circle(c, S(210), S(230), S(58), primary)
        circle(c, S(266), S(204), S(72), primary)
        circle(c, S(322), S(230), S(58), primary)
        circle(c, S(256), S(150), S(26), accent)
        circle(c, S(232), S(324), S(10), (30, 30, 30))
        circle(c, S(280), S(324), S(10), (30, 30, 30))
        rect(c, S(232), S(360), S(280), S(372), accent)
    return c


def write_png(path: Path, canvas):
    height = len(canvas)
    width = len(canvas[0])
    raw = b"".join(b"\x00" + bytes(v for pixel in row for v in pixel) for row in canvas)

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(
        b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def write_svg(path: Path, puzzle_id: str, name: str, kind: str):
    bg, primary, secondary, accent, extra = PALETTES[kind]
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-labelledby="title desc">
  <title id="title">{name}</title>
  <desc id="desc">PROJECT-OWNED Puzzle Kids vector source for {puzzle_id}; generated locally without external artwork.</desc>
  <rect width="512" height="512" rx="56" fill="{bg}"/>
  <circle cx="430" cy="78" r="54" fill="{secondary}" opacity="0.45"/>
  <circle cx="92" cy="92" r="28" fill="white" opacity="0.75"/>
  <circle cx="130" cy="90" r="36" fill="white" opacity="0.75"/>
  <circle cx="170" cy="98" r="28" fill="white" opacity="0.75"/>
  <path d="M70 364l7 14 15 2-11 11 3 15-14-7-14 7 3-15-11-11 15-2zM390 144l7 14 15 2-11 11 3 15-14-7-14 7 3-15-11-11 15-2zM438 326l7 14 15 2-11 11 3 15-14-7-14 7 3-15-11-11 15-2z" fill="{secondary}"/>
  <g fill="{primary}" stroke="rgba(0,0,0,.12)" stroke-width="8">
    <circle cx="256" cy="276" r="108"/>
  </g>
  <g fill="{accent}" opacity="0.9">
    <circle cx="220" cy="254" r="16"/><circle cx="292" cy="254" r="16"/>
    <rect x="216" y="330" width="80" height="18" rx="9"/>
  </g>
  <text x="256" y="470" text-anchor="middle" font-size="28" font-family="Verdana" fill="{extra}">{kind}</text>
</svg>
'''
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(svg, encoding="utf-8", newline="\n")


def metadata_for(path: Path) -> tuple[int, str]:
    data = path.read_bytes()
    return len(data), hashlib.sha256(data).hexdigest()


def main():
    manifest = []
    catalog = []
    source_root = ROOT / "assets" / "source" / "puzzles"
    image_root = ROOT / "assets" / "images"
    for puzzle_id, name, category, placeholder, level, kind in PACK:
        svg_path = source_root / f"{puzzle_id}.svg"
        full_rel = f"assets/images/{category}/{puzzle_id}.png"
        thumb_rel = f"assets/images/{category}/{puzzle_id}_thumb.png"
        full_path = ROOT / full_rel
        thumb_path = ROOT / thumb_rel

        write_svg(svg_path, puzzle_id, name, kind)
        write_png(full_path, draw_art(kind, FULL_SIZE))
        write_png(thumb_path, draw_art(kind, THUMB_SIZE))
        bytes_count, sha = metadata_for(full_path)

        manifest.append({
            "id": puzzle_id,
            "path": full_rel,
            "thumbnailPath": thumb_rel,
            "sourceTitle": f"Puzzle Kids original vector illustration - {name}",
            "sourceUrl": f"project-owned://assets/source/puzzles/{puzzle_id}.svg",
            "license": "PROJECT-OWNED",
            "licenseUrl": "project-owned://LICENSE",
            "attribution": ATTRIBUTION,
            "approved": True,
            "approvedBy": APPROVED_BY,
            "approvedAt": APPROVED_AT,
            "dimensions": {"width": FULL_SIZE, "height": FULL_SIZE},
            "format": "png",
            "bytes": bytes_count,
            "sha256": sha,
        })
        catalog.append({
            "id": puzzle_id,
            "name": name,
            "category": category,
            "level": level,
            "grid": {"rows": 3, "columns": 3} if level == 4 else {"rows": 2, "columns": 2},
            "image": full_rel,
            "thumbnail": thumb_rel,
            "placeholder": placeholder,
            "approved": True,
        })

    (ROOT / "assets" / "catalog" / "asset_licenses.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    (ROOT / "assets" / "catalog" / "puzzles.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )


if __name__ == "__main__":
    main()
