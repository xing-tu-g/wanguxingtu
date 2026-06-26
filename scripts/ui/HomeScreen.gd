extends Control

const BATTLE_SCREEN := "res://scenes/ui/BattleScreen.tscn"
const RESULT_SCREEN := "res://scenes/ui/ResultScreen.tscn"

const FontScaleScript: GDScript = preload("res://scripts/ui/theme/FontScale.gd")
const SaveServiceScript: GDScript = preload("res://scripts/core/SaveService.gd")
const MAT_DEPTH_FADE_HOME: ShaderMaterial = preload("res://assets/shaders/materials/depth_fade_home.tres")
const THEME_DEFAULT: Theme = preload("res://assets/theme/default_theme.tres")

@onready var _background_image: TextureRect = $Background/HomeBackgroundImage
@onready var _app_state: Node = get_node("/root/AppState")


func _ready() -> void:
	theme = THEME_DEFAULT
	print("万古星图首页 ready")
	$LogoArea/ButtonColumn/BattleButton.pressed.connect(_open_battle)
	$LogoArea/ButtonColumn/ResultButton.pressed.connect(_open_result)
	_setup_continue_button()
	_refresh_currency()
	_apply_depth_fade()
	_apply_font_scale()


func _apply_depth_fade() -> void:
	if _background_image == null:
		return
	_background_image.material = MAT_DEPTH_FADE_HOME


func _apply_font_scale() -> void:
	var vw := get_viewport_rect().size.x
	$LogoArea/Title.add_theme_font_size_override(&"font_size", FontScaleScript.title_size(vw))
	$LogoArea/Subtitle.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw))
	$VersionLabel.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw) - 2)
	$CurrencyBar/MasterLevel.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw))
	$CurrencyBar/StarStoneCount.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw))
	$CurrencyBar/GoldCount.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw))
	$CurrencyBar/BattleCount.add_theme_font_size_override(&"font_size", FontScaleScript.label_size(vw))


func _setup_continue_button() -> void:
	var continue_button := $LogoArea/ButtonColumn/ContinueButton
	continue_button.visible = SaveServiceScript.has_save()
	if not continue_button.pressed.is_connected(_continue_game):
		continue_button.pressed.connect(_continue_game)


func _continue_game() -> void:
	var save_data: Dictionary = SaveServiceScript.load_game()
	if save_data.is_empty():
		return
	SaveServiceScript.apply_save_to_appState(save_data, _app_state)
	var deck: Array = save_data.get("deck", {}).get("hero_ids", [])
	_route_to(BATTLE_SCREEN, {"player_deck": deck})


func _open_battle() -> void:
	_route_to(BATTLE_SCREEN)


func _open_result() -> void:
	_route_to(RESULT_SCREEN)


func _refresh_currency() -> void:
	$CurrencyBar/MasterLevel.text = "Lv.%d" % _app_state.master_level
	$CurrencyBar/StarStoneCount.text = str(_app_state.star_stone)
	$CurrencyBar/GoldCount.text = str(_app_state.gold)
	$CurrencyBar/BattleCount.text = str(_app_state.battles_fought)


func _route_to(scene_path: String, screen_data: Dictionary = {}) -> void:
	var router := get_parent()
	if router != null and router.has_method("show_screen"):
		if screen_data.is_empty():
			router.show_screen(scene_path)
		else:
			router.show_screen(scene_path, screen_data)
