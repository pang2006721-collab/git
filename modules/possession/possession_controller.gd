class_name PossessionController
extends Node
## One successful possession per round. Nearby selection uses the user's artwork.
## The transition owns its tween/time scale, and cancels cleanly on restart or exit.

signal possession_started(host: PossessableHost)
signal possession_finished(host: PossessableHost)

enum State { ROAMING, TRANSFERRING, POSSESSED }

@export_node_path("CharacterBody2D") var soul_path: NodePath
@export_node_path("Camera2D") var camera_path: NodePath
@export_node_path("Node") var shot_path: NodePath = ^"../PossessionCamera"
@export_node_path("CharacterBody2D") var source_body_path: NodePath
@export var source_focus_offset: Vector2 = Vector2.ZERO
@export var soul_initially_hidden: bool = false
@export var center_soul_artwork: bool = false
@export var enabled: bool = true
@export var selection_radius: float = 400.0
@export var transfer_duration: float = 0.48
@export_range(0.05, 1.0) var slow_motion_scale: float = 0.55
@export var possess_action: StringName = &"possess"
@export var host_group: StringName = &"possessable_hosts"

var state: State = State.ROAMING
var selected_host: PossessableHost
var soul: CharacterBody2D
var camera: FollowCamera
var shot: PossessionCamera
var _ghost_motor: PlatformerMotor
var _ghost_reader: PlatformerInput
var _soul_visual: Node2D
var _transfer_host: PossessableHost
var _tween: Tween
var _start: Vector2
var _end: Vector2
var _control: Vector2
var _saved_time_scale: float = 1.0
var _source_body: CharacterBody2D
var _art_anchor := Vector2.ZERO


func _ready() -> void:
	soul = get_node(soul_path) as CharacterBody2D
	camera = get_node(camera_path) as FollowCamera
	shot = get_node(shot_path) as PossessionCamera
	_ghost_motor = soul.get_node("Movement") as PlatformerMotor
	_ghost_reader = soul.get_node("Input") as PlatformerInput
	_soul_visual = soul.get_node("Visual") as Node2D
	_source_body = soul if source_body_path.is_empty() else get_node(source_body_path) as CharacterBody2D
	if center_soul_artwork:
		_art_anchor = -(_soul_visual.get_node("Sprite") as Sprite2D).position
	if soul_initially_hidden:
		soul.hide()
		_ghost_motor.enabled = false
		_ghost_reader.enabled = false
	if not InputMap.has_action(possess_action):
		InputMap.add_action(possess_action)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SHIFT
		key.location = KEY_LOCATION_LEFT
		InputMap.action_add_event(possess_action, key)


func _physics_process(_delta: float) -> void:
	if not enabled:
		clear_selection()
		return
	if state == State.ROAMING:
		_update_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(possess_action) and not event.is_echo():
		# Explicit location check also protects against a generic Shift binding.
		if event is InputEventKey and event.location == KEY_LOCATION_RIGHT:
			return
		if request_possession():
			get_viewport().set_input_as_handled()


func request_possession() -> bool:
	if not enabled or state != State.ROAMING:
		return false
	_update_selection()
	if not is_instance_valid(selected_host):
		return false
	_transfer_host = selected_host
	_transfer_host.freeze_for_transfer()
	selected_host = null
	state = State.TRANSFERRING
	if _source_body != soul:
		soul.global_position = _source_body.global_position + source_focus_offset
		soul.show()
	_ghost_motor.enabled = false
	_ghost_reader.enabled = false
	_ghost_reader.clear()
	_soul_visual.set_process(false)
	soul.velocity = Vector2.ZERO
	_start = _source_body.global_position + source_focus_offset if center_soul_artwork else soul.global_position
	_end = _transfer_host.focus_position()
	if center_soul_artwork:
		soul.global_position = _start + _art_anchor
	_control = (_start + _end) * 0.5 + Vector2(0, -30)
	_saved_time_scale = Engine.time_scale
	shot.begin(soul, _transfer_host)
	possession_started.emit(_transfer_host)
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_method(_animate_transfer, 0.0, 1.0, transfer_duration)
	_tween.tween_callback(_finish_transfer)
	return true


func _update_selection() -> void:
	var nearest: PossessableHost = null
	var nearest_distance := selection_radius * selection_radius
	for node in get_tree().get_nodes_in_group(host_group):
		var host := node as PossessableHost
		if host.claimed:
			continue
		var distance := (_source_body.global_position + source_focus_offset).distance_squared_to(host.focus_position())
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = host
	if selected_host == nearest:
		return
	if is_instance_valid(selected_host):
		selected_host.set_highlight(false)
	selected_host = nearest
	if is_instance_valid(selected_host):
		selected_host.set_highlight(true)


func _animate_transfer(progress: float) -> void:
	# A single smooth trajectory, with no stationary anticipation or impact hold.
	var flight := progress * progress * progress * (progress * (progress * 6.0 - 15.0) + 10.0)
	var envelope := pow(sin(progress * PI), 2.0)
	Engine.time_scale = _saved_time_scale * lerpf(1.0, slow_motion_scale, envelope)
	var center := _start.bezier_interpolate(_control, _control, _end, flight)
	var shrink := smoothstep(0.50, 1.0, flight)
	_soul_visual.scale = Vector2.ONE.lerp(Vector2(0.08, 0.13), shrink)
	_soul_visual.rotation = lerpf(0.0, 0.3, flight)
	_soul_visual.modulate.a = 1.0 - smoothstep(0.86, 1.0, flight)
	var anchor := (_art_anchor * _soul_visual.scale).rotated(_soul_visual.rotation)
	soul.global_position = center + anchor
	shot.sample(progress, soul.global_position, anchor)


func _finish_transfer() -> void:
	Engine.time_scale = _saved_time_scale
	soul.hide()
	_transfer_host.take_control()
	state = State.POSSESSED
	shot.finish(_transfer_host.body)
	possession_finished.emit(_transfer_host)
	_transfer_host = null


func reset() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	if state == State.TRANSFERRING:
		_restore_camera_and_time()
	shot.cancel()
	if is_instance_valid(selected_host):
		selected_host.set_highlight(false)
	selected_host = null
	_transfer_host = null
	state = State.ROAMING
	enabled = true
	soul.visible = not soul_initially_hidden
	_ghost_motor.enabled = not soul_initially_hidden
	_ghost_motor.reset()
	_ghost_reader.enabled = not soul_initially_hidden
	_ghost_reader.external_control = false
	_ghost_reader.clear()
	(_soul_visual as SquashStretch).reset()
	_soul_visual.set_process(true)
	_soul_visual.scale = Vector2.ONE
	_soul_visual.rotation = 0.0
	_soul_visual.modulate = Color.WHITE
	camera.set_follow_target(_source_body)


func clear_selection() -> void:
	if is_instance_valid(selected_host):
		selected_host.set_highlight(false)
	selected_host = null


func _restore_camera_and_time() -> void:
	Engine.time_scale = _saved_time_scale
	shot.cancel()


func set_source_body(body: CharacterBody2D, focus_offset: Vector2 = Vector2.ZERO) -> void:
	_source_body = body
	source_focus_offset = focus_offset


func _exit_tree() -> void:
	if state == State.TRANSFERRING:
		Engine.time_scale = _saved_time_scale
