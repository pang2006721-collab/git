extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void:run.call_deferred()
func check(ok:bool,message:String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func until(predicate:Callable,seconds:float=8.0) -> bool:
    var end:=Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec()<end:
        if predicate.call():return true
        await process_frame
    return false
func shot(label:String) -> void:
    if DisplayServer.get_name()=="headless":return
    await process_frame
    await process_frame
    RenderingServer.force_draw(false)
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/jungle-checkpoint-"+label+".png")
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await process_frame
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var point=game.get_node("JungleCheckpoint")
    var body=point.body
    point.restore_player()
    var branch=point.get_node("Branch")
    branch.hide()
    branch.get_node("Collision").disabled=true
    body.get_node("Movement").enabled=false
    point.layout.get_node("BeeEncounter").enabled=false
    body.global_position=point.global_position+Vector2(-270,100)
    game.camera.set_process(false)
    game.camera.adopt_view(point.global_position+Vector2(80,10),Vector2.ONE)
    var rest:Vector2=point.get_node("Float").position
    await create_timer(.3).timeout
    check(not point.active and point.get_node("Float").position==rest,"Bound diamond stays completely still before touch")
    await shot("bound")
    body.global_position=point.get_node("Contact").global_position-Vector2(34,-81.5)
    check(await until(func():return point.active,1),"Touching bound diamond activates checkpoint")
    check(not point.get_node("Binding").visible,"Binding bursts off on contact")
    await create_timer(.2).timeout
    await shot("burst")
    await create_timer(.6).timeout
    check(point.get_node("Float").position.y<-80,"Freed diamond floats above main vine")
    check(game.get_active_checkpoint()==point,"Jungle checkpoint takes priority")
    var flow=game.get_node("DeathFlow")
    for attempt in 2:
        game.die(&"bee")
        check(await until(func():return flow.overlay.state==flow.overlay.State.OPEN),"Squirrel death opens retry screen")
        flow.overlay.retry.pressed.emit()
        check(await until(func():return flow.state==flow.State.PLAYING),"Jungle checkpoint retry completes")
        check(game.player==body and body.get_node("Host").claimed,"Retry restores squirrel control")
        check(body.get_node("Movement").enabled and body.get_node("Input").enabled,"Ground movement and jumping restore")
        check(body.get_node("VineClimber").vine==null,"Respawn is free on branch instead of attached to old vine")
        check(not point.stage.fish.visible and not game.soul.visible and not game.demon.visible,"Earlier hosts stay hidden")
        check(branch.visible and not branch.broken,"Every respawn creates a fresh short branch")
        check(await until(func():return body.is_on_floor(),1),"Squirrel stands on short branch")
        check(branch.get_node("Art").texture.get_width()*branch.get_node("Art").scale.x<220,"Perch is only squirrel-sized")
        if attempt==0:
            await shot("perch")
            check(await until(func():return branch.broken,4),"Temporary branch breaks after standing grace")
            check(branch._pieces.size()==4,"Broken branch splits into four falling pieces")
            await process_frame
            await shot("broken")
            check(branch.get_node("Collision").disabled,"Broken ledge releases collision")
        else:
            # Hold jump and grab: actual controller must reach an existing hanging vine.
            var reader=body.get_node("Input")
            reader.external_control=true
            reader.jump_pressed=true
            reader.jump_held=true
            Input.action_press(&"possess")
            await physics_frame
            await physics_frame
            reader.jump_pressed=false
            check(await until(func():return body.get_node("VineClimber").vine!=null,1.5),"Squirrel can jump and grab nearby existing vine before perch breaks")
            Input.action_release(&"possess")
    print("JUNGLE_CHECKPOINT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
