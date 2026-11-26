extends SceneTree
var failures: Array[String] = []
var started: int = 0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var quick = root.get_node("SegmentQuickStart")
    quick.segment_started.connect(func(index): started = index)
    var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    await process_frame
    var key := InputEventKey.new()
    key.physical_keycode = KEY_3
    key.pressed = true
    root.push_input(key,true)
    for i in 500:
        await process_frame
        if started==3: break
    check(started==3,"Key 3 starts upper ocean directly from the menu")
    var game = current_scene
    var stage = game.get_node("OceanLink/FishStage")
    check(game.get_node("OceanLink").stage==game.get_node("OceanLink").Stage.OCEAN,"Upper shortcut bypasses the hell cutscene")
    check(game.player==stage.fish and stage.host.claimed and stage.fish.get_node("Input").enabled,"Shortcut starts with a controllable possessed fish")
    check(absf(stage.fish.position.y-32400)<30,"Shortcut begins in the upper ocean below the surface")
    check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35) and game.camera.target==stage.fish,"Shortcut keeps normal zoom and fish following")
    check(not game.get_node("OceanLink/Breath").active,"Demon breath timer cannot kill the shortcut fish")
    var shark = stage.get_node("Shark")
    shark.enabled = true
    shark._begin_lock()
    check(shark.visible and shark.state==shark.State.LOCKING,"Shark is visibly locking before tentacle impact")
    game.die(&"jellyfish_net")
    check(shark.visible and shark.state==shark.State.LOCKING and not shark.enabled and shark._finishing,"Death stops new attacks while preserving the committed shark, matching normal play")
    shark._process(.1)
    shark._physics_process(.1)
    check(shark.visible and shark._finishing,"Existing shark continues its attack during death freeze")
    started = 0
    root.push_input(key,true)
    for i in 500:
        await process_frame
        if started==3: break
    check(started==3 and not current_scene.dead,"Key 3 also reloads a clean upper ocean during death")
    print("UPPER_OCEAN_QUICK_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
