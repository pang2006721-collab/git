extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func until(predicate: Callable,seconds: float=8.0) -> bool:
    var end:=Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec()<end:
        if predicate.call(): return true
        await process_frame
    return false
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await process_frame
    await process_frame
    RenderingServer.force_draw(false)
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/ocean-checkpoint-"+label+".png")
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await process_frame
    game.get_node("SegmentStart").start_segment(3)
    var stage=game.get_node("OceanLink/FishStage")
    stage.set_physics_process(false)
    stage.get_node("JellyfishBoss").enabled=false
    stage.get_node("JellyfishBoss").reset()
    stage.get_node("JellyfishReveal").reset()
    var fish=stage.fish
    var point=game.get_node("OceanCheckpoint")
    fish.get_node("Movement").enabled=false
    fish.global_position=point.global_position+Vector2(-330,0)
    game.camera.set_process(false)
    game.camera.adopt_view(point.global_position+Vector2(-550,-80),Vector2.ONE)
    check(not point.active and not point.get_node("Float/Bubble").visible,"Bubble remains hidden before contact")
    check(point.get_node("Float/Diamond").z_index<17,"Embedded diamond sits behind original wall")
    await shot("embedded")
    fish.global_position=point.global_position+Vector2(-170,0)
    check(await until(func():return point.active,1),"Approaching fish activates checkpoint")
    await create_timer(.22).timeout
    check(point.get_node("Float/Bubble").visible,"Activation pops the bubble")
    await shot("pop")
    await create_timer(.65).timeout
    check(point.get_node("Float/Bubble").scale.is_equal_approx(Vector2.ONE),"Bubble settles exactly after rebound")
    check(point.get_node("Float").position.x < -150,"Diamond springs clear of wall")
    check(absf(point.get_node("Float/Diamond").rotation)<.001,"Popped diamond becomes upright")
    var motion:Vector2=fish.global_position
    fish.get_node("Movement").enabled=true
    fish.velocity=Vector2.ZERO
    check(fish.test_move(fish.global_transform,Vector2.RIGHT*20)==false,"Checkpoint water is outside wall collision")
    fish.get_node("Movement").enabled=false
    await shot("active")
    # Both reached: ocean must replace the earlier Hell checkpoint.
    game.get_node("Checkpoint").active=true
    check(game.get_active_checkpoint()==point,"Latest ocean checkpoint takes priority over Hell")
    stage.set_physics_process(true)
    var flow=game.get_node("DeathFlow")
    for attempt in 2:
        if attempt==1: stage.get_node("ShoreExit").start_on_shore(960)
        else: fish.global_position+=Vector2(-150,-450)
        game.die(&"impact")
        check(await until(func():return flow.overlay.state==flow.overlay.State.OPEN),"Ocean death screen opens")
        flow.overlay.retry.pressed.emit()
        check(await until(func():return flow.state==flow.State.PLAYING),"Ocean checkpoint return completes")
        check(game.player==fish and stage.host.claimed and stage.active,"Retry restores possessed fish")
        check(game.get_node("OceanLink").stage==game.get_node("OceanLink").Stage.OCEAN,"Retry stays in ocean stage")
        check(not game.demon.visible and not game.soul.visible,"No demon or ghost remains visible")
        check(fish.global_position.distance_to(point.global_position+Vector2(-point.pop_distance,0))<15,"Fish respawns in checkpoint bubble")
        check(fish.get_node("Input").enabled and fish.get_node("Movement").enabled and fish.get_node("Teleport").enabled,"Swim and dodge controls restore")
        check(stage.get_node("ShoreExit").state==stage.get_node("ShoreExit").State.SWIMMING,"Shore sequence resets to underwater swimming")
        check(fish.motion_mode==CharacterBody2D.MOTION_MODE_FLOATING,"Shore death retry restores floating body mode")
        check(not game.get_node("OceanLink/Breath").active,"Demon drowning timer stays off")
        game.die(&"impact")
        check(not game.dead,"Return gives brief death protection")
        check(not fish.get_node("Stun").apply(),"Return protection also prevents immediate stun")
        await create_timer(1.7).timeout
    await shot("respawn")
    print("OCEAN_CHECKPOINT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
