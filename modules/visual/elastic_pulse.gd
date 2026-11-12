extends Node
## 独立弹性模块：挂到 Node2D 或 Control 下即可复用。
@export var interval: float = 0.0
@export var first_delay: float = 1.0
@export var strength: float = 0.12
@export var stiffness: float = 190.0
@export var damping: float = 11.0
var pulse_count := 0
var _shape := Vector2.ONE
var _velocity := Vector2.ZERO
var _clock := 0.0
var _next := 0.0
var _base := Vector2.ONE
func _ready() -> void:
	_base = get_parent().scale
	_next = first_delay
func pulse() -> void:
	_shape = Vector2(1.0 + strength, 1.0 - strength)
	_velocity = Vector2(-1.2, 1.2)
	pulse_count += 1
func _process(delta: float) -> void:
	_clock += delta
	if interval > 0.0 and _clock >= _next:
		_next = _clock + interval
		pulse()
	var remaining := minf(delta, 0.1)
	while remaining > 0.0:
		var step := minf(remaining, 1.0 / 240.0)
		_velocity += ((Vector2.ONE - _shape) * stiffness - _velocity * damping) * step
		_shape += _velocity * step
		remaining -= step
	get_parent().scale = _base * _shape
