#!/usr/bin/env python3
"""Generate transparent pre-Android-8 launcher icons from the canonical brand asset."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/images/yours-icon-512.png"
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
BACKGROUND = (17, 17, 17)


def transparent_brand_icon(size: int) -> Image.Image:
    source = Image.open(SOURCE).convert("RGB")
    pixels = []
    for red, green, blue in source.getdata():
        distance = max(abs(red - BACKGROUND[0]), abs(green - BACKGROUND[1]), abs(blue - BACKGROUND[2]))
        alpha = max(0, min(255, round(distance * 255 / 221)))
        if alpha == 0:
            pixels.append((0, 0, 0, 0))
            continue
        coverage = alpha / 255
        restored = tuple(
            max(0, min(255, round((channel - background * (1 - coverage)) / coverage)))
            for channel, background in zip((red, green, blue), BACKGROUND)
        )
        pixels.append((*restored, alpha))
    source_with_alpha = Image.new("RGBA", source.size)
    source_with_alpha.putdata(pixels)
    return source_with_alpha.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    for density, size in SIZES.items():
        destination = ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        transparent_brand_icon(size).save(destination, optimize=True)
        print(destination.relative_to(ROOT))


if __name__ == "__main__":
    main()
