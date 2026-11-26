extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func changed(a: Image,b: Image) -> int:
    var count:=0
    for y in range(0,a.get_height(),3):
        for x in range(0,a.get_width(),3):
            if a.get_pixel(x,y)!=b.get_pixel(x,y):count+=1
    return count
func capture() -> Image:
    await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()
func run():
    root.size=Vector2i(1280,720)
    root.content_scale_size=Vector2i(1920,1080)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var quick=root.get_node("SegmentQuickStart")
    quick.start_segment(3)
    await quick.segment_started
    var game=current_scene
    game.get_node("RunRetrospective").recording_enabled=false
    var stage=game.get_node("OceanLink/FishStage")
    var fish=stage.fish
    fish.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
    game.get_node("OceanLink/FishBottomBoundary").disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
    game.process_mode=Node.PROCESS_MODE_DISABLED
    game.get_node("TextureStreamer").process_mode=Node.PROCESS_MODE_ALWAYS
    game.get_node("CameraOutput").process_mode=Node.PROCESS_MODE_ALWAYS
    var boundary=game.get_node("OceanLink/FishBottomBoundary")
    check(boundary.global_transform==game.global_transform,"Floor aligns with original map despite OceanLink offset")
    check(fish.collision_mask&128!=0 and game.demon.collision_mask&128==0,"Boundary affects fish without blocking demon eruption")
    await physics_frame
    for x in [285,400,960,1540,1650]:
        fish.global_position=game.to_global(Vector2(x,38800))
        var hit=fish.move_and_collide(Vector2(0,1000))
        check(hit!=null,"Real downward swim meets floor at x="+str(x))
        check(game.to_local(fish.global_position).y<39090,"Fish cannot swim through seabed")
        var before: Vector2=fish.global_position
        fish.move_and_collide(Vector2(0,1000))
        check(game.to_local(fish.global_position).y<39090,"Continuing downward cannot cross floor")
        fish.global_position=game.to_global(Vector2(x,38900))
        var blink_hit=fish.get_node("Teleport")._blink_motion(Vector2(0,800),true)
        check(blink_hit!=null,"Shift blink sweep also respects the bottom")
    for height in [30500,33000,38000,39000]:
        for direction in [-1,1]:
            fish.global_position=game.to_global(Vector2(960,height))
            var side_hit=fish.move_and_collide(Vector2(direction*2000,0))
            check(side_hit!=null,"Side wall blocks swimming at height="+str(height))
            var x: float=game.to_local(fish.global_position).x
            check(x>=270 and x<=1670,"Swimming is confined inside black wall outlines")
            fish.global_position=game.to_global(Vector2(960,height))
            var side_blink=fish.get_node("Teleport")._blink_motion(Vector2(direction*2000,0),true)
            check(side_blink!=null,"Blink cannot cross side wall")
    var walls=game.get_node("WorldLayers/OceanWalls")
    check(not walls.z_as_relative and walls.z_index>fish.z_index,"Wall foreground has absolute depth above fish")
    if DisplayServer.get_name()!="headless":
        for height in [33000,38800,39050]:
            game.camera.adopt_view(game.to_global(Vector2(960,height)),Vector2.ONE)
            game.camera.make_current()
            fish.global_position=game.to_global(Vector2(1780,height))
            fish.hide()
            await create_timer(1.5).timeout
            var background: Image=await capture()
            fish.show()
            var behind_wall: Image=await capture()
            check(changed(background,behind_wall)<5,"Wall hides fish at depth="+str(height))
            behind_wall.save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/ocean-wall-"+str(height)+".png")
            fish.global_position=game.to_global(Vector2(960,height))
            var visible_fish: Image=await capture()
            check(changed(background,visible_fish)>10,"Fish is visibly rendered in open water at same depth")
    print("OCEAN_BOTTOM_BOUNDARY failures=",failures)
    quit(1 if failures else 0)
