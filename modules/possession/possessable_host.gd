class_name PossessableHost
extends Node
## A host exposes its selection artwork, capture point and control handoff.

@export_node_path("CharacterBody2D") var body_path: NodePath = ^".."
@export var focus_offset: Vector2 = Vector2(0, -68)
var claimed: bool = false
var highlighted: bool = false
var body: CharacterBody2D
## Host adapters share enabled/clear/reset and visual pulse hooks, not a movement type.
var reader
var motor
var patrol
var visual
var _normal: Sprite2D
var _selected: Sprite2D


func _ready() -> void:
	add_to_group("possessable_hosts")
	body = get_node(body_path) as CharacterBody2D
	reader = body.get_node("Input")
	motor = body.get_node("Movement")
	patrol = body.get_node_or_null("Patrol")
	visual = body.get_node("Visual")
	_normal = visual.get_node("Sprite") as Sprite2D
	_selected = visual.get_node("SelectedSprite") as Sprite2D
	set_highlight(false)
	if patrol == null:
		reader.enabled = false
		reader.external_control = true
		reader.clear()
		motor.enabled = false
		motor.reset()


func focus_position() -> Vector2:
	return body.global_position + focus_offset


func set_highlight(value: bool) -> void:
	var next_highlight := value and not claimed
	var just_selected := next_highlight and not highlighted
	highlighted = next_highlight
	_normal.visible = not highlighted
	_selected.visible = highlighted
	# The SHIFT lettering belongs to the supplied artwork; never mirror the letters.
	_selected.flip_h = false
	if just_selected:
		visual.play_selection_pulse()


func freeze_for_transfer() -> void:
	if patrol != null:
		patrol.stop()
	reader.enabled = false
	reader.external_control = true
	reader.clear()
	motor.enabled = false
	body.velocity = Vector2.ZERO
	set_highlight(false)


func take_control() -> void:
	claimed = true
	if patrol != null:
		patrol.stop()
	reader.external_control = false
	reader.enabled = true
	reader.clear()
	motor.enabled = true
	motor.reset()
	set_highlight(false)
	visual.play_possession_pulse()


func reset() -> void:
	claimed = false
	motor.enabled = true
	motor.reset()
	visual.reset()
	visual.set_process(true)
	visual.modulate = Color.WHITE
	set_highlight(false)
	if patrol != null:
		patrol.start()
	else:
		reader.enabled = false
		reader.external_control = true
		reader.clear()
		motor.enabled = false
