extends Node
## 下落时提前看向脚下藤蔓；沿用同一台相机的平滑、死区与地图边界。
@export var max_look_down: float = 280.0
@onready var body: CharacterBody2D = get_parent()
@onready var defeat: Node = body.get_node("Defeat")
func _ready() -> void:
	process_priority = 5
func _process(_delta: float) -> void:
	var level: Node = defeat.level
	if level == null: return
	var camera: FollowCamera = level.camera
	camera.downward_look_target = body
	var free_fall: bool = level.player == body and not level.dead and not level.exit_in_progress and body.get_node("Host").claimed and body.get_node("VineClimber").vine == null and body.get_node("Movement").enabled and not body.is_on_floor()
	camera.downward_look_ahead = max_look_down if free_fall else 0.0
