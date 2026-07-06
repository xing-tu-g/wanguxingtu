extends Control
class_name StarChartWorldLayer

@export_enum("outer", "orbit", "core") var layer_kind := "outer"
@export var animation_speed := 1.0
@export var intensity := 1.0
@export var hover_boost := 1.0

var _time := 0.0
var _stars: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_static_stars()


func _process(delta: float) -> void:
	_time += delta * animation_speed * hover_boost
	queue_redraw()


func set_hover_boost(value: float) -> void:
	hover_boost = maxf(0.1, value)


func set_intensity(value: float) -> void:
	intensity = maxf(0.0, value)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	match layer_kind:
		"outer":
			_draw_outer_starfield(center, radius)
		"orbit":
			_draw_orbit_system(center, radius)
		"core":
			_draw_core_energy(center, radius)


func _build_static_stars() -> void:
	_stars.clear()
	for index in range(90):
		var seed := float(index + 1)
		var angle := fmod(seed * 2.399963, TAU)
		var distance := 0.18 + fmod(seed * 0.173, 0.78)
		var drift := 0.12 + fmod(seed * 0.047, 0.22)
		var scale := 0.45 + fmod(seed * 0.071, 1.15)
		_stars.append({
			"angle": angle,
			"distance": distance,
			"drift": drift,
			"scale": scale,
		})


func _draw_outer_starfield(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.96, Color(0.04, 0.10, 0.20, 0.05 * intensity))
	for star in _stars:
		var angle := float(star.angle) + _time * float(star.drift) * 0.10
		var distance := radius * float(star.distance)
		var parallax := Vector2(cos(_time * 0.16), sin(_time * 0.11)) * radius * 0.025
		var pos := center + Vector2(cos(angle), sin(angle)) * distance + parallax
		var alpha := (0.20 + 0.18 * sin(_time * 1.4 + angle * 3.0)) * intensity
		draw_circle(pos, float(star.scale), Color(0.70, 0.90, 1.0, alpha))
	for ring_index in range(3):
		var orbit_radius := radius * (0.58 + ring_index * 0.13)
		var color := Color(0.88, 0.72, 0.38, (0.08 - ring_index * 0.012) * intensity)
		draw_arc(center, orbit_radius, -0.6 + ring_index * 0.45, PI * 1.14 + ring_index * 0.34, 96, color, 1.0, true)


func _draw_orbit_system(center: Vector2, radius: float) -> void:
	for ring_index in range(4):
		var orbit_radius := radius * (0.32 + ring_index * 0.13)
		var rotation := _time * (0.20 + ring_index * 0.08) * (1.0 if ring_index % 2 == 0 else -1.0)
		var color := Color(0.88, 0.70, 0.34, (0.28 - ring_index * 0.035) * intensity)
		var blue := Color(0.28, 0.78, 1.0, (0.20 - ring_index * 0.02) * intensity)
		draw_arc(center, orbit_radius, rotation, rotation + TAU * 0.86, 160, color, 2.0, true)
		draw_arc(center, orbit_radius * 0.92, rotation + PI * 0.42, rotation + PI * 1.35, 120, blue, 1.35, true)
		var node_angle := rotation + _time * (0.55 + ring_index * 0.17)
		var node_pos := center + Vector2(cos(node_angle), sin(node_angle)) * orbit_radius
		draw_circle(node_pos, 3.0 + ring_index * 0.35, Color(0.78, 0.94, 1.0, 0.62 * intensity))
	for line_index in range(7):
		var angle := _time * (0.32 + line_index * 0.045) + line_index * TAU / 7.0
		var start := center + Vector2(cos(angle), sin(angle)) * radius * 0.20
		var finish := center + Vector2(cos(angle + 0.52), sin(angle + 0.52)) * radius * 0.62
		draw_line(start, finish, Color(0.32, 0.84, 1.0, 0.10 * intensity), 1.4, true)


func _draw_core_energy(center: Vector2, radius: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 2.4)
	draw_circle(center, radius * (0.35 + pulse * 0.025), Color(0.08, 0.36, 0.62, 0.34 * intensity))
	draw_circle(center, radius * (0.21 + pulse * 0.018), Color(0.18, 0.62, 0.86, 0.28 * intensity))
	draw_arc(center, radius * 0.29, _time * 0.9, _time * 0.9 + TAU * 0.78, 120, Color(1.0, 0.84, 0.42, 0.50 * intensity), 2.2, true)
	draw_arc(center, radius * 0.22, -_time * 1.15, -_time * 1.15 + TAU * 0.62, 100, Color(0.62, 0.92, 1.0, 0.42 * intensity), 1.8, true)
