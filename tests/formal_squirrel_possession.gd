extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    var fish = stage.fish
    var motor = fish.get_node("Movement")
    motor.set_physics_process(false)
    fish.get_node("Patrol").stop()
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
    var shore = stage.get_node("ShoreExit")
    shore.set_physics_process(false)
    var blink = fish.get_node("Teleport")
    fish.position = Vector2(960,shore.surface_y+1000)
    fish.velocity = Vector2(0,-420)
    game.get_node("CameraAttention").enabled = false
    game.camera.set_process(false)
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.offset = Vector2.ZERO
    game.camera.global_position = fish.global_position
    var controller = stage.get_node("JunglePossession")
    var handoff = stage.get_node("JungleHandoff")
    var layout = stage.get_node("JungleLayout")
    var squirrel = layout.get_node("Squirrel")
    var host = squirrel.get_node("Host")
    var climber = squirrel.get_node("VineClimber")
    handoff.set_physics_process(false)
    controller.set_physics_process(false)
    check(not controller.enabled and not host.claimed,"Jungle possession is unavailable during swimming")
    check(host.is_in_group("formal_jungle_hosts") and not host.is_in_group("possessable_hosts"),"Hell possession cannot accidentally choose the squirrel")
    shore.state = shore.State.STRANDED
    fish.global_position = squirrel.global_position+Vector2(100,80)
    fish.get_node("Teleport").enabled = false
    game.camera.global_position = squirrel.global_position
    layout._update_nearby()
    handoff._physics_process(.01)
    controller._physics_process(.01)
    check(controller.enabled and controller.selected_host==host,"Stranded fish selects the nearby swinging squirrel")
    check(squirrel.get_node("Visual/SelectedSprite").visible,"Provided SHIFT artwork appears before possession")
    var key := InputEventKey.new()
    key.physical_keycode = KEY_SHIFT
    key.location = KEY_LOCATION_RIGHT
    key.pressed = true
    root.push_input(key)
    check(controller.state==controller.State.ROAMING,"Right Shift does not claim the host")
    key = InputEventKey.new()
    key.physical_keycode = KEY_SHIFT
    key.location = KEY_LOCATION_LEFT
    key.pressed = true
    root.push_input(key)
    check(controller.state==controller.State.TRANSFERRING,"Actual left Shift begins possession")
    check(not game.dead and shore.state==shore.State.DEAD,"Leaving the fish does not trigger the stranded death screen")
    check(game.player==game.soul and squirrel.transferring,"Soul and host enter the existing transfer animation")
    check(shore._death_tween!=null and shore._death_tween.is_running(),"Leaving the fish starts its natural fade")
    shore._death_tween.custom_step(shore.death_hold_duration+.2)
    check(fish.visible and shore._visual.modulate.a>0 and shore._visual.modulate.a<1,"The old fish fades gradually rather than popping away")
    shore._death_tween.custom_step(shore.death_fade_duration+1)
    check(not fish.visible,"The abandoned fish disappears after fading")
    await controller.possession_finished
    check(controller.state==controller.State.POSSESSED and host.claimed,"Transfer finishes with a claimed squirrel")
    check(game.player==squirrel and game.camera.target==squirrel,"Player ownership and shared camera both move to the squirrel")
    check(climber.vine==squirrel.vine and climber.vine.rider==squirrel and not host.motor.enabled,"Possession preserves the swinging grip rather than dropping the squirrel")
    check(host.reader.enabled and not host.reader.external_control,"Keyboard now controls the squirrel")
    check(not squirrel.get_node("Visual/SelectedSprite").visible,"Shift prompt disappears after possession")
    host.reader.external_control = true
    host.reader.jump_held = true
    host.reader.move_axis = 1
    Input.action_press(&"possess")
    var grip: float = climber.vine.grip_length
    climber._physics_process(.01)
    climber.vine._physics_process(.1)
    check(climber.vine.grip_length<grip and absf(climber.vine.pump_axis)<=climber.automatic_swing_strength,"W climbs while automatic assistance drives the physical rope within bounded force")
    check(not climber.allow_mantle,"The player cannot mantle onto decorative thick main vines")
    climber.detach(true)
    Input.action_release(&"possess")
    check(climber.vine==null and host.motor.enabled,"Squirrel can jump off the rope and enter normal movement")
    for i in 240: controller.shot._process(.01)
    check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Camera returns to the normal 1.35 zoom")
    stage.reset()
    check(not controller.enabled and not host.claimed and squirrel.vine.rider==squirrel,"Replay restores idle swinging and clears possession")
    check(not squirrel.transferring and Engine.time_scale==1,"Replay leaves no slow motion or frozen transfer")
    stage.active = true
    game.player = fish
    shore.state = shore.State.STRANDED
    fish.global_position = squirrel.global_position+Vector2(0,80)
    handoff._physics_process(.01)
    check(controller.request_possession(),"A new replay can start possession normally")
    stage.reset()
    check(controller.state==controller.State.ROAMING and not controller.enabled and not host.claimed,"Restart during the soul flight cancels the pending handoff")
    check(not controller.shot.active and Engine.time_scale==1,"Cancelling transfer restores the camera and time scale")
    print("FORMAL_SQUIRREL_POSSESSION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
