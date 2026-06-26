extends Node
## SaveService — 存档读写单例。
## 注册为 Autoload，全局访问。
##
## 遵守 docs/04_battle_details_data_tests.md §12 的存档结构。
## 所有写操作最终序列化为 user://save.json。

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


## 创建一个符合文档结构的新存档模板。
static func create_default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"player": {
			"name": "玩家",
			"master_level": 1,
			"master_exp": 0,
			"coins": 0,
			"yuanbao": 0,
			"star_jade": 0,
			"rank_points": 0,
			"rare_tickets": 0,
			"legendary_tickets": 0,
		},
		"collection": {
			"heroes": {},
		},
		"deck": {
			"hero_ids": [],
		},
		"settings": {
			"show_battle_log": true,
			"battle_speed": 1.0,
			"music_enabled": true,
			"sfx_enabled": true,
		},
		"daily": {
			"date": "",
			"first_win_claimed": false,
			"wins_today": 0,
			"rare_tickets_won_today": 0,
		},
	}


## 检查 user://save.json 是否存在且可读。
static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 从磁盘读取存档。若文件不存在或损坏则返回空字典。
static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveService: 无法打开存档文件 %s。" % SAVE_PATH)
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("SaveService: JSON 解析失败：%s" % json.get_error_message())
		return {}

	var data = json.get_data()
	if not data is Dictionary:
		push_error("SaveService: 存档根节点不是 Dictionary。")
		return {}

	if int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("SaveService: 存档版本不匹配（期望 %d，实际 %d），将使用默认值。" % [SAVE_VERSION, int(data.get("version", 0))])
		return {}

	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var eb := tree.root.get_node_or_null("EventBus")
		if eb: eb.game_loaded.emit()
	return data


## 将存档写入磁盘。
## [param save_data] 必须是一个符合文档结构的 Dictionary。
static func save_game(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		push_error("SaveService: 不能写入空存档。")
		return false

	save_data["version"] = SAVE_VERSION

	var json_text := JSON.stringify(save_data, "\t", false)
	if json_text.is_empty():
		push_error("SaveService: JSON 序列化失败。")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: 无法写入存档文件 %s。" % SAVE_PATH)
		return false

	file.store_string(json_text)
	file.close()

	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var eb := tree.root.get_node_or_null("EventBus")
		if eb: eb.game_saved.emit()
	return true


## 删除当前存档。
static func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true

	var error := DirAccess.remove_absolute(SAVE_PATH)
	if error != OK:
		push_error("SaveService: 删除存档失败。")
		return false
	return true


## 从 AppState 构建存档数据。
static func build_save_from_appState(app_state, deck_hero_ids: Array = []) -> Dictionary:
	var save_data := create_default_save()
	var snap: Dictionary = app_state.snapshot()
	save_data["player"]["name"] = snap.get("player_name", "玩家")
	save_data["player"]["master_level"] = int(snap.get("master_level", 1))
	save_data["player"]["coins"] = int(snap.get("gold", 0))
	save_data["player"]["star_jade"] = int(snap.get("star_stone", 0))
	save_data["deck"]["hero_ids"] = deck_hero_ids.duplicate()
	return save_data


## 将存档数据恢复到 AppState。
static func apply_save_to_appState(save_data: Dictionary, app_state) -> void:
	var player: Dictionary = save_data.get("player", {})
	app_state.player_name = str(player.get("name", "玩家"))
	app_state.master_level = int(player.get("master_level", 1))
	app_state.gold = int(player.get("coins", 0))
	app_state.star_stone = int(player.get("star_jade", 0))
	app_state.battles_fought = 0
