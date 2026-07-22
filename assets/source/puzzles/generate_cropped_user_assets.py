#!/usr/bin/env python3
"""Generate PR1 WebP derivatives from local user-provided PNG staging inputs.

Offline only. No network. Root PNGs stay staging-only; generated WebPs use
`-pending` filenames to avoid overwriting existing published atlas/castle art.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE_DIR = ROOT / "assets" / "images"
PROVENANCE_PATH = ROOT / "assets" / "source" / "puzzles" / "provenance.json"
FULL_SIZE = 1024
THUMB_SIZE = 256
WEBP_QUALITY = 86


@dataclass(frozen=True)
class SourcePlan:
    source: str
    candidate_id: str
    output_id: str
    category: str
    mapping_status: str
    gate: str


PLANS = [
    SourcePlan("astro", "atlas-astronaut", "atlas-astronaut-pending", "space", "approved", "confirm astronaut semantics"),
    SourcePlan("camiones", "atlas-truck", "atlas-truck-pending", "vehicles", "pending", "ask if fleet/emergency semantics differ"),
    SourcePlan("car", "atlas-race-car", "atlas-race-car-pending", "vehicles", "pending", "ask if generic car vs race car differs"),
    SourcePlan("castillo", "castle-bright", "castle-bright-pending", "castles", "pending", "ask if princess scene semantics appear"),
    SourcePlan("castillo-princesa", "atlas-princess-castle", "atlas-princess-castle-pending", "castles", "pending", "high-risk: do not touch published castillo-princesa without explicit approval"),
    SourcePlan("dinosaurios", "atlas-dinosaurs", "atlas-dinosaurs-pending", "dinosaurs", "approved", "confirm dinosaurs semantics"),
    SourcePlan("doctora", "atlas-doctor", "atlas-doctor-pending", "professions", "approved", "confirm doctor semantics"),
    SourcePlan("princesa", "princess-crown", "princess-crown-pending", "princesses", "pending", "ask if crown vs princess portrait differs"),
    SourcePlan("animales", "atlas-animals", "atlas-animals-pending", "animals", "pending", "ask if animal group vs single animal differs"),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def file_meta(path: Path, *, width: int, height: int, format_name: str) -> dict[str, object]:
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "format": format_name,
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
        "dimensions": {"width": width, "height": height},
    }


def centered_square_box(width: int, height: int) -> tuple[int, int, int, int]:
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return (left, top, left + side, top + side)


def write_webp(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(
        path,
        "WEBP",
        quality=WEBP_QUALITY,
        method=6,
        exact=True,
    )


def generate() -> dict[str, object]:
    records = []
    for plan in PLANS:
        source_path = SOURCE_DIR / f"{plan.source}.png"
        if not source_path.exists():
            raise FileNotFoundError(f"Missing required staging input: {source_path.relative_to(ROOT).as_posix()}")

        with Image.open(source_path) as source_image:
            width, height = source_image.size
            crop_box = centered_square_box(width, height)
            cropped = source_image.convert("RGB").crop(crop_box)
            full_path = SOURCE_DIR / plan.category / f"{plan.output_id}.webp"
            thumb_path = SOURCE_DIR / plan.category / f"{plan.output_id}_thumb.webp"
            write_webp(cropped, full_path, FULL_SIZE)
            write_webp(cropped, thumb_path, THUMB_SIZE)

        records.append(
            {
                "source": file_meta(source_path, width=width, height=height, format_name="png"),
                "sourceUri": f"project-owned://assets/images/{plan.source}.png",
                "provenance": "user-provided",
                "license": "PROJECT-OWNED",
                "candidateId": plan.candidate_id,
                "outputId": plan.output_id,
                "category": plan.category,
                "mappingStatus": plan.mapping_status,
                "approved": plan.mapping_status == "approved",
                "approvalGate": plan.gate,
                "cropBox": list(crop_box),
                "full": file_meta(full_path, width=FULL_SIZE, height=FULL_SIZE, format_name="webp"),
                "thumbnail": file_meta(thumb_path, width=THUMB_SIZE, height=THUMB_SIZE, format_name="webp"),
            }
        )

    provenance = {
        "change": "puzzle-kids-cropped-assets-integration",
        "slice": "PR1",
        "policy": {
            "rootPngs": "local-staging-only",
            "network": "forbidden",
            "emojiAssets": "forbidden",
            "preSlicedPieces": "forbidden",
            "publishedAtlasOverwrite": "forbidden-in-pr1",
            "catalogRuntimeMapping": "deferred-to-pr2",
        },
        "generation": {
            "script": "assets/source/puzzles/generate_cropped_user_assets.py",
            "format": "webp",
            "quality": WEBP_QUALITY,
            "fullSize": {"width": FULL_SIZE, "height": FULL_SIZE},
            "thumbnailSize": {"width": THUMB_SIZE, "height": THUMB_SIZE},
            "cropPolicy": "center square crop from each root PNG, then Lanczos resize",
        },
        "sources": records,
    }
    PROVENANCE_PATH.write_text(json.dumps(provenance, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return provenance


if __name__ == "__main__":
    result = generate()
    source_count = len(result["sources"])
    derivative_count = source_count * 2
    print(f"Generated {derivative_count} WebP derivatives from {source_count} staging PNGs")
