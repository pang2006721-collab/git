extends SceneTree
var frames:=0
var hits:=0
var casts:=0
func _initialize():run.call_deferred()
func wait_frames(count:int):
    for i in count:
        await process_frame
        frames+=1
func run():
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.soul.hide()
    game.demon.hide()
    game.get_node("OrangePickupCounter").visible=false
    game.get_node("CameraAttention").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    game.player=stage.fish
    stage.fish.global_position=Vector2(960,35000)
    stage.set_physics_process(false)
    var reader=stage.fish.get_node("Input")
    reader.external_control=true
    reader.enabled=true
    reader.clear()
    stage.fish.get_node("Movement").enabled=false
    stage.fish.get_node("Visual").reset()
    var blink=stage.fish.get_node("Teleport")
    blink.enabled=true
    blink.teleported.connect(func(_a,_b):casts+=1)
    game.camera.enabled=true
    game.camera.set_process(false)
    game.camera.global_position=Vector2(960,34900)
    game.camera.zoom=Vector2.ONE
    var shark=load("res://scenes/enemies/ocean_shark.tscn").instantiate()
    shark.entry_side=-1
    shark.first_spawn_delay=1.0
    root.add_child(shark)
    shark.configure(stage.fish,game.camera)
    shark.player_hit.connect(func(_d):hits+=1)
    shark.enabled=true
    for i in 180:
        if shark.state==shark.State.DASHING:break
        await wait_frames(1)
    assert(shark.state==shark.State.DASHING)
    await wait_frames(9)
    var locked:Vector2=shark.locked_point
    var before:Vector2=stage.fish.global_position
    var beat:=frames/60.0
    reader.up_held=true
    var key=InputEventKey.new()
    key.physical_keycode=KEY_SHIFT
    key.keycode=KEY_SHIFT
    key.location=KEY_LOCATION_LEFT
    key.pressed=true
    blink._unhandled_input(key)
    await wait_frames(12)
    reader.up_held=false
    assert(casts==1 and stage.fish.global_position.y<before.y-300,"Actual Shift blink must move the fish away")
    assert(shark.locked_point==locked,"Committed shark attack must not retarget after the dodge")
    await wait_frames(150)
    assert(hits==0 and not game.dead,"The real shark sweep must miss the dodging fish")
    var file=FileAccess.open("res://assets/video/ocean_dodge.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"shift_beats":[beat],"duration":frames/60.0},"  "))
    file.close()
    print("OCEAN_RECORDING_PASS ",frames," frames; beat=",beat)
    quit()
