extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    root.size=Vector2i(1280,720)
    root.content_scale_size=Vector2i(1920,1080)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var quick=root.get_node("SegmentQuickStart")
    quick.start_segment(6)
    await quick.segment_started
    var game=current_scene
    game.get_node("RunRetrospective").recording_enabled=false
    var rings=game.get_node("SkyOranges")
    var bird=rings.bird
    var ledger=game.get_node("HellOranges")
    var layout=bird.get_parent()
    var cloud=layout.get_node("SkyCloudExit")
    var bird_stage=layout.get_node("CanopyBirdStage")
    var eagle=layout.get_node("SkyEagle")
    game.process_mode=Node.PROCESS_MODE_DISABLED
    game.get_node("TextureStreamer").process_mode=Node.PROCESS_MODE_ALWAYS
    game.get_node("CameraOutput").process_mode=Node.PROCESS_MODE_ALWAYS
    eagle.reset()
    check(rings.get_child_count()==42 and rings.ring_centers.size()==7,"Seven rings have exactly forty-two oranges")
    check(is_equal_approx(bird_stage._spawn.y-rings.ring_centers[0].y,650.0),"First ring sits 650 pixels above bird spawn")
    check(rings.ring_radius==95,"Uses compact ocean ring size")
    for i in range(1,rings.ring_centers.size()):
        check(rings.ring_centers[i-1].y-rings.ring_centers[i].y>400,"Rings progress upward with clear separation")
    for ring in rings.ring_centers.size():
        for i in 6:
            var orange=rings.get_child(ring*6+i)
            check(is_equal_approx(orange.position.distance_to(rings.ring_centers[ring]),rings.ring_radius),"Six evenly spaced oranges on each circle")
            check(orange.position.y>cloud.height_at("sky",orange.position.x)+250,"Oranges remain below cloud transition")
            check(orange.position.x>250 and orange.position.x<1670,"Rings stay clear of side entrances")
    if DisplayServer.get_name()!="headless":
        bird.global_position=game.to_global(rings.ring_centers[0]+Vector2(0,180))
        game.camera.set_follow_target(bird,true)
        game.camera.make_current()
        await create_timer(2).timeout
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/sky-orange-rings.png")
    var first=rings.get_child(0)
    bird.global_position=first.global_position
    game.dead=true
    rings._physics_process(.01)
    check(not first.collected,"Death cannot collect oranges")
    game.dead=false
    game.exit_in_progress=true
    rings._physics_process(.01)
    check(not first.collected,"Cloud transition cannot collect oranges")
    game.exit_in_progress=false
    for center in rings.ring_centers:
        rings._previous=Vector2.INF
        for step in [Vector2(0,-75),Vector2(75,0),Vector2(0,75),Vector2(-75,0)]:
            bird.global_position=game.to_global(center+step)
            rings._physics_process(.01)
    check(ledger.collected_count==42,"Small four-direction flight collects all forty-two")
    check(rings.get_children().all(func(o):return o.collected and o._collector==bird),"Oranges absorb into bird")
    rings._physics_process(.01)
    check(ledger.collected_count==42,"Collected oranges cannot count twice")
    for orange in rings.get_children():orange._process(.4)
    check(rings.get_children().all(func(o):return not o.visible),"Absorption finishes naturally")
    bird_stage.reset()
    check(ledger.collected_count==42 and first.collected,"Retry preserves sky pickup progress")
    print("SKY_ORANGE_RINGS failures=",failures)
    quit(1 if failures else 0)
