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
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.process_mode=Node.PROCESS_MODE_DISABLED
    game.get_node("TextureStreamer").process_mode=Node.PROCESS_MODE_ALWAYS
    game.get_node("CameraOutput").process_mode=Node.PROCESS_MODE_ALWAYS
    var transition=game.get_node("OceanLink/FishStage/JungleLayout/CanopyTransition")
    var cutout: Sprite2D
    for child in transition.get_children():
        if child is Sprite2D and is_equal_approx(child.position.y,20480):cutout=child
    check(cutout!=null,"Original underside foreground exists")
    if cutout==null:quit(1);return
    var source: Image=load("res://assets/art/reference_map/10.png").get_image()
    var image: Image=cutout.texture.get_image()
    var tested:=0
    for x in range(0,1920,8):
        for y in range(0,300,4):
            var pixel:=image.get_pixel(x,y)
            var original:=source.get_pixel(x,y+1)
            check(Vector3(pixel.r,pixel.g,pixel.b).distance_to(Vector3(original.r,original.g,original.b))<.001,"Cutout retains source RGB at transparent edge")
            if pixel.a==0:tested+=1
    check(tested>100,"Transparent pixels are included in comparison")
    check(cutout.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Cut edge cannot interpolate transparent black")
    if DisplayServer.get_name()!="headless":
        for zoom in [1.0,1.35]:
            game.camera.adopt_view(game.to_global(Vector2(960,20620)),Vector2.ONE*zoom)
            game.camera.make_current()
            await create_timer(1.0).timeout
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/canopy-edge-"+str(zoom)+".png")
    print("CANOPY_CUTOUT_EDGE failures=",failures)
    quit(1 if failures else 0)
