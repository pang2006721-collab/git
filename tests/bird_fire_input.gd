extends SceneTree
func _initialize(): run.call_deferred()
func run():
    root.get_node("SegmentQuickStart").start_segment(6)
    await create_timer(1.5).timeout
    var bird=current_scene.get_node("OceanLink/FishStage/JungleLayout/Bird")
    var fire=bird.get_node("Boost")
    for location in [KEY_LOCATION_UNSPECIFIED,KEY_LOCATION_LEFT,KEY_LOCATION_RIGHT]:
        fire.tick(6.1,false)
        var key=InputEventKey.new()
        key.physical_keycode=KEY_SHIFT
        key.keycode=KEY_SHIFT
        key.location=location
        key.pressed=true
        Input.parse_input_event(key)
        await create_timer(.15).timeout
        if not fire.burning or not fire._fire.is_visible_in_tree():
            push_error("Shift input failed for location "+str(location))
            quit(1)
            return
        print("FIRE_INPUT_OK=",location)
        key=key.duplicate()
        key.pressed=false
        Input.parse_input_event(key)
        fire.reset()
    quit()
