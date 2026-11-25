extends Node2D
## 原画橘子：沿真实平台顶面定位，小幅摆动，不改变收集判定的可读性。
@export var anchor_path: NodePath
@export var surface_offset: Vector2 = Vector2(0,-100)
@export var use_surface: bool = true
@export var bob_height: float = 7.0
@export var sway_width: float = 4.0
@export var bob_period: float = 2.4
@export var pickup_radius: float = 26.0
var collected: bool = false
var _clock: float = 0.0
var _offset: Vector2
var anchor: Node2D
var art: Sprite2D
func _ready() -> void:
    anchor=get_node(anchor_path)
    var point: Vector2=anchor.to_global(surface_offset)
    if use_surface:
        var shape: CollisionPolygon2D=anchor.get_node("Collision")
        point=load("res://modules/environment/hell_surface.gd").top_at(shape,anchor.global_position.x+surface_offset.x)+Vector2(0,surface_offset.y)
    _offset=anchor.to_local(point)
    _clock=float(get_index())*.43
    art=Sprite2D.new()
    art.texture=preload("res://assets/art/collectibles/orange.png")
    art.scale=Vector2.ONE*.52
    add_child(art)
    _process(0)
func _process(delta: float) -> void:
    _clock+=delta
    global_position=anchor.to_global(_offset)+Vector2(sin(_clock*TAU/(bob_period*1.4))*sway_width,sin(_clock*TAU/bob_period)*bob_height)
func collect() -> void:
    if collected: return
    collected=true
    # 先记账再反馈，死亡/重试不会复制同一颗。
    var tween=create_tween()
    tween.set_parallel(true)
    tween.tween_property(art,"position:y",-26.0,.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(art,"scale",Vector2.ONE*.68,.18)
    tween.tween_property(art,"modulate:a",0.0,.18)
    tween.chain().tween_callback(hide)
