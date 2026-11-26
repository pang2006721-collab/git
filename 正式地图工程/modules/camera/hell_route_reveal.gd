extends Node
## 接近团团时一次性扩大视野，同时展示主角、团团和传送后的落脚点。
const SURFACE=preload("res://modules/environment/hell_surface.gd")
@export_node_path("Node2D") var reveal_target_path: NodePath=^"../Fork/Targets/Target03"
@export var notice_seconds: float=2.4
@export var return_seconds: float=.85
@export var approach_height: float=900.0
@export var approach_width: float=1100.0
var active: bool=false
var target: Node2D
var _seen: Dictionary={}
var _elapsed: float=0.0
var _rest_zoom: Vector2
var _attention_enabled: bool=true
var _landing: Vector2
var _returning: bool=false
var _return_elapsed: float=0.0
var _return_zoom: Vector2
var _return_center: Vector2
@onready var level: Node2D=get_parent()
@onready var camera: Camera2D=level.get_node("Camera")
@onready var attention: Node=level.get_node("CameraAttention")
@onready var fork: Node2D=level.get_node("Fork")
@onready var lava_reveal: Node=level.get_node("LavaRiseReveal")
func _ready() -> void:
    process_priority=7
    level.died.connect(reset.bind(true))
    fork.interaction_reset.connect(reset)
    fork.exchanged.connect(_on_exchanged)
func _eligible() -> bool:
    return level.visible and not level.dead and not level.exit_in_progress and level.get_node("WallEntry").completed and level.player==level.demon and level.demon.get_node("Host").claimed and camera.target==level.demon and level.get_node("OceanLink").stage==0
func _wide_zoom() -> float:
    return maxf(1.0,camera.get_viewport_rect().size.x/level.get_node("RisingLava").world_width)
func _destination(ball: Node2D) -> Vector2:
    var best: Vector2=ball.global_position
    var nearest: float=INF
    var candidates: Array=get_tree().get_nodes_in_group("hell_platforms")
    candidates.append_array(level.get_node("Terrain").get_children())
    for platform in candidates:
        if platform.get("broken")==true:continue
        var point: Vector2=SURFACE.landing_on(platform)
        if not point.is_finite() or point.y>=ball.global_position.y-40:continue
        var distance: float=point.distance_to(ball.global_position)
        if distance<nearest:
            nearest=distance
            best=point
    return best
func _process(delta: float) -> void:
    if not _eligible() or lava_reveal.active:
        reset()
        return
    if not active:
        if level.get_node("PossessionCamera").active:return
        if fork.flying or fork.swapping or fork.launching:return
        var nearest: float=INF
        for ball in level.get_node("Fork/Targets").get_children():
            if ball!=get_node_or_null(reveal_target_path):continue
            if _seen.has(ball.name):continue
            var gap: Vector2=level.demon.global_position-ball.global_position
            if gap.y<180 or gap.y>approach_height or absf(gap.x)>approach_width:continue
            var landing: Vector2=_destination(ball)
            var span: float=level.demon.global_position.y-minf(ball.global_position.y,landing.y)
            if span>camera.get_viewport_rect().size.y/_wide_zoom()-150:continue
            if gap.length()<nearest:
                nearest=gap.length()
                target=ball
                _landing=landing
        if nearest==INF:return
        active=true
        _seen[target.name]=true
        _elapsed=0.0
        _rest_zoom=camera.zoom
        _attention_enabled=attention.enabled
        attention.enabled=false
    if _returning:
        _process_return(delta)
        return
    _elapsed+=delta
    var return_at: float=maxf(.4,notice_seconds-return_seconds)
    if _elapsed>=return_at:
        _begin_return()
        _process_return(_elapsed-return_at)
        return
    var weight: float=smoothstep(0,.4,_elapsed)
    camera.zoom=_rest_zoom.lerp(Vector2.ONE*_wide_zoom(),weight)
    var bounds:=Rect2(level.demon.global_position,Vector2.ZERO).expand(target.global_position).expand(_landing)
    var normal: Vector2=_normal_center()
    camera.framing_bias=(bounds.get_center()-normal)*weight
    camera.precise_framing=true
func _normal_center() -> Vector2:
    var normal: Vector2=level.demon.global_position+camera.framing_offset
    normal.x+=clampf(level.demon.velocity.x/520.0,-1,1)*camera.horizontal_look_ahead
    normal.y-=clampf(-level.demon.velocity.y/1200.0,0,1)*camera.upward_look_ahead
    return normal
func _begin_return(restart: bool=false) -> void:
    if _returning and not restart:return
    _returning=true
    _return_elapsed=0.0
    _return_zoom=camera.zoom
    _return_center=camera.global_position
    # 从当前画面交接，覆盖普通传送的短促跟随，不在交换帧重置缩放。
    camera.blend_to_target(level.demon,return_seconds)
func _process_return(delta: float) -> void:
    _return_elapsed+=delta
    var u: float=clampf(_return_elapsed/maxf(return_seconds,.01),0.0,1.0)
    var eased: float=u*u*u*(u*(u*6.0-15.0)+10.0)
    camera.zoom=_return_zoom.lerp(_rest_zoom,eased)
    var normal: Vector2=_normal_center()
    camera.framing_bias=_return_center.lerp(normal,eased)-normal
    camera.precise_framing=true
    if u>=1.0:reset()
func _on_exchanged(_body: Node2D) -> void:
    if active:_begin_return(true)
func reset(clear_seen: bool=false) -> void:
    if active:
        active=false
        _returning=false
        camera.zoom=_rest_zoom
        camera.framing_bias=Vector2.ZERO
        camera.precise_framing=false
        attention.enabled=_attention_enabled
    if clear_seen:_seen.clear()
