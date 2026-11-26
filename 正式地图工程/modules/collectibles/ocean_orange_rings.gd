extends Node2D
## 海底七圈，每圈六颗；同相位漂动保留整齐的圆形。
const PICKUP = preload("res://modules/collectibles/orange_pickup.gd")
const ART = preload("res://assets/art/collectibles/orange.png")
@export var ring_centers: Array[Vector2] = [Vector2(1130,38150),Vector2(780,37000),Vector2(1150,35850),Vector2(780,34700),Vector2(1140,33550),Vector2(800,32400),Vector2(1100,31250)]
@export var ring_radius: float = 110.0
@export_range(3,12) var oranges_per_ring: int = 6
var _previous: Vector2 = Vector2.INF
@onready var level: Node2D = get_parent()
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")
@onready var ledger: Node2D = level.get_node("HellOranges")
func _ready() -> void:
    z_index = 15
    for ring in ring_centers.size():
        for index in oranges_per_ring:
            var orange := Node2D.new()
            orange.name = "OceanRing%02dOrange%02d" % [ring+1,index+1]
            orange.set_script(PICKUP)
            orange.position = ring_centers[ring]+Vector2.from_angle(-PI*.5+TAU*index/oranges_per_ring)*ring_radius
            var art := Sprite2D.new()
            art.name = "Art"
            art.texture = ART
            orange.add_child(art)
            add_child(orange)
func _physics_process(_delta: float) -> void:
    var fish: CharacterBody2D = stage.fish
    if not stage.active or not stage.host.claimed or level.player != fish or level.dead or level.exit_in_progress or not level.is_visible_in_tree() or stage.get_node("ShoreExit").state != stage.get_node("ShoreExit").State.SWIMMING:
        _previous = Vector2.INF
        return
    var collision: CollisionShape2D = fish.get_node("Collision")
    var center: Vector2 = collision.global_position
    var before: Vector2 = _previous if _previous.is_finite() and _previous.distance_to(center)<300 else center
    _previous = center
    var radius: float = 30.0
    if collision.shape is CapsuleShape2D: radius = collision.shape.radius*absf(fish.global_scale.x)
    for orange in get_children():
        if orange.collected: continue
        var closest: Vector2 = Geometry2D.get_closest_point_to_segment(orange.global_position,before,center)
        if closest.distance_to(orange.global_position) <= orange.pickup_radius+radius:
            ledger.collect_for_player(orange,fish)
