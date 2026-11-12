extends Node
## 首页鼠标拖拽；放开后恢复原有扇翅 AI，不影响关卡中的小鸟。
@export var screen_bounds := Rect2(75, 80, 1770, 920)
var dragging := false
var _offset := Vector2.ZERO
@onready var _bird: CharacterBody2D = get_parent()
@onready var _motor: Node = _bird.get_node("Movement")
@onready var _patrol: Node = _bird.get_node("Patrol")
@onready var _sprite: Sprite2D = _bird.get_node("Visual/Sprite")
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse: Vector2 = _bird.get_canvas_transform().affine_inverse() * event.position
		if event.pressed and _sprite.get_rect().grow(16).has_point(_sprite.to_local(mouse)):
			begin_drag(mouse)
			get_viewport().set_input_as_handled()
		elif not event.pressed and dragging:
			end_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		drag_to(_bird.get_canvas_transform().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()
func begin_drag(mouse: Vector2) -> void:
	dragging = true
	_offset = _bird.global_position - mouse
	_patrol.stop()
	_motor.enabled = false
	_bird.velocity = Vector2.ZERO
	_bird.get_node("Visual").play_selection_pulse()
func drag_to(mouse: Vector2) -> void:
	if dragging:
		_bird.global_position = (mouse + _offset).clamp(screen_bounds.position, screen_bounds.end)
func end_drag() -> void:
	if not dragging:
		return
	dragging = false
	# 给巡游和扇翅留出边缘空间，当前位置连续接回 AI，不瞬移。
	var margin: Vector2 = _patrol.patrol_radius + Vector2(20, 110)
	_patrol.center = _bird.position.clamp(screen_bounds.position + margin, screen_bounds.end - margin)
	_bird.velocity = Vector2.ZERO
	_motor.enabled = true
	_patrol.start()
	_bird.get_node("Visual").play_possession_pulse()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and dragging:
		end_drag()
