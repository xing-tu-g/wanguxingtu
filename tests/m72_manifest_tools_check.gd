extends SceneTree

const CHECK_SCRIPT := "res://scripts/check_test_manifest.ps1"
const ADB_SCRIPT := "res://scripts/android_smoke_capture.ps1"
const CURRENT_DOC := "res://docs/CURRENT.md"


func _init() -> void:
	var failures: Array[String] = []
	_check_manifest_tool(failures)
	_check_adb_tool(failures)
	_check_current_doc(failures)
	if failures.is_empty():
		print("M72 manifest and smoke tool checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_manifest_tool(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(CHECK_SCRIPT)
	_expect(not source.is_empty(), "manifest check PowerShell script exists", failures)
	_expect(source.contains("MANIFEST_TEST_COUNT"), "manifest tool outputs manifest count", failures)
	_expect(source.contains("TEST_FILE_COUNT"), "manifest tool outputs test file count", failures)
	_expect(source.contains("TEST_NOT_IN_MANIFEST"), "manifest tool reports test files missing from manifest", failures)
	_expect(source.contains("MANIFEST_FILE_MISSING"), "manifest tool reports manifest references missing files", failures)
	_expect(source.contains("MANIFEST_ORDER_INVALID"), "manifest tool reports natural order failures", failures)
	_expect(source.contains("TEST_MANIFEST_SYNC_CLEAN"), "manifest tool outputs clean sentinel", failures)
	_expect(source.contains("Get-ChildItem") and source.contains("-Filter \"*.gd\""), "manifest tool scans gd tests only", failures)


func _check_adb_tool(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(ADB_SCRIPT)
	_expect(not source.is_empty(), "ADB smoke PowerShell script exists", failures)
	_expect(source.contains("builds/wanguxingtu-m70-b01-004535-debug.apk"), "ADB tool defaults to current playable APK", failures)
	_expect(source.contains("com.wanguxingtu.mvp"), "ADB tool defaults to MVP package name", failures)
	_expect(source.contains("exec-out") and source.contains("screencap"), "ADB tool uses exec-out screencap", failures)
	_expect(source.contains("ProcessStartInfo") and source.contains("RedirectStandardOutput") and source.contains("UseShellExecute"), "ADB tool captures native output without PowerShell error records", failures)
	_expect(source.contains("WriteAllBytes"), "ADB tool writes binary screenshots safely", failures)
	_expect(source.contains("ADB_DEVICE_NOT_READY"), "ADB tool reports offline or missing devices clearly", failures)
	_expect(source.contains("ADB_AUTO_SERIAL"), "ADB tool auto-selects the only online device", failures)
	_expect(source.contains("am") and source.contains("force-stop"), "ADB tool force-stops app before launch for clean logs", failures)
	_expect(source.contains("万古星图首页 ready"), "ADB tool waits for Godot home screen log before screenshot", failures)
	_expect(source.contains("ADB_SCREENSHOT_TOO_SMALL"), "ADB tool rejects early black or tiny screenshots", failures)
	_expect(source.contains("FATAL EXCEPTION|E AndroidRuntime|SCRIPT ERROR|Parse Error|Compile Error"), "ADB tool scans strict crash/script errors", failures)
	_expect(source.contains("ADB_SMOKE_CAPTURE_CLEAN"), "ADB tool outputs clean sentinel", failures)


func _check_current_doc(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string(CURRENT_DOC)
	_expect(source.contains("scripts/check_test_manifest.ps1"), "CURRENT documents manifest sync command", failures)
	_expect(source.contains("scripts/android_smoke_capture.ps1"), "CURRENT documents ADB smoke command", failures)
	_expect(source.contains("75"), "CURRENT documents current manifest size", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
