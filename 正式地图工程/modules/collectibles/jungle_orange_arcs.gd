extends Node2D
## 八段真实换藤飞行轨迹上的30颗橘子；跟随原角色身体路线，重试保留收集进度。
const PICKUP = preload("res://modules/collectibles/orange_pickup.gd")
const ART = preload("res://assets/art/collectibles/orange.png")
var _previous: Vector2 = Vector2.INF
@onready var level: Node2D = get_parent()
@onready var body: CharacterBody2D = level.get_node("OceanLink/FishStage/JungleLayout/Squirrel")
@onready var ledger: Node2D = level.get_node("HellOranges")
func _ready() -> void:
    z_index=15
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/jungle/formal/orange_arcs.json"))
    for group in data.groups.size():
        for index in data.groups[group].oranges.size():
            var point: Array=data.groups[group].oranges[index]
            var orange:=Node2D.new()
            orange.name="JungleArc%02dOrange%02d"%[group+1,index+1]
            orange.set_script(PICKUP)
            orange.position=Vector2(point[0],point[1])
            var art:=Sprite2D.new()
            art.name="Art"
            art.texture=ART
            orange.add_child(art)
            add_child(orange)
func _physics_process(_delta: float) -> void:
    if level.player!=body or not body.get_node("Host").claimed or level.dead or level.exit_in_progress or not level.is_visible_in_tree():
        _previous=Vector2.INF
        return
    var collision: CollisionShape2D=body.get_node("Collision")
    var center: Vector2=collision.global_position
    var before: Vector2=_previous if _previous.is_finite() and _previous.distance_to(center)<300 else center
    _previous=center
    var radius: float=collision.shape.radius*absf(body.global_scale.x)
    for orange in get_children():
        if orange.collected: continue
        var closest: Vector2=Geometry2D.get_closest_point_to_segment(orange.global_position,before,center)
        if closest.distance_to(orange.global_position)<=orange.pickup_radius+radius:
            ledger.collect_for_player(orange,body)
