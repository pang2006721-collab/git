extends Node2D
## 编辑器中的位置就是静态摆放位置；同相位轻摆保持小组对齐。
@export var bob_height: float = 7.0
@export var sway_width: float = 4.0
@export var bob_period: float = 2.4
@export var artwork_scale: float = .85
@export var pickup_radius: float = 43.0
@export var pop_seconds: float = .08
@export var absorb_seconds: float = .24
var _collector: CharacterBody2D
var _eat_elapsed: float = 0.0
var _eat_start: Vector2
var collected: bool = false
var _clock: float = 0.0
var _origin: Vector2
var art: Sprite2D
func _ready() -> void:
    _origin=position
    _clock=0.0
    art=$Art
    art.scale=Vector2.ONE*artwork_scale
    _process(0)
func _process(delta: float) -> void:
    if collected:
        _animate_absorb(delta)
        return
    _clock+=delta
    position=_origin+Vector2(sin(_clock*TAU/(bob_period*1.4))*sway_width,sin(_clock*TAU/bob_period)*bob_height)
func collect(body: CharacterBody2D) -> void:
    if collected: return
    collected=true
    _collector=body
    _eat_start=global_position
    _eat_elapsed=0.0
    process_mode=Node.PROCESS_MODE_ALWAYS
func _animate_absorb(delta: float) -> void:
    if not visible: return
    _eat_elapsed+=delta
    if _eat_elapsed<pop_seconds:
        var pulse: float=sin(clampf(_eat_elapsed/maxf(pop_seconds,.001),0,1)*PI)
        art.scale=Vector2(1.0+.3*pulse,1.0-.16*pulse)*artwork_scale
        return
    var u: float=clampf((_eat_elapsed-pop_seconds)/maxf(absorb_seconds,.001),0,1)
    var target: Vector2=_eat_start
    if is_instance_valid(_collector):
        var collision: Node2D=_collector.get_node_or_null("Collision")
        target=collision.global_position if collision!=null else _collector.global_position+Vector2(0,-56)
    var eased: float=u*u
    global_position=_eat_start.lerp(target,eased)+Vector2(0,-18*sin(PI*u))
    art.scale=Vector2.ONE*artwork_scale*lerpf(1.0,.04,eased)
    if u>=1.0: hide()
