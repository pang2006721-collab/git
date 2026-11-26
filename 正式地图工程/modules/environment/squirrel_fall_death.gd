extends Node
## 从最近一次起跳/松藤后的最高点量自由下落距离；抓藤和安全着地重新计数。
@export var fatal_drop_pixels: float = 500.0
var _tracking: bool = false
var _apex_y: float = 0.0
@onready var body: CharacterBody2D = get_parent()
@onready var climber: Node = body.get_node("VineClimber")
@onready var motor: Node = body.get_node("Movement")
@onready var defeat: Node = body.get_node("Defeat")
func _ready() -> void:
	process_physics_priority = 10
func reset() -> void:
	_tracking = false
func _physics_process(_delta: float) -> void:
	var level: Node = defeat.level
	if level == null or level.dead or level.exit_in_progress or level.player != body or not body.get_node("Host").claimed or body.transferring or climber.vine != null or not motor.enabled:
		reset()
		return
	for checkpoint_name in ["Checkpoint", "OceanCheckpoint", "JungleCheckpoint"]:
		var checkpoint: Node = level.get_node_or_null(checkpoint_name)
		if checkpoint != null and checkpoint.grace_remaining > 0.0:
			reset()
			return
	var height: float = body.global_position.y
	# 先检查本帧落差，再处理落地，避免跨过阈值时恰好着地而漏判。
	if _tracking and height - _apex_y > fatal_drop_pixels:
		level.die(&"fall")
		return
	if body.is_on_floor():
		reset()
		return
	if not _tracking or body.velocity.y < 0.0:
		_apex_y = height
		_tracking = true
	else:
		_apex_y = minf(_apex_y, height)
