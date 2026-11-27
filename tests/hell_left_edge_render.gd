extends SceneTree
func _initialize():run.call_deferred()
func run():
    root.size=Vector2i(1280,720)
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    game.process_mode=Node.PROCESS_MODE_DISABLED
    game.get_node("Camera").enabled=false
    var camera=Camera2D.new()
    camera.position=Vector2(960,51460)
    root.add_child(camera)
    camera.make_current()
    var probe=Polygon2D.new()
    probe.polygon=PackedVector2Array([Vector2(-8,51430),Vector2(8,51430),Vector2(8,51490),Vector2(-8,51490)])
    probe.color=Color.GREEN
    probe.z_index=17
    game.add_child(probe)
    await process_frame
    await RenderingServer.frame_post_draw
    var image=root.get_texture().get_image()
    image.save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/hell-wall-fill.png")
    var actual=image.get_pixel(2,360)
    var expected=image.get_pixel(16,360)
    print("EDGE_COLORS=",actual," / ",expected)
    assert(actual.g<.3 and actual.r>.2,"Foreground fill must hide the green object behind the wall")
    assert(Vector3(actual.r,actual.g,actual.b).distance_to(Vector3(expected.r,expected.g,expected.b))<.04,"Edge must match adjacent wall color")
    print("HELL_WALL_FILL_NATIVE_PASS")
    quit()
