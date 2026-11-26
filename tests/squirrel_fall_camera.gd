extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)
func run():
	var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var body = game.get_node("OceanLink/FishStage/JungleLayout/Squirrel")
	var climber = body.get_node("VineClimber")
	body.get_node("Host").take_control()
	climber.detach(false)
	body.get_node("Movement").enabled = true
	game.player = body
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var framing = body.get_node("FallLookahead")
	var camera = game.camera
	camera.world_bounds = Rect2(0, 0, 1980, 54000)
	body.global_position = Vector2(960, 25000)
	camera.set_follow_target(body, true)
	var baseline: float = camera.global_position.y
	var zoom_before: Vector2 = camera.zoom
	body.velocity = Vector2(0, 1200)
	framing._process(.016)
	check(camera.downward_look_ahead == 280, "Squirrel free fall enables downward framing")
	camera._process(1.0 / 60.0)
	check(camera.global_position.y > baseline and camera.global_position.y - baseline < 30, "Camera begins a smooth downward move")
	for tick in 120: camera._process(1.0 / 60.0)
	check(camera.global_position.y > baseline + 200, "Lower vines become visible ahead of the player")
	check(camera.zoom == zoom_before, "Framing never changes zoom")
	# Catching a vine cancels the look-ahead, then ordinary camera smoothing returns it.
	climber.vine = game.get_node("OceanLink/FishStage/JungleLayout").vines[0]
	framing._process(.016)
	check(camera.downward_look_ahead == 0, "Catching a vine cancels fall look-ahead")
	var before_return: float = camera.global_position.y
	camera._process(1.0 / 60.0)
	check(absf(camera.global_position.y - before_return) < 30, "Catch does not snap the camera")
	for tick in 120: camera._process(1.0 / 60.0)
	check(camera.global_position.y < before_return - 100, "Camera returns after catching")
	climber.vine = null
	body.velocity.y = -1000
	camera.set_follow_target(body, true)
	framing._process(.016)
	for tick in 120: camera._process(1.0 / 60.0)
	check(camera.global_position.y <= baseline, "Upward travel keeps its upward framing")
	# A stale fall value cannot affect a new possession target.
	body.velocity.y = 1200
	framing._process(.016)
	game.demon.global_position = body.global_position
	game.demon.velocity = Vector2(0, 1200)
	camera.set_follow_target(game.demon, true)
	var demon_baseline: float = camera.global_position.y
	for tick in 120: camera._process(1.0 / 60.0)
	check(is_equal_approx(camera.global_position.y, demon_baseline), "Other characters do not inherit squirrel look-ahead")
	camera.set_follow_target(body, true)
	body.global_position.y = 53980
	for tick in 120: camera._process(1.0 / 60.0)
	var half_height: float = camera.get_viewport_rect().size.y * .5 / camera.zoom.y
	check(camera.global_position.y + half_height <= camera.world_bounds.end.y + .01, "Lower map boundary remains clamped")
	print("SQUIRREL_FALL_CAMERA failures=", failures)
	quit(1 if failures else 0)
