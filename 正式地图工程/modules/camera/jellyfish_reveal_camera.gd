extends Node2D
## 水母登场拉远同一台正式相机；接近海面后归还构图。
signal reveal_started
signal reveal_finished
@export var reveal_seconds: float=1.8
@export var return_seconds: float=1.0
@export var wide_zoom: float=1.0
@export var minimum_wide_seconds: float=2.0
@export var restore_depth: float=2300.0
enum State { WAITING, REVEALING, WIDE, RETURNING, FINISHED }
var state: State=State.WAITING
var elapsed:=0.0
var _wide_elapsed:=0.0
var _pending:=false
var _rest_zoom:=Vector2.ONE
var _bounded_wide_zoom:=Vector2.ONE
var _return_zoom:=Vector2.ONE
@onready var stage: Node=get_parent()
@onready var level: Node=stage.get_parent().get_parent()
@onready var camera: FollowCamera=level.get_node_or_null("Camera")
@onready var fish: CharacterBody2D=get_node("../Fish")
@onready var boss: Node2D=get_node("../JellyfishBoss")
func _ready() -> void:
    process_priority=5
    top_level=true
    if level is Node2D: global_transform=level.global_transform
    boss.appeared.connect(func(): _pending=true)
func _process(delta: float) -> void:
    if not is_instance_valid(camera) or not stage.active or stage.level.dead: return
    if state==State.WAITING:
        if _pending and stage.level.player==fish and not stage.possession.shot.active:
            _rest_zoom=camera.zoom
            var viewport_size:=camera.get_viewport_rect().size
            var minimum_zoom:=maxf(viewport_size.x/camera.world_bounds.size.x,viewport_size.y/camera.world_bounds.size.y)
            _bounded_wide_zoom=Vector2.ONE*maxf(wide_zoom,minimum_zoom)
            state=State.REVEALING
            elapsed=0
            reveal_started.emit()
        return
    if state==State.FINISHED: return
    var shore=stage.get_node("ShoreExit")
    if state==State.WIDE: _wide_elapsed+=delta
    var near_surface: bool=fish.position.y<=shore.surface_y+restore_depth
    var surface_sequence: bool=shore.state!=shore.State.SWIMMING
    if state!=State.RETURNING and ((near_surface and state==State.WIDE and _wide_elapsed>=minimum_wide_seconds) or surface_sequence or stage.level.player!=fish):
        state=State.RETURNING
        elapsed=0
        _return_zoom=camera.zoom
    elapsed+=delta
    if state==State.REVEALING:
        var u:=smoothstep(0,reveal_seconds,elapsed)
        camera.zoom=_rest_zoom.lerp(_bounded_wide_zoom,u)
        if elapsed>=reveal_seconds:
            state=State.WIDE
            _wide_elapsed=0
            reveal_finished.emit()
    elif state==State.RETURNING:
        var u:=smoothstep(0,return_seconds,elapsed)
        camera.zoom=_return_zoom.lerp(_rest_zoom,u)
        if elapsed>=return_seconds: _finish_return()
func finish_for_surface() -> void:
    if state not in [State.WAITING,State.FINISHED]: _finish_return()
func _finish_return() -> void:
    camera.zoom=_rest_zoom
    state=State.FINISHED
func reset() -> void:
    if state not in [State.WAITING,State.FINISHED] and is_instance_valid(camera): camera.zoom=_rest_zoom
    state=State.WAITING
    elapsed=0
    _wide_elapsed=0
    _pending=false
