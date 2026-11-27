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
    await create_timer(2.6).timeout
    assert(tutorial.pulse_index==2)
    await create_timer(2.2).timeout
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
    assert(not FileAccess.file_exists("user://test_tutorial_dismiss.cfg"))
    print("HELL_TUTORIAL_PASS: video, synced pulse, freeze, completion, restore, close")
    game.queue_free()
    await process_frame
    quit()
