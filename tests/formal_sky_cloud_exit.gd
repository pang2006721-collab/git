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
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/sky-cloud-"+label+".png")
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await process_frame
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("CameraAttention").enabled=false
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    var exit=layout.get_node("SkyCloudExit")
    # 本测试只隔离检查原钻云组件；正式整段接续另由natural_heaven_ending覆盖。
    exit.ending_handoff.enabled=false
    var eagle=layout.get_node("SkyEagle")
    var arrival_snapshot:Dictionary={}
    exit.arrived.connect(func():
        arrival_snapshot["velocity"]=game.soul.velocity
        arrival_snapshot["position"]=game.soul.position
        arrival_snapshot["input"]=game.soul.get_node("Input").enabled
        arrival_snapshot["ripple"]=exit._ripple.visible
    )
    eagle.set_process(false)
    bird.get_node("Host").take_control()
    bird.get_node("Movement").enabled=false
    game.player=bird
    game.soul.hide()
    game.demon.hide()
    bird.position=Vector2(960,exit.height_at("sky",960)+150)
    game.camera.zoom=Vector2.ONE
    game.camera.set_follow_target(bird,true)
    game.camera.set_process(true)
    game.camera.make_current()
    var camera_id:int=root.get_camera_2d().get_instance_id()
    await create_timer(.2).timeout
    check(exit.state==exit.State.WAITING,"No premature transition below top cloud")
    check(exit.get_node("SkyCloudFront").z_index>bird.z_index,"Original cloud masks bird from foreground")
    check(exit.get_node("SkyCloudFront").texture.resource_path=="res://assets/art/reference_map/02.png","Cloud uses current formal map art")
    eagle.get_node("Hail")._on_departed()
    await create_timer(.4).timeout
    check(not eagle.get_node("Hail").stones.is_empty(),"Fixture has active hail before entering cloud")
    await shot("approach")
    bird.position.y=exit.height_at("sky",960)+20
    check(await until(func():return exit.state==exit.State.ENTERING,1),"Crossing original cloud edge starts entry")
    check(game.exit_in_progress and not bird.get_node("Input").enabled and not bird.get_node("Movement").enabled,"Cloud entrance takes control once")
    check(eagle.get_node("Hail").stones.is_empty() and not eagle.is_processing(),"Cloud entry clears hail and stops eagle")
    await create_timer(.3).timeout
    await shot("burrow")
    check(await until(func():return exit.state==exit.State.TRAVELLING),"Bird hides before camera travel")
    check(not bird.visible,"Bird is completely inside cloud before ascent")
    var start_y:float=game.camera.global_position.y
    await create_timer(1).timeout
    check(game.camera.global_position.y<start_y-300,"Same camera moves upward through existing map")
    check(await until(func():return exit.state==exit.State.COMPLETE),"Cloud travel and ghost emergence complete")
    check(arrival_snapshot.velocity==Vector2(0,-620),"Ghost gets exact legacy upward launch speed")
    check(arrival_snapshot.position.distance_to(Vector2(960,exit.walkway_y-2))<.1,"Ghost starts immediately at cloud surface")
    check(arrival_snapshot.input and arrival_snapshot.ripple,"Legacy launch immediately enables control and pulses cloud ripple")
    check(game.soul.scale==Vector2.ONE*1.4,"Legacy ghost size is retained")
    check(root.get_camera_2d().get_instance_id()==camera_id,"Transition preserves the existing display camera")
    check(game.player==game.soul and game.soul.visible and not bird.visible,"Heaven hands control to original ghost")
    check(game.soul.get_node("Input").enabled and game.soul.get_node("Movement").enabled,"Ghost can move after emergence")
    check(not game.exit_in_progress and game.camera.is_processing(),"Camera following and gameplay resume")
    check(game.camera.world_bounds==Rect2(0,0,1920,52000),"Authored world bounds remain unchanged")
    await shot("heaven")
    check(await until(func():return game.soul.is_on_floor(),4),"Ghost lands on the original painted cloud")
    var soul=game.soul
    var left_height:float=soul.position.y
    var reader=soul.get_node("Input")
    reader.external_control=true
    reader.move_axis=-1.0
    await create_timer(.6).timeout
    check(absf(soul.position.y-left_height)<2,"Invisible walkway stays level while walking")
    check(exit.gaze.gaze.x<0,"God eyes follow ghost moving left")
    await create_timer(1.1).timeout
    check(soul.position.x>exit.walkway_bounds.x+25,"Left air wall stops ghost leaving platform")
    reader.move_axis=1.0
    await create_timer(3).timeout
    check(exit.gaze.gaze.x>0,"God eyes follow ghost moving right")
    check(soul.position.x<exit.walkway_bounds.y-25,"Right air wall stops ghost leaving platform")
    reader.move_axis=0
    await shot("walkway")
    exit.reset()
    await process_frame
    check(exit.state==exit.State.WAITING and bird.visible and eagle.is_processing(),"Reset clears cloud transition and restores bird/eagle lifecycle")
    check(exit._floor_collision.disabled or not exit._floor_collision.is_inside_tree(),"Heaven floor is retired after reset")
    print("FORMAL_SKY_CLOUD_EXIT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
