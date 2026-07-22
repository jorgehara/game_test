#!/usr/bin/env python3
"""Extract Puzzle Kids atlas panels into offline WebP puzzle assets.

Source provenance:
- `assets/images/varios-assets.png` is project-owner provided art.
- On 2026-07-22 the user explicitly confirmed ownership and authorized using
  and publishing derived puzzle assets.

This script is deterministic and offline. It does not add catalog/manifest
runtime records; PR1 only creates derived files and measured metadata for PR2.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/images/varios-assets.png"
METADATA = ROOT / "assets/source/puzzles/atlas_crop_metadata.json"
FULL_SIZE = 1024
THUMB_SIZE = 256
WEBP_QUALITY = 86


@dataclass(frozen=True)
class Panel:
    id: str
    name_es: str
    category: str
    level: int
    panel_box: tuple[int, int, int, int]
    crop_box: tuple[int, int, int, int]

    @property
    def full_path(self) -> Path:
        return ROOT / f"assets/images/{self.category}/{self.id}.webp"

    @property
    def thumb_path(self) -> Path:
        return ROOT / f"assets/images/{self.category}/{self.id}_thumb.webp"


PANELS = [
    Panel("atlas-dinosaurs", "Dinosaurios aventureros", "dinosaurs", 4, (0, 0, 467, 374), (46, 0, 420, 374)),
    Panel("atlas-race-car", "Auto de carrera", "vehicles", 4, (467, 0, 934, 374), (513, 0, 887, 374)),
    Panel("atlas-princess-castle", "Princesa y castillo", "castles", 2, (934, 0, 1402, 374), (981, 0, 1355, 374)),
    Panel("atlas-doctor", "Médica amable", "professions", 2, (0, 374, 467, 748), (46, 374, 420, 748)),
    Panel("atlas-astronaut", "Astronauta espacial", "space", 4, (467, 374, 934, 748), (513, 374, 887, 748)),
    Panel("atlas-animals", "Animales amigos", "animals", 2, (934, 374, 1402, 748), (981, 374, 1355, 748)),
    Panel("atlas-airplane", "Avión alegre", "vehicles", 2, (0, 748, 467, 1122), (46, 748, 420, 1122)),
    Panel("atlas-truck", "Camión de trabajo", "vehicles", 2, (467, 748, 934, 1122), (513, 748, 887, 1122)),
    Panel("atlas-emergency-vehicles", "Vehículos de emergencia", "vehicles", 4, (934, 748, 1402, 1122), (981, 748, 1355, 1122)),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def save_webp(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(path, "WEBP", quality=WEBP_QUALITY, method=6)


def file_metadata(path: Path) -> dict[str, object]:
    with Image.open(path) as image:
        width, height = image.size
        fmt = image.format.lower()
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "format": fmt,
        "width": width,
        "height": height,
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
    }


def main() -> None:
    with Image.open(SOURCE) as atlas:
        if atlas.size != (1402, 1122):
            raise SystemExit(f"Unexpected atlas size: {atlas.size}")
        atlas = atlas.convert("RGB")

        outputs = []
        for panel in PANELS:
            cropped = atlas.crop(panel.crop_box)
            save_webp(cropped, panel.full_path, FULL_SIZE)
            save_webp(cropped, panel.thumb_path, THUMB_SIZE)

            full = file_metadata(panel.full_path)
            thumb = file_metadata(panel.thumb_path)
            if full["bytes"] > 800 * 1024:
                raise SystemExit(f"Full image cap exceeded: {full['path']} {full['bytes']}")
            if thumb["bytes"] > 80 * 1024:
                raise SystemExit(f"Thumbnail cap exceeded: {thumb['path']} {thumb['bytes']}")

            outputs.append({
                "id": panel.id,
                "nameEs": panel.name_es,
                "category": panel.category,
                "level": panel.level,
                "panelBox": panel.panel_box,
                "cropBox": panel.crop_box,
                "full": full,
                "thumbnail": thumb,
            })

    metadata = {
        "change": "puzzle-kids-atlas-assets",
        "slice": "PR1",
        "source": {
            "path": SOURCE.relative_to(ROOT).as_posix(),
            "title": "varios-assets.png local atlas",
            "dimensions": {"width": 1402, "height": 1122},
            "bytes": SOURCE.stat().st_size,
            "sha256": sha256(SOURCE),
            "license": "PROJECT-OWNED",
            "provenance": "User/project owner explicitly confirmed ownership and authorized using/publishing derived assets on 2026-07-22.",
            "bundling": "Source atlas remains local input only; do not stage or reference it in pubspec/catalog.",
        },
        "generation": {
            "fullSize": {"width": FULL_SIZE, "height": FULL_SIZE},
            "thumbnailSize": {"width": THUMB_SIZE, "height": THUMB_SIZE},
            "format": "webp",
            "quality": WEBP_QUALITY,
            "cropPolicy": "Explicit 3x3 panel boxes from 1402x1122 atlas, then centered 374x374 square crop per panel to avoid horizontal remainder drift and neighboring-panel bleed.",
        },
        "outputs": outputs,
    }
    METADATA.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"outputs": len(outputs), "files": len(outputs) * 2}, indent=2))


if __name__ == "__main__":
    main()
