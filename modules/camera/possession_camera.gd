class_name PossessionCamera
extends Node
## A quiet tracking handoff: keep normal framing and let zoom settle after control returns.

@export_node_path("Camera2D") var camera_path: NodePath = ^"../FollowCamera"
@export_group("Possession shot / 附身运镜")
@export_range(1.0, 1.3) var close_up_zoom: float = 1.12
@export var zoom_response: float = 8.0

var active: bool = false
var recovering: bool = false
var _camera: FollowCamera
var _focus: Marker2D
var _host: PossessableHost
var _old_target: Node2D
var _old_zoom: Vector2
var _old_unscaled: bool
var _zoom_velocity := Vector2.ZERO
var _recovery_time: float = 0.0
var _start_offset := Vector2.ZERO


func _ready() -> void:
	_camera = get_node(camera_path) as FollowCamera
	_focus = Marker2D.new()
	_focus.name = "ShotFocus"
	add_child(_focus)


func begin(source: Node2D, host: PossessableHost) -> void:
	if active:
		cancel()
	active = true
	recovering = false
	_host = host
	_old_target = _camera.target
	_old_zoom = _camera.zoom
	_old_unscaled = _camera.use_unscaled_time
	_zoom_velocity = Vector2.ZERO
	_recovery_time = 0.0
	_start_offset = _old_target.global_position - source.global_position if is_instance_valid(_old_target) else Vector2.ZERO
	_focus.global_position = source.global_position + _start_offset
	_camera.use_unscaled_time = true
	_camera.clear_impulse()
	_camera.set_follow_target(_focus)


func sample(progress: float, soul_position: Vector2, visual_anchor: Vector2 = Vector2.ZERO) -> void:
	if not active or recovering:
		return
	var blend := smoothstep(0.0, 1.0, progress)
	# Keep the normal camera offset/deadzone. End at the host's feet for a seamless swap.
	_focus.global_position = soul_position + _start_offset * (1.0 - blend) - (_host.focus_offset + visual_anchor) * blend


func _process(delta: float) -> void:
	if not active:
		return
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	var target_zoom := _old_zoom if recovering else _old_zoom * close_up_zoom
	var remaining := minf(real_delta, 0.1)
	while remaining > 0.0:
		var step := minf(remaining, 1.0 / 120.0)
		# Critical damping keeps velocity continuous when the zoom goal changes at handoff.
		_zoom_velocity += ((target_zoom - _camera.zoom) * zoom_response * zoom_response - _zoom_velocity * 2.0 * zoom_response) * step
		_camera.zoom += _zoom_velocity * step
		remaining -= step
	if recovering:
		_recovery_time += real_delta
		if (_camera.zoom.distance_to(_old_zoom) < 0.0003 and _zoom_velocity.length() < 0.003) or _recovery_time >= 2.0:
			_restore()


func finish(new_target: Node2D) -> void:
	# Return player control now; recovery continues independently alongside gameplay.
	recovering = true
	_camera.set_follow_target(new_target)


func cancel() -> void:
	if not active:
		return
	_restore()
	if is_instance_valid(_old_target):
		_camera.set_follow_target(_old_target)


func _restore() -> void:
	_camera.zoom = _old_zoom
	_camera.use_unscaled_time = _old_unscaled
	_camera.clear_impulse()
	_zoom_velocity = Vector2.ZERO
	recovering = false
	active = false
