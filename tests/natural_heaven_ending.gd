extends SceneTree
var failures: Array[String] = []
var snap: Dictionary
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func until(predicate: Callable, seconds: float = 15.0) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		if predicate.call(): return true
		await process_frame
	return false
func is_ending() -> bool:
	return current_scene != null and current_scene.scene_file_path.ends_with("settlement_descent.tscn")
func scenario(count: int, nested: bool) -> void:
	var game
	if nested:
		var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		menu.get_node("GameHandoff").prepare()
		game = menu.get_node("GameHandoff").gameplay
		game.visible = true
		game.get_node("CameraOutput").enabled = true
		game.get_node("MusicRegions").enabled = true
	else:
		game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
		root.add_child(game)
		current_scene = game
	await process_frame
	game.get_node("WallEntry").reset_for_replay()
	game.get_node("WallEntry").completed = true
	game.get_node("FlyingEnemies").enabled = false
	game.get_node("CameraAttention").enabled = false
	var history = game.get_node("RunRetrospective")
	history.recording_enabled = false
	history.deaths[&"hell"] = 3
	history.deaths[&"sky"] = 2
	var image := Image.create(16,9,false,Image.FORMAT_RGB8)
	image.fill(Color.CORAL)
	history.append_frame(&"sky", image.save_jpg_to_buffer())
	game.get_node("HellOranges").collected_count = count
	var stage = game.get_node("OceanLink/FishStage")
	stage.activate()
	var layout = stage.get_node("JungleLayout")
	var bird = layout.get_node("Bird")
	var cloud = layout.get_node("SkyCloudExit")
	bird.get_node("Host").take_control()
	bird.get_node("Movement").enabled = false
	bird.get_node("Input").enabled = false
	game.player = bird
	game.soul.hide()
	game.demon.hide()
	# 不调用快捷入口或_enter：由真实云边触发条件启动。
	bird.position = Vector2(960, cloud.height_at("sky",960) + 150)
	game.camera.zoom = Vector2.ONE * 1.35
	game.camera.set_follow_target(bird,true)
	game.camera.set_process(true)
	if not nested: game.camera.make_current()
	await create_timer(0.1).timeout
	check(cloud.state == cloud.State.WAITING, "natural approach waits below cloud")
	snap = {}
	cloud.arrived.connect(func():
		snap.position = root.canvas_transform * game.soul.global_position
		snap.velocity = root.canvas_transform.basis_xform(game.soul.velocity)
		snap.level_id = game.get_instance_id()
	)
	bird.position.y = cloud.height_at("sky",960) + 20
	check(await until(is_ending), "natural cloud continues to ending; nested=" + str(nested))
	if not is_ending(): return
	var ending = current_scene
	check(not is_instance_id_valid(snap.level_id), "old level and menu released after handoff")
	check(root.canvas_transform.is_equal_approx(Transform2D.IDENTITY), "camera output cleared")
	check(ending.arrival_position.distance_to(snap.position) < 2, "actual display-space position retained")
	check(ending.arrival_velocity.distance_to(snap.velocity) < 2, "launch velocity retained")
	check(ending.oranges_total == count and ending.opening.oranges_total == count, "actual count retained without granting 100")
	check(ending.data.deaths[&"hell"] == 3 and ending.data.deaths[&"sky"] == 2, "full run deaths retained")
	check(ending.data.clips[&"sky"].size() == 1, "actual replay retained")
	var fixed: Vector2 = ending.world.position
	check(await until(func(): return ending.elapsed >= 4.6,8), "reward reaches landing")
	check(ending.opening.soul_halo.visible == (count >= 100), "100 threshold respected")
	check(ending.world.position.distance_to(fixed) < 0.01, "room camera holds while ghost bounces")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture: Image = root.get_texture().get_image()
		capture.save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/natural-heaven-%d.png" % count)
		var halo_pixels := 0
		for y in range(80,150):
			for x in range(545,735):
				var pixel := capture.get_pixel(x,y)
				if pixel.r > 0.9 and pixel.g > 0.75 and pixel.b < 0.65: halo_pixels += 1
		check(halo_pixels > 500, "native halo is actually rendered")
		var footer: Color = capture.get_pixel(640,700)
		check(footer.r > 0.7 and footer.g > 0.5 and footer.b > 0.5, "cloud footer has no missing texture noise")
	check(await until(func(): return ending._review_started,8), "cloud dive automatically leads to recap")
	check(ending.gate.phase == ending.gate.Phase.COMPLETE, "recap starts after dive finishes")
	check(ending.opening.soul_halo.visible == (count >= 100), "recap does not invent a halo")
	unload_current_scene()
	await process_frame
	await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1920,1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await scenario(37,true)
	await scenario(100,false)
	print("NATURAL_HEAVEN_ENDING_FAILURES=",failures.size())
	quit(0 if failures.is_empty() else 1)
