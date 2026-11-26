extends CanvasLayer
## 拾取时在屏幕上方正中临时弹出本局总数，再向上弹走；不常驻画面。
@export_node_path("Node2D") var collection_path: NodePath=^"../HellOranges"
@export var digit_height: float=96.0
@export var top_margin: float=48.0
@export var pop_seconds: float=.2
@export var hold_seconds: float=.55
@export var exit_seconds: float=.4
@export var exit_rise: float=105.0
@export_range(0.0,1.0) var motion_amount: float=1.0
const DIGIT_REGIONS: Array[Rect2]=[
    Rect2(406,34,38,47),Rect2(370,29,29,51),Rect2(401,34,38,41),
    Rect2(450,24,31,57),Rect2(402,29,46,58),Rect2(406,26,43,52),
    Rect2(402,33,38,52),Rect2(414,28,38,59),Rect2(406,26,47,58),Rect2(447,28,41,59)]
enum Phase { HIDDEN, POP, HOLD, EXIT }
var phase: Phase=Phase.HIDDEN
var displayed_count: int=0
var _target_count: int=0
var _elapsed: float=0.0
var _rise: float=0.0
var _width: float=0.0
var _digits: Array[AtlasTexture]=[]
@onready var collection: Node2D=get_node(collection_path)
@onready var level: Node2D=collection.get_parent()
@onready var anchor: Node2D=$Anchor
@onready var numbers: Node2D=$Anchor/Numbers
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    for digit in 10:
        var atlas=AtlasTexture.new()
        atlas.atlas=load("res://assets/art/ui/orange_counter/%d.png"%digit)
        atlas.region=DIGIT_REGIONS[digit]
        atlas.filter_clip=true
        _digits.append(atlas)
    collection.orange_collected.connect(_on_orange_collected)
    var fork: Node=level.get_node_or_null("Fork")
    if fork!=null:fork.interaction_reset.connect(reset_view)
    reset_view()
func reset_view() -> void:
    displayed_count=collection.collected_count
    _target_count=displayed_count
    phase=Phase.HIDDEN
    visible=false
    _elapsed=0.0
    _rise=0.0
    numbers.scale=Vector2.ONE
    numbers.modulate=Color.WHITE
func _on_orange_collected(total: int,_orange_id: StringName) -> void:
    if total<=_target_count:return
    _target_count=total
    if phase!=Phase.POP:_begin_pop()
func _begin_pop() -> void:
    displayed_count+=1
    _render_digits()
    phase=Phase.POP
    _elapsed=0.0
    _sample()
    _place_at_top()
    visible=level.is_visible_in_tree()
func _render_digits() -> void:
    for child in numbers.get_children():
        numbers.remove_child(child)
        child.queue_free()
    var text: String=str(displayed_count)
    var widths: Array[float]=[]
    _width=0.0
    for character in text:
        var region: Rect2=DIGIT_REGIONS[int(character)]
        var width: float=region.size.x*digit_height/region.size.y
        widths.append(width)
        _width+=width
    _width+=maxi(0,text.length()-1)*8.0
    var x: float=-_width*.5
    for index in text.length():
        var sprite=Sprite2D.new()
        sprite.texture=_digits[int(text[index])]
        sprite.scale=Vector2.ONE*digit_height/DIGIT_REGIONS[int(text[index])].size.y
        sprite.position=Vector2(x+widths[index]*.5,0)
        numbers.add_child(sprite)
        x+=widths[index]+8.0
func _process(delta: float) -> void:
    if phase==Phase.HIDDEN:return
    var remaining: float=delta/maxf(Engine.time_scale,.001)
    # 大帧间隔或连续三颗也逐个消费事件，不丢计数。
    while remaining>0.0 and phase!=Phase.HIDDEN:
        var duration: float=maxf(.01,pop_seconds if phase==Phase.POP else hold_seconds if phase==Phase.HOLD else exit_seconds)
        var step: float=minf(remaining,maxf(0.0,duration-_elapsed))
        _elapsed+=step
        remaining-=step
        if _elapsed<duration:break
        _elapsed=0.0
        if phase==Phase.POP:
            if displayed_count<_target_count:_begin_pop()
            else:phase=Phase.HOLD
        elif phase==Phase.HOLD:phase=Phase.EXIT
        else:phase=Phase.HIDDEN
    _sample()
    _place_at_top()
    visible=phase!=Phase.HIDDEN and level.is_visible_in_tree()
func _sample() -> void:
    _rise=0.0
    numbers.modulate.a=1.0
    numbers.scale=Vector2.ONE
    if phase==Phase.POP:
        var u: float=clampf(_elapsed/maxf(.01,pop_seconds),0,1)
        var t: float=u-1.0
        var back: float=1.0+2.70158*t*t*t+1.70158*t*t
        numbers.scale=Vector2.ONE*lerpf(1.0,lerpf(.3,1.0,back),motion_amount)
        _rise=-18.0*(1.0-smoothstep(0.0,1.0,u))*motion_amount
    elif phase==Phase.EXIT:
        var u: float=clampf(_elapsed/maxf(.01,exit_seconds),0,1)
        _rise=exit_rise*u*u*motion_amount
        var stretch: Vector2=Vector2(1.0-.22*sin(PI*u),1.0+.24*sin(PI*u))
        numbers.scale=Vector2.ONE.lerp(stretch,motion_amount)
        numbers.modulate.a=1.0-smoothstep(.15,1.0,u)
func _place_at_top() -> void:
    var screen: Vector2=get_viewport().get_visible_rect().size
    anchor.position=Vector2(screen.x*.5,top_margin+digit_height*.5)
    numbers.position=Vector2(0,-_rise)
