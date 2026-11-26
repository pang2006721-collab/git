extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)
func until(predicate: Callable, seconds: float = 12.0) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		if predicate.call(): return true
		await process_frame
	return false
func run():
	# 正式首页中的关卡也是嵌套场景，返回时应释放整个旧流程。
	var wrapper := Node2D.new()
	root.add_child(wrapper)
	current_scene = wrapper
	var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	wrapper.add_child(game)
	game.get_node("RunRetrospective").recording_enabled = false
	game.get_node("WallEntry").reset_for_replay()
	game.get_node("WallEntry").completed = true
	game.die()
	var flow = game.get_node("DeathFlow")
	check(await until(func(): return flow.overlay.state == flow.overlay.State.OPEN), "Actual death opens popup")
	var overlay = flow.overlay
	overlay.home.pressed.emit()
	overlay.home.pressed.emit()
	check(flow.state == flow.State.HOME, "Home click commits to returning")
	var transition = root.get_node_or_null("DeathHomeTransition")
	check(transition != null and transition.started, "Home immediately starts ending-style transition")
	check(transition.layer > overlay.layer and transition.beans.layer > transition.layer, "Black covers death UI with beans above it")
	check(transition.beans.get_node("Layout/Corner").get_child_count() == 5, "Reuses the same five loading characters")
	var count := 0
	for child in root.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("settlement_return_home.gd"): count += 1
	check(count == 1, "Repeated home clicks cannot duplicate transitions")
	check(await until(func(): return transition.beans.visible), "Five characters appear after fade to black")
	check(transition.black.color.a > .99, "Loading stays on a fully black screen")
	await process_frame
	check(not is_instance_valid(wrapper), "Old gameplay is released beneath black screen")
	if DisplayServer.get_name() != "headless":
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/death-home-loading.png")
	await transition.completed
	check(transition.menu_ready and current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "Ready cover scene is revealed")
	check(transition.black.color.a < .001, "Black fades completely away")
	check(root.get_camera_2d() == current_scene.get_node("DescentCamera"), "Home camera owns the viewport")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/death-home-cover.png")
	await process_frame
	check(not is_instance_valid(transition), "Transition removes itself after return")
	print("DEATH_HOME_LOADING failures=", failures)
	quit(1 if failures else 0)
