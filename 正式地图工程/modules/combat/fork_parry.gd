extends Node
## 两把叉子的可见杆身进行连续扫掠，避免高速交错漏判。
signal parried(enemy_fork: Node2D)
@export var contact_radius: float = 20.0
@export var sample_spacing: float = 10.0
@export var recoil_seconds: float = .16
var _previous: Transform2D
var _was_active: bool = false
var _pulse: Tween
var _rest_scale: Vector2
@onready var weapon: Node2D=get_parent()
@onready var level: Node2D=weapon.get_parent()
func _ready() -> void:
    process_physics_priority=100
    _rest_scale=weapon.get_node("ForkSprite").scale
    _previous=weapon.get_node("ForkSprite").global_transform
func _active() -> bool:
    return weapon.flying and weapon.fork.is_visible_in_tree() and not level.dead and not level.exit_in_progress and level.player==level.demon and level.demon.get_node("Host").claimed
func _physics_process(_delta: float) -> void:
    _was_active=_active()
    _previous=weapon.fork.global_transform
func try_deflect(enemy: Node2D,from: Vector2,to: Vector2) -> bool:
    if not _active() or enemy.deflected or enemy._stuck: return false
    var current: Transform2D=weapon.fork.global_transform
    var previous: Transform2D=_previous if _was_active else current
    var travel: float=from.distance_to(to)+previous.origin.distance_to(current.origin)
    var steps: int=clampi(int(ceil(travel/maxf(sample_spacing,1.0))),1,128)
    var enemy_axis: Vector2=Vector2(0,50).rotated(enemy.global_rotation)
    for i in range(steps+1):
        var t: float=float(i)/steps
        var pose: Transform2D=previous.interpolate_with(current,t)
        var center: Vector2=from.lerp(to,t)
        var points:=Geometry2D.get_closest_points_between_segments(pose*Vector2(-66,0),pose*Vector2(26,-43),center-enemy_axis,center+enemy_axis)
        if points[0].distance_to(points[1])>contact_radius:continue
        enemy.global_position=center
        var side: float=signf(center.x-level.demon.global_position.x)
        if side==0:side=float(level.demon.get_node("Movement").facing)
        enemy.deflect(Vector2(side*.85,-.7).normalized())
        _feedback()
        parried.emit(enemy)
        return true
    return false
func _feedback() -> void:
    if _pulse!=null:_pulse.kill()
    weapon.fork.scale=_rest_scale*Vector2(1.22,.8)
    _pulse=create_tween()
    _pulse.tween_property(weapon.fork,"scale",_rest_scale,recoil_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    level.camera.add_trauma(.22)
func reset() -> void:
    _was_active=false
    if _pulse!=null:_pulse.kill()
    weapon.fork.scale=_rest_scale
