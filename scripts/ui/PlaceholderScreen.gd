extends Control

const HOME_SCREEN := "res://scenes/ui/HomeScreen.tscn"

@export var screen_title := "占位页面"
@export_multiline var screen_body := ""


func _ready() -> void:
	var title := get_node_or_null("Margin/Layout/Title") as Label
	if title != null:
		title.text = screen_title

	var body := get_node_or_null("Margin/Layout/Body") as Label
	if body != null:
		body.text = screen_body

	var home_button := get_node_or_null("Margin/Layout/HomeButton") as Button
	if home_button != null:
		home_button.pressed.connect(_return_home)


func _return_home() -> void:
	var router := get_parent()
	if router != null and router.has_method("show_screen"):
		router.show_screen(HOME_SCREEN)
