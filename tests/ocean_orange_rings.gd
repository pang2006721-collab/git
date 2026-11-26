extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok:
        failures += 1
        push_error(message)
func run():
    root.size=Vector2i(1280,720)
    root.content_scale_size=Vector2i(1920,1080)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var quick=root.get_node("SegmentQuickStart")
    quick.start_segment(3)
    await quick.segment_started
    var game=current_scene
    game.get_node("RunRetrospective").recording_enabled=false
    var rings=game.get_node("OceanOranges")
    var stage=game.get_node("OceanLink/FishStage")
    var fish=stage.fish
    var ledger=game.get_node("HellOranges")
    var camera=game.camera
    game.set_physics_process(false)
    stage.set_physics_process(false)
    fish.get_node("Movement").enabled=false
    fish.get_node("Patrol").stop()
    for n in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab","FinalSharks"]:
        stage.get_node(n).process_mode=Node.PROCESS_MODE_DISABLED
    check(rings.get_child_count()==42,"Seven rings contain exactly 42 oranges")
    await physics_frame
    await process_frame
    var space=fish.get_world_2d().direct_space_state
    for ring in rings.ring_centers.size():
        for i in 6:
            var orange=rings.get_child(ring*6+i)
            check(is_equal_approx(orange._origin.distance_to(rings.ring_centers[ring]),rings.ring_radius),"Every orange lies on its circle")
            var query=PhysicsPointQueryParameters2D.new()
            query.position=orange.global_position
            query.collision_mask=16
            check(space.intersect_point(query).is_empty(),"Orange is outside terrain: "+str(orange.name))
    fish.global_position=rings.to_global(rings.ring_centers[0])+Vector2(0,300)
    camera.set_follow_target(fish,true)
    if DisplayServer.get_name()!="headless":
        await create_timer(2).timeout
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/ocean-orange-ring.png")
    var orange=rings.get_child(0)
    fish.global_position=orange.global_position-fish.get_node("Collision").position
    rings._previous=Vector2.INF
    rings._physics_process(.01)
    check(orange.collected and ledger.collected_count==1,"Fish pickup updates the shared total")
    check(orange.visible and orange._collector==fish,"Orange begins absorbing into fish before disappearing")
    rings._physics_process(.01)
    check(ledger.collected_count==1,"Repeated overlap counts only once")
    orange._process(.4)
    check(not orange.visible,"Absorption finishes and hides orange")
    # 一小圈上下左右移动即可收齐，不必沿大圆追每颗。
    var group_center: Vector2=rings.to_global(rings.ring_centers[1])
    for step in [Vector2(0,-75),Vector2(75,0),Vector2(0,75),Vector2(-75,0)]:
        fish.global_position=group_center+step-fish.get_node("Collision").position
        rings._previous=Vector2.INF
        rings._physics_process(.01)
    var group_count:=0
    for i in range(6,12):
        if rings.get_child(i).collected: group_count+=1
    check(group_count==6,"Small 150-pixel movement area collects the complete six-orange ring")
    var total_before_retry: int=ledger.collected_count
    var other=rings.get_child(1)
    game.dead=true
    fish.global_position=other.global_position-fish.get_node("Collision").position
    rings._physics_process(.01)
    check(not other.collected,"Death cannot collect oranges")
    game.dead=false
    stage.reset()
    check(orange.collected and ledger.collected_count==total_before_retry,"Retry keeps ocean collection progress")
    print("OCEAN_ORANGE_RINGS failures=",failures)
    quit(1 if failures else 0)
