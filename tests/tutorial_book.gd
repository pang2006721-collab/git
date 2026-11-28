extends SceneTree
const SAVE="user://test_tutorial_book.cfg"
func _initialize():run.call_deferred()
func click(button:Control):
    var at=button.get_global_rect().get_center()
    var motion=InputEventMouseMotion.new()
    motion.position=at
    motion.global_position=at
    root.push_input(motion,true)
    await process_frame
    for down in [true,false]:
        var event=InputEventMouseButton.new()
        event.position=at
        event.global_position=at
        event.button_index=MOUSE_BUTTON_LEFT
        event.pressed=down
        event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
        root.push_input(event,true)
        await process_frame
func ready_page(book,index:int):
    for i in 150:
        await create_timer(.02).timeout
        if book.page_index==index and not book._switching and is_instance_valid(book.chapter):break
    if book.page_index!=index or book._switching:print("BOOK_NOT_READY target=",index," actual=",book.page_index," active=",book._active," switching=",book._switching," entry=",book.entry.get_global_rect())
    assert(book.page_index==index and not book._switching)
    await create_timer(.35).timeout
    if not book.is_open():
        print("BOOK_CLOSED_DURING_READY index=",index)
        quit(1)
        return
    assert(book.dot_art[index].scale.x>1.2)
    for i in 4:
        assert(book.dot_art[i].modulate.r>(.95 if i==index else .0))
        if i!=index:assert(book.dot_art[i].scale.x<.85 and book.dot_art[i].modulate.r<.5)
func run():
    root.size=Vector2i(1280,720)
    root.content_scale_size=Vector2i(1920,1080)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    if FileAccess.file_exists(SAVE):DirAccess.remove_absolute(SAVE)
    var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    var cursor=preload("res://modules/ui/authored_cursor.gd")
    assert(cursor.texture!=null and cursor.texture.get_width()<=64 and cursor.texture.get_height()<=64)
    assert(Rect2(Vector2.ZERO,cursor.texture.get_size()).has_point(cursor.hotspot))
    cursor.texture.get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/cursor-adjusted.png")
    var book=menu._tutorial_book
    book.save_path=SAVE
    await create_timer(.3).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/menu-tutorial-book.png")
    await click(book.entry)
    await ready_page(book,0)
    if "--preview" in OS.get_cmdline_user_args():
        for index in 4:
            if index>0:
                await click(book.right)
                await ready_page(book,index)
            await create_timer(1.2).timeout
        await click(book.chapter.close_art)
        await create_timer(1.1).timeout
        assert(not paused)
        print("TUTORIAL_BOOK_PREVIEW_PASS")
        quit()
        return
    assert(book.is_open() and paused and book.dots.size()==4)
    assert(book.left.disabled and not book.left.visible and not book.right.disabled)
    assert(book.right.get_meta("presence").get_child(0).size==Vector2(76,196))
    assert(book._feedback.pulse_count>0)
    menu._start_game()
    assert(not menu._starting)
    await click(book.right)
    await ready_page(book,1)
    var partial=ConfigFile.new()
    partial.load(SAVE)
    assert(not partial.get_value("watched","hell",false),"Switching early cannot mark the tutorial watched")
    await click(book.dots[3])
    await ready_page(book,3)
    assert(book.right.disabled and not book.right.visible and not book.left.disabled)
    await click(book.left)
    await ready_page(book,2)
    assert(book.right.visible and book.right.get_meta("presence").scale.is_equal_approx(Vector2.ONE))
    for index in 4:
        await click(book.dots[index])
        await ready_page(book,index)
        var clip=book.chapter
        var completed_count:Array=[0]
        clip.completed.connect(func():completed_count[0]+=1)
        var photograph_time:float=1.0 if index!=3 else 6.5
        await create_timer(photograph_time).timeout
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/tutorial-book-page-"+str(index)+".png")
        for i in 85:
            if completed_count[0]>0:break
            await create_timer(.2).timeout
        assert(completed_count[0]>0,"Playback did not complete: "+str(index)+" pos="+str(clip.movie.stream_position)+" playing="+str(clip.movie.is_playing()))
        assert(is_instance_valid(clip) and clip.movie.is_playing() and book.is_open() and paused,"Completed page loops instead of dismissing the book")
        var cfg=ConfigFile.new()
        assert(cfg.load(SAVE)==OK and cfg.get_value("watched",book.CHAPTERS[index],false))
        assert(not cfg.get_value("level_entered",book.CHAPTERS[index],false),"Homepage viewing does not count as playing the level")
        print("BOOK_PAGE_PASS ",book.CHAPTERS[index])
    await click(book.chapter.close_art)
    await create_timer(1.1).timeout
    assert(not book.is_open() and not paused and book.entry.visible)
    assert(menu.get_node("Bird/MouseDrag").is_processing_input())
    await click(book.entry)
    await ready_page(book,0)
    var keyboard=InputEventKey.new()
    keyboard.physical_keycode=KEY_RIGHT
    keyboard.pressed=true
    root.push_input(keyboard,true)
    await ready_page(book,1)
    keyboard=InputEventKey.new()
    keyboard.physical_keycode=KEY_ESCAPE
    keyboard.pressed=true
    root.push_input(keyboard,true)
    await create_timer(1.1).timeout
    assert(not paused and not book.is_open())
    print("TUTORIAL_BOOK_PASS: mouse entry/arrows/dots, four pages, active beans, partial/full watch, loop, keyboard, close/restore")
    quit()
