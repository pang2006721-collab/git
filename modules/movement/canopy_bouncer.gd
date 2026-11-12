extends Node
## 树冠内待机、按次跳出、空中转向与原地落回；与普通平台移动互斥。
@export var jump_speed: float = 1420.0
@export var gravity: float = 2100.0
@export var air_speed: float = 470.0
@export var burial_depth: float = 230.0
var enabled := false
var buried := true
var released := false
var body: CharacterBody2D
var landing_x := 960.0
var _sky: Node2D
var _velocity:=Vector2.ZERO
func _ready() -> void:
	_sky=get_parent()
func begin(squirrel: CharacterBody2D, x: float) -> void:
	body=squirrel
	enabled=true
	released=false
	buried=true
	landing_x=clampf(x,310,1610)
	_velocity=Vector2.ZERO
	body.get_node("Movement").enabled=false
	body.get_node("Input").enabled=false
	body.global_position=_sky.to_global(Vector2(landing_x,_sky.canopy_y(landing_x)+burial_depth))
	body.hide()
	launch()
func launch() -> void:
	if not enabled or not buried or released:
		return
	buried=false
	body.z_index=_sky.get_node("CanopyForeground").z_index+1
	body.show()
	_velocity=Vector2(0,-jump_speed)
	_sky.ripple_at(landing_x)
	body.get_node("Visual").play_possession_pulse()
func release_host() -> void:
	# 灵魂离开即停止向上弹跳，保留横向惯性，由重力接管下落。
	released=true
	_velocity.y=maxf(_velocity.y,0.0)
func _physics_process(delta: float) -> void:
	if not enabled or body==null:
		return
	if buried:
		if not released and Input.is_action_just_pressed(&"flap"):
			launch()
		return
	if not released:
		_velocity.x=move_toward(_velocity.x,Input.get_axis(&"move_left",&"move_right")*air_speed,1700*delta)
	_velocity.y+=gravity*delta
	var p:Vector2=_sky.to_local(body.global_position)+_velocity*delta
	p.x=clampf(p.x,290,1630)
	body.global_position=_sky.to_global(p)
	body.velocity=_velocity*body.global_scale
	if absf(_velocity.x)>5:
		body.get_node("Visual/Sprite").flip_h=_velocity.x>0
	if _velocity.y>0 and p.y>=_sky.canopy_y(p.x)+burial_depth:
		landing_x=p.x
		buried=true
		_velocity=Vector2.ZERO
		body.velocity=Vector2.ZERO
		body.hide()
		_sky.ripple_at(landing_x)
func reset() -> void:
	enabled=false
	released=false
	buried=true
	_velocity=Vector2.ZERO
