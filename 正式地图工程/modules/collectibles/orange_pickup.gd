extends Node2D
## 编辑器中的位置就是静态摆放位置；同相位轻摆保持小组对齐。
@export var bob_height: float = 7.0
@export var sway_width: float = 4.0
@export var bob_period: float = 2.4
@export var artwork_scale: float = .85
@export var pickup_radius: float = 43.0
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
    _clock+=delta
    position=_origin+Vector2(sin(_clock*TAU/(bob_period*1.4))*sway_width,sin(_clock*TAU/bob_period)*bob_height)
func collect() -> void:
    if collected: return
    collected=true
    # 先记账再反馈，死亡/重试不会复制同一颗。
    var tween=create_tween()
    tween.set_parallel(true)
    tween.tween_property(art,"position:y",-26.0,.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(art,"scale",Vector2.ONE*artwork_scale*1.3,.18)
    tween.tween_property(art,"modulate:a",0.0,.18)
    tween.chain().tween_callback(hide)
