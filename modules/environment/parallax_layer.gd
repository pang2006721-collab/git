class_name SimpleParallaxLayer
extends Node2D
## Positive factors move with the camera (farther away); negative factors move faster.
## The artwork remains unmodified; only this layer's transform changes.

@export_node_path("Camera2D") var camera_path: NodePath
@export var motion_factor: Vector2 = Vector2(0.0, 0.18)
@export var align_vertical_edges: bool = false

var _camera: Camera2D
var _origin: Vector2
var _camera_origin: Vector2
var _reference_half_height: float
var _art_world_bounds: Rect2


func _ready() -> void:
	# Read this frame's resolved camera position, after follow and visual impulses.
	process_priority = 30
	_camera = get_node(camera_path) as Camera2D
	_origin = position
	# Capture the real starting position after the camera has snapped to the actor.
	call_deferred("reset_reference")


func _process(_delta: float) -> void:
	if is_instance_valid(_camera):
		var travel := _camera.global_position - _camera_origin
		if align_vertical_edges and _camera is FollowCamera:
			travel.y = _edge_aligned_y(_camera.global_position.y) - _edge_aligned_y(_camera_origin.y)
		position = _origin + travel * motion_factor / global_scale


func _edge_aligned_y(camera_y: float) -> float:
	# 侧面素材只按所属地图对齐，不能随镜头扩展到森林、天空而移动接缝。
	var bounds: Rect2 = _art_world_bounds
	var top := bounds.position.y + _reference_half_height
	var span := bounds.size.y - _reference_half_height * 2.0
	if span <= 0.0:
		return 0.0
	var t := clampf((camera_y - top) / span, 0.0, 1.0)
	# Derivative stays in [-1, 1]. No rapid unwinding of accumulated displacement
	# in a narrow edge band; both authored seams still meet exactly.
	return -span * t * (1.0 - t)


func reset_reference() -> void:
	position = _origin
	_camera_origin = _camera.global_position
	_reference_half_height = _camera.get_viewport_rect().size.y * 0.5 / _camera.zoom.y
	var art := get_node_or_null("Art") as Sprite2D
	if art != null:
		var rect := art.get_rect()
		var start: Vector2 = get_parent().to_global(_origin + art.position + rect.position * art.scale)
		_art_world_bounds = Rect2(start, rect.size * art.scale * global_scale)
	elif _camera is FollowCamera:
		_art_world_bounds = _camera.world_bounds
