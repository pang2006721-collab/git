extends SceneTree
func _initialize():run.call_deferred()
func run():
    assert(ProjectSettings.get_setting("application/boot_splash/show_image")==false)
    assert(ProjectSettings.get_setting("application/config/icon")=="res://assets/art/ui/game_icon.png")
    var boot=load("res://scenes/ui/branded_boot.tscn").instantiate()
    root.add_child(boot)
    current_scene=boot
    await create_timer(1.2).timeout
    var overlay=root.get_node("BootLoading")
    assert(overlay.black.color.a==1 and overlay.beans.visible)
    assert(overlay.beans._actors.size()==5)
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/branded-boot-beans.png")
    for i in 200:
        if overlay.menu_ready:break
        await create_timer(.01).timeout
    assert(overlay.menu_ready and overlay.black.color.a==1.0)
    assert(overlay.layer>current_scene._tutorial_book.layer,"Loading must cover the homepage book")
    assert(overlay.beans.layer>overlay.layer,"Beans remain above the black curtain")
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        var frame=root.get_texture().get_image()
        var ratio:Vector2=Vector2(frame.get_size())/root.get_visible_rect().size
        var button:Rect2=current_scene._tutorial_book.entry.get_global_rect()
        for y in range(int(button.position.y*ratio.y),int(button.end.y*ratio.y),3):
            for x in range(int(button.position.x*ratio.x),int(button.end.x*ratio.x),3):
                var c:Color=frame.get_pixel(x,y)
                assert(maxf(c.r,maxf(c.g,c.b))<.015,"No book pixels may leak through the loading curtain")
    for i in 200:
        if not is_instance_valid(overlay):break
        await create_timer(.05).timeout
    assert(not is_instance_valid(overlay))
    assert(current_scene.scene_file_path=="res://scenes/ui/main_menu.tscn")
    assert(current_scene.get_node("Start").visible and not paused)
    print("BRANDED_BOOT_PASS: black splash, original icon, five animated beans, background menu load, reveal")
    quit()
