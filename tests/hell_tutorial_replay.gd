extends SceneTree
func _initialize():run.call_deferred()
func run():
    for attempt in 2:
        var key=InputEventKey.new()
        key.physical_keycode=KEY_1
        key.pressed=true
        root.push_input(key,true)
        for i in 200:
            await create_timer(.02).timeout
            if current_scene!=null and current_scene.scene_file_path=="res://scenes/levels/formal_hell_entry.tscn":break
        await create_timer(2.0).timeout
        assert(current_scene!=null and not current_scene.has_node("HellTutorial"))
        assert(not paused,"Key 1 starts hell without a tutorial popup")
    print("HELL_NO_MODAL_PASS: normal scene assembly and repeated key 1")
    quit()
