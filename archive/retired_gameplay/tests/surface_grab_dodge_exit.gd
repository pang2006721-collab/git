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
    var grab = stage.get_node("SurfaceGrab")
    grab.set_physics_process(false)
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
    for offscreen in [false,true]:
        grab.reset()
        shore.reset()
        fish.position = Vector2(960,shore.surface_y+1000)
        fish.velocity = Vector2(0,-420)
        game.camera.global_position = fish.global_position
        grab._physics_process(.01)
        check(grab.state==grab.State.WARNING,"Encounter begins with visible warning")
        var origin: Vector2 = fish.global_position
        var destination: Vector2 = origin+Vector2(0,-320)
        fish.global_position = destination
        blink.teleported.emit(origin,destination)
        check(not grab.blocks_exit(),"Successful blink immediately opens the surface route")
        var y: float = fish.position.y
        fish.position.y = shore.surface_y+100
        fish.velocity.y = -420
        grab._hold_surface_route()
        check(fish.position.y==shore.surface_y+100 and fish.velocity.y==-420,"No hidden clamp or swim slowdown remains after evasion")
        fish.position.y = y
        if offscreen: game.camera.global_position.y -= 3000
        for i in 250: grab._physics_process(.01)
        check(grab.state==grab.State.FINISHED and grab.rounds_completed==1,"Evasion completes exactly one encounter, including when original arms leave the camera")
        check(grab.attacks_started<=1 and grab._warning_arms.is_empty(),"No replacement warning or second attack appears")
        check(not grab.retreats.is_empty(),"Missed arms sink instead of disappearing")
        for i in 500: grab._physics_process(.01)
        check(grab.state==grab.State.FINISHED and not grab.blocks_exit(),"Continuing upward never restarts the trap")
        fish.position.y = shore.surface_y-2
        fish.velocity.y = -420
        fish.get_node("Input").external_control = true
        fish.get_node("Input").up_held = true
        shore._physics_process(.01)
        check(shore.state==shore.State.AIRBORNE,"Fish can actually leap out after evading")
    # Exiting during the warning must retire the same arms, not delete or rearm them.
    grab.reset()
    shore.reset()
    fish.position.y = shore.surface_y+1000
    fish.velocity.y = -420
    game.camera.global_position = fish.global_position
    grab._physics_process(.01)
    blink.teleported.emit(fish.global_position,fish.global_position+Vector2(0,-320))
    shore.state = shore.State.AIRBORNE
    grab._physics_process(.01)
    check(grab.state==grab.State.FINISHED and grab.rounds_completed==1 and grab.retreats.size()==1,"Early surface exit retires the warning arms and completes the encounter")
    grab.reset()
    check(grab.state==grab.State.WAITING and not grab._evaded and grab.rounds_completed==0,"A fresh replay resets evasion and encounter count")
    print("SURFACE_GRAB_DODGE_EXIT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
