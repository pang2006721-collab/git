class_name VineClimber
extends Node
## S 大范围抓取，W/S 攀爬，A/D 借力摆荡，空格带着惯性跳离。
@export var hands_offset := Vector2(0,-60)
@export var grip_body_offset := Vector2(78,60)
var grip_side: float = 1.0
var vine: SwingVine
var jump_origin: Vector2
var _body: CharacterBody2D
var _motor: PlatformerMotor
var _reader: PlatformerInput
var _host: PossessableHost
var _cooldown: float = 0.0
var _wait_for_grab_release: bool = false
var _mantle_time: float = -1.0
var _mantle_start: Vector2
var _mantle_end: Vector2
func _ready() -> void:
	process_physics_priority = -5
	_body = get_parent()
	_motor = _body.get_node("Movement")
	_reader = _body.get_node("Input")
	_host = _body.get_node("Host")
	jump_origin = _body.global_position
	_motor.jumped.connect(func(): jump_origin=_body.global_position)
	if not InputMap.has_action(&"vine_release"):
		InputMap.add_action(&"vine_release")
		var key := InputEventKey.new()
		key.physical_keycode=KEY_SPACE
		InputMap.action_add_event(&"vine_release",key)
func _physics_process(delta: float) -> void:
	_cooldown=maxf(0,_cooldown-delta)
	if not _reader.down_held:
		_wait_for_grab_release=false
	if not _host.claimed:
		return
	if _mantle_time>=0:
		_mantle_time+=delta
		var blend:=smoothstep(0,0.25,_mantle_time)
		_body.move_and_collide(_mantle_start.lerp(_mantle_end,blend)-_body.global_position)
		if blend>=1:
			_mantle_time=-1
			_motor.enabled=true
			_motor.reset()
		return
	if vine != null:
		vine.climb_axis=float(_reader.down_held)-float(_reader.jump_held)
		vine.pump_axis=_reader.move_axis
		if Input.is_action_just_pressed(&"vine_release"):
			detach(true)
		elif vine.grip_length>=vine.length-1.0 and _reader.down_held:
			detach(false)
			_body.velocity.y=maxf(_body.velocity.y,120.0)
			_wait_for_grab_release=true
		elif vine.grip_length<=40 and _reader.jump_held:
			var anchor:=vine.global_position
			var side:float=-1 if vine.position.x<900 else 1
			detach(false)
			_motor.enabled=false
			_mantle_time=0
			_mantle_start=_body.global_position
			_mantle_end=anchor+Vector2(side*105,-155)*_body.global_scale
		return
	if _reader.down_held and _cooldown<=0 and not _wait_for_grab_release:
		try_grab()
func try_grab() -> bool:
	if not _host.claimed:
		return false
	var hands:=_body.global_position+hands_offset*_body.global_scale
	var nearest: SwingVine
	var distance:=INF
	for node in get_tree().get_nodes_in_group("swing_vines"):
		var candidate:=node as SwingVine
		var current_distance:=hands.distance_to(candidate.closest_grip(hands))
		if candidate.can_grab(hands) and current_distance<distance:
			nearest=candidate
			distance=current_distance
	if nearest==null:
		return false
	if _body.is_on_floor():
		jump_origin=_body.global_position
	var grip:=nearest.closest_grip(hands)
	grip_side=signf(_body.global_position.x-grip.x) if absf(_body.global_position.x-grip.x)>15 else 1.0
	nearest.rider_offset=Vector2(grip_body_offset.x*grip_side,grip_body_offset.y)*_body.global_scale
	nearest.catch(_body,_body.velocity,jump_origin)
	vine=nearest
	_motor.enabled=false
	return true
func detach(jump: bool) -> void:
	if vine==null:
		return
	var exit_velocity:=vine.release()
	vine=null
	_motor.enabled=true
	_motor.reset()
	_body.velocity=exit_velocity+Vector2(_reader.move_axis*120,-440 if jump else 0)
	jump_origin=_body.global_position
	_cooldown=0.3
func reset() -> void:
	if vine!=null:
		vine.release()
	vine=null
	_mantle_time=-1
	_cooldown=0
	_wait_for_grab_release=false
	_motor.enabled=true
