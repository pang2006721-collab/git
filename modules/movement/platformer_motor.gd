class_name PlatformerMotor
extends Node
## Attach under a CharacterBody2D. Moves collision geometry, never visual scale.
## Signals allow visuals, camera and audio to react without coupling them to movement.

signal jumped
signal landed(impact_speed: float)
signal facing_changed(direction: float)

@export_node_path("CharacterBody2D") var body_path: NodePath = ^".."
@export var input_path: NodePath = ^"../Input"
@export var enabled: bool = true
@export_group("Horizontal movement / 水平移动")
@export var move_speed: float = 520.0
@export var acceleration: float = 3200.0
@export var braking: float = 4200.0
@export_range(0.0, 1.0) var air_control: float = 0.8
@export_group("Jump / 跳跃")
@export var jump_speed: float = 1210.0
@export var gravity: float = 2200.0
@export var max_fall_speed: float = 1600.0
@export_range(0.0, 0.3) var coyote_time: float = 0.12
@export_range(0.0, 0.3) var jump_buffer_time: float = 0.12
@export_range(0.1, 1.0) var jump_release_multiplier: float = 0.48
@export var fast_fall_multiplier: float = 1.65

var body: CharacterBody2D
var reader: Node
var facing: float = 1.0
var _coyote_left: float = 0.0
var _buffer_left: float = 0.0


func _ready() -> void:
	process_physics_priority = -10
	body = get_node(body_path) as CharacterBody2D
	reader = get_node(input_path)
	assert(body != null, "PlatformerMotor needs a CharacterBody2D")


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var grounded_before := body.is_on_floor()
	_coyote_left = coyote_time if grounded_before else maxf(0.0, _coyote_left - delta)
	_buffer_left = jump_buffer_time if reader.jump_pressed else maxf(0.0, _buffer_left - delta)
	var axis: float = reader.move_axis
	var response: float = braking if is_zero_approx(axis) else acceleration
	if not grounded_before:
		response *= air_control
	body.velocity.x = move_toward(body.velocity.x, axis * move_speed, response * delta)
	if not is_zero_approx(axis) and signf(axis) != facing:
		facing = signf(axis)
		facing_changed.emit(facing)
	if not grounded_before:
		var gravity_scale: float = fast_fall_multiplier if reader.down_held and body.velocity.y > 0.0 else 1.0
		body.velocity.y = minf(body.velocity.y + gravity * gravity_scale * delta, max_fall_speed)
	var did_jump := false
	if _buffer_left > 0.0 and _coyote_left > 0.0:
		body.velocity.y = -jump_speed
		_coyote_left = 0.0
		_buffer_left = 0.0
		did_jump = true
		jumped.emit()
	if not reader.jump_held and body.velocity.y < -jump_speed * jump_release_multiplier:
		body.velocity.y = -jump_speed * jump_release_multiplier
	var impact_speed := maxf(body.velocity.y, 0.0)
	body.move_and_slide()
	if not grounded_before and body.is_on_floor() and not did_jump:
		landed.emit(impact_speed)


func reset() -> void:
	body.velocity = Vector2.ZERO
	_coyote_left = 0.0
	_buffer_left = 0.0
