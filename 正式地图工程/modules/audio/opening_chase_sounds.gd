extends Node
## 普通追击一箭一声，末尾密集箭雨使用一次原多箭素材，避免二十四次叠音。
@onready var map: Node2D = get_node("../DescentWorld/ArrivalMap")
var _volley_played: bool = false
@onready var ghost: Node2D = map.get_node("ChaseActors/Ghost")

func _ready() -> void:
    map.get_node("NearMissArrows").arrow_fired.connect(_single_arrow)
    map.get_node("PillarArrows").arrow_fired.connect(_single_arrow)
    map.get_node("ExitArrows").arrow_fired.connect(_final_volley)

func _process(_delta: float) -> void:
    Sfx.set_cinematic_running(ghost.running and ghost.is_visible_in_tree())

func _exit_tree() -> void:
    Sfx.set_cinematic_running(false)

func _single_arrow(_index: int) -> void:
    Sfx.play(&"arrow")

func _final_volley(_index: int) -> void:
    if _volley_played: return
    _volley_played = true
    Sfx.play(&"volley")
