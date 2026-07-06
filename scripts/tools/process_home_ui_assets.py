from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "image2.0" / "shouye"
TARGET_DIR = ROOT / "assets" / "ui" / "home"
PROCESSED_DIR = TARGET_DIR / "processed"
REPORT_PATH = TARGET_DIR / "home_ui_asset_report.json"

EXPECTED_FILES = [
    "icon_star_core_default.png",
    "icon_star_core_hover.png",
    "icon_star_core_pressed.png",
    "icon_star_core_matching.png",
    "icon_quest_default.png",
    "icon_quest_hover.png",
    "icon_quest_pressed.png",
    "icon_activity_default.png",
    "icon_activity_hover.png",
    "icon_activity_pressed.png",
    "icon_deck_default.png",
    "icon_deck_hover.png",
    "icon_deck_pressed.png",
    "icon_codex_default.png",
    "icon_codex_hover.png",
    "icon_codex_pressed.png",
    "icon_summon_default.png",
    "icon_summon_hover.png",
    "icon_summon_pressed.png",
    "icon_report_default.png",
    "icon_report_hover.png",
    "icon_settings_default.png",
    "icon_settings_hover.png",
    "icon_settings_pressed.png",
    "icon_mail_default.png",
    "icon_mail_hover.png",
    "icon_mail_pressed.png",
    "icon_friends_default.png",
    "icon_friends_hover.png",
    "icon_friends_pressed.png",
    "panel_player_bg.png",
    "panel_player_avatar_frame.png",
    "panel_player_exp_bar_bg.png",
    "panel_player_exp_bar_fill.png",
    "star_map_background.png",
    "star_map_orbit_layer.png",
    "star_map_node.png",
    "star_map_glow.png",
    "panel_topbar_bg.png",
    "icon_coin.png",
    "icon_star_coin.png",
    "icon_star_track.png",
]

OPAQUE_BACKGROUND_ALLOWED = {
    "star_map_background.png",
}

GLOBAL_LOW_SAT_CLEAR = {
    "panel_player_avatar_frame.png",
}


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return sum((a[i] - b[i]) ** 2 for i in range(3)) ** 0.5


