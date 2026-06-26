extends Control
class_name UIcon

enum IconType {
	CROWN,
	STAR,
	COIN,
	SWORDS,
	BACK_ARROW,
	SCROLL,
	CARD,
	GRID,
	PLAY,
	RESET,
	CROSS,
	TROPHY,
	HEART,
	SHIELD,
	GEM,
	HOME,
	GEAR,
}

@export var icon: IconType = IconType.STAR
@export var icon_color: Color = Color(1.0, 1.0, 1.0, 0.9)

const _S: float = 32.0
const _H: float = _S * 0.5
const _Q: float = _S * 0.25


func _draw() -> void:
	match icon:
		IconType.CROWN:    _draw_crown()
		IconType.STAR:     _draw_star()
		IconType.COIN:     _draw_coin()
		IconType.SWORDS:   _draw_swords()
		IconType.BACK_ARROW: _draw_back_arrow()
		IconType.SCROLL:   _draw_scroll()
		IconType.CARD:     _draw_card()
		IconType.GRID:     _draw_grid()
		IconType.PLAY:     _draw_play()
		IconType.RESET:    _draw_reset()
		IconType.CROSS:    _draw_cross()
		IconType.TROPHY:   _draw_trophy()
		IconType.HEART:    _draw_heart()
		IconType.SHIELD:   _draw_shield()
		IconType.GEM:      _draw_gem()
		IconType.HOME:     _draw_home()
		IconType.GEAR:     _draw_gear()


func _draw_crown() -> void:
	var base_y := _S * 0.72
	var pts := PackedVector2Array([
		Vector2(2, base_y), Vector2(_S - 2, base_y),
		Vector2(_S - 2, _S - 2), Vector2(2, _S - 2),
	])
	draw_colored_polygon(pts, icon_color)
	var tips: Array[Vector2] = [
		Vector2(_H, 3),
		Vector2(_H - _Q, base_y - 4),
		Vector2(_H + _Q, base_y - 4),
	]
	draw_colored_polygon(PackedVector2Array(tips), icon_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(_H + _Q + 2, base_y - 4),
		Vector2(_H - _Q - 2, base_y - 4),
		Vector2(_H, 3),
	]), icon_color.lightened(0.15))


func _draw_star() -> void:
	var cx := _H; var cy := _H; var r_outer := _H * 0.9; var r_inner := _H * 0.38
	var pts: Array[Vector2] = []
	for i in 5:
		var a_outer: float = (deg_to_rad(-90.0 + 72.0 * i))
		var a_inner: float = (deg_to_rad(-90.0 + 36.0 + 72.0 * i))
		pts.append(Vector2(cx + cos(a_outer) * r_outer, cy + sin(a_outer) * r_outer))
		pts.append(Vector2(cx + cos(a_inner) * r_inner, cy + sin(a_inner) * r_inner))
	draw_colored_polygon(PackedVector2Array(pts), icon_color)


func _draw_coin() -> void:
	var cx := _H; var cy := _H; var r := _H * 0.82
	draw_circle(Vector2(cx, cy), r, icon_color)
	draw_arc(Vector2(cx, cy), r * 0.65, 0.0, PI * 2, 16, icon_color.darkened(0.25), 1.5)


func _draw_swords() -> void:
	var w := 1.8
	draw_line(Vector2(4, _S - 4), Vector2(_S - 4, 4), icon_color, w)
	draw_line(Vector2(4, 4), Vector2(_S - 4, _S - 4), icon_color, w)
	draw_circle(Vector2(4, _S - 4), 2.5, icon_color.lightened(0.2))
	draw_circle(Vector2(_S - 4, 4), 2.5, icon_color.lightened(0.2))


func _draw_back_arrow() -> void:
	var pts := PackedVector2Array([
		Vector2(_S - 6, 6), Vector2(8, _H), Vector2(_S - 6, _S - 6),
	])
	draw_colored_polygon(pts, icon_color)
	draw_line(Vector2(8, _H), Vector2(_S - 2, _H), icon_color, 3.0)


func _draw_scroll() -> void:
	var m := 3.0
	draw_rect(Rect2(m, m + 4, _S - m * 2, _S - m * 2 - 8), icon_color, false, 1.5)
	draw_rect(Rect2(m + 6, m, _S - m * 2 - 12, 8), icon_color)
	draw_rect(Rect2(m + 6, _S - m - 8, _S - m * 2 - 12, 8), icon_color)


func _draw_card() -> void:
	var r := Rect2(4, 5, _S - 8, _S - 10)
	draw_rect(r, icon_color, false, 1.5, 3)
	draw_rect(Rect2(r.position.x + 5, r.position.y + 5, r.size.x - 10, 8), icon_color)
	draw_rect(Rect2(r.position.x + 5, r.position.y + 16, r.size.x - 14, 6), icon_color.darkened(0.25))


