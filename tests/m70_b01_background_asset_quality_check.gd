extends SceneTree

const B01_PATH := "res://assets/art/backgrounds/B01_battle_background.png"
const MIN_ASPECT := 1.70
const MAX_ASPECT := 1.80
const MAX_CENTER_LUMA := 185.0
const MAX_CENTER_BRIGHT_RATIO := 0.22
const MAX_BOTTOM_LUMA := 145.0
const MIN_BLUE_RATIO := 0.82


func _init() -> void:
	var failures: Array[String] = []
	var image := _load_png_image(B01_PATH)
	if image == null or image.is_empty():
		failures.append("FAIL: B01 background image loads from stable path")
	else:
		_check_asset_shape(image, failures)
		_check_readability_regions(image, failures)

	if failures.is_empty():
		print("M70 B01 background asset quality checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_asset_shape(image: Image, failures: Array[String]) -> void:
	var size := image.get_size()
	var aspect := float(size.x) / float(size.y)
	_expect(size.x >= 1280 and size.y >= 720, "B01 background resolution is large enough", failures)
	_expect(aspect >= MIN_ASPECT and aspect <= MAX_ASPECT, "B01 background stays near 16:9", failures)


func _load_png_image(path: String) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Image.new()
	var buffer := file.get_buffer(file.get_length())
	var image := Image.new()
	var error := image.load_png_from_buffer(buffer)
	if error != OK:
		return Image.new()
	return image


func _check_readability_regions(image: Image, failures: Array[String]) -> void:
	var size := image.get_size()
	var center := Rect2i(
		int(size.x * 0.20),
		int(size.y * 0.33),
		int(size.x * 0.60),
		int(size.y * 0.34)
	)
	var bottom := Rect2i(
		0,
		int(size.y * 0.67),
		size.x,
		int(size.y * 0.33)
	)
	var full := Rect2i(0, 0, size.x, size.y)
	var center_stats := _region_stats(image, center, 4)
	var bottom_stats := _region_stats(image, bottom, 4)
	var full_stats := _region_stats(image, full, 8)

	_expect(center_stats.average_luma <= MAX_CENTER_LUMA, "center board zone is not over-bright", failures)
	_expect(center_stats.bright_ratio <= MAX_CENTER_BRIGHT_RATIO, "center board zone has limited high highlights", failures)
	_expect(bottom_stats.average_luma <= MAX_BOTTOM_LUMA, "bottom hand zone remains UI-friendly", failures)
	_expect(full_stats.blue_ratio >= MIN_BLUE_RATIO, "B01 background keeps blue-purple star-map tone", failures)


func _region_stats(image: Image, rect: Rect2i, step: int) -> Dictionary:
	var luma_sum := 0.0
	var bright_count := 0
	var blue_count := 0
	var total := 0
	var max_x: int = mini(rect.position.x + rect.size.x, image.get_width())
	var max_y: int = mini(rect.position.y + rect.size.y, image.get_height())
	for y in range(rect.position.y, max_y, step):
		for x in range(rect.position.x, max_x, step):
			var color := image.get_pixel(x, y)
			var red := color.r * 255.0
			var green := color.g * 255.0
			var blue := color.b * 255.0
			var luma := 0.2126 * red + 0.7152 * green + 0.0722 * blue
			luma_sum += luma
			if luma > 190.0:
				bright_count += 1
			if blue > red * 1.12 and blue > green * 0.80:
				blue_count += 1
			total += 1
	if total == 0:
		return {"average_luma": 255.0, "bright_ratio": 1.0, "blue_ratio": 0.0}
	return {
		"average_luma": luma_sum / float(total),
		"bright_ratio": float(bright_count) / float(total),
		"blue_ratio": float(blue_count) / float(total),
	}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
