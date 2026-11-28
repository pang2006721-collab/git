extends SceneTree
const SAVE="user://test_ocean_tutorial.cfg"
func _initialize():run.call_deferred()
func run():
    root.size=Vector2i(1280,720)
    if FileAccess.file_exists(SAVE):DirAccess.remove_absolute(SAVE)
    node_added.connect(func(node):
        if node.name=="OceanTutorial":node.save_path=SAVE)
    var key=InputEventKey.new()
    key.physical_keycode=KEY_3
    key.pressed=true
    Input.parse_input_event(key)
    Input.flush_buffered_events()
    var tutorial
    for i in 200:
        await create_timer(.02).timeout
        if current_scene!=null:
            tutorial=current_scene.get_node_or_null("OceanTutorial")
            if tutorial!=null and tutorial.active:break
    assert(tutorial!=null and tutorial.active and paused)
    assert(tutorial.stage_key=="ocean" and tutorial.pulses.size()==1)
    assert(tutorial.frame_origin==Vector2(240,1224))
    var fish=current_scene.get_node("OceanLink/FishStage/Fish")
    var frozen:Vector2=fish.global_position
    await create_timer(3.0).timeout
    assert(fish.global_position==frozen)
    assert(tutorial.pulse_index==1)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/ocean-tutorial-popup.png")
    for i in 80:
        if not is_instance_valid(tutorial):break
        await create_timer(.1).timeout
    assert(not paused)
    var cfg=ConfigFile.new()
    assert(cfg.load(SAVE)==OK and cfg.get_value("watched","ocean",false))
    assert(not cfg.get_value("watched","hell",false),"Ocean completion cannot mark hell as watched")
    root.get_node("SegmentQuickStart").start_segment(3)
    for i in 200:
        await create_timer(.02).timeout
        tutorial=current_scene.get_node_or_null("OceanTutorial")
        if tutorial!=null and tutorial.active:break
    assert(tutorial!=null and tutorial.active,"Key 3 repeats even after completed")
    await create_timer(.5).timeout
    tutorial.close_art.pressed.emit()
    await create_timer(.7).timeout
    assert(not paused)
    print("OCEAN_TUTORIAL_PASS: key3, blue frame, one Shift cue, freeze, stage persistence, replay, close")
    quit()
