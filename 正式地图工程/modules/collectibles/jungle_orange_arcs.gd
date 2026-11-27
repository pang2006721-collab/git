extends "res://modules/collectibles/orange_collection_group.gd"
## 上方六段换藤飞行轨迹上的24颗橘子；跟随原角色身体路线，重试保留收集进度。
@onready var body: CharacterBody2D = level.get_node("OceanLink/FishStage/JungleLayout/Squirrel")
func _ready() -> void:
    z_index=15
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/jungle/formal/orange_arcs.json"))
    for group in data.groups.size():
        for index in data.groups[group].oranges.size():
            var point: Array=data.groups[group].oranges[index]
            spawn_orange("JungleArc%02dOrange%02d"%[group+1,index+1],Vector2(point[0],point[1]))
func _physics_process(_delta: float) -> void:
    if level.player!=body or not body.get_node("Host").claimed or level.dead or level.exit_in_progress or not level.is_visible_in_tree():
        _previous=Vector2.INF
        return
    collect_body(body,0.0)
