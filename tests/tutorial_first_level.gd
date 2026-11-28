extends SceneTree
func _initialize():run.call_deferred()
func run():
    const SAVE="user://test_tutorial_first_level.cfg"
    if FileAccess.file_exists(SAVE):DirAccess.remove_absolute(SAVE)
    for stage in ["hell","ocean","jungle","sky"]:
        var cfg=ConfigFile.new()
        cfg.load(SAVE)
        cfg.set_value("watched",stage,true)
        cfg.save(SAVE)
        var probe=load(get_script().resource_path.get_base_dir()+"/support/tutorial_offer_probe.gd").new()
        probe.save_path=SAVE
        probe.stage_key=stage
        root.add_child(probe)
        probe._offer()
        await process_frame
        assert(probe.offers==1,"Even a completed homepage lesson must show on first level entry")
        probe.book_mode=true
        probe._mark_level_entered()
        cfg.load(SAVE)
        assert(not cfg.get_value("level_entered",stage,false))
        probe.book_mode=false
        probe._mark_level_entered()
        probe._offer()
        await process_frame
        assert(probe.offers==1,"The level offer stops only after an in-level entry")
        probe._force_replay=true
        probe._offer()
        await process_frame
        assert(probe.offers==2,"Shortcut replay remains available")
        probe.queue_free()
    print("FIRST_LEVEL_TUTORIAL_PASS: four stages, home watched versus level entered, force replay")
    quit()
