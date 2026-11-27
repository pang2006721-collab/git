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
    seed(317)
    var choices: Array[int] = []
    for trial in 20:
        grab.reset()
        grab._physics_process(.01)
        for i in 140: grab._physics_process(.01)
        check(grab.state==grab.State.REACHING,"A random on-screen arm launches after warning")
        var selected: int = int(grab._arm.get_meta(&"formation_index"))
        if not choices.has(selected): choices.append(selected)
        for arm in grab._warning_arms:
            check(arm.visual_only and arm._shapes.is_empty(),"Visual tentacles do not rebuild needless physics capsules")
        grab._evaded = true
        for i in 70: grab._physics_process(.01)
        check(grab.state==grab.State.FINISHED and grab.attacks_started==1 and not grab.blocks_exit(),"One missed random attack opens the way to shore")
        if trial==0:
            check(grab.retreats.size()==2,"Unused arms and the missed attacking arm both receive a sinking retreat")
            var retreat = grab.retreats.back()
            retreat.set_physics_process(false)
            var sinking = retreat._arms[0]
            var original_y: float = sinking.global_position.y
            retreat._physics_process(.25)
            check(sinking.visible and sinking.modulate.a==1 and not sinking.is_queued_for_deletion(),"A missed arm stays visible instead of instantly disappearing or fading")
            check(sinking.global_position.y>original_y,"Retreat physically moves the arm down through the water")
            var midway: float = sinking.global_position.y
            retreat._physics_process(.4)
            check(sinking.global_position.y>midway,"The sinking movement continues smoothly")
            retreat._physics_process(.6)
            var highest := INF
            for point in sinking.centerline:
                highest = minf(highest,sinking.to_global(point).y-sinking.thickness*.5)
            var bottom: float = game.camera.global_position.y+game.camera.get_viewport_rect().size.y*.5/game.camera.zoom.y
            check(highest>bottom and retreat.is_queued_for_deletion(),"Retreat frees the original arm only after its full body has sunk out of view")
    check(choices.size()>=3,"Random selection varies across the visible arms rather than always choosing the nearest")
    grab.reset()
    grab._physics_process(.01)
    for i in 60: grab._physics_process(.01)
    var arm = grab._warning_arms[0]
    var before: PackedVector2Array = arm.mesh.polygon.duplicate()
    grab._physics_process(1.0/120)
    check(arm.mesh.polygon!=before,"Curve deformation updates every frame rather than waiting for a 24Hz tick")
    for phase in range(40):
        arm.wave_phase = phase*.16
        arm.geometry_locked = false
        arm.sample(1)
        for face in arm.mesh.polygons:
            var points: PackedVector2Array = arm.mesh.polygon
            check((points[face[1]]-points[face[0]]).cross(points[face[2]]-points[face[0]])<0,"Thick waving tentacle geometry cannot fold inside-out or tear")
    grab._evaded = true
    for i in 200: grab._physics_process(.01)
    fish.position.y = shore.surface_y-2
    fish.velocity.y = -420
    fish.get_node("Input").external_control = true
    fish.get_node("Input").up_held = true
    shore._physics_process(.01)
    check(shore.state==shore.State.AIRBORNE,"Normal W-to-shore leap works after the single encounter")
    print("SURFACE_RANDOM_GRAB_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
