extends Sprite2D
## 褶皱使用阻尼弹簧挤压和回弹，透明度保持不变。
@export var stiffness: float = 210.0
@export var damping: float = 11.0
@export var impact_shape := Vector2(1.38,0.48)
@export var shrink_start: float = 0.42
@export var duration: float = 0.72
var _age:=0.0
var _base_scale:=Vector2.ONE
var _shape:=Vector2.ONE
var _velocity:=Vector2.ZERO
func _ready() -> void:
	_base_scale=scale
func pulse() -> void:
	_age=0
	show()
	modulate.a=1.0
	_shape=impact_shape
	_velocity=Vector2(-2.0,5.5)
	scale=_base_scale*_shape
func _process(delta:float) -> void:
	if not visible:
		return
	_age+=delta
	var remaining:=minf(delta,0.1)
	while remaining>0:
		var step:=minf(remaining,1.0/240.0)
		_velocity+=((Vector2.ONE-_shape)*stiffness-_velocity*damping)*step
		_shape+=_velocity*step
		remaining-=step
	# 弹一下后收拢到零，使用形变消失，不改变透明度。
	scale=_base_scale*_shape*(1.0-smoothstep(shrink_start,duration,_age))
	if _age>=duration:
		hide()
func reset() -> void:
	_age=0
	_shape=Vector2.ONE
	_velocity=Vector2.ZERO
	scale=_base_scale
	modulate.a=1.0
	hide()
