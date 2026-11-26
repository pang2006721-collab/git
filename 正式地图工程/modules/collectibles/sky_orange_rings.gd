extends Node2D
## 天空三圈，每圈六颗；同相位轻漂，第一圈位于起飞后上方，给附身和起飞留出空间。
const PICKUP = preload("res://modules/collectibles/orange_pickup.gd")
const ART = preload("res://assets/art/collectibles/orange.png")
@export var ring_centers: Array[Vector2] = [Vector2(1040,0),Vector2(820,11000),Vector2(1100,5700)]
@export var first_ring_above_spawn: float = 650.0
@export var ring_radius: float = 95.0
@export var bird_attraction_bonus: float = 30.0
@export_range(3,12) var oranges_per_ring: int = 6
var _previous: Vector2 = Vector2.INF
@onready var level: Node2D = get_parent()
@onready var bird: CharacterBody2D = level.get_node("OceanLink/FishStage/JungleLayout/Bird")
@onready var ledger: Node2D = level.get_node("HellOranges")
func _ready() -> void:
    z_index = 15
    ring_centers[0]=level.to_local(bird.global_position)-Vector2(0,first_ring_above_spawn)
    for ring in ring_centers.size():
        for index in oranges_per_ring:
            var orange := Node2D.new()
            orange.name = "SkyRing%02dOrange%02d" % [ring+1,index+1]
            orange.set_script(PICKUP)
            orange.position = ring_centers[ring]+Vector2.from_angle(-PI*.5+TAU*index/oranges_per_ring)*ring_radius
            var art := Sprite2D.new()
            art.name = "Art"
            art.texture = ART
            orange.add_child(art)
            add_child(orange)
func _physics_process(_delta: float) -> void:
    if not bird.get_node("Host").claimed or level.player != bird or level.dead or level.exit_in_progress or not level.is_visible_in_tree():
        _previous = Vector2.INF
        return
    var collision: CollisionShape2D = bird.get_node("Collision")
    var center: Vector2 = collision.global_position
    var before: Vector2 = _previous if _previous.is_finite() and _previous.distance_to(center)<300 else center
    _previous = center
    var radius: float = 30.0
    if collision.shape is CircleShape2D or collision.shape is CapsuleShape2D: radius = collision.shape.radius*absf(bird.global_scale.x)
    for orange in get_children():
        if orange.collected: continue
        var closest: Vector2 = Geometry2D.get_closest_point_to_segment(orange.global_position,before,center)
        if closest.distance_to(orange.global_position) <= orange.pickup_radius+radius+bird_attraction_bonus:
            ledger.collect_for_player(orange,bird)
