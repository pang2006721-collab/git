class_name PlatformPatrol
extends Node
## Writes into the same input reader as a player, keeping movement physics reusable.

@export var enabled: bool = true
@export var left_x: float = 1000.0
@export var right_x: float = 1200.0
@export var walk_speed: float = 145.0
@export_node_path("Node") var motor_path: NodePath = ^"../Movement"
@export_node_path("Node") var input_path: NodePath = ^"../Input"
var direction: float = 1.0
var motor: PlatformerMotor
var reader: PlatformerInput


func _ready() -> void:
	process_physics_priority = -15
	motor = get_node(motor_path) as PlatformerMotor
	reader = get_node(input_path) as PlatformerInput
	if enabled:
		start()


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	if motor.body.position.x >= right_x:
		direction = -1.0
	elif motor.body.position.x <= left_x:
		direction = 1.0
	reader.move_axis = direction * walk_speed / motor.move_speed
	reader.jump_pressed = false
	reader.jump_held = false
	reader.down_held = false


func start() -> void:
	enabled = true
	direction = 1.0
	reader.external_control = true
	reader.enabled = false
	reader.clear()


func stop() -> void:
	enabled = false
	reader.clear()
