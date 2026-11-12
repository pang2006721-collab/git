class_name PlatformerInput
extends Node
## Reusable keyboard reader. The motor also accepts any reader exposing these fields.
## Input actions are created only if missing; another project can define its own bindings.

@export var enabled: bool = true
@export var left_action: StringName = &"move_left"
@export var right_action: StringName = &"move_right"
@export var jump_action: StringName = &"jump"
@export var down_action: StringName = &"move_down"

var move_axis: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false
var down_held: bool = false
## Set this for deterministic integration checks, replays, or an AI controller.
var external_control: bool = false


func _ready() -> void:
	process_physics_priority = -20
	_bind_default(left_action, [KEY_A])
	_bind_default(right_action, [KEY_D])
	_bind_default(jump_action, [KEY_W, KEY_SPACE])
	_bind_default(down_action, [KEY_S])
	_bind_default(&"restart", [KEY_R])


func _physics_process(_delta: float) -> void:
	if external_control:
		return
	move_axis = Input.get_axis(left_action, right_action) if enabled else 0.0
	jump_pressed = enabled and Input.is_action_just_pressed(jump_action)
	jump_held = enabled and Input.is_action_pressed(jump_action)
	down_held = enabled and Input.is_action_pressed(down_action)


func clear() -> void:
	move_axis = 0.0
	jump_pressed = false
	jump_held = false
	down_held = false


func _bind_default(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
