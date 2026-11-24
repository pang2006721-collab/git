extends "res://modules/enemies/enemy_fork.gd"
## 小恶魔弹道发射加短时有限追踪，命中触发松鼠晕倒失败。
@export var tracking_seconds: float = 1.8
@export var turn_rate: float = 5.0
var _previous_target := Vector2.INF
const ART = preload("res://assets/art/jungle/formal/bee_stinger.png")
func _ready() -> void:
    gravity=100
    speed=1200
    add_to_group("bee_stingers")
    var art:=Sprite2D.new()
    art.texture=ART
    art.scale=Vector2.ONE*.6
    add_child(art)
func _physics_process(delta: float) -> void:
    if not is_instance_valid(encounter) or not encounter.can_simulate():
        hide()
        queue_free()
        return
    _age+=delta
    if _age>lifetime:
        queue_free()
        return
    var center: Vector2 = encounter.target_position()
    var last_target: Vector2 = center if not _previous_target.is_finite() or _previous_target.distance_to(center)>500 else _previous_target
    _previous_target=center
    if not _pierced_player and encounter.is_active() and _age<=tracking_seconds and encounter.is_on_screen(global_position):
        var toward: Vector2 = encounter.intercept_target(global_position,velocity.length(),.2)-global_position
        if velocity.dot(toward)>0:
            var turn: float = clampf(wrapf(toward.angle()-velocity.angle(),-PI,PI),-turn_rate*delta,turn_rate*delta)
            velocity=velocity.rotated(turn)
    var previous: Vector2 = global_position
    var next: Vector2 = previous+velocity*delta+Vector2(0,gravity*delta*delta*.5)
    velocity.y+=gravity*delta
    var closest: Vector2 = Geometry2D.get_closest_point_to_segment(center,previous,next)
    var relative: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2.ZERO,previous-last_target,next-center)
    var hits_player: bool = not _pierced_player and encounter.is_active() and relative.length()<55 and encounter.is_on_screen(closest)
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(previous,next,32))
    if not hit.is_empty() and (not hits_player or previous.distance_squared_to(hit.position)<previous.distance_squared_to(closest)):
        hide()
        queue_free()
        return
    if hits_player:
        if encounter.player_spinning():
            _pierced_player=true
            velocity=-velocity*.7+Vector2(0,-180)
            global_position=previous+velocity*delta
            rotation=velocity.angle()+PI*.5
            encounter.bee_deflected()
            return
        _pierced_player=true
        encounter.defeat_player()
    global_position=next
    rotation=velocity.angle()+PI*.5
