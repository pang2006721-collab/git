extends Node2D
## 本局收集记录独立于关卡重试；回首页或重载正式场景自然清空。
signal orange_collected(total: int, orange_id: StringName)
@export var goal_count: int = 100
var collected_count: int = 0
var collected_ids: Dictionary = {}
var _previous: Vector2 = Vector2.INF
@onready var level: Node2D=get_parent()
func _physics_process(_delta: float) -> void:
    if level.dead or level.exit_in_progress or not level.visible or not level.get_node("WallEntry").completed or level.player!=level.demon or not level.demon.get_node("Host").claimed:
        _previous=Vector2.INF
        return
    var body: CharacterBody2D=level.player
    var collision: Node2D=body.get_node_or_null("Collision")
    var center: Vector2=collision.global_position if collision!=null else body.global_position+Vector2(0,-60)
    var body_radius: float=collision.shape.radius*absf(body.global_scale.x) if collision is CollisionShape2D and collision.shape is CapsuleShape2D else 25.0
    var before: Vector2=_previous if _previous.is_finite() and _previous.distance_to(center)<300 else center
    _previous=center
    for orange in get_children():
        if orange.collected: continue
        var closest: Vector2=Geometry2D.get_closest_point_to_segment(orange.global_position,before,center)
        if closest.distance_to(orange.global_position)>orange.pickup_radius+body_radius: continue
        orange.collect(body)
        collected_ids[orange.name]=true
        collected_count=collected_ids.size()
        orange_collected.emit(collected_count,orange.name)
func has_goal() -> bool:
    return collected_count>=goal_count
