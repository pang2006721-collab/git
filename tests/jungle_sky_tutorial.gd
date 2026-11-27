extends SceneTree
var preview_clips:Array=[]
const SAVE="user://test_jungle_sky_tutorial.cfg"
func _initialize():run.call_deferred()
func run():
    root.size=Vector2i(1280,720)
    if FileAccess.file_exists(SAVE):DirAccess.remove_absolute(SAVE)
    node_added.connect(func(node):
        if node.name in ["JungleTutorial","SkyTutorial"]:node.save_path=SAVE)
    for index in [5,6]:
        root.get_node("SegmentQuickStart").start_segment(index)
        var name_key="JungleTutorial" if index==5 else "SkyTutorial"
        var stage_key="jungle" if index==5 else "sky"
        var tutorial
        for i in 240:
            await create_timer(.02).timeout
            if current_scene!=null:
                tutorial=current_scene.get_node_or_null(name_key)
                if tutorial!=null and tutorial.active:break
        assert(tutorial!=null and tutorial.active and paused)
        var clip_start:=Engine.get_process_frames()/60.0
        var actor=current_scene.player
        var frozen:Vector2=actor.global_position
        var photograph_time:float=2.0 if index==5 else 6.9
        await create_timer(photograph_time).timeout
        assert(actor.global_position==frozen,"Tutorial must freeze the controlled body")
        assert(tutorial.frame.material.get_shader_parameter("movie_ready"))
        assert(tutorial.key_art.self_modulate.g<.95,"Held Shift is visually held during the recorded action")
        if index==6:assert(tutorial.frame.material.get_shader_parameter("use_hole_mask"),"Sky preserves the white cloud border")
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/"+stage_key+"-tutorial-popup.png")
        var count:int=tutorial.pulse_index
        for i in 100:
            if not is_instance_valid(tutorial):break
            count=maxi(count,tutorial.pulse_index)
            await create_timer(.1).timeout
        assert(not paused)
        assert(count==(2 if index==5 else 1))
        preview_clips.append({"stage":stage_key,"start":clip_start,"end":Engine.get_process_frames()/60.0})
        var cfg=ConfigFile.new()
        assert(cfg.load(SAVE)==OK and cfg.get_value("watched",stage_key,false))
        if index==5:assert(not cfg.get_value("watched","sky",false))
        root.get_node("SegmentQuickStart").start_segment(index)
        for i in 240:
            await create_timer(.02).timeout
            tutorial=current_scene.get_node_or_null(name_key)
            if tutorial!=null and tutorial.active:break
        assert(tutorial!=null and tutorial.active,"Completed tutorials can still be replayed with shortcuts")
        await create_timer(.5).timeout
        tutorial.close_art.pressed.emit()
        await create_timer(.7).timeout
        assert(not paused)
        print("JUNGLE_SKY_TUTORIAL_PASS ",stage_key)
    var file=FileAccess.open("C:/Users/14930/Documents/Codex/2026-11-18/m/tutorial-stage-previews.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(preview_clips,"  "))
    file.close()
    quit()
