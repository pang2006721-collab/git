extends SceneTree
func _initialize():run.call_deferred()
func run():
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    for name_key in ["HellTutorial","OceanTutorial"]:
        var tutorial=game.get_node(name_key)
        tutorial.save_path="user://test_tutorial_sync.cfg"
        tutorial.start()
        for i in 60:
            await process_frame
            if tutorial.panel.modulate.a>.99:break
        assert(tutorial.panel.modulate.a>.99)
        assert(tutorial.frame.material.get_shader_parameter("movie_ready"))
        assert(tutorial.movie.is_playing() and tutorial.movie.stream_position<.3)
        assert(tutorial.panel.scale.x<.95,"Video must already be playing during the start of the bounce")
        assert(tutorial.movie.get_video_texture().get_width()>0)
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/"+name_key+"-synced-entry.png")
        tutorial.finish(false)
        await create_timer(.5).timeout
        assert(not paused,"Closing during entry cancels the entrance and restores gameplay")
        print("SYNCED_ENTRY_PASS ",name_key)
    quit()
