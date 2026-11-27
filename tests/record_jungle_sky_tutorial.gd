extends SceneTree
var frames:=0
var game
var stage
var layout
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
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.soul.hide()
    game.demon.hide()
    game.get_node("OrangePickupCounter").visible=false
    game.get_node("CameraAttention").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for key in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:stage.get_node(key).process_mode=Node.PROCESS_MODE_DISABLED
    layout=stage.get_node("JungleLayout")
    for key in ["BeeEncounter","CanopyTransition","SkyCloudExit","CanopyBirdStage"]:layout.get_node(key).process_mode=Node.PROCESS_MODE_DISABLED
    game.camera.enabled=true
    game.camera.zoom=Vector2.ONE
    game.camera.set_process(false)
    if "--sky" in OS.get_cmdline_user_args():await record_sky()
    else:await record_jungle()
func record_jungle():
    var body=layout.get_node("Squirrel")
    var climber=body.get_node("VineClimber")
    var motor=body.get_node("Movement")
    var reader=body.get_node("Input")
    body.get_node("FallDeath").set_physics_process(false)
    body.get_node("Host").take_control()
    game.player=body
    climber.detach(false)
    reader.external_control=true
    reader.enabled=true
    reader.clear()
    motor.enabled=true
    motor.reset()
    var floor_shape=layout.get_node("JungleFloor/Collision")
    var floor_y:float=floor_shape.global_position.y-floor_shape.shape.size.y*.5
    var vine=layout.get_node("InteractiveVines/Vine09")
    body.global_position=Vector2(vine.global_position.x+70,floor_y-3)
    game.camera.global_position=Vector2(960,(floor_y+vine.global_position.y)*.5)
    await wait_frames(45)
    assert(body.is_on_floor(),"Squirrel starts on the actual ground")
    reader.jump_pressed=true
    reader.jump_held=true
    await wait_frames(6)
    reader.jump_pressed=false
    var first_press:=frames/60.0
    Input.action_press(&"possess")
    for i in 100:
        if climber.vine!=null:break
        await wait_frames(1)
    assert(climber.vine!=null,"Held Shift catches the real vine after jumping")
    reader.jump_held=false
    reader.move_axis=1
    var caught_at:=frames
    var ready:=false
    for i in 240:
        await wait_frames(1)
        if frames-caught_at>90 and body.velocity.x>250 and body.velocity.y<0:
            ready=true
            break
    assert(ready,"Actual rope swing must build rightward and upward momentum")
    var before:Vector2=body.global_position
    var release_time:=frames/60.0
    Input.action_release(&"possess")
    await wait_frames(3)
    assert(climber.vine==null and body.velocity.y<0,"Releasing Shift launches the squirrel upward")
    game.camera.resume_follow_from_current_position(body)
    game.camera.set_process(true)
    reader.move_axis=1
    var next_vine=layout.get_node("InteractiveVines/Vine08")
    var reached:=false
    for i in 100:
        await wait_frames(1)
        var hands:Vector2=body.global_position+climber.hands_offset*body.global_scale
        if next_vine.can_grab(hands):
            reached=true
            break
    print("JUNGLE_FLIGHT next=",reached," before=",before," body=",body.global_position)
    var beats:Array=[first_press]
    var holds:Array=[[first_press,release_time]]
    if reached:
        var catch_time:=frames/60.0
        Input.action_press(&"possess")
        await wait_frames(5)
        assert(climber.vine==next_vine,"Held Shift catches the next actual vine")
        beats.append(catch_time)
        await wait_frames(65)
        holds.append([catch_time,frames/60.0])
    else:
        assert(body.global_position.y<before.y,"Release demonstrates upward progress")
        await wait_frames(25)
    Input.action_release(&"possess")
    save_recording("jungle",beats,holds)
func record_sky():
    var bird=layout.get_node("Bird")
    bird.get_node("Host").take_control()
    game.player=bird
    bird.global_position=Vector2(960,12000)
    bird.show()
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Movement").enabled=true
    bird.get_node("Patrol").set_physics_process(false)
    bird.get_node("Input").external_control=false
    bird.get_node("Input").enabled=true
    var eagle=layout.get_node("SkyEagle")
    eagle.set_process(false)
    var hail=eagle.get_node("Hail")
    hail.set_physics_process(false)
    hail._rng.seed=43
    var fire=bird.get_node("Boost")
    fire.reset()
    game.camera.global_position=bird.global_position+Vector2(0,-160)
    await wait_frames(312)
    hail._spawn_row()
    var stone:Dictionary=hail.stones[0]
    for other in hail.stones.slice(1):other.art.queue_free()
    hail.stones.clear()
    hail.stones.append(stone)
    stone.art.global_position.x=bird.global_position.x
    hail._previous_target=bird.global_position
    hail.set_physics_process(true)
    for i in 140:
        if stone.art.global_position.y>=bird.global_position.y-220:break
        await wait_frames(1)
    assert(fire.heat>=.999 and not fire.burning,"The real six-second charge fills before Shift")
    var beat:=frames/60.0
    Input.action_press(&"bird_boost")
    await wait_frames(20)
    assert(fire.is_burning() and stone.get("melting",false),"Held Shift burns and starts melting the approaching ice")
    var partial:float=stone.art.scale.x
    await wait_frames(14)
    assert(stone.art.scale.x<partial,"The actual ice shrinks gradually")
    await wait_frames(34)
    assert(not hail.stones.has(stone) and not game.dead,"Sustained flame melts the actual block without death")
    Input.action_release(&"bird_boost")
    var release_time:=frames/60.0
    await wait_frames(55)
    save_recording("sky",[beat],[[beat,release_time]])
func save_recording(key:String,beats:Array,holds:Array):
    var data={"shift_beats":beats,"shift_holds":holds,"duration":frames/60.0}
    var file=FileAccess.open("res://assets/video/"+key+"_shift.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(data,"  "))
    file.close()
    print("TUTORIAL_RECORDING_PASS ",key," ",JSON.stringify(data))
    quit()
