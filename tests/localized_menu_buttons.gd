extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)
func run():
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1920,1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var settings = root.get_node("GameSettings")
	var original: int = settings.language_index
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(0.2).timeout
	for i in range(4):
		settings.language_index = i
		settings.changed.emit()
		await process_frame
		for name_key in ["start","settings"]:
			var label: TextureRect = menu._localized_buttons.labels[name_key]
			check(label.texture.resource_path.ends_with(name_key+"_"+settings.LANGUAGES[i]+".png"), "button matches selected language")
			check(label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "text does not block clicks")
		check(menu.get_node("Start").texture_normal.resource_path.ends_with("start_base.png"), "outlined characters use latest original artwork")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/menu-buttons-%s.png" % settings.LANGUAGES[i])
	menu._settings_pressed()
	await create_timer(0.24).timeout
	check(not menu._settings_popup._close_art.scale.is_equal_approx(Vector2.ONE), "cross duang on popup opening")
	await create_timer(0.8).timeout
	check(menu._settings_popup._close_art.scale.is_equal_approx(Vector2.ONE), "cross settles")
	menu._settings_popup._cycle_language(1)
	var language: String = settings.LANGUAGES[settings.language_index]
	check(menu._localized_buttons.labels.start.texture.resource_path.ends_with("start_"+language+".png"), "changing settings updates menu behind popup immediately")
	for label in menu._localized_buttons.labels.values():
		check(not label.scale.is_equal_approx(Vector2.ONE), "menu text duang immediately on language change")
	var pulses: int = menu._localized_buttons._feedback.pulse_count
	settings.changed.emit()
	check(menu._localized_buttons._feedback.pulse_count == pulses, "same language or audio change does not restart text bounce")
	await create_timer(1.0).timeout
	for label in menu._localized_buttons.labels.values():
		check(label.scale.is_equal_approx(Vector2.ONE), "text settles after repeated language changes")
	menu._settings_popup.close()
	await create_timer(0.2).timeout
	menu.get_node("Start/Pulse").pulse()
	await create_timer(0.05).timeout
	check(not menu.get_node("Start").scale.is_equal_approx(Vector2.ONE), "new artwork retains menu bounce")
	settings.language_index = original
	settings.changed.emit()
	print("LOCALIZED_MENU_BUTTON_FAILURES=",failures)
	quit(failures)
