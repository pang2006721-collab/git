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
@export var downward_look_ahead: float = 0.0
@export var downward_full_speed: float = 900.0
## 可选：仅向此角色提供下落前瞻，切换附身对象时不串到其他角色。
var downward_look_target: Node2D
@export_group("Landing impulse / 落地反馈")
@export_range(0.0, 30.0) var max_impulse_pixels: float = 18.0
@export var impulse_decay: float = 3.8

## Cinematic modules can temporarily drive these without touching the follow center.
var use_unscaled_time: bool = false
var cinematic_offset: Vector2 = Vector2.ZERO
## 活跃游玩中的受击震动独立叠加，不覆盖过场构图。
var hit_offset: Vector2 = Vector2.ZERO
## 构图模块提供世界单位偏移；仍由本相机统一平滑和限制地图边界。
var framing_bias: Vector2 = Vector2.ZERO
## 机关构图有明确安全区时，不让跟随死区抵消已经计算好的偏移。
var precise_framing: bool = false
var _retarget_from := Vector2.ZERO
var _retarget_seconds: float = 0.0
var _retarget_elapsed: float = 0.0

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
	var desired := target.global_position + framing_offset + framing_bias
	if target is CharacterBody2D:
		var velocity: Vector2 = (target as CharacterBody2D).velocity
		desired.x += clampf(velocity.x / 520.0, -1.0, 1.0) * horizontal_look_ahead
		desired.y -= clampf(-velocity.y / 1200.0, 0.0, 1.0) * upward_look_ahead
		if downward_look_target == null or downward_look_target == target:
			desired.y += smoothstep(80.0, maxf(downward_full_speed, 81.0), velocity.y) * downward_look_ahead
	if _retarget_elapsed < _retarget_seconds:
		_retarget_elapsed = minf(_retarget_elapsed + delta, _retarget_seconds)
		var u := _retarget_elapsed / _retarget_seconds
		var eased := u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
		desired = _retarget_from.lerp(desired, eased)
	var difference := desired - _center
	var zone := Vector2.ZERO if precise_framing else dead_zone
	var outside := Vector2(_outside_dead_zone(difference.x, zone.x), _outside_dead_zone(difference.y, zone.y))
	_center = _clamp_center(_center + outside * (1.0 - exp(-follow_speed * delta)))
	_trauma = maxf(0.0, _trauma - impulse_decay * delta)
	_impulse_time += delta
	var noise_point := _impulse_time * 26.0
	var shake := Vector2(_noise.get_noise_2d(noise_point, 0.0), _noise.get_noise_2d(0.0, noise_point + 31.0)) * _trauma * _trauma * max_impulse_pixels
	global_position = _center
	# Offset layers the impact over follow; clamp the result to avoid exposing edges.
	offset = _clamp_center(_center + shake + cinematic_offset + hit_offset) - _center


func snap_to_target() -> void:
	_retarget_elapsed = _retarget_seconds
	_center = _clamp_center(target.global_position + framing_offset + framing_bias)
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
	hit_offset = Vector2.ZERO


func set_follow_target(new_target: Node2D, snap: bool = false) -> void:
	target = new_target
	if snap:
		snap_to_target()


func resume_follow_from_current_position(new_target: Node2D) -> void:
	# A scripted move owns global_position; adopt it before normal following resumes.
	target = new_target
	_retarget_elapsed = _retarget_seconds
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


func adopt_view(center: Vector2, view_zoom: Vector2) -> void:
	## 连续镜头交接时接收已有视野，避免重新对准角色造成跳帧。
	zoom = view_zoom
	_retarget_elapsed = _retarget_seconds
	_center = _clamp_center(center)
	global_position = _center
	offset = Vector2.ZERO
	_trauma = 0.0

func blend_to_target(new_target: Node2D, seconds: float = 0.28) -> void:
	## 传送改变角色位置，不立即改变画面位置；保留同一台显示相机。
	target = new_target
	_retarget_from = _center
	_retarget_seconds = maxf(seconds, 0.01)
	_retarget_elapsed = 0.0
	clear_impulse()
