extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)
func until(predicate: Callable, seconds: float = 6.0) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		if predicate.call(): return true
		await process_frame
	return false
func run():
	var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("WallEntry").reset_for_replay()
	game.get_node("WallEntry").completed = true
	game.get_node("RunRetrospective").recording_enabled = false
	var layout = game.get_node("OceanLink/FishStage/JungleLayout")
	var body = layout.get_node("Squirrel")
	var host = body.get_node("Host")
	var climber = body.get_node("VineClimber")
	var motor = body.get_node("Movement")
	var monitor = body.get_node("FallDeath")
	var defeat = body.get_node("Defeat")
	host.take_control()
	game.player = body
	body.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for n in ["Checkpoint", "OceanCheckpoint", "JungleCheckpoint"]: game.get_node(n).grace_remaining = 0
	climber.detach(false)
	motor.enabled = true
	body.global_position = Vector2(960, 25000)
	body.velocity = Vector2(0, 100)
	monitor._physics_process(.01)
	body.position.y += 999
	monitor._physics_process(.01)
	check(not game.dead, "999 pixels is safe")
	body.position.y += 1
	monitor._physics_process(.01)
	check(not game.dead, "Exactly 1000 pixels is safe")
	# Catching a vine clears the earlier free fall even while it swings downward.
	climber.vine = layout.vines[0]
	body.position.y += 300
	monitor._physics_process(.01)
	check(not game.dead and not monitor._tracking, "Hanging and swinging never count as a free fall")
	climber.vine = null
	body.velocity.y = -100
	monitor._physics_process(.01)
	body.position.y -= 330
	monitor._physics_process(.01)
	body.velocity.y = 100
	body.position.y += 330
	monitor._physics_process(.01)
	check(not game.dead, "Normal jump height remains safe")
	# Rebirth grace and reset must clear the previous drop.
	game.get_node("JungleCheckpoint").grace_remaining = 1
	body.position.y += 600
	monitor._physics_process(.01)
	check(not game.dead and not monitor._tracking, "Rebirth grace cannot inherit a fatal fall")
	game.get_node("JungleCheckpoint").grace_remaining = 0
	monitor._physics_process(.01)
	body.position.y += 490
	monitor._physics_process(.01)
	defeat.reset()
	check(not monitor._tracking, "Retry reset clears drop history")
	monitor._physics_process(.01)
	body.position.y += 1001
	game.camera.set_process(false)
	game.camera.global_position = body.global_position
	game.camera.make_current()
	monitor._physics_process(.01)
	check(not game.dead, "Crossing 1000 pixels in midair does not kill")
	# 使用真实地面碰撞验证落地判定，而非伪造 is_on_floor。
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 16
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(400, 20)
	shape.shape = rectangle
	floor_body.add_child(shape)
	root.add_child(floor_body)
	floor_body.global_position = body.global_position + Vector2(0, 30)
	await physics_frame
	for tick in 20:
		body.velocity = Vector2(0, 1200)
		body.move_and_slide()
		monitor._physics_process(1.0 / 120.0)
		if game.dead: break
		await physics_frame
	check(body.is_on_floor(), "Actual collision reaches the ground")
	check(game.dead and game.death_reason == &"fall", "Landing after a drop above 1000 pixels kills the squirrel")
	check(defeat.falling and defeat.corpse.visible, "Original stunned expression starts immediately")
	check(not body.get_node("Visual/Sprite").visible, "Live pose is hidden")
	check(defeat.corpse.texture.atlas.resource_path.ends_with("stunned.png"), "Uses supplied squirrel pose")
	var flow = game.get_node("DeathFlow")
	await process_frame
	check(not flow.overlay.visible and defeat.falling, "Popup waits for the falling animation")
	check(await until(func(): return flow.overlay.state == flow.overlay.State.OPEN), "Death popup opens after the fall")
	check(flow.overlay.death_stage == &"jungle", "Fall death shows squirrel card")
	check(game.get_node("RunRetrospective").deaths[&"jungle"] == 1, "Death counts once in jungle")
	print("SQUIRREL_FALL_DEATH failures=", failures)
	quit(1 if failures else 0)
