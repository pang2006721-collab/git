extends SceneTree
var failures:Array[String]=[]
var starts:int=0
func _initialize() -> void:run.call_deferred()
func check(ok:bool,message:String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func six() -> void:
    var key:=InputEventKey.new()
    key.physical_keycode=KEY_6
    key.pressed=true
    root.push_input(key,true)
func until(predicate:Callable,seconds:float=8.0) -> bool:
    var end:=Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec()<end:
        if predicate.call():return true
        await process_frame
    return false
func run() -> void:
    root.get_node("SegmentQuickStart").segment_started.connect(func(index):
        if index==6:starts+=1
    )
    var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    six()
    check(await until(func():return starts==1),"Physical key 6 starts upper sky from menu")
    var game=current_scene
    var layout=game.get_node("OceanLink/FishStage/JungleLayout")
    var bird=layout.get_node("Bird")
    var cloud=layout.get_node("SkyCloudExit")
    check(game.player==bird and bird.get_node("Host").claimed,"Quick start directly controls possessed bird")
    check(bird.get_node("Input").enabled and bird.get_node("Movement").enabled,"Bird controls are immediately usable")
    check(bird.position.y>cloud.height_at("sky",960)+1100 and bird.position.y<cloud.height_at("sky",960)+1400,"Spawn is above sky midpoint but safely below top cloud")
    check(cloud.state==cloud.State.WAITING and not game.exit_in_progress,"Quick start does not skip into cloud cutscene")
    check(layout.get_node("SkyEagle")._armed,"Normal eagle encounter is armed")
    check(not game.soul.visible and not game.demon.visible and not game.get_node("OceanLink/FishStage/Fish").visible,"Earlier hosts stay hidden")
    var start_y:float=bird.position.y
    Input.action_press(&"flap")
    await create_timer(1).timeout
    Input.action_release(&"flap")
    check(bird.position.y<start_y-200,"Holding W actually climbs in upper sky preview")
    bird.position.y=cloud.height_at("sky",960)+20
    check(await until(func():return cloud.state==cloud.State.ENTERING,1),"Preview can enter top cloud normally")
    var old_id:int=game.get_instance_id()
    six()
    check(await until(func():return starts==2),"Key 6 also works during cloud cutscene")
    check(current_scene.get_instance_id()!=old_id and not current_scene.exit_in_progress,"Cutscene restart loads fresh scene")
    current_scene.die(&"impact")
    await process_frame
    six()
    check(await until(func():return starts==3),"Key 6 works from death state")
    check(not current_scene.dead and current_scene.player==current_scene.get_node("OceanLink/FishStage/JungleLayout/Bird"),"Death restart restores clean upper sky control")
    print("UPPER_SKY_QUICK_START_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
