extends SceneTree
var failures: Array[String]=[]
var flaps:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    var crown=layout.get_node("CanopyTransition")
    var handoff=layout.get_node("CanopyBirdStage")
    var possession=layout.get_node("CanopyPossession")
    bird.get_node("Movement").flapped.connect(func(): flaps+=1)
    var origin: Vector2=bird.position
    var identity: int=bird.get_instance_id()
    for i in 160: await physics_frame
    check(crown.state==crown.State.WAITING and bird.visible,"Bird already exists before the canopy transition")
    check(bird.position.distance_to(origin)>40 and flaps>0,"The pre-existing bird actually patrols and flaps before the camera arrives")
    check(not possession.enabled and not bird.get_node("Visual/SelectedSprite").visible,"Bird cannot be selected from the jungle before the canopy arrival")
    check(bird.get_node("Visual/Sprite").texture.atlas.resource_path.begins_with("res://assets/art/sky/bird_"),"Flight uses the confirmed original bird artwork")
    check(bird.get_node("Host").is_in_group("formal_canopy_birds") and not bird.get_node("Host").is_in_group("possessable_hosts"),"Bird selection is isolated from earlier hosts")
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    crown._begin()
    crown._begin_emerge()
    check(bird.get_instance_id()==identity and bird.position!=origin,"Canopy animation reveals the same bird without spawning or rewinding it")
    var naturally_reachable:=false
    for i in 300:
        await physics_frame
        if possession.selected_host==bird.get_node("Host"): naturally_reachable=true
        if crown.play.bouncer.buried: crown.play.bouncer.launch()
    check(naturally_reachable,"Normal canopy jumps can actually reach the patrolling bird's Shift selection range")
    crown.play.bouncer.set_physics_process(false)
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Patrol").set_physics_process(false)
    body.global_position=bird.global_position+Vector2(0,80)
    handoff._physics_process(0)
    possession._physics_process(0)
    check(possession.selected_host==bird.get_node("Host") and bird.get_node("Visual/SelectedSprite").visible,"Jumping close to the bird reveals the supplied SHIFT selection art")
    var key:=InputEventKey.new()
    key.physical_keycode=KEY_SHIFT
    key.location=KEY_LOCATION_LEFT
    key.pressed=true
    root.push_input(key,true)
    check(possession.state==possession.State.TRANSFERRING and crown.play.bouncer.released,"Actual Shift leaves the squirrel and begins bird possession")
    for i in 150:
        await process_frame
        if possession.state==possession.State.POSSESSED: break
    check(possession.state==possession.State.POSSESSED and game.player==bird and bird.get_node("Host").claimed,"Possession completes with the player controlling the bird")
    check(not bird.get_node("Patrol").enabled and bird.get_node("Movement").enabled and not bird.get_node("Input").external_control,"Manual flight replaces the idle patrol")
    var reader=bird.get_node("Input")
    reader.external_control=true
    reader.jump_pressed=true
    bird.get_node("Movement")._physics_process(.016)
    check(bird.velocity.y< -400 and is_equal_approx(Engine.time_scale,1),"The possessed bird can flap upward with normal time restored")
    layout.reset()
    check(not bird.get_node("Host").claimed and bird.get_node("Patrol").enabled and not possession.enabled,"Replay restores the flying NPC and clears the bird handoff")
    print("FORMAL_CANOPY_BIRD_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
