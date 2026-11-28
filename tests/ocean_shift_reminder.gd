extends SceneTree
func _initialize():run.call_deferred()
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("DeathFlow").queue_free()
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("CameraAttention").enabled=false
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    for name in ["Pacing","Shark","FinalSharks","SideTentacle","BossTentacleNet","JellyfishBoss","Octopus","PinkSharks","ShoreExit"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var fish=stage.fish
    var blink=fish.get_node("Teleport")
    var stun=fish.get_node("Stun")
    fish.get_node("Patrol").stop()
    fish.get_node("Input").external_control=true
    fish.get_node("Input").clear()
    fish.get_node("Movement").enabled=false
    fish.global_position=Vector2(10000,35000)
    game.camera.set_process(false)
    game.camera.set_follow_target(fish,true)
    game.camera.global_position=fish.global_position
    var hint=game.get_node("OceanShiftReminder")
    var side=stage.get_node("SideTentacle")
    var shark=stage.get_node("Shark")
    side.attacking=true
    side._clock=0
    await create_timer(.2).timeout
    assert(not hint.visible and not game.has_node("OceanTutorial"),"First exposure is uninterrupted, without a modal")
    assert(stun.apply(Vector2.RIGHT))
    await create_timer(.1).timeout
    assert(hint.needed.tentacle and not hint.visible,"Stun arms future guidance but does not urge unusable input")
    await create_timer(.9).timeout
    side.attacking=true
    side._clock=0
    await create_timer(.2).timeout
    assert(hint.visible and not paused,"Next tentacle prompts usable Shift without pausing")
    blink.cooldown_remaining=.3
    await create_timer(.2).timeout
    assert(not hint.visible,"Cooldown suppresses the prompt")
    blink.reset()
    await create_timer(.2).timeout
    assert(hint.visible)
    assert(blink.try_teleport(Vector2.UP))
    await create_timer(.45).timeout
    assert(not hint.learned.tentacle and hint.successes.tentacle==1,"First tentacle success does not finish teaching")
    blink.reset()
    assert(blink.try_teleport(Vector2.UP))
    await create_timer(.45).timeout
    assert(hint.learned.tentacle and hint.successes.tentacle==2 and not hint.learned.shark,"Second tentacle success learns only that category")
    side.attacking=false
    var net=stage.get_node("BossTentacleNet")
    var row=Node2D.new()
    net.add_child(row)
    row.global_position=fish.global_position
    var arm=load("res://modules/visual/jellyfish_net_tendril.gd").new()
    arm.start=Vector2(-100,0)
    arm.finish=Vector2(100,0)
    row.add_child(arm)
    net.rows.append({"node":row,"arms":[arm],"age":0.0})
    assert(hint._tentacle_threat(),"Boss barrier tentacles are covered too")
    row.position.x+=2000
    assert(not hint._tentacle_threat(),"Distant tentacles do not spam the cue")
    net.reset()
    blink.reset()
    game.die(&"shark")
    assert(game.dead and hint.needed.shark,"Real shark death arms retry guidance")
    game.dead=false
    stage._on_transfer_finished(stage.host)
    fish.get_node("Movement").enabled=false
    shark.enabled=true
    shark._begin_lock()
    await create_timer(.2).timeout
    assert(hint.visible,"Next slender shark lock warns above the fish")
    assert((hint.art.get_global_transform()*(hint.art.size*.5)).is_equal_approx(hint._follow_position))
    assert(blink.try_teleport(Vector2.RIGHT))
    await create_timer(.45).timeout
    assert(not hint.learned.shark and hint.successes.shark==1,"First shark dodge still allows reminders")
    blink.reset()
    assert(blink.try_teleport(Vector2.RIGHT))
    await create_timer(.45).timeout
    assert(hint.learned.shark and hint.successes.shark==2 and hint.learned.tentacle,"Second shark dodge learns separately")
    shark.reset()
    var final_shark=stage.get_node("FinalSharks").get_child(0)
    final_shark._begin_lock()
    assert(hint._shark_threat(),"Final three slender sharks share the same contextual cue")
    final_shark.cancel_pending_attack()
    shark._begin_lock()
    hint.learned.shark=false
    hint.successes.shark=0
    blink.reset()
    assert(blink.try_teleport(Vector2.RIGHT))
    await create_timer(.07).timeout
    blink.reset()
    game.die(&"shark")
    await create_timer(.4).timeout
    assert(not hint.learned.shark and not hint.visible,"A blink followed by death is not marked learned")
    print("OCEAN_SHIFT_PROMPT_PASS: actual stun/blink/death, separate categories, barrier proximity, cooldown, no modal")
    quit()
