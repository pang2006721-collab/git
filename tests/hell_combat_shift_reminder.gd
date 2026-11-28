extends SceneTree
func _initialize():run.call_deferred()
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("WallEntry").control_ready.emit()
    assert(not game.has_node("HellTutorial") and not paused,"Normal hell entry has no modal recording")
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.get_node("CameraAttention").enabled=false
    var body=game.demon
    body.get_node("Host").take_control()
    game.player=body
    game.sleeping.hide()
    game.zzz.hide()
    body.get_node("Visual").show()
    body.get_node("Movement").enabled=false
    body.get_node("Input").enabled=false
    body.global_position=Vector2(1080,50600)
    game.camera.set_process(false)
    game.camera.global_position=body.global_position+Vector2(0,-220)
    var manager=game.get_node("FlyingEnemies")
    var rig=game.get_node("Fork")
    rig.set_physics_process(false)
    rig.enemy_hit_chance=1.0
    var prompt=game.get_node("HellCombatShiftReminder")
    var hint=game.get_node("FirstOrbShiftReminder")
    for index in 3:
        var enemy=manager.ENEMY.instantiate()
        enemy.encounter=manager
        enemy.position=manager.to_local(body.global_position+Vector2(260,-180))
        manager.get_node("Enemies").add_child(enemy)
        enemy.set_physics_process(false)
        manager.enemy_spawned.emit(enemy)
        rig.selected=enemy
        enemy.set_state(1)
        rig.selection_changed.emit(enemy)
        await create_timer(.3).timeout
        assert(hint.visible==(index<2),"Only the first two selected enemies get a head prompt")
        if index<2:
            assert(prompt.is_reminding())
            assert(hint._follow_position.distance_to(hint.head_target())<85)
            if DisplayServer.get_name()!="headless":
                await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/hell-combat-shift-"+str(index)+".png")
            var key=InputEventKey.new()
            key.physical_keycode=KEY_SHIFT
            key.keycode=KEY_SHIFT
            key.location=KEY_LOCATION_LEFT
            key.pressed=true
            hint._input(key)
            rig._unhandled_input(key)
            assert(rig.flying and not prompt.is_reminding(),"Throw acknowledges this enemy's prompt")
            await create_timer(.75).timeout
            assert(prompt.successes==index+1,"Only defeated enemies advance success count")
            assert(enemy.is_defeated(),"Hint leaves the actual enemy defeat animation intact")
            assert(not hint.visible)
        rig.reset()
        enemy.queue_free()
        await process_frame
    var chapter=load("res://modules/tutorial/hell_tutorial.gd").new()
    chapter.book_mode=true
    chapter.save_path="user://test_hell_combat_book.cfg"
    game.add_child(chapter)
    chapter.start()
    if DisplayServer.get_name()!="headless":
        await create_timer(.4).timeout
        assert(chapter.active and chapter.movie.is_playing() and chapter.panel.modulate.a>0)
        chapter.close_art.pressed.emit()
        await create_timer(.7).timeout
    print("HELL_COMBAT_SHIFT_PASS: first two enemies, real throw/defeat, head follow, no hell popup, homepage recording retained")
    quit()
