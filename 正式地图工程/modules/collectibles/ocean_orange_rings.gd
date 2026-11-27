extends "res://modules/collectibles/orange_collection_group.gd"
## 海底七圈，每圈六颗；同相位漂动保留整齐的圆形。
@export var ring_centers: Array[Vector2] = [Vector2(1130,38150),Vector2(780,37000),Vector2(1150,35850),Vector2(780,34700),Vector2(1140,33550),Vector2(800,32400),Vector2(1100,31250)]
@export var ring_radius: float = 95.0
@export var fish_attraction_bonus: float = 30.0
@export_range(3,12) var oranges_per_ring: int = 6
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")
func _ready() -> void:
    z_index = 15
    for ring in ring_centers.size():
        spawn_ring(ring_centers[ring],ring_radius,oranges_per_ring,"OceanRing%02d"%[ring+1])
func _physics_process(_delta: float) -> void:
    var fish: CharacterBody2D = stage.fish
    if not stage.active or not stage.host.claimed or level.player != fish or level.dead or level.exit_in_progress or not level.is_visible_in_tree() or stage.get_node("ShoreExit").state != stage.get_node("ShoreExit").State.SWIMMING:
        _previous = Vector2.INF
        return
    collect_body(stage.fish,fish_attraction_bonus)
