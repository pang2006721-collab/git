class_name FollowCamera
extends Camera2D
## Target, smoothing, look-ahead and bounds only. No hard-coded level or player names.

@export_node_path("Node2D") var target_path: NodePath
@export var world_bounds: Rect2 = Rect2(0, 0, 1980, 3240)
@export_group("Framing / 构图")
@export var framing_offset: Vector2 = Vector2(0, -145)
@export var dead_zone: Vector2 = Vector2(110, 65)
@export var follow_speed: float = 6.0
@export var horizontal_look_ahead: float = 95.0
@export var upward_look_ahead: float = 65.0
@export_group("Landing impulse / 落地反馈")
@export_range(0.0, 30.0) var max_impulse_pixels: float = 18.0
@export var impulse_decay: float = 3.8

## Cinematic modules can temporarily drive these without touching the follow center.
var use_unscaled_time: bool = false
var cinematic_offset: Vector2 = Vector2.ZERO

var target: Node2D
var _center := Vector2.ZERO
var _trauma: float = 0.0
var _impulse_time: float = 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D
	assert(target != null, "FollowCamera needs a target")
	position_smoothing_enabled = false
	limit_smoothed = true
	_noise.seed = 1729
	_noise.frequency = 0.5
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	process_priority = 10
	snap_to_target()


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if use_unscaled_time:
		delta /= maxf(Engine.time_scale, 0.001)
	var desired := target.global_position + framing_offset
	if target is CharacterBody2D:
		var velocity: Vector2 = (target as CharacterBody2D).velocity
		desired.x += clampf(velocity.x / 520.0, -1.0, 1.0) * horizontal_look_ahead
		desired.y -= clampf(-velocity.y / 1200.0, 0.0, 1.0) * upward_look_ahead
	var difference := desired - _center
	var outside := Vector2(_outside_dead_zone(difference.x, dead_zone.x), _outside_dead_zone(difference.y, dead_zone.y))
	_center = _clamp_center(_center + outside * (1.0 - exp(-follow_speed * delta)))
	_trauma = maxf(0.0, _trauma - impulse_decay * delta)
	_impulse_time += delta
	var noise_point := _impulse_time * 26.0
	var shake := Vector2(_noise.get_noise_2d(noise_point, 0.0), _noise.get_noise_2d(0.0, noise_point + 31.0)) * _trauma * _trauma * max_impulse_pixels
	global_position = _center
	# Offset layers the impact over follow; clamp the result to avoid exposing edges.
	offset = _clamp_center(_center + shake + cinematic_offset) - _center


func snap_to_target() -> void:
	_center = _clamp_center(target.global_position + framing_offset)
	global_position = _center
	_trauma = 0.0
	clear_impulse()
	reset_smoothing()
	force_update_scroll()


func add_landing_impulse(impact_speed: float) -> void:
	_trauma = minf(0.7, _trauma + impact_speed / 2000.0)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func clear_impulse() -> void:
	_trauma = 0.0
	offset = Vector2.ZERO
	cinematic_offset = Vector2.ZERO


func set_follow_target(new_target: Node2D, snap: bool = false) -> void:
	target = new_target
	if snap:
		snap_to_target()


func resume_follow_from_current_position(new_target: Node2D) -> void:
	# A scripted move owns global_position; adopt it before normal following resumes.
	target = new_target
	_center = _clamp_center(global_position)
	global_position = _center
	clear_impulse()
	reset_smoothing()
	force_update_scroll()


func _outside_dead_zone(value: float, half_size: float) -> float:
	return signf(value) * maxf(absf(value) - half_size, 0.0)


func _clamp_center(point: Vector2) -> Vector2:
	var half_view := get_viewport_rect().size * 0.5 / zoom
	var low := world_bounds.position + half_view
	var high := world_bounds.end - half_view
	return Vector2(clampf(point.x, low.x, high.x) if low.x <= high.x else world_bounds.get_center().x, clampf(point.y, low.y, high.y) if low.y <= high.y else world_bounds.get_center().y)
