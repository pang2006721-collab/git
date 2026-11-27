extends "res://modules/collectibles/orange_collection_group.gd"
## 天空七圈，每圈六颗；同相位轻漂，第一圈位于起飞后上方，给附身和起飞留出空间。
@export var ring_centers: Array[Vector2] = [Vector2(1040,0),Vector2(780,0),Vector2(1120,0),Vector2(820,11000),Vector2(1120,9233),Vector2(780,7467),Vector2(1100,5700)]
@export var first_ring_above_spawn: float = 650.0
@export var ring_radius: float = 95.0
@export var bird_attraction_bonus: float = 30.0
@export_range(3,12) var oranges_per_ring: int = 6
@onready var bird: CharacterBody2D = level.get_node("OceanLink/FishStage/JungleLayout/Bird")
func _ready() -> void:
    z_index = 15
    ring_centers[0]=level.to_local(bird.global_position)-Vector2(0,first_ring_above_spawn)
    # 在原先三圈之间补四圈，保留第一圈、中段及穿云前的位置。
    for index in [1,2]:
        ring_centers[index].y=lerpf(ring_centers[0].y,ring_centers[3].y,float(index)/3.0)
    for ring in ring_centers.size():
        spawn_ring(ring_centers[ring],ring_radius,oranges_per_ring,"SkyRing%02d"%[ring+1])
func _physics_process(_delta: float) -> void:
    if not bird.get_node("Host").claimed or level.player != bird or level.dead or level.exit_in_progress or not level.is_visible_in_tree():
        _previous = Vector2.INF
        return
    collect_body(bird,bird_attraction_bonus)
