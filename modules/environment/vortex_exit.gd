class_name VortexExit
extends Area2D
## Only the possessed body, jumping into the mouth, can trigger this exit.
## The level decides what happens after capture; the reusable exit only animates it.

signal capture_started(body: CharacterBody2D)
signal capture_finished(body: CharacterBody2D)

@export_node_path("Node2D") var mouth_path: NodePath = ^"Mouth"
@export var capture_duration: float = 0.78
@export var require_upward_motion: bool = true
@export var spin_radians: float = 1.1

var eligible_body: CharacterBody2D
var active: bool = false
var _body: CharacterBody2D
var _visual: Node2D
var _tween: Tween
var _mouth: Node2D
var _start: Vector2


func _ready() -> void:
	_mouth = get_node(mouth_path) as Node2D
	body_entered.connect(try_capture)


func try_capture(body: Node2D) -> bool:
	if active or body != eligible_body or not is_instance_valid(eligible_body):
		return false
	if require_upward_motion and eligible_body.velocity.y >= -10.0:
		return false
	active = true
	_body = eligible_body
	_visual = _body.get_node("Visual") as Node2D
	_start = _body.global_position
	capture_started.emit(_body)
	_visual.set_process(false)
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_method(_animate_capture, 0.0, 1.0, capture_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func(): capture_finished.emit(_body))
	return true


func _animate_capture(progress: float) -> void:
	_body.global_position = _start.lerp(_mouth.global_position, progress)
	_visual.scale = Vector2.ONE.lerp(Vector2(0.025, 0.10), progress)
	_visual.rotation = spin_radians * progress * progress
	_visual.modulate.a = 1.0 - smoothstep(0.7, 1.0, progress)


func reset() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	if is_instance_valid(_visual):
		_visual.scale = Vector2.ONE
		_visual.rotation = 0.0
		_visual.modulate = Color.WHITE
		_visual.set_process(true)
	active = false
	eligible_body = null
	_body = null
