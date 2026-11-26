extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)
func run():
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var quick = root.get_node("SegmentQuickStart")
	quick.start_segment(6)
	await quick.segment_started
	var game = current_scene
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var record = game.get_node("RunRetrospective")
	record.recording_enabled = false
	var flow = game.get_node("DeathFlow")
	var ui = flow.overlay
	var actors = {
		&"hell": game.demon,
		&"ocean": game.get_node("OceanLink/FishStage/Fish"),
		&"jungle": game.get_node("OceanLink/FishStage/JungleLayout/Squirrel"),
		&"sky": game.get_node("OceanLink/FishStage/JungleLayout/Bird"),
	}
	game.get_node("OceanLink").stage = 0
	for stage_name in actors:
		game.player = actors[stage_name]
		check(flow._stage_at_death() == stage_name, "Actual actor routes to " + str(stage_name))
		ui.show_death(flow._stage_at_death())
		await ui.presentation_finished
		check(ui.death_stage == stage_name, "Popup selects " + str(stage_name))
		check(ui.card.size == ui.card.texture.get_size(), "Native art aspect is preserved")
		check(ui.card.scale.is_equal_approx(Vector2.ONE), "Pop settles correctly")
		check(not ui.retry.disabled and not ui.home.disabled, "Both buttons remain enabled")
		if stage_name != &"hell":
			check(ui.card.texture.resource_path.ends_with(str(stage_name) + "_end.png"), "Correct supplied image")
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/death-card-" + str(stage_name) + ".png")
		await ui.dismiss()
		check(ui.state == ui.State.HIDDEN and ui.card.modulate.a == 1.0, "Dismiss resets popup for retry")
	game.player = game.soul
	record.current_stage = &"jungle"
	check(flow._stage_at_death() == &"jungle", "Soul during transfer keeps its stage")
	game.player = game.demon
	game.get_node("OceanLink").stage = 4
	check(flow._stage_at_death() == &"ocean", "Before fish possession ocean death uses fish")
	ui.show_death(&"hell")
	check(ui.card.texture == ui._hell_texture and ui.card.position == Vector2(627,184), "Demon art restored after other cards")
	print("STAGE_DEATH_CARDS failures=", failures)
	quit(1 if failures else 0)
