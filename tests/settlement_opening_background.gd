extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    if DisplayServer.get_name() == "headless":
        print("Opening background test requires native rendering")
        quit(1)
        return
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1920,1080)
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var scene = load("res://scenes/previews/settlement_descent.tscn").instantiate()
    scene.auto_play = false
    scene.interactive = false
    root.add_child(scene)
    current_scene = scene
    scene.set_process(false)
    scene.sample(9.2)
    await create_timer(.3).timeout
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    var original_god: int = 0
    var duplicate_god: int = 0
    for y in range(100,320):
        for x in range(450,830):
            var pixel: Color = image.get_pixel(x,y)
            if maxf(pixel.r,maxf(pixel.g,pixel.b)) < .12: original_god += 1
    for y in range(620,715):
        for x in range(400,880):
            var pixel: Color = image.get_pixel(x,y)
            if maxf(pixel.r,maxf(pixel.g,pixel.b)) < .12: duplicate_god += 1
    check(original_god > 500,"The one original God remains visible as the camera descends")
    check(duplicate_god == 0,"No second God's black outline leaks out below the opening room")
    check(image.get_pixel(640,650).r > .7,"Cloud background remains drawn instead of a missing-texture gap")
    scene.sample(10.5)
    await RenderingServer.frame_post_draw
    var with_ghost: PackedByteArray = root.get_texture().get_image().get_data()
    scene.ghost_layer.hide()
    await RenderingServer.frame_post_draw
    check(with_ghost == root.get_texture().get_image().get_data(),"Ghost and halo remain fully occluded in the cloud passage")
    print("SETTLEMENT_OPENING_FAILURES=",failures.size()," GOD_PIXELS=",original_god," DUPLICATE_PIXELS=",duplicate_god)
    quit(0 if failures.is_empty() else 1)
