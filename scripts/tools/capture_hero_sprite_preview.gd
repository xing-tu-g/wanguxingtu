extends SceneTree

const BattleScreenScene: PackedScene = preload("res://scenes/ui/BattleScreen.tscn")
const BoardModelScript: GDScript = preload("res://scripts/battle/BoardModel.gd")


func _init() -> void:
	root.size = Vector2i(2400, 1080)
	var screen: Control = BattleScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	_place_preview_unit(screen, "zhaoyun", 1, 3)
	_place_preview_unit(screen, "guanyu", 2, 3)
	_place_preview_unit(screen, "zhangfei", 3, 3)
	_place_preview_unit(screen, "machao", 4, 3)
	screen.first_deploy_hint_dismissed = true
	screen._refresh_board()
	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	var path := OS.get_environment("BATTLE_PREVIEW_PATH")
	if path.is_empty():
		path = OS.get_environment("TEMP").path_join("wanguxingtu-hero-sprites-preview.png")
	image.save_png(path)
	print("HERO_SPRITE_PREVIEW=%s" % path)
	screen.queue_free()
	quit(0)


func _place_preview_unit(screen: Control, hero_id: String, column: int, row: int) -> void:
	var hero_def: Dictionary = screen.battle_state.get_hero_def(hero_id)
	var unit_data: Dictionary = screen.battle_state.build_unit_data(hero_id, hero_def)
	unit_data["instance_id"] = "preview_%s" % hero_id
	screen.battle_state.create_unit_instance(unit_data, BoardModelScript.SIDE_LEFT, column, row)
