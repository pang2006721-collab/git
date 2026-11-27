extends SceneTree
var game
var frames:=0
func _initialize():run.call_deferred()
func wait_frames(count:int):
    for i in count:
        await process_frame
        frames+=1
func run():
    root.size=Vector2i(1280,720)
    game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    game.get_node("OrangePickupCounter").visible=false
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("CameraAttention").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.soul.show()
    game.soul.global_position=game.demon.global_position+Vector2(-165,0)
    game.soul.get_node("Movement").enabled=false
    game.soul.get_node("Input").enabled=false
    game.camera.enabled=true
    game.camera.set_follow_target(game.soul)
    game.camera.global_position=game.demon.global_position+Vector2(0,-180)
    await wait_frames(60)
    game.possession.enabled=true
    assert(game.possession.request_possession())
    await wait_frames(100)
    var rig=game.get_node("Fork")
    rig.reset()
    var target=game.get_node("Fork/Targets/Target02")
    var platform=game.get_node("Platforms/Static08")
    var surface=load("res://modules/environment/hell_surface.gd")
    var motor=game.demon.get_node("Movement")
    var reader=game.demon.get_node("Input")
    reader.external_control=true
    reader.enabled=true
    reader.clear()
    motor.enabled=true
    motor.reset()
    game.demon.global_position=surface.landing_on(platform)
    game.demon.reset_physics_interpolation()
    game.camera.set_process(false)
    game.camera.global_position=Vector2(960,(target.global_position.y+game.demon.global_position.y)*.5)
    game.set_physics_process(false)
    await wait_frames(60)
    assert(game.demon.is_on_floor(),"Demo must start standing on the real platform")
    assert(rig.selected==null,"Target must be outside locking range before the jump")
    var standing_y:float=game.demon.global_position.y
    reader.jump_pressed=true
    reader.jump_held=true
    await wait_frames(2)
    reader.jump_pressed=false
    for i in 50:
        if rig.selected==target:break
        await wait_frames(1)
    assert(rig.selected==target,"The actual jump must naturally acquire the target")
    assert(not game.demon.is_on_floor() and game.demon.global_position.y<standing_y-100,"Selection happens during a real jump")
    await wait_frames(8)
    var throw_frame:=frames
    var arrivals:Array=[]
    rig.exchanged.connect(func(body):arrivals.append(body.global_position))
    var key=InputEventKey.new()
    key.physical_keycode=KEY_SHIFT
    key.keycode=KEY_SHIFT
    key.location=KEY_LOCATION_LEFT
    key.pressed=true
    rig._unhandled_input(key)
    assert(rig.flying,"One Shift throws only after automatic selection")
    reader.jump_held=false
    await wait_frames(140)
    assert(arrivals.size()==1,"The fork must actually reach the selected ball and teleport")
    rig.reset()
    motor.enabled=true
    motor.reset()
    reader.external_control=true
    reader.clear()
    game.demon.global_position=surface.landing_on(platform)
    game.demon.reset_physics_interpolation()
    game.camera.global_position=Vector2(960,game.demon.global_position.y-200)
    motor.facing=1.0
    motor.facing_changed.emit(1.0)
    await wait_frames(45)
    assert(game.demon.is_on_floor())
    var encounter=game.get_node("FlyingEnemies")
    encounter.enabled=true
    encounter.set_physics_process(false)
    var enemy=load("res://scenes/enemies/flying_demon.tscn").instantiate()
    enemy.encounter=encounter
    enemy.position=game.demon.global_position+Vector2(260,-220)
    encounter.get_node("Enemies").add_child(enemy)
    enemy._cooldown=10.0
    await wait_frames(45)
    print("ENEMY_DEMO ",game.demon.global_position," ",enemy.global_position," selected=",rig.selected," flying=",rig.flying," launch=",rig.launching)
    assert(rig.selected==enemy,"Enemy must be selected by the real targeting controller")
    rig.enemy_hit_chance=1.0
    var attack_frame:=frames
    rig._unhandled_input(key)
    await wait_frames(30)
    assert(is_instance_valid(enemy) and enemy.is_defeated(),"Fork must trigger the actual enemy death animation")
    await wait_frames(130)
    var meta={"shift_beats":[1.0,throw_frame/60.0,attack_frame/60.0],"duration":frames/60.0,"jump_from":"Platforms/Static08","target":"Target02"}
    var file=FileAccess.open("res://assets/video/hell_shift.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(meta,"  "))
    file.close()
    print("TUTORIAL_RECORDING_COMPLETE ",JSON.stringify(meta))
    quit()
