extends SceneTree

const MANIFEST_PATH := "res://tests/test_manifest_mvp.txt"
const RUNNER_PATH := "res://scripts/run_mvp_manifest_tests.sh"

func _init() -> void:
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	_assert(manifest_text.length() > 0, "主线测试 manifest 必须存在")
	_assert(manifest_text.find("MVP 主线脚本测试清单") >= 0, "manifest 需要中文说明")
	var tests := _manifest_tests(manifest_text)
	_assert(tests.size() >= 69, "manifest 主线测试数量不能少于 M69 固化时的 69 个")
	var sorted := tests.duplicate()
	sorted.sort_custom(_natural_test_sort)
	_assert(tests == sorted, "manifest 应按里程碑自然顺序排列")
	for test_path in tests:
		_assert(test_path.begins_with("tests/"), "测试路径必须位于 tests/ 下: " + test_path)
		_assert(test_path.ends_with(".gd"), "测试路径必须是 .gd: " + test_path)
		_assert(FileAccess.file_exists("res://" + test_path), "manifest 引用的测试必须存在: " + test_path)
	_assert(tests.has("tests/m1_deployment_check.gd"), "manifest 应包含 M1 核心部署测试")
	_assert(tests.has("tests/m68_top_info_layout_check.gd"), "manifest 应包含最新 M68 UI 测试")
	_assert(tests.has("tests/m70_b01_background_asset_quality_check.gd"), "manifest 应包含 M70 B01 背景资源测试")
	_assert(tests.has("tests/m71_b02_home_background_check.gd"), "manifest 应包含 M71 B02 首页背景测试")
	var runner_text := FileAccess.get_file_as_string(RUNNER_PATH)
	_assert(runner_text.find("SCRIPT ERROR|Parse Error|Compile Error") >= 0, "runner 必须严格扫描 Godot 脚本/解析/编译错误")
	_assert(runner_text.find("RUNNING_TEST_COUNT") >= 0, "runner 必须输出测试数量")
	_assert(runner_text.find("MVP_MANIFEST_CLEAN") >= 0, "runner 必须输出成功哨兵")
	print("M69 manifest runner checks passed: %d tests" % tests.size())
	quit(0)

func _manifest_tests(text: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in text.split("
"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		result.append(line)
	return result

func _natural_test_sort(left: String, right: String) -> bool:
	return _test_sort_key(left) < _test_sort_key(right)

func _test_sort_key(path: String) -> String:
	var regex := RegEx.new()
	regex.compile("m([0-9]+)([a-z]?)_")
	var matched := regex.search(path)
	if matched == null:
		return path
	var number := int(matched.get_string(1))
	var suffix := matched.get_string(2)
	return "%04d%s_%s" % [number, suffix, path]

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
