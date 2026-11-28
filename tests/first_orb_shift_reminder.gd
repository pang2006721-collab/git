extends SceneTree
func _initialize():run.call_deferred()
func until(predicate:Callable,seconds:float=3.0)->bool:
    var end=Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec()<end:
        if predicate.call():return true
        await physics_frame
    return false
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    root.add_child(game)
    current_scene=game
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.get_node("CameraAttention").enabled=false
    game.set_physics_process(false)
    var body=game.demon
    body.get_node("Host").take_control()
    game.player=body
    game.sleeping.hide()
    game.zzz.hide()
    body.show()
    body.get_node("Visual").show()
    var motor=body.get_node("Movement")
    var reader=body.get_node("Input")
    reader.external_control=true
    reader.enabled=true
    reader.clear()
    motor.enabled=true
    motor.reset()
    var surface=load("res://modules/environment/hell_surface.gd")
    body.global_position=surface.landing_on(game.get_node("Platforms/Static08"))
    var ball=game.get_node("Fork/Targets/Target02")
    var rig=game.get_node("Fork")
    var hint=game.get_node("FirstOrbShiftReminder")
    game.camera.set_process(false)
    game.camera.global_position=Vector2(960,(ball.global_position.y+body.global_position.y)*.5)
    assert(await until(func():return body.is_on_floor()))
    assert(not hint.visible and not hint.missed.has(ball.name),"No hint before a missed attempt")
    for attempt in 2:
        reader.jump_pressed=true
        reader.jump_held=true
        await physics_frame
        await physics_frame
        reader.jump_pressed=false
        assert(await until(func():return rig.selected==ball),"Real platform jump locks the orb")
        if attempt==0:
            assert(not hint.visible,"First opportunity lets the player try independently")
            reader.jump_held=false
            assert(await until(func():return body.is_on_floor()))
            assert(hint.missed.has(ball.name),"Missed jump arms the next opportunity")
        else:
            assert(await until(func():return hint.visible))
            hint._process(.15)
            assert(hint.art.scale.y<.8,"Reminder has a strong pressed shape")
            assert((hint.art.get_global_transform()*(hint.art.size*.5)).is_equal_approx(hint._follow_position),"Repeated press is centered on the following anchor")
            assert(not paused,"Reminder does not interrupt play")
            var target_before:Vector2=hint.head_target()
            assert(hint._follow_position.distance_to(target_before)<100,"Hint stays near the demon head rather than screen center")
            body.global_position.x+=100
            var moved:Vector2=hint.head_target()
            hint._follow_head(.016)
            assert(hint._follow_position.x<moved.x-10,"Head label trails horizontal movement")
            for i in 90:hint._follow_head(1.0/60)
            assert(hint._follow_position.distance_to(moved)<1,"Head label catches up after stopping")
            body.global_position.x-=100
            hint._follow_ready=false
            hint._process(0)

            if DisplayServer.get_name()!="headless":
                await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/first-orb-shift-reminder.png")
            var key=InputEventKey.new()
            key.physical_keycode=KEY_SHIFT
            key.keycode=KEY_SHIFT
            key.location=KEY_LOCATION_LEFT
            key.pressed=true
            hint._input(key)
            rig._unhandled_input(key)
            assert(rig.flying and hint.learned.has(ball.name))
            hint._process(.15)
            assert(hint.visible and hint.art.scale.y<.8,"Actual Shift gives a visible pressed response before dismissal")
            assert((hint.art.get_global_transform()*(hint.art.size*.5)).is_equal_approx(hint._follow_position),"Actual Shift also rebounds around the following center")
            reader.jump_held=false
            assert(await until(func():return not hint.visible))
            hint._reset_interaction()
            assert(hint.learned.has(ball.name),"Retry keeps learned orb state within this run")
    print("FIRST_ORB_REMINDER_PASS: actual missed/repeated jump, strong press, throw acknowledgement, no pause")
    quit()
