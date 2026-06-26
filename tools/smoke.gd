extends SceneTree

# Scene smoke test for 万古星图 (M87 terrain visualization check)
const SCENES := [
	"res://scenes/ui/BattleScreen.tscn",
	"res://scenes/battle/Board.tscn",
	"res://scenes/battle/Tile.tscn",
	"res://scenes/battle/UnitView.tscn",
	"res://scenes/battle/MasterHud.tscn",
	"res://scenes/ui/HomeScreen.tscn",
	"res://scenes/boot/Boot.tscn",
]

func _initialize() -> void:
	var failed := 0
	var shader_errors := 0

	for s in SCENES:
		var ps := load(s) as PackedScene
		if ps == null:
			push_error("FAIL load: %s" % s)
			failed += 1
			continue

		var inst := ps.instantiate()
		if inst == null:
			push_error("FAIL instantiate: %s" % s)
			failed += 1
			continue

		print("OK %s (children=%d, type=%s)" % [s, inst.get_child_count(), inst.get_class()])
		inst.queue_free()

	# Check shader materials loaded correctly
	var shader_mats := [
		"res://assets/shaders/materials/terrain_swamp.tres",
		"res://assets/shaders/materials/terrain_river.tres",
		"res://assets/shaders/materials/terrain_high_land.tres",
	]
	for mat_path in shader_mats:
		var mat := load(mat_path) as ShaderMaterial
		if mat == null:
			push_error("FAIL load ShaderMaterial: %s" % mat_path)
			failed += 1
			continue
		if mat.shader == null:
			push_error("FAIL ShaderMaterial has null shader: %s" % mat_path)
			failed += 1
			continue
		print("OK ShaderMaterial %s (shader=%s)" % [mat_path, mat.shader.resource_path])

	# Summary
	if failed == 0:
		print("=== ALL %d SCENES + %d MATERIALS PASSED ===" % [SCENES.size(), shader_mats.size()])
	else:
		push_error("=== %d FAILURES ===" % failed)

	quit(0 if failed == 0 else 1)
