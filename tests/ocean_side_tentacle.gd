extends SceneTree
var failures: Array[String] = []
var attacks: Array[int] = []
var watching_camera: Camera2D
var maximum_shake: float = 0.0
func _process(_delta):
    if is_instance_valid(watching_camera): maximum_shake=maxf(maximum_shake,watching_camera.offset.length())
    return false
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var stage = game.get_node("OceanLink/FishStage")
    var trap = stage.get_node("SideTentacle")
    var fish = stage.fish
    trap.attack_started.connect(func(side: int): attacks.append(side))
    var y = 38000.0
    var bounds: Vector2 = trap._bounds_at(y)
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    fish.position = Vector2(bounds.x+180,y)
    trap.linger_elapsed = 1.99
    await create_timer(.05).timeout
    check(attacks.is_empty() and is_zero_approx(trap.linger_elapsed),"An unpossessed fish never triggers the trap")
    stage.activate()
    for name in ["Shark","Octopus","PinkSharks","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    fish.get_node("Movement").enabled = false
    fish.get_node("Input").external_control = true
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.set_follow_target(fish,true)
    watching_camera=game.camera
    await create_timer(.95).timeout
    check(attacks.is_empty() and trap.linger_elapsed>.8,"A short stay near the left wall does not attack early")
    fish.position.x = (bounds.x+bounds.y)*.5
    await create_timer(.05).timeout
    check(is_zero_approx(trap.linger_elapsed),"Returning to the middle clears the exposure timer")
    fish.position.x = bounds.y-180
    await create_timer(1.05).timeout
    check(attacks.is_empty() and trap.linger_elapsed>.9,"A separate short right-wall stay is not accumulated with the left stay")
    fish.position.x = bounds.x+180
    await create_timer(.03).timeout
    check(trap.linger_elapsed<.06,"Switching walls restarts the two-second timer")
    await create_timer(1.88).timeout
    check(attacks.is_empty(),"No attack occurs before two continuous seconds on the same side")
    await create_timer(.14).timeout
    check(attacks==[-1] and trap.attacking,"Two seconds at the left wall starts a left-wall attack")
    check(trap._anchor.x<trap._bounds_at(y-trap.spawn_above_pixels).x and trap._rig.scale.x>0,"Left tentacle is rooted behind the wall and faces into the water")
    check(absf(trap._anchor.y-(y-340.0))<.01,"Left tentacle emerges 340 pixels above the fish to block its upward route")
    check(trap.z_index<game.get_node("WorldLayers/OceanWalls").z_index,"Wall foreground covers the tentacle root")
    check(fish.get_node("Teleport").try_teleport(Vector2.RIGHT),"Fish can use its real Shift skill during the attack anticipation")
    await create_timer(trap.emerge_seconds+trap.raise_seconds+trap.strike_seconds+trap.retract_seconds+.1).timeout
    check(not game.dead and not trap.attacking,"Blinking beyond the locked attack avoids damage and the arm retracts")
    trap.reset()
    trap.linger_seconds = .05
    fish.position = Vector2(bounds.y-180,y)
    fish.velocity = Vector2.ZERO
    game.camera.set_follow_target(fish,true)
    await create_timer(.09).timeout
    check(attacks==[-1,1] and trap._rig.scale.x<0 and trap._anchor.x>trap._bounds_at(y-trap.spawn_above_pixels).y,"Right wall attack mirrors the arm while preserving its root")
    check(absf(trap._anchor.y-(y-340.0))<.01,"Right tentacle uses the same above-fish emergence height")
    var stun=fish.get_node("Stun")
    for i in 160:
        await physics_frame
        if stun.dizzy_remaining>0: break
    check(not game.dead and trap._hit and stun.stun_remaining>0,"Visible wall slap stuns the fish instead of losing the run")
    check(not is_instance_valid(trap.corpse) and fish.get_node("Visual").visible,"Stun keeps the real fish visible without a death body")
    check(fish.get_node("Visual/Sprite").material!=null,"Hit displays the spiral eye over the original fish artwork")
    check(not fish.get_node("Input").enabled and not fish.get_node("Movement").enabled,"Fish briefly pauses swimming while dazed")
    trap.linger_seconds=10
    await create_timer(1.0).timeout
    check(not game.dead and fish.get_node("Input").enabled and fish.get_node("Teleport").enabled,"Swimming input and blink recover automatically")
    check(not stun.apply(Vector2.RIGHT),"Short recovery protection prevents consecutive tentacle stun")
    await create_timer(.5).timeout
    check(fish.get_node("Visual/Sprite").material==null,"Dizzy eye returns exactly to the original appearance")
    check(not game.get_node("DeathFlow").overlay.visible,"No failure screen is shown for a tentacle stun")
    stage.reset()
    check(not trap.attacking and is_zero_approx(trap.linger_elapsed) and not is_instance_valid(trap.corpse),"Replay clears pending tentacles")
    check(not stun.is_protected() and fish.get_node("Visual").visible and not stage.host.claimed,"Replay clears stun and restores ordinary patrol")
    print("OCEAN_SIDE_TENTACLE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
