extends SceneTree
const TEST_SAVE="user://test_tutorial_replay.cfg"
func _initialize():run.call_deferred()
func run():
    var cfg=ConfigFile.new()
    cfg.set_value("watched","hell",true)
    cfg.save(TEST_SAVE)
    node_added.connect(func(node):
        if node.name=="HellTutorial":node.save_path=TEST_SAVE)
    for attempt in 2:
        var key=InputEventKey.new()
        key.physical_keycode=KEY_1
        key.pressed=true
        Input.parse_input_event(key)
        Input.flush_buffered_events()
        key=InputEventKey.new()
        key.physical_keycode=KEY_1
        key.pressed=false
        Input.parse_input_event(key)
        var tutorial
        for frame in 180:
            await create_timer(.02).timeout
            if current_scene!=null:
                tutorial=current_scene.get_node_or_null("HellTutorial")
                if tutorial!=null and tutorial.active:break
        assert(tutorial!=null and tutorial.active,"Pressing 1 must replay despite watched state")
        assert(paused)
        await create_timer(.5).timeout
        assert(is_equal_approx(tutorial.shade.color.a,.84))
        print("TUTORIAL_REPLAY_ATTEMPT=",attempt+1)
    var tutorial=current_scene.get_node("HellTutorial")
    tutorial.close_art.pressed.emit()
    await create_timer(.7).timeout
    assert(not paused)
    var verify=ConfigFile.new()
    verify.load(TEST_SAVE)
    assert(verify.get_value("watched","hell",false))
    print("TUTORIAL_REPLAY_PASS: watched state, repeated key 1 during playback, darker shade, close")
    quit()
