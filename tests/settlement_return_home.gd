extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var old := Node2D.new()
    root.add_child(old)
    current_scene = old
    var transition = load("res://modules/cinematic/settlement_return_home.gd").new()
    transition.fade_to_black_seconds = .05
    transition.minimum_black_seconds = .1
    transition.reveal_seconds = .2
    root.add_child(transition)
    check(transition.beans.get_node("Layout/Corner").get_child_count() == 5,"Reuses all five original loading characters")
    transition.start()
    await create_timer(.08).timeout
    check(transition.black.color.a > .99,"Loading starts on a fully black screen")
    check(transition.beans.visible,"Five characters are visible during the black transition")
    await transition.completed
    check(transition.menu_ready and current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn","A ready home scene is revealed")
    check(transition.black.color.a < .001,"The black overlay fades away completely")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        var pixel: Color = image.get_pixel(100,100)
        check(maxf(pixel.r,maxf(pixel.g,pixel.b)) > .1,"The home scene is actually rendered, not a black viewport")
    print("SETTLEMENT_RETURN_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