def background_color(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    w, h = rgba.size
    samples = [
        rgba.getpixel((0, 0)),
        rgba.getpixel((w - 1, 0)),
        rgba.getpixel((0, h - 1)),
        rgba.getpixel((w - 1, h - 1)),
        rgba.getpixel((w // 2, 0)),
        rgba.getpixel((w // 2, h - 1)),
        rgba.getpixel((0, h // 2)),
        rgba.getpixel((w - 1, h // 2)),
    ]
    return tuple(round(sum(px[i] for px in samples) / len(samples)) for i in range(3))


def has_clean_alpha(image: Image.Image) -> bool:
    if "A" not in image.getbands():
        return False
    rgba = image.convert("RGBA")
    w, h = rgba.size
    points = [
        (0, 0),
        (w - 1, 0),
        (0, h - 1),
        (w - 1, h - 1),
        (w // 2, 0),
        (w // 2, h - 1),
        (0, h // 2),
        (w - 1, h // 2),
    ]
    return all(rgba.getpixel(pt)[3] == 0 for pt in points)


def is_edge_background_pixel(
    rgb: tuple[int, int, int],
    seed_rgb: tuple[int, int, int],
    tolerance: float,
) -> bool:
    r, g, b = rgb
    brightness = (r + g + b) / 3.0
    saturation = max(rgb) - min(rgb)
    if color_distance(rgb, seed_rgb) <= tolerance:
        return True
    if saturation <= 28 and (brightness >= 210 or brightness <= 48):
        return True
    if saturation <= 18 and 58 <= brightness <= 218:
        return True
    return False


def flood_background_mask(image: Image.Image, tolerance: float) -> set[tuple[int, int]]:
    rgba = image.convert("RGBA")
    w, h = rgba.size
    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()
    seed_color: dict[tuple[int, int], tuple[int, int, int]] = {}
    seeds = []
    step = max(1, min(w, h) // 64)
    for x in range(0, w, step):
        seeds.append((x, 0))
        seeds.append((x, h - 1))
    for y in range(0, h, step):
        seeds.append((0, y))
        seeds.append((w - 1, y))
    for point in seeds:
        q.append(point)
        seen.add(point)
        seed_color[point] = rgba.getpixel(point)[:3]
    while q:
        x, y = q.popleft()
        seed_rgb = seed_color[(x, y)]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen:
                nr, ng, nb, _ = rgba.getpixel((nx, ny))
                if is_edge_background_pixel((nr, ng, nb), seed_rgb, tolerance):
                    seen.add((nx, ny))
                    seed_color[(nx, ny)] = seed_rgb
                    q.append((nx, ny))
    return seen


def clear_global_low_saturation_background(image: Image.Image) -> Image.Image:
    out = image.convert("RGBA")
    pix = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a == 0:
                continue
            brightness = (r + g + b) / 3.0
            saturation = max(r, g, b) - min(r, g, b)
            if saturation <= 24 and (brightness >= 205 or brightness <= 45 or 58 <= brightness <= 218):
                pix[x, y] = (r, g, b, 0)
    return out


def transparentize(image: Image.Image, file_name: str) -> Image.Image:
    rgba = image.convert("RGBA")
    w, h = rgba.size
    bg = background_color(rgba)
    brightness = sum(bg) / 3.0
    tolerance = 34.0 if brightness > 200 or brightness < 35 else 26.0
    mask = flood_background_mask(rgba, tolerance)
    out = rgba.copy()
    pix = out.load()
    for x, y in mask:
        r, g, b, _ = pix[x, y]
        dist = color_distance((r, g, b), bg)
        saturation = max(r, g, b) - min(r, g, b)
        brightness = (r + g + b) / 3.0
        if saturation <= 28 and (brightness >= 210 or brightness <= 48):
            alpha = 0
        elif saturation <= 18 and 58 <= brightness <= 218:
            alpha = 0
        elif dist <= tolerance * 0.55:
            alpha = 0
        else:
            alpha = int(255 * min(1.0, max(0.0, (dist - tolerance * 0.55) / (tolerance * 0.45))))
        pix[x, y] = (r, g, b, alpha)
    if file_name in GLOBAL_LOW_SAT_CLEAR:
        out = clear_global_low_saturation_background(out)
    return out


def main() -> int:
    TARGET_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    report = []
    missing = []
    for name in EXPECTED_FILES:
        src = SOURCE_DIR / name
        if not src.exists():
            missing.append(name)
            continue
        raw = Image.open(src)
        target = TARGET_DIR / name
        raw.save(target)
        clean_alpha = has_clean_alpha(raw)
        mode = raw.mode
        action = "copied_clean_alpha" if clean_alpha else "copied_opaque_allowed"
        processed_path = None
        needs_art_fix = False
        if not clean_alpha and name not in OPAQUE_BACKGROUND_ALLOWED:
            processed = transparentize(raw, name)
            processed_path = PROCESSED_DIR / name
            processed.save(processed_path)
            if not has_clean_alpha(processed):
                needs_art_fix = True
                action = "processed_needs_art_fix"
            else:
                action = "processed_transparent"
        report.append(
            {
                "file": name,
                "source_mode": mode,
                "size": list(raw.size),
                "has_clean_alpha": clean_alpha,
                "used_path": ("res://assets/ui/home/processed/" + name)
                if processed_path is not None and not needs_art_fix
                else ("res://assets/ui/home/" + name),
                "processed_path": ("res://assets/ui/home/processed/" + name) if processed_path is not None else "",
                "action": action,
                "needs_art_fix": needs_art_fix,
            }
        )
    REPORT_PATH.write_text(json.dumps({"missing": missing, "assets": report}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"HOME_UI_ASSET_REPORT={REPORT_PATH}")
    print(f"HOME_UI_ASSET_MISSING={','.join(missing) if missing else 'NONE'}")
    print(f"HOME_UI_ASSET_COUNT={len(report)}")
    print(f"HOME_UI_ASSET_NEEDS_ART_FIX={sum(1 for item in report if item['needs_art_fix'])}")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
