extends CanvasLayer
const CURSOR=preload("res://modules/ui/authored_cursor.gd")
@export var idle_seconds:float=.9
const GAMEPLAY_SCENES=["res://scenes/levels/formal_hell_entry.tscn","res://scenes/previews/settlement_descent.tscn"]
var _idle:float=10.0
var _reveal_age:float=1.0
var _visibility:float=1.0
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
    get_tree().scene_changed.connect(_reset_for_scene)
    _reset_for_scene()
    _update_pose()
func _gameplay()->bool:
    var scene=get_tree().current_scene
    if scene==null or get_tree().paused:return false
    if scene.scene_file_path not in GAMEPLAY_SCENES:return false
    return scene.get("dead")!=true
func _reset_for_scene():
    _idle=idle_seconds+1.0
    _reveal_age=1.0
    _visibility=0.0 if _gameplay() else 1.0
func _input(event:InputEvent):
    if event is InputEventMouseMotion and (event.relative.length_squared()>.01 or event.position.distance_squared_to(_position)>.01):
        if _gameplay() and _idle>=idle_seconds:
            _reveal_age=0.0
        _idle=0.0
    if event is InputEventMouse:
        _position=event.position
        _inside=get_viewport().get_visible_rect().has_point(_position)
    if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
        pulse_count+=1
        elapsed=0.0
    _update_pose()
func _process(delta:float):
    elapsed=minf(1.0,elapsed+delta)
    _idle+=delta
    _reveal_age=minf(1.0,_reveal_age+delta)
    var wanted:float=0.0 if _gameplay() and _idle>=idle_seconds else 1.0
    _visibility=move_toward(_visibility,wanted,delta/.12)
    _update_pose()
func _update_pose():
    if not is_instance_valid(art):return
    var factor:=get_viewport().get_visible_rect().size/Vector2(get_window().size)
    art.size=CURSOR.texture.get_size()*factor
    art.pivot_offset=art.size*.5
    art.position=_position-CURSOR.hotspot*factor
    var squash:float=1.0-.22*cos(elapsed*29.0)*exp(-elapsed*12.0) if elapsed<.35 else 1.0
    var u:float=clampf(_reveal_age/.24,0.0,1.0)-1.0
    var pop:float=1.0+2.70158*u*u*u+1.70158*u*u if _gameplay() else 1.0
    art.scale=Vector2(1.0/squash,squash)*maxf(.01,pop)
    art.modulate.a=_visibility
    art.visible=_inside and _visibility>0.0
