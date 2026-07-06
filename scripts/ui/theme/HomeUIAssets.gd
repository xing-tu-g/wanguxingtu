extends RefCounted

const ROOT := "res://assets/ui/home/"
const PROCESSED := "res://assets/ui/home/processed/"

const NEEDS_ART_FIX := {
	"icon_settings_default.png": true,
	"icon_settings_hover.png": true,
}

const OPAQUE_ALLOWED := {
	"star_map_background.png": true,
}

const STATE_TEXTURES := {
	"star_core": {
		"default": "icon_star_core_default.png",
		"hover": "icon_star_core_hover.png",
		"pressed": "icon_star_core_pressed.png",
		"matching": "icon_star_core_matching.png",
	},
	"quest": {
		"default": "icon_quest_default.png",
		"hover": "icon_quest_hover.png",
		"pressed": "icon_quest_pressed.png",
	},
	"activity": {
		"default": "icon_activity_default.png",
		"hover": "icon_activity_hover.png",
		"pressed": "icon_activity_pressed.png",
	},
	"deck": {
		"default": "icon_deck_default.png",
		"hover": "icon_deck_hover.png",
		"pressed": "icon_deck_pressed.png",
	},
	"codex": {
		"default": "icon_codex_default.png",
		"hover": "icon_codex_hover.png",
		"pressed": "icon_codex_pressed.png",
	},
	"summon": {
		"default": "icon_summon_default.png",
		"hover": "icon_summon_hover.png",
		"pressed": "icon_summon_pressed.png",
	},
	"report": {
		"default": "icon_report_default.png",
		"hover": "icon_report_default.png",
		"pressed": "icon_report_default.png",
	},
	"settings": {
		"default": "icon_settings_pressed.png",
		"hover": "icon_settings_pressed.png",
		"pressed": "icon_settings_pressed.png",
	},
	"mail": {
		"default": "icon_mail_default.png",
		"hover": "icon_mail_hover.png",
		"pressed": "icon_mail_pressed.png",
	},
	"friends": {
		"default": "icon_friends_default.png",
		"hover": "icon_friends_hover.png",
		"pressed": "icon_friends_pressed.png",
	},
}

const DIRECT_TEXTURES := {
	"player_panel": "panel_player_bg.png",
	"player_avatar_frame": "panel_player_avatar_frame.png",
	"player_exp_bg": "panel_player_exp_bar_bg.png",
	"player_exp_fill": "panel_player_exp_bar_fill.png",
	"star_map_background": "star_map_background.png",
	"star_map_orbit": "star_map_orbit_layer.png",
	"star_map_node": "star_map_node.png",
	"star_map_glow": "star_map_glow.png",
	"topbar_panel": "panel_topbar_bg.png",
	"coin": "icon_coin.png",
	"star_coin": "icon_star_coin.png",
	"star_track": "icon_star_track.png",
}


static func texture(file_name: String) -> Texture2D:
	var path := texture_path(file_name)
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Home UI texture missing: %s" % path)
	return texture


static func direct(key: String) -> Texture2D:
	return texture(str(DIRECT_TEXTURES.get(key, "")))


static func button_state(group: String, state: String) -> Texture2D:
	var config: Dictionary = STATE_TEXTURES.get(group, {})
	return texture(str(config.get(state, config.get("default", ""))))


static func texture_path(file_name: String) -> String:
	if file_name.is_empty():
		return ""
	if OPAQUE_ALLOWED.has(file_name):
		return ROOT + file_name
	if NEEDS_ART_FIX.has(file_name):
		return ROOT + file_name
	if ResourceLoader.exists(PROCESSED + file_name):
		return PROCESSED + file_name
	return ROOT + file_name
