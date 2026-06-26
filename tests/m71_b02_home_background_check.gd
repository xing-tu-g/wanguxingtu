extends SceneTree

const HomeScreenScene: PackedScene = preload("res://scenes/ui/HomeScreen.tscn")
const B02_PATH := "res://assets/art/backgrounds/B02_home_background.png"
const MIN_ASPECT := 1.70
const MAX_ASPECT := 1.80
const MAX_TITLE_LUMA := 125.0
const MAX_BUTTON_LUMA := 205.0
const MIN_BLUE_RATIO := 0.65


func _init() -> void:
	root.content_scale_size = Vector2i(2400, 1080)
	var failures: Array[String] = []
	var screen = HomeScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	_check_home_background_nodes(screen, failures)
	_check_home_background_asset(failures)

	screen.queue_free()
	if failures.is_empty():
		print("M71 B02 home background checks passed")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _check_home_background_nodes(screen: Control, failures: Array[String]) -> void:
	_expect(screen.has_node("Background/HomeBackgroundImage"), "B02 home background image node exists", failures)
	_expect(screen.has_node("Background/HomeReadabilityWash"), "home readability wash node exists", failures)
	var image_node: TextureRect = screen.get_node("Background/HomeBackgroundImage")
	var wash: ColorRect = screen.get_node("Background/HomeReadabilityWash")
	_expect(image_node.texture != null, "B02 home texture is assigned", failures)
	if image_node.texture != null:
		_expect(image_node.texture.resource_path == B02_PATH, "B02 home background uses stable art path", failures)
	_expect(image_node.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "B02 home background uses 16:9 cover crop", failures)
	_expect(image_node.mouse_filter == Control.MOUSE_FILTER_IGNORE, "B02 home background does not catch input", failures)
	_expect(wash.mouse_filter == Control.MOUSE_FILTER_IGNORE, "home readability wash does not catch input", failures)
	_expect(wash.color.a >= 0.40 and wash.color.a <= 0.55, "home readability wash balances art and UI", failures)


func _check_home_background_asset(failures: Array[String]) -> void:
	var image := _load_png_image(B02_PATH)
	if image == null or image.is_empty():
		failures.append("FAIL: B02 home background image loads from stable path")
		return
	var size := image.get_size()
	var aspect := float(size.x) / float(size.y)
	_expect(size.x >= 1280 and size.y >= 720, "B02 home background resolution is large enough", failures)
	_expect(aspect >= MIN_ASPECT and aspect <= MAX_ASPECT, "B02 home background stays near 16:9", failures)

	var title_stats := _region_stats(image, Rect2i(0, 0, size.x, int(size.y * 0.34)), 4)
	var button_stats := _region_stats(image, Rect2i(int(size.x * 0.25), int(size.y * 0.50), int(size.x * 0.50), int(size.y * 0.50)), 4)
	var full_stats := _region_stats(image, Rect2i(0, 0, size.x, size.y), 8)
	_expect(title_stats.average_luma <= MAX_TITLE_LUMA, "title zone stays readable on B02", failures)
	_expect(button_stats.average_luma <= MAX_BUTTON_LUMA, "button zone is bright but controlled on B02", failures)
	_expect(full_stats.blue_ratio >= MIN_BLUE_RATIO, "B02 home background keeps blue-purple star-map tone", failures)


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


func _region_stats(image: Image, rect: Rect2i, step: int) -> Dictionary:
	var luma_sum := 0.0
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
			luma_sum += 0.2126 * red + 0.7152 * green + 0.0722 * blue
			if blue > red * 1.12 and blue > green * 0.80:
				blue_count += 1
			total += 1
	if total == 0:
		return {"average_luma": 255.0, "blue_ratio": 0.0}
	return {
		"average_luma": luma_sum / float(total),
		"blue_ratio": float(blue_count) / float(total),
	}


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
