extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func until(predicate: Callable, seconds: float = 8.0) -> bool:
    var end := Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec()<end:
        if predicate.call(): return true
        await process_frame
    return false
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await process_frame
    await process_frame
    RenderingServer.force_draw(false)
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/checkpoint-"+label+".png")
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await process_frame
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("CameraAttention").enabled=false
    game.soul.hide()
    game.awake=true
    game.sleeping.hide()
    game.zzz.hide()
    var demon=game.demon
    demon.get_node("Host").take_control()
    demon.get_node("Patrol").process_mode=Node.PROCESS_MODE_DISABLED
    demon.get_node("Visual").show()
    game.player=demon
    game.possession.state=PossessionController.State.POSSESSED
    game.possession.enabled=false
    var point=game.get_node("Checkpoint")
    var platform=point.get_node(point.platform_path)
    check(point.z_index<platform.z_index,"Checkpoint renders behind existing platform")
    check(not point.has_node("Support"),"Checkpoint adds no floating support")
    var surface:Vector2=game.SURFACE.top_at(platform.get_node("Collision"),point.global_position.x)
    check(absf(point.global_position.y-surface.y-3)<.1,"Pedestal base rests on existing platform")
    demon.global_position=point.global_position+Vector2(-260,0)
    demon.get_node("Movement").enabled=false
    game.camera.set_follow_target(demon,true)
    game.camera.set_process(false)
    game.camera.adopt_view(point.global_position+Vector2(0,-180),Vector2.ONE*1.1)
    check(not point.active,"Checkpoint starts embedded and inactive")
    point._on_touch(game.soul)
    check(not point.active,"Ghost cannot register demon checkpoint")
    await shot("inactive")
    demon.global_position=point.global_position+Vector2(0,-180)
    demon.velocity=Vector2.ZERO
    demon.get_node("Movement").enabled=true
    check(await until(func(): return point.active,2),"Physical contact activates checkpoint")
    check(await until(func(): return demon.is_on_floor(),2),"Existing platform supports the player")
    var feet:Vector2=demon.global_position
    await create_timer(.7).timeout
    check(demon.global_position.distance_to(feet)<5,"Standing on the existing platform stays stable")
    check(point.get_node("Diamond").position.y < -125,"Diamond rises out of stone")
    var y:float=point.get_node("Diamond").position.y
    await create_timer(.5).timeout
    check(absf(y-point.get_node("Diamond").position.y)>2,"Activated diamond bobs")
    await shot("active")
    var flow=game.get_node("DeathFlow")
    for attempt in 2:
        demon.global_position=point.global_position+Vector2(100,-450)
        game.die(&"impact")
        check(await until(func(): return flow.overlay.state==flow.overlay.State.OPEN),"Death overlay opens")
        flow.overlay.retry.pressed.emit()
        check(await until(func(): return flow.state==flow.State.PLAYING),"Checkpoint retry completes")
        check(game.player==demon and demon.get_node("Host").claimed,"Retry preserves possessed demon")
        check(not game.soul.visible and game.get_node("WallEntry").completed,"Checkpoint skips ghost entry")
        check(demon.global_position.distance_to(point.get_node("Spawn").global_position)<12,"Retry returns to fixed stone position")
        check(demon.get_node("Input").enabled and demon.get_node("Movement").enabled,"Retry restores movement and input")
        check(point.active,"Checkpoint survives repeated deaths")
        check(game.get_node("RisingLava").surface_y-demon.position.y>600,"Lava resets below checkpoint")
        game.die(&"impact")
        check(not game.dead,"Brief return grace prevents immediate death")
        await create_timer(1.3).timeout
    await shot("respawn")
    # 从重生平台直接向左走落到较低平台，再沿平台走近即可锁定团团，全程不按跳跃。
    game.get_node("RisingLava").reset()
    var step=game.get_node("Platforms/CheckpointStep")
    var reader=demon.get_node("Input")
    demon.global_position=Vector2(1100,point.global_position.y-6)
    demon.velocity=Vector2.ZERO
    demon.get_node("Movement").reset()
    await create_timer(.15).timeout
    reader.external_control=true
    reader.move_axis=-1.0
    reader.jump_pressed=false
    reader.jump_held=false
    await physics_frame
    await physics_frame
    reader.jump_pressed=false
    reader.jump_held=false
    check(await until(func(): return demon.global_position.x<910 or game.dead,2),"Walking left reaches the lower platform without jumping")
    reader.move_axis=0.0
    check(await until(func(): return demon.is_on_floor() or game.dead,2),"Walking off checkpoint lands safely on the lower platform")
    check(not game.dead,"Approach avoids overhead spikes")
    check(absf(demon.global_position.y-game.SURFACE.landing_on(step).y)<10,"Player lands on new stepping platform")
    reader.move_axis=-1.0
    check(await until(func(): return demon.global_position.x<770 or game.dead,1),"Walk along the lower platform toward the left ball")
    reader.move_axis=0.0
    check(await until(func(): return game.get_node("Fork").selected==game.get_node("Fork/Targets/Target04"),1),"Left ball can be locked from stepping platform")
    game.camera.adopt_view(Vector2(850,44580),Vector2.ONE*.95)
    await shot("left-step")
    print("HELL_CHECKPOINT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
