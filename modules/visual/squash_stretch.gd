class_name SquashStretch
extends Node2D
## Visual-only spring: jumping stretches, landing squashes, motion adds a small lean.
## Keep the collision body outside this node. Place this node's origin at the feet.

@export_node_path("Node") var motor_path: NodePath = ^"../Movement"
@export_node_path("Sprite2D") var sprite_path: NodePath = ^"Sprite"
@export var artwork_faces_right: bool = true
@export_group("Duang / 弹性")
@export var spring_stiffness: float = 180.0
@export var spring_damping: float = 14.0
@export var jump_shape: Vector2 = Vector2(0.80, 1.22)
@export var landing_shape: Vector2 = Vector2(1.30, 0.72)
@export var selection_shape: Vector2 = Vector2(1.24, 0.78)
@export_range(0.0, 0.3) var run_bounce: float = 0.035
@export_range(0.0, 15.0) var max_lean_degrees: float = 5.0

var _motor: PlatformerMotor
var _sprite: Sprite2D
var _spring_position: Vector2 = Vector2.ONE
var _spring_velocity: Vector2 = Vector2.ZERO
var _phase: float = 0.0


func _ready() -> void:
	_motor = get_node(motor_path) as PlatformerMotor
	_sprite = get_node(sprite_path) as Sprite2D
	_motor.jumped.connect(_on_jump)
	_motor.landed.connect(_on_land)
	_motor.facing_changed.connect(_on_facing_changed)
	_on_facing_changed(_motor.facing)


func _process(delta: float) -> void:
	# Small substeps keep the damped spring stable even during a slow frame.
	var remaining := minf(delta, 0.1)
	while remaining > 0.0:
		var step := minf(remaining, 1.0 / 120.0)
		_spring_velocity += ((Vector2.ONE - _spring_position) * spring_stiffness - _spring_velocity * spring_damping) * step
		_spring_position += _spring_velocity * step
		remaining -= step
	var speed_ratio := clampf(absf(_motor.body.velocity.x) / _motor.move_speed, 0.0, 1.0)
	var run_shape := Vector2.ONE
	if _motor.body.is_on_floor() and speed_ratio > 0.05:
		_phase += delta * 19.0 * speed_ratio
		var pulse := sin(_phase) * run_bounce * speed_ratio
		run_shape = Vector2(1.0 - pulse, 1.0 + pulse)
	scale = _spring_position * run_shape
	var lean := deg_to_rad(max_lean_degrees) * _motor.body.velocity.x / _motor.move_speed
	rotation = lerp_angle(rotation, lean, 1.0 - exp(-12.0 * delta))


func _on_jump() -> void:
	_spring_position = jump_shape
	_spring_velocity = Vector2(-1.0, 1.0)


func _on_land(impact_speed: float) -> void:
	var weight := clampf(impact_speed / 1100.0, 0.15, 1.0)
	_spring_position = Vector2.ONE.lerp(landing_shape, weight)
	_spring_velocity = Vector2(1.6, -1.6) * weight


func _on_facing_changed(direction: float) -> void:
	_sprite.flip_h = (direction > 0.0) != artwork_faces_right


func play_possession_pulse() -> void:
	_spring_position = Vector2(0.76, 1.25)
	_spring_velocity = Vector2(2.0, -2.0)


func play_selection_pulse() -> void:
	_spring_position = selection_shape
	_spring_velocity = Vector2(-1.0, 2.0)


func reset() -> void:
	_spring_position = Vector2.ONE
	_spring_velocity = Vector2.ZERO
	scale = Vector2.ONE
	rotation = 0.0
	_on_facing_changed(_motor.facing)
