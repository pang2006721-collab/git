extends SceneTree
func _initialize():run.call_deferred()
func run():
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    game.get_node("WallEntry").play()
    await create_timer(1.0).timeout
    var tutorial=game.get_node("HellTutorial")
    tutorial.save_path="user://test_hell_tutorial.cfg"
    if FileAccess.file_exists(tutorial.save_path):DirAccess.remove_absolute(tutorial.save_path)
    var old_mode=game.get_node("FlyingEnemies").process_mode
    tutorial.start()
    assert(paused)
    var before:Vector2=game.soul.global_position
    await create_timer(1.7).timeout
    assert(game.soul.global_position==before)
    assert(tutorial.pulse_index==1)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/tutorial-popup.png")
    var pulse_count:=0
    for i in 160:
        if not is_instance_valid(tutorial):break
        pulse_count=maxi(pulse_count,tutorial.pulse_index)
        await create_timer(.1).timeout
    assert(pulse_count==3,"All three recorded Shift uses must receive a matching cue")
    assert(is_instance_valid(tutorial) and tutorial.active and paused,"Playback completion must leave the level tutorial open")
    tutorial.close_art.pressed.emit()
    await create_timer(.8).timeout
    assert(not paused)
    var cfg=ConfigFile.new()
    assert(cfg.load("user://test_hell_tutorial.cfg")==OK)
    assert(cfg.get_value("watched","hell",false))
    assert(game.get_node("FlyingEnemies").process_mode==old_mode)
    var second=load("res://modules/tutorial/hell_tutorial.gd").new()
    second.save_path="user://test_tutorial_dismiss.cfg"
    if FileAccess.file_exists(second.save_path):DirAccess.remove_absolute(second.save_path)
    game.add_child(second)
    second.start()
    await create_timer(.7).timeout
    second.close_art.pressed.emit()
    await create_timer(.8).timeout
    assert(not paused)
    var skipped=ConfigFile.new()
    assert(skipped.load("user://test_tutorial_dismiss.cfg")==OK)
    assert(not skipped.get_value("watched","hell",false) and skipped.get_value("level_entered","hell",false))
    print("HELL_TUTORIAL_PASS: video, synced pulse, freeze, completion, restore, close")
    game.queue_free()
    await process_frame
    quit()
