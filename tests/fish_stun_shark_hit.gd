extends SceneTree
var failures:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    for final_attack in [false,true]:
        var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
        root.add_child(game)
        current_scene=game
        game.get_node("WallEntry").reset_for_replay()
        game.get_node("WallEntry").completed=true
        game.get_node("RunRetrospective").recording_enabled=false
        var stage=game.get_node("OceanLink/FishStage")
        stage.activate()
        stage.host.take_control()
        stage._on_transfer_finished(stage.host)
        var fish=stage.fish
        fish.global_position=game.to_global(Vector2(960,33000))
        game.camera.set_follow_target(fish,true)
        var pacing=stage.get_node("Pacing")
        var stun=fish.get_node("Stun")
        check(stun.apply(Vector2.RIGHT),"Applies real stun")
        check(stun.stun_remaining>0 and not fish.get_node("Movement").enabled,"Stunned fish cannot swim")
        check(not pacing.damage_allowed() and pacing.damage_allowed(true),"Only skinny shark damage bypasses stun protection")
        game.get_node("OceanCheckpoint").grace_remaining=1
        check(not pacing.damage_allowed(true),"Checkpoint grace still protects from sharks")
        game.get_node("OceanCheckpoint").grace_remaining=0
        pacing.update(0,true,33000)
        var shark=stage.get_node("FinalSharks").sharks[0] if final_attack else stage.get_node("Shark")
        shark.enabled=true
        shark._begin_lock()
        shark._begin_dash()
        shark.global_position=fish.get_node("Collision").global_position-Vector2(180,0)
        shark.dash_direction=Vector2.RIGHT
        shark.state_elapsed=.2
        shark._advance_dash(.1)
        check(game.dead and game.death_reason==&"shark","Real skinny shark collision kills stunned fish, final="+str(final_attack))
        check(shark.visible and shark.state==shark.State.DASHING,"Attack persists after hitting fish")
        game.queue_free()
        await process_frame
        await process_frame
    print("FISH_STUN_SHARK_HIT failures=",failures)
    quit(1 if failures else 0)
