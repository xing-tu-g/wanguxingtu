class_name BattleUIAssets
extends RefCounted

const BACKGROUND := "res://assets/ui/battle/background/battle_background.png"
const GRID_BLUE_IDLE := "res://assets/ui/battle/grid/grid_blue_idle.png"
const GRID_BLUE_HOVER := "res://assets/ui/battle/grid/grid_blue_hover.png"
const GRID_BLUE_SELECTED := "res://assets/ui/battle/grid/grid_blue_selected.png"
const GRID_RED_IDLE := "res://assets/ui/battle/grid/grid_red_idle.png"
const GRID_MID_IDLE := "res://assets/ui/battle/grid/grid_mid_idle.png"
const GRID_BLOCK := "res://assets/ui/battle/grid/grid_block.png"
const HAND_CARD_BG := "res://assets/ui/battle/hand/hand_card_button_bg.png"
const PLAYER_MASTER := "res://assets/manual_art_inbox/masters/C01_player_astrologer.png"
const ENEMY_MASTER := "res://assets/manual_art_inbox/masters/C02_enemy_astrologer.png"

const ICON_COST := "res://assets/ui/icons/attribute/icon_cost.png"
const ICON_HP := "res://assets/ui/icons/attribute/icon_hp.png"
const ICON_ATTACK := "res://assets/ui/icons/attribute/icon_attack.png"
const ICON_MOVE := "res://assets/ui/icons/attribute/icon_move.png"
const ICON_RANGE := "res://assets/ui/icons/attribute/icon_range.png"

const CLASS_ICON_PATHS := {
	"mage": "res://assets/ui/icons/class/icon_class_mage.png",
	"warrior": "res://assets/ui/icons/class/icon_class_warrior.png",
	"tank": "res://assets/ui/icons/class/icon_class_tank.png",
	"assassin": "res://assets/ui/icons/class/icon_class_assassin.png",
	"archer": "res://assets/ui/icons/class/icon_class_archer.png",
}

const FACTION_ICON_PATHS := {
	"wei": "res://assets/ui/icons/faction/icon_faction_wei.png",
	"shu": "res://assets/ui/icons/faction/icon_faction_shu.png",
	"wu": "res://assets/ui/icons/faction/icon_faction_wu.png",
	"qun": "res://assets/ui/icons/faction/icon_faction_qun.png",
}

static func grid_texture(zone: String, terrain: String, selected: bool, hover_ready: bool) -> Texture2D:
	if selected:
		return load(GRID_BLUE_SELECTED) as Texture2D
	if terrain != "grass":
		return load(GRID_BLOCK) as Texture2D
	if hover_ready:
		return load(GRID_BLUE_HOVER) as Texture2D
	if zone == "left_deployment":
		return load(GRID_BLUE_IDLE) as Texture2D
	if zone == "right_deployment":
		return load(GRID_RED_IDLE) as Texture2D
	return load(GRID_MID_IDLE) as Texture2D


static func hand_card_style(
	bg: Color = Color(0.045, 0.082, 0.155, 0.78),
	border: Color = Color(1.0, 0.80, 0.40, 0.62),
	inner_shadow: Color = Color(0.20, 0.58, 0.82, 0.24)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = inner_shadow
	style.shadow_size = 5
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


static func hand_tray_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(HAND_CARD_BG) as Texture2D
	style.texture_margin_left = 96
	style.texture_margin_top = 96
	style.texture_margin_right = 96
	style.texture_margin_bottom = 96
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 12
	style.modulate_color = Color(0.92, 0.96, 1.0, 1.0)
	return style


static func framed_button_style(tint: Color = Color(0.72, 0.82, 0.90, 1.0), margin: int = 24) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(HAND_CARD_BG) as Texture2D
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	style.modulate_color = tint
	return style


static func background_texture() -> Texture2D:
	return load(BACKGROUND) as Texture2D


static func master_texture(side: String) -> Texture2D:
	if side == "right":
		return load(ENEMY_MASTER) as Texture2D
	return load(PLAYER_MASTER) as Texture2D


static func attribute_icon(attribute_id: String) -> Texture2D:
	match attribute_id:
		"cost":
			return _load_texture(ICON_COST)
		"hp":
			return _load_texture(ICON_HP)
		"attack":
			return _load_texture(ICON_ATTACK)
		"move":
			return _load_texture(ICON_MOVE)
		"range":
			return _load_texture(ICON_RANGE)
		_:
			return null


static func class_icon(class_id: String) -> Texture2D:
	var path := str(CLASS_ICON_PATHS.get(class_id, ""))
	return _load_texture(path) if not path.is_empty() else null


static func faction_icon(faction_id: String) -> Texture2D:
	var path := str(FACTION_ICON_PATHS.get(faction_id, ""))
	return _load_texture(path) if not path.is_empty() else null


static func texture(path: String) -> Texture2D:
	return _load_texture(path)


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var file_path := path
	if file_path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(file_path)
	if not FileAccess.file_exists(file_path):
		return null
	var image := Image.new()
	var error := image.load(file_path)
	if error != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
