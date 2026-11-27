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
    key.physical_keycode = KEY_4
    key.pressed = true
    root.push_input(key,true)
    for i in 500:
        await process_frame
        if started==4: break
    check(started==4,"Key 4 starts directly on shore from the menu")
    var game = current_scene
    var stage = game.get_node("OceanLink/FishStage")
    var shore = stage.get_node("ShoreExit")
    var squirrel = stage.get_node("JungleLayout/Squirrel")
    var controller = stage.get_node("JunglePossession")
    check(game.player==stage.fish and stage.host.claimed,"Shortcut retains fish control before possession")
    check(shore.state==shore.State.STRANDED and shore.elapsed<1,"Fish starts already landed with a fresh twelve-second struggle timer")
    check(not stage.fish.get_node("Movement").enabled and not stage.fish.get_node("Teleport").enabled,"Landed fish cannot swim or blink")
    check(shore._sprite.texture==shore.stranded_texture,"Fish uses the supplied landed artwork")
    check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35) and game.camera.target==stage.fish,"Camera starts on shore with normal framing")
    check(controller.enabled and controller.selected_host==squirrel.get_node("Host"),"Nearby squirrel is immediately ready for Shift possession")
    check(squirrel.get_node("Visual/SelectedSprite").visible,"Authored Shift prompt is visible")
    check(not stage.has_node("SurfaceGrab"),"Shortcut has no retired grab node")
    check(not stage.get_node("JellyfishBoss").enabled and not stage.get_node("Shark").enabled,"Underwater pursuit stays inactive at the shore checkpoint")
    var shift := InputEventKey.new()
    shift.physical_keycode = KEY_SHIFT
    shift.location = KEY_LOCATION_LEFT
    shift.pressed = true
    root.push_input(shift,true)
    check(controller.state==controller.State.TRANSFERRING,"Actual Shift can possess the squirrel from checkpoint 4")
    # Pressing 4 during transfer must reload without preserving the old soul tween.
    started = 0
    root.push_input(key,true)
    for i in 500:
        await process_frame
        if started==4: break
    check(started==4 and Engine.time_scale==1,"Key 4 also resets an in-progress possession cleanly")
    check(current_scene.get_node("OceanLink/FishStage/ShoreExit").state==2,"Repeated shortcut returns to the landed fish")
    current_scene.die(&"stranded")
    await process_frame
    await process_frame
    started = 0
    root.push_input(key,true)
    for i in 500:
        await process_frame
        if started==4: break
    check(started==4 and not current_scene.dead,"Key 4 works during death freeze")
    print("SHORE_QUICK_START_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
