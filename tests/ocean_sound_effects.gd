extends SceneTree
var failures: Array[String] = []
var counts: Dictionary = {}
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func heard(cue: StringName): counts[cue] = counts.get(cue,0)+1
func total(cue: StringName) -> int: return counts.get(cue,0)
func run():
    var sfx = root.get_node("Sfx")
    sfx.played.connect(heard)
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    game.soul.position = game.demon.position+Vector2(-90,0)
    for i in 5: await physics_frame
    check(game.possession.request_possession(),"Hell setup possession succeeds")
    await create_timer(2.6,true,false,true).timeout
    var link = game.get_node("OceanLink")
    var stage = link.get_node("FishStage")
    game.demon.get_node("Movement").enabled = false
    game.demon.get_node("Input").enabled = false
    game.demon.global_position = link.vortex.global_position+Vector2(0,70)
    game.demon.velocity = Vector2(0,-600)
    game.camera.set_follow_target(game.demon,true)
    for i in 600:
        await process_frame
        if link.stage==link.Stage.OCEAN: break
    check(stage.active,"Real capture, travel and eruption complete")
    check(total(&"transition_mouth")==2,"Suction and eruption each sound exactly once")
    check(total(&"transition_travel")==1,"Interior transition sounds once")
    game.demon.get_node("Movement").enabled = false
    game.demon.global_position = stage.fish.global_position+Vector2(-100,67)
    for i in 5: await physics_frame
    await process_frame
    check(stage.possession.request_possession(),"Actual demon to fish transfer starts")
    check(total(&"soul_exit")==1 and total(&"fish_enter")==0,"Exit sounds before fish entry")
    check(not stage.possession.request_possession(),"Repeat transfer is rejected")
    await create_timer(2.6,true,false,true).timeout
    check(total(&"fish_enter")==1 and total(&"soul_exit")==1,"Completed transfer sounds entry exactly once")
    stage.set_physics_process(false)
    game.set_physics_process(false)
    for child in ["Shark","Octopus","SideTentacle","PinkSharks","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(child).process_mode = Node.PROCESS_MODE_DISABLED
    var fish = stage.fish
    fish.get_node("Movement").enabled = false
    fish.get_node("Input").external_control = true
    fish.get_node("Input").clear()
    fish.global_position = Vector2(10000,20000)
    var blink = fish.get_node("Teleport")
    check(blink.try_teleport(Vector2.RIGHT),"Successful blink starts")
    check(not blink.try_teleport(Vector2.RIGHT),"Repeated blink is rejected")
    await create_timer(.12).timeout
    check(total(&"fish_blink")==1,"Only actual blink arrival sounds")
    fish.position = Vector2(960,36000)
    var shark = stage.get_node("Shark")
    shark._begin_lock()
    check(total(&"shark_dash")==0,"Lock warning does not sound dash")
    shark._begin_dash()
    check(total(&"shark_dash")==1,"Dash onset sounds once")
    var side = stage.get_node("SideTentacle")
    side.side = -1
    side._begin_attack()
    check(total(&"tentacle_slap")==0,"Side emergence has no premature slap")
    side._clock = side.emerge_seconds+side.raise_seconds+.01
    side._sample_attack()
    side._sample_attack()
    check(total(&"tentacle_slap")==1,"Side strike sounds once across repeated samples")
    side.reset()
    var net = stage.get_node("BossTentacleNet")
    net.enabled = true
    game.camera.global_position = fish.global_position
    game.camera.offset = Vector2.ZERO
    game.camera.zoom = Vector2.ONE*.7
    net._spawn_row()
    var row: Dictionary = net.rows[0]
    check(total(&"jellyfish_strike")==0,"Jellyfish warning is silent")
    var expected := 0
    for arm in row.arms:
        if not arm.cancelled:
            arm.warning_confirmed = true
            expected += 1
    check(expected>0,"Test includes a visible attacking tendril")
    for i in 160: net._physics_process(.01)
    check(total(&"jellyfish_strike")==expected,"Each actual jellyfish strike sounds once")
    for i in 10: net._physics_process(.01)
    check(total(&"jellyfish_strike")==expected,"Formed jellyfish walls do not repeat audio")
    var visitor = stage.get_node("Octopus").get_child(0)
    visitor._release_cloud()
    check(total(&"octopus_ink")==1,"Ink release sounds immediately")
    visitor.ink_sprayed.emit()
    check(total(&"octopus_ink")==1,"Later ink contact does not replay spray audio")
    await create_timer(2.8,true,false,true).timeout
    print("OCEAN_SOUND_FAILURES=",failures.size())
    game.queue_free()
    for i in 3: await process_frame
    quit(0 if failures.is_empty() else 1)
