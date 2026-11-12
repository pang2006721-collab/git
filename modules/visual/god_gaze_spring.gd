extends Node2D
## 眼睛在脸部范围内持续追踪玩家，整个上帝按固定间隔弹性回弹。
@export var pulse_interval: float = 3.2
@export var eye_travel:=Vector2(7,4)
@export var stiffness: float = 160.0
@export var damping: float = 10.0
var target:Node2D
var _eyes_origin:=Vector2.ZERO
var _brows_origin:=Vector2.ZERO
var _shape:=Vector2.ONE
var _velocity:=Vector2.ZERO
var _clock:=0.0
var pulse_count:=0
func _ready() -> void:
	_eyes_origin=$Eyes.position
	_brows_origin=$Brows.position
func pulse() -> void:
	_shape=Vector2(1.15,0.84)
	_velocity=Vector2(-1.4,2.5)
	pulse_count+=1
func _process(delta:float) -> void:
	_clock+=delta
	if _clock>=pulse_interval:
		_clock=fmod(_clock,pulse_interval)
		pulse()
	var remaining:=minf(delta,0.1)
	while remaining>0:
		var step:=minf(remaining,1.0/240.0)
		_velocity+=((Vector2.ONE-_shape)*stiffness-_velocity*damping)*step
		_shape+=_velocity*step
		remaining-=step
	scale=_shape
	if is_instance_valid(target):
		var direction:Vector2=to_local(target.global_position)-(_eyes_origin+Vector2(55,17.5))
		var gaze:=Vector2(direction.x/180.0,direction.y/180.0).limit_length(1.0)*eye_travel
		$Eyes.position=$Eyes.position.lerp(_eyes_origin+gaze,1-exp(-14*delta))
		$Brows.position=$Brows.position.lerp(_brows_origin+Vector2(0,gaze.y*0.12),1-exp(-10*delta))
func reset() -> void:
	_shape=Vector2.ONE
	_velocity=Vector2.ZERO
	_clock=0
	pulse_count=0
	scale=Vector2.ONE
	$Eyes.position=_eyes_origin
	$Brows.position=_brows_origin
