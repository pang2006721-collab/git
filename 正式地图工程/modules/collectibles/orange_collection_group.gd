extends Node2D
## Shared pickup construction and swept-body collection; stage scripts own layout and eligibility.
const PICKUP = preload("res://modules/collectibles/orange_pickup.gd")
const ART = preload("res://assets/art/collectibles/orange.png")
var _previous: Vector2 = Vector2.INF
@onready var level: Node2D = get_parent()
@onready var ledger: Node2D = level.get_node("HellOranges")
func spawn_orange(id: String, point: Vector2) -> void:
    var orange:=Node2D.new()
    orange.name=id
    orange.set_script(PICKUP)
    orange.position=point
    var art:=Sprite2D.new()
    art.name="Art"
    art.texture=ART
    orange.add_child(art)
    add_child(orange)
func spawn_ring(center: Vector2, radius: float, count: int, prefix: String) -> void:
    for index in count:
        spawn_orange(prefix+"Orange%02d"%[index+1],center+Vector2.from_angle(-PI*.5+TAU*index/count)*radius)
func collect_body(body: CharacterBody2D, attraction_bonus: float=0.0) -> void:
    var collision: CollisionShape2D=body.get_node("Collision")
    var center: Vector2=collision.global_position
    var before: Vector2=_previous if _previous.is_finite() and _previous.distance_to(center)<300 else center
    _previous=center
    var radius: float=30.0
    if collision.shape is CircleShape2D or collision.shape is CapsuleShape2D:
        radius=collision.shape.radius*absf(body.global_scale.x)
    for orange in get_children():
        if orange.collected:continue
        var closest: Vector2=Geometry2D.get_closest_point_to_segment(orange.global_position,before,center)
        if closest.distance_to(orange.global_position)<=orange.pickup_radius+radius+attraction_bonus:
            ledger.collect_for_player(orange,body)
