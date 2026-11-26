extends Node
## 第一次成功交换后短暂兼顾主角与下方岩浆，不锁住玩家操作。
@export var notice_seconds: float = 2.0
@export var widen_seconds: float = .35
@export var return_seconds: float = .5
var active: bool = false
var _elapsed: float = 0.0
var _rest_zoom: Vector2
var _attention_enabled: bool = true
@onready var level: Node2D=get_parent()
@onready var camera: Camera2D=level.get_node("Camera")
@onready var lava: Node2D=level.get_node("RisingLava")
@onready var attention: Node=level.get_node("CameraAttention")
func _ready() -> void:
    process_priority=6
    lava.first_exchange_started.connect(_start)
    level.died.connect(reset)
func _start() -> void:
    if active:return
    active=true
    _elapsed=0.0
    _rest_zoom=camera.zoom
    _attention_enabled=attention.enabled
    attention.enabled=false
func _process(delta: float) -> void:
    if not active:return
    if level.dead or level.exit_in_progress or level.player!=level.demon:
        reset()
        return
    _elapsed+=delta
    var weight: float=smoothstep(0,widen_seconds,_elapsed)*(1.0-smoothstep(notice_seconds-return_seconds,notice_seconds,_elapsed))
    # 拉远仍受原图宽度限制，不能露出两侧地图外。
    var wide: float=maxf(1.0,camera.get_viewport_rect().size.x/lava.world_width)
    camera.zoom=_rest_zoom.lerp(Vector2.ONE*wide,weight)
    var head: float=level.demon.global_position.y-100.0
    var lava_y: float=level.to_global(Vector2(960,lava.surface_y)).y
    var center_y: float=(head+lava_y)*.5
    var lookahead: float=clampf(-level.demon.velocity.y/1200.0,0,1)*camera.upward_look_ahead
    camera.framing_bias=Vector2(0,(center_y-level.demon.global_position.y-camera.framing_offset.y+lookahead)*weight)
    camera.precise_framing=true
    if _elapsed>=notice_seconds:reset()
func reset() -> void:
    if not active:return
    active=false
    camera.zoom=_rest_zoom
    camera.framing_bias=Vector2.ZERO
    camera.precise_framing=false
    attention.enabled=_attention_enabled
