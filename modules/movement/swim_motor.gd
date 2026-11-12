class_name SwimMotor
extends Node
## Inertial water movement. W supplies lift, gravity supplies sinking, S adds downthrust.
## Uses the same acceleration/drag model at any physics rate; collisions stay on the body.

@export_node_path("CharacterBody2D") var body_path: NodePath = ^".."
@export_node_path("Node") var input_path: NodePath = ^"../Input"
@export var enabled: bool = true
@export_group("Horizontal / 水平游动")
@export var horizontal_acceleration: float = 700.0
@export var max_horizontal_speed: float = 470.0
@export var horizontal_drag: float = 1.15
@export_group("Vertical / 上浮与下沉")
@export var sinking_acceleration: float = 150.0
@export var upward_thrust: float = 620.0
@export var downward_thrust: float = 750.0
@export var max_rise_speed: float = 420.0
@export var max_sink_speed: float = 680.0
@export var vertical_drag: float = 0.75

var body: CharacterBody2D
var reader: SwimInput


func _ready() -> void:
	process_physics_priority = -10
	body = get_node(body_path) as CharacterBody2D
	reader = get_node(input_path) as SwimInput


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var force_y := sinking_acceleration
	if reader.up_held and not reader.down_held:
		force_y -= upward_thrust
	elif reader.down_held and not reader.up_held:
		force_y += downward_thrust
	body.velocity.x = _drag_step(body.velocity.x, reader.move_axis * horizontal_acceleration, horizontal_drag, delta)
	body.velocity.y = _drag_step(body.velocity.y, force_y, vertical_drag, delta)
	body.velocity.x = clampf(body.velocity.x, -max_horizontal_speed, max_horizontal_speed)
	body.velocity.y = clampf(body.velocity.y, -max_rise_speed, max_sink_speed)
	body.move_and_slide()


func reset() -> void:
	body.velocity = Vector2.ZERO


func _drag_step(speed: float, acceleration: float, drag: float, delta: float) -> float:
	if drag <= 0.0001:
		return speed + acceleration * delta
	var decay := exp(-drag * delta)
	return speed * decay + acceleration / drag * (1.0 - decay)
