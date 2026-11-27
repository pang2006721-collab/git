extends Node2D
@export var room_framing_offset:=Vector2(0,-220)
@onready var ghost:CharacterBody2D=$Ghost
@onready var god:Node2D=$God/Visual
var active:=false
var camera:FollowCamera
var _standalone:=false
var _saved_framing:=Vector2.ZERO
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	ghost.get_node("Movement").enabled=false
	ghost.get_node("Input").enabled=false
	god.target=ghost
	$FollowCamera.enabled=false
	_standalone=get_parent()==get_tree().root
	if _standalone:
		$FollowCamera.enabled=true
		begin($FollowCamera)
		camera.snap_to_target()
func begin(shared_camera:FollowCamera) -> void:
	camera=shared_camera
	_saved_framing=camera.framing_offset
	camera.framing_offset=room_framing_offset
	active=true
	ghost.position=$GhostSpawn.position
	ghost.show()
	var reader:PlatformerInput=ghost.get_node("Input")
	reader.enabled=true
	reader.external_control=false
	reader.clear()
	var motor:PlatformerMotor=ghost.get_node("Movement")
	motor.enabled=true
	motor.reset()
	ghost.velocity=Vector2(0,-620)
	ghost.get_node("Visual").play_possession_pulse()
	$CloudRipple.position.x=ghost.position.x
	$CloudRipple.pulse()
	god.target=ghost
	camera.resume_follow_from_current_position(ghost)
	camera.set_process(true)
func reset() -> void:
	if active and is_instance_valid(camera):
		camera.framing_offset=_saved_framing
	active=false
	ghost.hide()
	ghost.get_node("Movement").enabled=false
	ghost.get_node("Input").enabled=false
	ghost.get_node("Input").clear()
	ghost.velocity=Vector2.ZERO
	ghost.position=$GhostSpawn.position
	ghost.get_node("Visual").reset()
	$CloudRipple.reset()
	god.reset()
func _unhandled_input(event:InputEvent) -> void:
	if _standalone and event.is_action_pressed(&"restart") and not event.is_echo():
		reset()
		begin(camera)
		camera.snap_to_target()
