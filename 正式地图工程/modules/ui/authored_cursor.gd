extends RefCounted
const ART=preload("res://assets/art/ui/authored_cursor.png")
const SIZE=48
const TILT_CORRECTION=15.0
static var texture:Texture2D
static var hotspot:=Vector2.ZERO
static var driver:Node
static func apply():
    if DisplayServer.get_name()=="headless":return
    if texture==null:
        var image=ART.get_image()
        image.resize(SIZE,roundi(float(image.get_height())*SIZE/image.get_width()),Image.INTERPOLATE_LANCZOS)
        var tip:=Vector2(1,1)
        var closest:=INF
        for y in mini(12,image.get_height()):
            for x in mini(12,image.get_width()):
                if image.get_pixel(x,y).a>.7 and x+y<closest:
                    closest=x+y
                    tip=Vector2(x,y)
        var angle:=deg_to_rad(TILT_CORRECTION)
        var bounds:=Rect2(Vector2.ZERO,Vector2.ZERO)
        for corner in [Vector2(image.get_width(),0),Vector2(0,image.get_height()),Vector2(image.get_size())]:bounds=bounds.expand(corner.rotated(angle))
        var origin:=bounds.position.floor()-Vector2(2,2)
        var rotated=Image.create(ceili(bounds.end.x-origin.x)+2,ceili(bounds.end.y-origin.y)+2,false,Image.FORMAT_RGBA8)
        for y in rotated.get_height():
            for x in rotated.get_width():
                var source:Vector2=(Vector2(x+.5,y+.5)+origin).rotated(-angle)-Vector2(.5,.5)
                rotated.set_pixel(x,y,_sample(image,source))
        var used:Rect2i=rotated.get_used_rect()
        hotspot=tip.rotated(angle)-origin-Vector2(used.position)
        texture=ImageTexture.create_from_image(rotated.get_region(used))
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    var tree:=Engine.get_main_loop() as SceneTree
    if tree!=null:
        if not tree.root.tree_exiting.is_connected(_shutdown):tree.root.tree_exiting.connect(_shutdown,CONNECT_ONE_SHOT)
        if not is_instance_valid(driver):
            driver=load("res://modules/ui/cursor_click_feedback.gd").new()
            driver.name="AuthoredCursorFeedback"
            tree.root.add_child.call_deferred(driver)
static func _sample(image:Image,point:Vector2)->Color:
    var start:=Vector2i(point.floor())
    var fraction:Vector2=point-Vector2(start)
    var result:=Color(0,0,0,0)
    for dy in 2:
        for dx in 2:
            var at:=start+Vector2i(dx,dy)
            if at.x<0 or at.y<0 or at.x>=image.get_width() or at.y>=image.get_height():continue
            var c:=image.get_pixelv(at)
            var weight:float=(fraction.x if dx else 1-fraction.x)*(fraction.y if dy else 1-fraction.y)
            result+=Color(c.r*c.a,c.g*c.a,c.b*c.a,c.a)*weight
    if result.a>0:result=Color(result.r/result.a,result.g/result.a,result.b/result.a,result.a)
    return result
static func _shutdown():
    for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND]:Input.set_custom_mouse_cursor(null,shape)
    texture=null
    driver=null
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
