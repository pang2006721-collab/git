class_name VerticalSceneTransition
extends Node
## Move the existing gameplay camera through physically stitched world artwork.
signal finished
@export var duration: float = 3.6
@export_range(0.0, 1.0) var motion_strength: float = 1.0
@export var suction_zoom: float = 1.06
@export var suction_duration: float = 0.78
var preparing: bool = false
var rest_zoom := Vector2.ONE
var active: bool = false
var elapsed: float = 0.0
var camera: FollowCamera
var _start: Vector2
var _end: Vector2
var _entry_zoom: Vector2
var _prepare_time: float = 0.0

func prepare(shared_camera: FollowCamera, normal_zoom: Vector2 = Vector2.ONE) -> void:
	camera = shared_camera
	rest_zoom = normal_zoom
	_entry_zoom = camera.zoom
	_prepare_time = 0.0
	preparing = true

func travel(shared_camera: FollowCamera, destination: Vector2) -> void:
	camera = shared_camera
	if not preparing:
		rest_zoom = camera.zoom
	preparing = false
	_entry_zoom = camera.zoom
	_start = camera.global_position
	_end = destination
	elapsed = 0.0
	active = true
	camera.clear_impulse()
	camera.set_process(false)

func cancel() -> void:
	active = false
	if is_instance_valid(camera):
		if preparing or camera.zoom != rest_zoom:
			camera.zoom = rest_zoom
		camera.set_process(true)
	preparing = false

func _process(delta: float) -> void:
	if preparing:
		_prepare_time += delta
		var pull := smoothstep(0.0, suction_duration, _prepare_time)
		camera.zoom = _entry_zoom.lerp(rest_zoom * lerpf(1.0, suction_zoom, motion_strength), pull)
		return
	if not active:
		return
	elapsed = minf(elapsed + delta, duration)
	var p := clampf(elapsed / duration, 0.0, 1.0)
	# Slightly earlier peak speed, with one continuous deceleration into the ocean.
	var q := 1.0 - pow(1.0 - p, 1.2)
	var progress := q * q * q * (q * (q * 6.0 - 15.0) + 10.0)
	camera.zoom = _entry_zoom.lerp(rest_zoom, smoothstep(0.0, 0.72, p))
	camera.global_position = _start.lerp(_end, progress)
	camera.force_update_scroll()
	if elapsed >= duration:
		camera.zoom = rest_zoom
		active = false
		finished.emit()