func _draw_grid() -> void:
	var gap := 2.0; var sz := (_S - gap * 3) / 2.0
	for r in 2:
		for c in 2:
			draw_rect(Rect2(gap + c * (sz + gap), gap + r * (sz + gap), sz, sz), icon_color, false, 1.0)


func _draw_play() -> void:
	var pts := PackedVector2Array([
		Vector2(8, 5), Vector2(8, _S - 5), Vector2(_S - 5, _H),
	])
	draw_colored_polygon(pts, icon_color)


func _draw_reset() -> void:
	var cx := _H; var cy := _H; var r := _H * 0.7
	draw_arc(Vector2(cx, cy), r, deg_to_rad(-150.0), deg_to_rad(80.0), 24, icon_color, 2.5)
	var tip := Vector2(cx + cos(deg_to_rad(80.0)) * r, cy + sin(deg_to_rad(80.0)) * r)
	var a1 := deg_to_rad(80.0) + PI * 0.7
	var a2 := deg_to_rad(80.0) - PI * 0.7
	var s := 5.0
	draw_colored_polygon(PackedVector2Array([
		tip,
		tip + Vector2(cos(a1) * s, sin(a1) * s),
		tip + Vector2(cos(a2) * s, sin(a2) * s),
	]), icon_color)


func _draw_cross() -> void:
	draw_line(Vector2(4, 4), Vector2(_S - 4, _S - 4), icon_color, 2.5)
	draw_line(Vector2(_S - 4, 4), Vector2(4, _S - 4), icon_color, 2.5)


func _draw_trophy() -> void:
	var m := 3.0; var cup_w := _S - 16
	var stem_w := 5.0; var stem_h := 8.0
	draw_rect(Rect2(8, 5, cup_w, _S - stem_h - 8), icon_color, false, 1.5)
	draw_rect(Rect2(_H - stem_w * 0.5, _S - stem_h - 3, stem_w, stem_h + 3), icon_color)
	draw_rect(Rect2(_H - 9, 3, 18, 4), icon_color)
	draw_rect(Rect2(8, _S * 0.3, cup_w, 8), icon_color.darkened(0.15), true)


func _draw_heart() -> void:
	var cx := _H; var cy := _H + 2; var s := _H * 0.65
	var pts := PackedVector2Array([
		Vector2(cx, cy + s),
		Vector2(cx - s, cy - s * 0.3),
		Vector2(cx - s * 0.5, cy - s * 0.9),
		Vector2(cx, cy - s * 0.2),
		Vector2(cx + s * 0.5, cy - s * 0.9),
		Vector2(cx + s, cy - s * 0.3),
	])
	draw_colored_polygon(pts, icon_color)


func _draw_shield() -> void:
	var pts := PackedVector2Array([
		Vector2(_H, 3),
		Vector2(_S - 4, 8),
		Vector2(_S - 4, _H),
		Vector2(_H, _S - 4),
		Vector2(4, _H),
		Vector2(4, 8),
	])
	draw_colored_polygon(pts, icon_color)
	var inner: Array[Vector2] = []
	for i in pts.size():
		var p := pts[i]
		inner.append(Vector2(p.x + (4.0 if p.x < _H else -4.0), p.y + 4.0))
		inner.append(pts[i])
	draw_colored_polygon(PackedVector2Array([
		Vector2(_H, 7),
		Vector2(_S - 8, 12),
		Vector2(_S - 8, _H),
		Vector2(_H, _S - 8),
		Vector2(8, _H),
		Vector2(8, 12),
	]), icon_color.lightened(0.2))


func _draw_gem() -> void:
	var pts := PackedVector2Array([
		Vector2(_H, 2), Vector2(_S - 3, _H),
		Vector2(_H, _S - 4), Vector2(3, _H),
	])
	draw_colored_polygon(pts, icon_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(_H, 8), Vector2(_S - 8, _H),
		Vector2(_H, _S - 10), Vector2(8, _H),
	]), icon_color.lightened(0.3))


func _draw_home() -> void:
	draw_rect(Rect2(_H - 10, _H + 2, 20, 16), icon_color)
	var pts := PackedVector2Array([
		Vector2(_H, 4), Vector2(6, _H + 3), Vector2(_S - 6, _H + 3),
	])
	draw_colored_polygon(pts, icon_color)


func _draw_gear() -> void:
	var cx := _H; var cy := _H; var r_outer := _H * 0.7; var r_inner := _H * 0.4
	draw_circle(Vector2(cx, cy), r_outer, icon_color, false, 1.5)
	draw_circle(Vector2(cx, cy), r_inner, icon_color, false, 1.5)
	draw_circle(Vector2(cx, cy), 2.0, icon_color)
	for i in 6:
		var a: float = deg_to_rad(float(i) * 60.0)
		var p := Vector2(cx + cos(a) * r_outer, cy + sin(a) * r_outer)
		draw_circle(p, 3.5, icon_color)
