extends CanvasLayer
## 作者提供的 SHIFT 按键图，固定在屏幕上方，持续快速弹跳并响应每次挣扎。
const ART = preload("res://assets/art/characters/fish/abilities/struggle_shift.png")
var active: bool = false
var sprite: Sprite2D
var _clock: float = 0
var _weight: float = 0
var _kick: float = 0
func _ready() -> void:
    layer = 40
    sprite = Sprite2D.new()
    sprite.texture = ART
    add_child(sprite)
    hide_prompt(true)
func show_prompt() -> void:
    active = true
    visible = true
    _clock = 0
    _weight = 0
func pulse() -> void:
    _kick = 1
func hide_prompt(immediate: bool = false) -> void:
    active = false
    if immediate:
        visible = false
        _weight = 0
        _kick = 0
func _process(delta: float) -> void:
    if not visible: return
    _clock += delta
    _kick = move_toward(_kick,0,delta*7)
    _weight = move_toward(_weight,1.0 if active else 0.0,delta/.16)
    var u := _weight
    var pop := 1+2.7*pow(u-1,3)+1.7*pow(u-1,2)
    var beat := maxf(0,sin(_clock*TAU*4.8))
    var size := get_viewport().get_visible_rect().size
    var base := minf(.60,size.x*.20/ART.get_width())
    sprite.position = Vector2(size.x*.5,size.y*.10-beat*12-_kick*7)
    sprite.scale = Vector2(base*(1+beat*.18+_kick*.08),base*(1-beat*.12+_kick*.06))*maxf(.01,pop)
    sprite.rotation = sin(_clock*TAU*2.4)*.025
    sprite.modulate.a = smoothstep(0,.25,_weight)
    if not active and _weight<=0: visible = false
