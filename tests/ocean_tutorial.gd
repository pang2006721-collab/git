extends SceneTree
func _initialize():run.call_deferred()
func run():
    for attempt in 2:
        var key=InputEventKey.new()
        key.physical_keycode=KEY_3
        key.pressed=true
        root.push_input(key,true)
        for i in 240:
            await create_timer(.02).timeout
            if current_scene!=null and current_scene.scene_file_path=="res://scenes/levels/formal_hell_entry.tscn":break
        await create_timer(.5).timeout
        assert(not current_scene.has_node("OceanTutorial") and not paused)
        assert(current_scene.has_node("OceanShiftReminder"))
    print("OCEAN_NO_MODAL_PASS: repeated key 3 uses contextual guidance")
    quit()
