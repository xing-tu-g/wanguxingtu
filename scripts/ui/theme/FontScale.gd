class_name FontScale
extends RefCounted

## Adaptive font sizing that scales with viewport width.
## Callers pass size.x from their Control.get_viewport_rect().

## Title / heading size — e.g. "万古星图", "星图对弈".
static func title_size(viewport_width: float) -> int:
	return clampi(int(viewport_width / 18.0), 36, 62)


## Body / paragraph size — e.g. battle log, result text, currency labels.
static func body_size(viewport_width: float) -> int:
	return clampi(int(viewport_width / 48.0), 18, 28)


## Small assist labels — e.g. zone bars, tutorial step text, version.
static func label_size(viewport_width: float) -> int:
	return clampi(int(viewport_width / 60.0), 12, 22)


## Hand card hero name size — slightly larger than body for readability.
static func hand_card_size(viewport_width: float) -> int:
	return clampi(int(viewport_width / 42.0), 20, 30)
