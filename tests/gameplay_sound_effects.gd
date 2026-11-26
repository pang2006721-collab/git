extends SceneTree
var failures: Array[String] = []
var cues: Array[StringName] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func count(cue: StringName) -> int:
    return cues.count(cue)
func run():
    var sfx = root.get_node("Sfx")
    sfx.played.connect(func(cue):cues.append(cue))
    check(sfx.levels.size()==20,"All twenty supplied sound effects including ocean and transition cues are available")
    check(AudioServer.get_bus_index("SFX")>=0 and sfx._movement.bus==&"SFX","Movement and one-shots use an independent SFX bus")
    var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    var first_click := count(&"ui")
    menu.get_node("Settings").pressed.emit()
    check(count(&"ui")==first_click+1,"First menu click sounds immediately without waiting for deferred binding")
    sfx._bind_button(menu.get_node("Settings"))
    await process_frame
    await process_frame
    var before := count(&"ui")
    menu.get_node("Settings").pressed.emit()
    check(count(&"ui")==before+1,"Actual settings button plays exactly one UI click")
    var map = menu.get_node("DescentWorld/ArrivalMap")
    before = count(&"arrow")
    map.get_node("NearMissArrows")._fire(0)
    map.get_node("PillarArrows")._fire(0)
    check(count(&"arrow")==before+2,"Each actual ordinary chase arrow produces one sound")
    before = count(&"volley")
    var exit_arrows = map.get_node("ExitArrows")
    for i in range(exit_arrows.target_paths.size()): exit_arrows._fire(i)
    check(count(&"volley")==before+1,"The final twenty-four-arrow rain uses one dense volley sound without stacking it twenty-four times")
    var ghost_runner = map.get_node("ChaseActors/Ghost")
    menu.get_node("DescentWorld").show()
    map.show()
    map.get_node("ChaseActors").show()
    ghost_runner.start()
    await create_timer(.1).timeout
    check(sfx.cinematic_running and sfx._movement_kind==&"ghost_run" and sfx._movement.playing,"Chase animation's running ghost uses the supplied ground-movement loop")
    menu.get_node("GameHandoff").prepare()
    menu.get_node("GameHandoff").gameplay.get_node("GameplaySounds")._physics_process(0)
    check(sfx.cinematic_running and sfx._movement_target>0,"Background gameplay preloading cannot mute the cinematic footsteps")
    ghost_runner.running = false
    await create_timer(.15).timeout
    check(not sfx.cinematic_running and not sfx._movement.playing,"Cinematic footsteps fade out as soon as the ghost stops")
    ghost_runner.start()
    await create_timer(.05).timeout
    check(sfx.cinematic_running,"Cinematic audio can restart without creating duplicate loops")
    before = count(&"ui")
    menu.get_node("Start").pressed.emit()
    check(count(&"ui")==before+1,"Start click also sounds once")
    menu.queue_free()
    await process_frame
    check(not sfx.cinematic_running,"Leaving the menu clears cinematic audio ownership")
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    game.get_node("RisingLava").process_mode = Node.PROCESS_MODE_DISABLED
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var audio = game.get_node("GameplaySounds")
    game.soul.position = game.demon.position+Vector2(-90,0)
    await physics_frame
    await physics_frame
    before = count(&"possess")
    check(game.possession.request_possession(),"Actual Shift possession can start")
    check(count(&"possess")==before+1,"Successful demon possession plays one Shift sound at transfer start")
    check(not game.possession.request_possession() and count(&"possess")==before+1,"Holding or repeating Shift during transfer cannot duplicate possession audio")
    await create_timer(.6).timeout
    game.demon.get_node("Movement").enabled = false
    game.demon.get_node("Input").external_control = true
    var fork = game.get_node("Fork")
    fork.set_physics_process(false)
    var ball = game.get_node("Fork/Targets/Target02")
    game.demon.global_position = ball.global_position+Vector2(-260,260)
    game.camera.set_follow_target(game.demon,true)
    fork.selected = ball
    before = count(&"fork")
    fork._throw()
    check(count(&"fork")==before+1,"Throwing the player's real fork produces its sound")
    await create_timer(.4).timeout
    before = count(&"bounce")
    fork._swap_and_bounce()
    var jumps_before_bounce := count(&"jump")
    await create_timer(.35).timeout
    check(count(&"bounce")==before+1,"Ball bounce audio starts with actual launch after teleport")
    await create_timer(1.1).timeout
    check(count(&"jump")==jumps_before_bounce+1,"Landing after the actual ball launch plays the landing sound once")
    game.demon.get_node("Movement").landed.emit(650)
    check(count(&"jump")==jumps_before_bounce+1,"Ball landing cannot replay on repeated floor contact")
    fork.reset()
    game.demon.get_node("Movement").enabled = false
    var manager = game.get_node("FlyingEnemies")
    manager.enabled = true
    game.camera.set_follow_target(game.demon,true)
    before = count(&"fork")
    manager._shoot(game.demon.global_position+Vector2(0,-50),game.demon.global_position+Vector2(220,-140))
    check(count(&"fork")==before+1,"An enemy's actual launched fork uses the same normalized throw cue")
    manager.enabled = false
    manager.reset()
    var brittle = game.get_node("Platforms/Breakable18")
    brittle.set_physics_process(false)
    game.camera.set_follow_target(brittle,true)
    before = count(&"fracture")
    brittle._release_pieces()
    check(count(&"fracture")==before+1,"Breaking the actual platform plays one fracture cue at separation")
    brittle.reset()
    var motor = game.demon.get_node("Movement")
    game.demon.global_position = game._demon_spawn
    motor.reset()
    motor.enabled = true
    game.player = game.demon
    var reader = game.demon.get_node("Input")
    reader.enabled = true
    reader.external_control = true
    reader.clear()
    for i in range(20): await physics_frame
    reader.move_axis = 1
    for i in range(12): await physics_frame
    check(sfx._movement_kind==&"demon_run" and sfx._movement.playing,"Real grounded demon movement starts the running loop")
    before = count(&"jump")
    reader.move_axis = 0
    reader.jump_pressed = true
    reader.jump_held = true
    await physics_frame
    await physics_frame
    reader.jump_pressed = false
    check(count(&"jump")==before+1,"One real demon jump produces one jump cue")
    for i in range(20): await physics_frame
    check(not sfx._movement.playing,"Footsteps fade out while airborne instead of running through a jump")
    reader.jump_held = false
    for i in range(260):
        await physics_frame
        if game.demon.is_on_floor(): break
    check(game.demon.is_on_floor() and count(&"jump")==before+2,"The same jump sound plays once again on the real landing")
    motor.landed.emit(600)
    check(count(&"jump")==before+2,"Standing contacts and synthetic landing feedback do not repeat the jump-landing cue")
    motor.enabled = false
    game.player = game.soul
    game.soul.show()
    game.soul.position = game._ghost_spawn
    var ghost_motor = game.soul.get_node("Movement")
    var ghost_reader = game.soul.get_node("Input")
    ghost_reader.enabled = true
    ghost_reader.external_control = true
    ghost_reader.clear()
    ghost_motor.enabled = true
    for i in range(20): await physics_frame
    ghost_reader.move_axis = 1
    for i in range(12): await physics_frame
    check(sfx._movement_kind==&"ghost_run" and sfx._movement.playing,"The ghost's real flat-ground movement uses the eleventh supplied cue")
    check(absf(sfx._movement.volume_db-8.13)<.1,"Ghost footsteps use the reduced gain during actual movement")
    before = count(&"death")
    game.die(&"impact")
    game.die(&"impact")
    check(count(&"death")==before+1,"Repeated death calls still produce a single death sound")
    await create_timer(.15,true,false,true).timeout
    check(not sfx._movement.playing,"Death immediately requests footsteps to fade out even during level freeze")
    var stage = game.get_node("OceanLink/FishStage")
    game.dead = false
    game.exit_in_progress = false
    game.player = stage.fish
    game.die(&"impact")
    check(count(&"death")==before+2,"The same shared player death event sounds in the ocean as well")
    var overlay = game.get_node("DeathFlow").overlay
    await process_frame
    overlay.state = overlay.State.OPEN
    before = count(&"ui")
    overlay.retry.pressed.emit()
    check(count(&"ui")==before+1,"Death-window retry button uses the common UI click")
    await create_timer(2.8,true,false,true).timeout
    game.queue_free()
    await process_frame
    await process_frame
    print("GAMEPLAY_SOUND_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
