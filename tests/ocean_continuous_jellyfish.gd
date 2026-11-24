extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void:run.call_deferred()
func check(ok:bool,message:String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await process_frame
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    var fish=stage.fish
    fish.get_node("Movement").enabled=false
    var pacing=stage.get_node("Pacing")
    var net=stage.get_node("BossTentacleNet")
    var boss=stage.get_node("JellyfishBoss")
    for name in ["Shark","Octopus","JellyfishBoss","BossTentacleNet","SideTentacle","FinalSharks"]:stage.get_node(name).set_physics_process(false)
    for lane in stage.get_node("PinkSharks").get_children():lane.set_physics_process(false)
    stage.get_node("JellyfishReveal").set_process(false)
    boss.state=boss.State.PRESENT
    var waves:Array=[]
    net.row_started.connect(func(height):waves.append(height))
    for height in [37500.0,35000.0,33000.0,31600.0]:
        net.reset()
        fish.global_position=game.to_global(Vector2(960,height))
        game.camera.set_follow_target(fish,true)
        pacing.update(0,true,height)
        check(net.enabled,"Jellyfish stays enabled across early, middle, late and upper ocean")
        var before:int=waves.size()
        net._physics_process(net.wave_interval+.01)
        check(waves.size()==before+1 and not net.rows.is_empty(),"Jellyfish actually creates a wave in every phase")
    check(is_equal_approx(net.wave_interval,1.65) and is_equal_approx(net.charge_seconds,1.15),"Original cadence and reaction warning remain unchanged")
    fish.global_position=game.to_global(Vector2(960,35000))
    pacing.update(0,true,35000)
    stage.get_node("Octopus").visitors[0].state=stage.get_node("Octopus").visitors[0].State.SWIMMING
    pacing.update(0,true,35000)
    check(net.enabled,"Octopus being present does not silence jellyfish")
    stage.get_node("InkOverlay").splash()
    pacing.update(0,true,35000)
    check(net.enabled,"Ink does not remove jellyfish warning presence")
    stage._on_boss_net_hit(Vector2.RIGHT)
    check(fish.get_node("Stun").stun_remaining==0,"Ink protection still prevents blind extra punishment")
    stage.get_node("InkOverlay").reset()
    pacing.request_rest(1.25)
    pacing.update(0,true,35000)
    check(net.enabled and not net.spawn_allowed and not net.damage_enabled and not net.rows.is_empty(),"Recovery preserves existing tentacles while suppressing new attacks and damage")
    pacing.update(1.3,true,35000)
    check(net.enabled,"Jellyfish resumes immediately after recovery rest")
    var checkpoint=game.get_node("OceanCheckpoint")
    checkpoint.activate()
    fish.global_position=checkpoint.global_position+Vector2(-155,0)
    pacing.update(3,true,32300)
    check(not net.spawn_allowed and not net.damage_enabled,"Checkpoint bubble area stays safe")
    fish.global_position=game.to_global(Vector2(960,31900))
    pacing.update(0,true,31900)
    check(net.enabled,"Jellyfish resumes after leaving checkpoint area")
    pacing.prepare_final()
    stage.get_node("FinalSharks").triggered=true
    pacing.update(0,true,31000)
    check(not net.enabled and net.rows.is_empty(),"Final three-shark attack retains its clear stage")
    print("OCEAN_CONTINUOUS_JELLYFISH_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
