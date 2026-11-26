extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    var lava = game.get_node("RisingLava")
    lava.set_physics_process(false)
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    game.get_node("Fork").set_physics_process(false)
    game.demon.get_node("Movement").enabled = false
    game.demon.position = Vector2(500,51000)
    check(not lava.armed and not lava.visible,"Opening ghost phase starts without rising lava")
    lava._physics_process(120)
    check(not lava.armed and is_equal_approx(lava.surface_y,lava.initial_surface_y),"Waiting through intro cannot consume the escape time")
    game.player = game.demon
    game.demon.get_node("Host").take_control()
    game.demon.get_node("Movement").enabled = false
    game.demon.position = Vector2(500,51796)
    lava._physics_process(2)
    check(not lava.armed,"Possession on the starting ledge leaves time to learn")
    game.demon.position = Vector2(1191,51808)
    var initial: float = lava.initial_surface_y
    lava._physics_process(.1)
    check(not lava.armed,"Reaching first platform alone must not start lava")
    var normal_zoom:Vector2=game.camera.zoom
    game.get_node("Fork").exchanged.emit(game.demon)
    check(lava.armed and lava.visible,"First successful transfer starts lava")
    lava._physics_process(.1)
    check(absf(lava.surface_y-(initial-6))<.02,"Lava rises at 60 pixels per second after transfer")
    var reveal=game.get_node("LavaRiseReveal")
    reveal.set_process(false)
    check(reveal.active,"First successful transfer also starts the lava camera notice")
    game.camera.set_follow_target(game.demon,true)
    reveal._process(.5)
    check(game.camera.framing_bias.y>0 and game.camera.zoom.x>=1.0,"Notice looks downward and respects original map width")
    check(game.demon.get_node("Input").enabled,"Camera notice preserves player control")
    reveal._process(2.0)
    check(not reveal.active and game.camera.zoom.is_equal_approx(normal_zoom),"Camera returns to normal framing after the notice")
    game.demon.position.y -= 800
    var height: float = lava.surface_y
    game.camera.global_position += Vector2(300,-2000)
    game.demon.position.y -= 1500
    lava._physics_process(1)
    check(absf(lava.surface_y-(height-60))<.02,"Camera or player movement never pulls the lava upward")
    height = lava.surface_y
    game.get_node("Fork").launching = true
    lava._physics_process(5)
    check(absf(lava.surface_y-(height-300))<.02,"Lava continues rising throughout fork launch")
    game.get_node("Fork").launching = false
    height = lava.surface_y
    game.get_node("Fork").exchanged.emit(game.demon)
    check(is_equal_approx(lava.surface_y,height),"Later exchanges never restart or lower the lava")
    check(not reveal.active,"Later exchanges do not replay the camera notice")
    game.get_node("OceanLink").stage = 2
    lava._physics_process(10)
    check(is_equal_approx(lava.surface_y,height),"Volcano transition and ocean do not advance lava")
    game.get_node("OceanLink").stage = 0
    game.demon.position = Vector2(960,41000)
    lava.surface_y = lava.ceiling_y+10
    lava._physics_process(2)
    check(is_equal_approx(lava.surface_y,lava.ceiling_y),"Lava stops below the original volcano mouth")
    check(game.get_node("WorldLayers/Lava").z_index>game.get_node("Platforms/Static01").z_index,"Original lava covers the submerged platform")
    check(lava.z_index>game.get_node("Platforms/Static01").z_index,"Rising lava covers all ordinary platforms")
    check(game.get_node("WorldLayers/Walls").z_index>lava.z_index,"Side walls and their attached ledges always render in front of lava")
    lava.reset()
    check(not lava.armed and not lava.visible and is_equal_approx(lava.surface_y,initial),"Retry resets world height, grace and visibility")
    game.get_node("SegmentStart").start_segment(2)
    check(lava.armed and is_zero_approx(lava.grace_remaining),"Shortcut 2 starts nearby lava with no extra startup delay")
    check(absf(lava.surface_y-game.demon.position.y-650)<.1,"Shortcut lava starts safely below the last platform")
    lava.reset()
    game.demon.position = Vector2(500,51000)
    lava.arm(50000)
    lava.grace_remaining = 0
    game.get_node("Fork").launching = false
    game.get_node("Fork").swapping = false
    game.demon.position.y = lava.surface_at(500)+1
    lava._physics_process(.01)
    check(game.dead and game.death_reason==&"lava","Touching the drawn surface uses the real death flow")
    game.restart()
    check(not lava.armed and not lava.visible and not game.dead,"Real restart clears lava death and pressure")
    print("RISING_HELL_LAVA_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
