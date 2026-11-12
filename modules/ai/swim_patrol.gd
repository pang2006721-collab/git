class_name SwimPatrol
extends Node
## Gentle bounded swimming through the same input/movement modules as the player.
@export var horizontal_radius: float = 155.0
@export var vertical_radius: float = 42.0
@export var cruise_speed: float = 90.0
var enabled: bool = true
var center: Vector2
var direction: float = -1.0
var _time: float = 0.0
var _motor: SwimMotor
var _reader: SwimInput

func _ready() -> void:
	process_physics_priority = -15
	_motor = get_node("../Movement")
	_reader = get_node("../Input")
	center = _motor.body.position
	start()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_time += delta
	var body := _motor.body
	if body.position.x >= center.x + horizontal_radius:
		direction = -1.0
	elif body.position.x <= center.x - horizontal_radius:
		direction = 1.0
	# Brake at each edge using ordinary water acceleration, preserving inertia.
	_reader.move_axis = clampf((direction * cruise_speed - body.velocity.x) * 3.0 / _motor.horizontal_acceleration, -0.65, 0.65)
	var target_y := center.y + sin(_time * 1.4) * vertical_radius
	var desired_y := clampf((target_y - body.position.y) * 2.0, -65.0, 65.0)
	_reader.up_held = body.velocity.y > desired_y
	_reader.down_held = false

func start() -> void:
	enabled = true
	direction = -1.0
	_time = 0.0
	_reader.external_control = true
	_reader.enabled = true
	_reader.clear()
	_motor.enabled = true

func stop() -> void:
	enabled = false
	_reader.clear()
