class_name SwimInput
extends Node
## Independent WASD input for a swimming body. No jump or possession rules here.

@export var enabled: bool = true
var external_control: bool = false
var move_axis: float = 0.0
var up_held: bool = false
var down_held: bool = false


func _ready() -> void:
	process_physics_priority = -20
	_bind(&"swim_left", KEY_A)
	_bind(&"swim_right", KEY_D)
	_bind(&"swim_up", KEY_W)
	_bind(&"swim_down", KEY_S)
	_bind(&"restart", KEY_R)


func _physics_process(_delta: float) -> void:
	if external_control:
		return
	move_axis = Input.get_axis(&"swim_left", &"swim_right") if enabled else 0.0
	up_held = enabled and Input.is_action_pressed(&"swim_up")
	down_held = enabled and Input.is_action_pressed(&"swim_down")


func clear() -> void:
	move_axis = 0.0
	up_held = false
	down_held = false


func get_visual_direction() -> Vector2:
	# Visual feedback samples the latest input per render frame, not the last physics tick.
	if not enabled:
		return Vector2.ZERO
	if external_control:
		return Vector2(move_axis, float(down_held) - float(up_held))
	return Vector2(Input.get_axis(&"swim_left", &"swim_right"), Input.get_axis(&"swim_up", &"swim_down"))


func _bind(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
