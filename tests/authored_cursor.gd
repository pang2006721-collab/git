extends SceneTree
const CURSOR=preload("res://modules/ui/authored_cursor.gd")
func _initialize():run.call_deferred()
func press():
    var event=InputEventMouseButton.new()
    event.position=Vector2(200,100)
    event.global_position=event.position
    event.button_index=MOUSE_BUTTON_LEFT
    event.pressed=true
    root.push_input(event,true)
func run():
    CURSOR.apply()
    await process_frame
    var driver=root.get_node("AuthoredCursorFeedback")
    var movement=InputEventMouseMotion.new()
    movement.position=Vector2(200,100)
    movement.global_position=movement.position
    root.push_input(movement,true)
    var before:Vector2=root.get_mouse_position()
    var center:Vector2=driver.art.get_global_transform()*(driver.art.size*.5)
    press()
    assert(driver.pulse_count==1 and driver.art.scale.y<.85)
    assert(root.get_mouse_position()==before,"Cursor feedback cannot move the click point")
    assert((driver.art.get_global_transform()*(driver.art.size*.5)).is_equal_approx(center),"The spring must keep its visual center fixed")
    assert(driver.art.mouse_filter==Control.MOUSE_FILTER_IGNORE)
    assert(Input.mouse_mode==Input.MOUSE_MODE_HIDDEN)
    await create_timer(.08).timeout
    press()
    assert(driver.pulse_count==2 and driver.art.scale.y<.85)
    paused=true
    await create_timer(.5).timeout
    assert(driver.art.scale.is_equal_approx(Vector2.ONE),"The spring settles while a tutorial pauses gameplay")
    paused=false
    print("AUTHORED_CURSOR_PASS: one GPU sprite, centered spring, fixed click coordinates, rapid clicks, paused UI, reset")
    quit()
