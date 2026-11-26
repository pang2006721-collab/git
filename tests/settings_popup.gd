extends SceneTree
var failures := 0
var popup
var settings
var original: Array
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", detail)
func click(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	settings = root.get_node("GameSettings")
	original = [settings.sfx_volume, settings.music_volume, settings.language_index]
	var scene = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	popup = scene._settings_popup
	scene._settings_pressed()
	await create_timer(0.4).timeout
	check(popup.is_open(), "Settings opens")
	check(not scene.get_node("Bird/MouseDrag").is_processing_input(), "modal blocks bird drag")
	await click(Vector2(600, 300))
	check(popup.is_open(), "panel blank does not dismiss")
	for value in [0.0, 0.5, 1.0]:
		await click(Vector2(832 + value * 302, 368))
		check(absf(settings.sfx_volume - value) < 0.03, "sfx slider click %s" % value)
		var expected := "speaker_low" if value < 0.34 else ("speaker_medium" if value < 0.67 else "speaker_high")
		check(popup._speaker.texture.resource_path.ends_with(expected + ".png"), "speaker three states")
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) == (value == 0), "sfx mute at zero")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(1134, 368)
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var move := InputEventMouseMotion.new()
	move.position = Vector2(983, 368)
	move.relative = Vector2(-151, 0)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move, true)
	await process_frame
	check(absf(settings.sfx_volume - 0.5) < 0.03, "drag changes volume and speaker")
	check(not popup._knobs[popup._sfx].scale.is_equal_approx(Vector2.ONE), "slider thumb has independent bounce")
	check(popup._sfx.scale.is_equal_approx(Vector2.ONE), "bounce leaves slider hitbox unchanged")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(1500, 368)
	release.pressed = false
	root.push_input(release, true)
	await process_frame
	check(popup.is_open(), "release outside slider does not close popup")
	await click(Vector2(906, 525))
	check(absf(settings.music_volume - 0.25) < 0.03, "music independent slider")
	check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("BgmMusic")), settings.music_volume), "music bus gain")
	var before: int = settings.language_index
	await click(Vector2(900, 680))
	check(settings.language_index == (before + 1) % 4, "language row cycles down")
	check(not popup._language.scale.is_equal_approx(Vector2.ONE), "language switch visibly squashes and rebounds")
	await click(Vector2(1084, 665))
	check(settings.language_index == before, "up arrow reverses")
	await click(Vector2(1084, 697))
	check(settings.language_index == (before + 1) % 4, "down arrow cycles once")
	for i in range(4):
		settings.language_index = i
		popup._refresh()
		check(popup._language.texture.resource_path.ends_with(popup.LANG_ART[i] + ".png"), "language original art")
		if DisplayServer.get_name() == "headless":
			check(popup._language.texture.get_image().get_used_rect().has_area(), "hidden PSD language has visible pixels")
	await create_timer(1.0).timeout
	check(popup._language.scale.is_equal_approx(Vector2.ONE), "rapid language switches settle to original size")
	check(popup._knobs[popup._sfx].scale.is_equal_approx(Vector2.ONE), "thumb settles without size accumulation")
	settings.language_index = before
	settings.set_sfx(0.5)
	settings.set_music(0.25)
	var config := ConfigFile.new()
	check(config.load(settings.SAVE_PATH) == OK and is_equal_approx(config.get_value("audio", "sfx"), 0.5), "saved preferences")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/settings-popup-native.png")
	await click(Vector2(1500, 900))
	await create_timer(0.2).timeout
	check(not popup.is_open(), "outside blank closes")
	check(scene.get_node("Bird/MouseDrag").is_processing_input(), "bird drag restored")
	scene._settings_pressed()
	await create_timer(0.4).timeout
	check(is_equal_approx(popup._sfx.value, 0.5) and is_equal_approx(popup._music.value, 0.25), "reopening retains values")
	await click(Vector2(1284,245))
	await create_timer(0.2).timeout
	check(not popup.is_open(), "top right cross closes settings")
	check(scene.get_node("Bird/MouseDrag").is_processing_input(), "cross restores menu input")
	scene._settings_pressed()
	await create_timer(0.4).timeout
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await create_timer(0.2).timeout
	check(not popup.is_open(), "Escape closes")
	settings.language_index = original[2]
	settings.set_sfx(original[0])
	settings.set_music(original[1])
	print("SETTINGS_POPUP_FAILURES=", failures)
	quit(failures)
