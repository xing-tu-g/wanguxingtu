extends SceneTree

const BATTLE_SCREEN_PATH := "res://scripts/ui/BattleScreen.gd"
const BATTLE_TUTORIAL_VIEW_PATH := "res://scripts/ui/BattleTutorialView.gd"


func _init() -> void:
	var failures: Array[String] = []
	var screen_source := FileAccess.get_file_as_string(BATTLE_SCREEN_PATH)
	var tutorial_view_source := FileAccess.get_file_as_string(BATTLE_TUTORIAL_VIEW_PATH)

	_expect(not screen_source.is_empty(), "BattleScreen.gd is readable", failures)
	_expect(not tutorial_view_source.is_empty(), "BattleTutorialView.gd is readable", failures)
	_expect(tutorial_view_source.contains("class_name BattleTutorialView"), "BattleTutorialView exposes a class name", failures)
	_expect(screen_source.contains('preload("res://scripts/ui/BattleTutorialView.gd")'), "BattleScreen preloads BattleTutorialView", failures)
	_expect(screen_source.contains("battle_tutorial_view.setup("), "BattleScreen initializes BattleTutorialView", failures)
	_expect(screen_source.contains("func _update_first_deploy_hint"), "BattleScreen keeps first-deploy compatibility wrapper", failures)
	_expect(screen_source.contains("battle_tutorial_view.update_first_deploy_hint()"), "first-deploy wrapper delegates to BattleTutorialView", failures)
	_expect(screen_source.contains("battle_tutorial_view.update_tutorial_progress()"), "tutorial-progress wrapper delegates to BattleTutorialView", failures)
	_expect(screen_source.contains("battle_tutorial_view.show_deploy_failure_toast("), "toast wrapper delegates to BattleTutorialView", failures)
	_expect(screen_source.contains("battle_tutorial_view.process(delta)"), "BattleScreen delegates toast timing to BattleTutorialView", failures)
	_expect(tutorial_view_source.contains("func update_first_deploy_hint"), "BattleTutorialView owns first-deploy hint refresh", failures)
	_expect(tutorial_view_source.contains("func update_tutorial_progress"), "BattleTutorialView owns tutorial progress refresh", failures)
	_expect(tutorial_view_source.contains("func show_deploy_failure_toast"), "BattleTutorialView owns deploy-failure toast display", failures)
	_expect(tutorial_view_source.contains("func process"), "BattleTutorialView owns toast fade timing", failures)

	if failures.is_empty():
		print("M78 battle tutorial view split checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
