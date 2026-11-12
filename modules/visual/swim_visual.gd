class_name SwimVisual
extends Node2D
## Input decides facing immediately; velocity and water inertia stay in SwimMotor.

@export_node_path("CharacterBody2D") var body_path: NodePath = ^".."
@export_node_path("Sprite2D") var sprite_path: NodePath = ^"Sprite"
@export_node_path("Node") var input_path: NodePath = ^"../Input"
@export var artwork_faces_right: bool = false
@export var max_bank_degrees: float = 22.0
@export var turn_response: float = 24.0

var _body: CharacterBody2D
var _sprite: Sprite2D
var _reader: SwimInput
var _facing: float = -1.0
var _spring_position := Vector2.ONE
var _spring_velocity := Vector2.ZERO


func _ready() -> void:
	_body = get_node(body_path) as CharacterBody2D
	_sprite = get_node(sprite_path) as Sprite2D
	_reader = get_node(input_path) as SwimInput


func _process(delta: float) -> void:
	var remaining := minf(delta, 0.1)
	while remaining > 0.0:
		var step := minf(remaining, 1.0 / 120.0)
		_spring_velocity += ((Vector2.ONE - _spring_position) * 180.0 - _spring_velocity * 14.0) * step
		_spring_position += _spring_velocity * step
		remaining -= step
	scale = _spring_position
	var direction := _reader.get_visual_direction()
	var axis := direction.x
	if absf(axis) > 0.05:
		_facing = signf(axis)
	_sprite.flip_h = (_facing > 0.0) != artwork_faces_right
	var vertical_input := direction.y
	var angle := atan2(vertical_input, maxf(absf(axis), 0.6)) * _facing
	angle = clampf(angle, -deg_to_rad(max_bank_degrees), deg_to_rad(max_bank_degrees))
	rotation = lerp_angle(rotation, angle, 1.0 - exp(-turn_response * delta))


func reset() -> void:
	rotation = 0.0
	_facing = -1.0
	_sprite.flip_h = artwork_faces_right
	_spring_position = Vector2.ONE
	_spring_velocity = Vector2.ZERO
	scale = Vector2.ONE


func play_selection_pulse() -> void:
	_spring_position = Vector2(1.16, 0.88)
	_spring_velocity = Vector2(-1.0, 1.0)


func play_possession_pulse() -> void:
	_spring_position = Vector2(0.88, 1.12)
	_spring_velocity = Vector2(1.0, -1.0)
