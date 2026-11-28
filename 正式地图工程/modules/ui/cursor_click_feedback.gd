extends CanvasLayer
const CURSOR=preload("res://modules/ui/authored_cursor.gd")
var pulse_count:int=0
var elapsed:float=1.0
var art:TextureRect
var _position:=Vector2.ZERO
var _inside:=true
func _ready():
    layer=1000
    process_mode=Node.PROCESS_MODE_ALWAYS
    process_priority=1000
    art=TextureRect.new()
    art.texture=CURSOR.texture
    art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(art)
    _position=get_viewport().get_mouse_position()
    get_window().mouse_exited.connect(func():_inside=false;art.hide())
    get_window().mouse_entered.connect(func():_inside=true;_position=get_viewport().get_mouse_position())
    _update_pose()
func _input(event:InputEvent):
    if event is InputEventMouse:
        _position=event.position
        _inside=get_viewport().get_visible_rect().has_point(_position)
    if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
        pulse_count+=1
        elapsed=0.0
    _update_pose()
func _process(delta:float):
    elapsed=minf(1.0,elapsed+delta)
    _update_pose()
func _update_pose():
    if not is_instance_valid(art):return
    var factor:=get_viewport().get_visible_rect().size/Vector2(get_window().size)
    art.size=CURSOR.texture.get_size()*factor
    art.pivot_offset=art.size*.5
    art.position=_position-CURSOR.hotspot*factor
    var squash:float=1.0-.22*cos(elapsed*29.0)*exp(-elapsed*12.0) if elapsed<.35 else 1.0
    art.scale=Vector2(1.0/squash,squash)
    art.visible=_inside
