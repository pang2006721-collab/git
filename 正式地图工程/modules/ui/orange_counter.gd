extends CanvasLayer
## 原画数字 HUD；收集事件排队逐颗弹动，计数仍由本局收集模块负责。
@export_node_path("Node2D") var collection_path: NodePath=^"../HellOranges"
@export var left_margin: float=48.0
@export var top_margin: float=32.0
@export var artwork_scale: float=1.0
@export_range(0.0,1.0) var motion_amount: float=1.0
@export var pop_seconds: float=.22
const DIGIT_REGIONS: Array[Rect2]=[
    Rect2(406,34,38,47),Rect2(370,29,29,51),Rect2(401,34,38,41),
    Rect2(450,24,31,57),Rect2(402,29,46,58),Rect2(406,26,43,52),
    Rect2(402,33,38,52),Rect2(414,28,38,59),Rect2(406,26,47,58),Rect2(447,28,41,59)]
var displayed_count: int=0
var _target_count: int=0
var _pulse_time: float=-1.0
var _incremented: bool=false
var _clock: float=0.0
var _digits: Array[AtlasTexture]=[]
var _logo_origin: Vector2
var _multiply_origin: Vector2
@onready var collection: Node2D=get_node(collection_path)
@onready var level: Node2D=collection.get_parent()
@onready var anchor: Control=$Anchor
@onready var contents: Node2D=$Anchor/Contents
@onready var logo: Sprite2D=$Anchor/Contents/Logo
@onready var multiply: Sprite2D=$Anchor/Contents/Multiply
@onready var numbers: Node2D=$Anchor/Contents/Numbers
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    for digit in 10:
        var atlas=AtlasTexture.new()
        atlas.atlas=load("res://assets/art/ui/orange_counter/%d.png"%digit)
        atlas.region=DIGIT_REGIONS[digit]
        atlas.filter_clip=true
        _digits.append(atlas)
    displayed_count=collection.collected_count
    _target_count=displayed_count
    _render_digits()
    collection.orange_collected.connect(_on_orange_collected)
    _process(0.0)
func _on_orange_collected(total: int,_orange_id: StringName) -> void:
    _target_count=maxi(total,_target_count)
func _render_digits() -> void:
    for child in numbers.get_children():
        numbers.remove_child(child)
        child.queue_free()
    var text: String=str(displayed_count)
    var width: float=0.0
    var widths: Array[float]=[]
    for character in text:
        var region: Rect2=DIGIT_REGIONS[int(character)]
        var glyph_width: float=region.size.x*48.0/region.size.y
        widths.append(glyph_width)
        width+=glyph_width
    width+=maxi(0,text.length()-1)*5.0
    # 数字从固定起点排，换字宽度和进位不会把橘子与乘号推来推去。
    numbers.position=Vector2(131.0+width*.5,30.8)
    var x: float=-width*.5
    for index in text.length():
        var sprite=Sprite2D.new()
        sprite.texture=_digits[int(text[index])]
        sprite.scale=Vector2.ONE*48.0/DIGIT_REGIONS[int(text[index])].size.y
        sprite.position=Vector2(x+widths[index]*.5,0)
        numbers.add_child(sprite)
        x+=widths[index]+5.0
    _multiply_origin=Vector2(107,31.8)
    _logo_origin=Vector2(38,30.8)
func _process(delta: float) -> void:
    # CanvasLayer 独立于地图相机；预载关卡时不提前出现在开场动画中。
    var entry: Node=level.get_node("WallEntry")
    visible=level.is_visible_in_tree() and (entry.playing or entry.completed)
    anchor.offset_left=left_margin
    anchor.offset_right=left_margin
    anchor.offset_top=top_margin
    anchor.offset_bottom=top_margin
    contents.scale=Vector2.ONE*artwork_scale
    var real_delta: float=delta/maxf(Engine.time_scale,.001)
    _clock+=real_delta
    logo.position=_logo_origin+Vector2(sin(_clock*1.6)*1.8,sin(_clock*2.1)*2.4)*motion_amount
    logo.rotation=sin(_clock*1.7)*.025*motion_amount
    multiply.position=_multiply_origin+Vector2(sin(_clock*1.9+.8)*1.3,sin(_clock*2.0+1.2)*1.7)*motion_amount
    multiply.rotation=sin(_clock*1.5+.6)*.035*motion_amount
    if _pulse_time<0.0:
        if displayed_count>=_target_count:return
        _pulse_time=0.0
        _incremented=false
    _pulse_time+=real_delta
    var duration: float=maxf(.1,pop_seconds)
    var anticipation: float=duration*.2
    if not _incremented and _pulse_time>=anticipation:
        displayed_count+=1
        _incremented=true
        _render_digits()
    var squash: Vector2
    if _pulse_time<anticipation:
        squash=Vector2.ONE.lerp(Vector2(1.08,.84),_pulse_time/anticipation)
    else:
        var u: float=clampf((_pulse_time-anticipation)/(duration-anticipation),0.0,1.0)
        var bounce: float=sin(PI*u)*exp(-2.0*u)
        squash=Vector2(1.0+.28*bounce,1.0+.5*bounce)
    numbers.scale=Vector2.ONE.lerp(squash,motion_amount)
    if _pulse_time>=duration:
        numbers.scale=Vector2.ONE
        _pulse_time=-1.0
