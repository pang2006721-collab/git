class_name CameraImpact
extends Node
## A transient visual impulse layered after camera follow. Never moves actors or terrain.
@export_range(0.0, 1.0) var motion_strength: float = 1.0
@export var max_offset: float = 20.0
@export var spring_stiffness: float = 170.0
@export var spring_damping: float = 23.0
var camera: FollowCamera
var _displacement := Vector2.ZERO
var _velocity := Vector2.ZERO
var _trauma: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	process_priority = 20

func kick_up() -> void:
	_velocity.y -= 260.0 * motion_strength
	_trauma = minf(_trauma + 0.4 * motion_strength, 1.0)

func reset() -> void:
	_displacement = Vector2.ZERO
	_velocity = Vector2.ZERO
	_trauma = 0.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO

func _process(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	if _trauma == 0.0 and _displacement.length() < 0.001 and _velocity.length() < 0.01:
		return
	var remaining := minf(delta, 0.1)
	while remaining > 0.0:
		var step := minf(remaining, 1.0 / 120.0)
		_velocity += (-_displacement * spring_stiffness - _velocity * spring_damping) * step
		_displacement += _velocity * step
		remaining -= step
	_trauma = maxf(0.0, _trauma - delta * 1.8)
	_time += delta
	var noise := Vector2(sin(_time * 37.0), sin(_time * 49.0 + 0.7)) * _trauma * _trauma * 4.0
	var impulse := (_displacement + noise).limit_length(max_offset)
	camera.offset = camera._clamp_center(camera.global_position + camera.offset + impulse) - camera.global_position
