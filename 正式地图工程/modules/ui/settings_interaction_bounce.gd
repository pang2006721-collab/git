extends Node
## 仅驱动美术形变，不缩放按钮或滑杆的交互范围。
var _motions: Dictionary = {}
var _last_pulse: Dictionary = {}
var pulse_count: int = 0

func pulse(art: Control, strength: float = 0.14, interval: float = 0.0) -> void:
	var now := Time.get_ticks_msec() * 0.001
	if now - float(_last_pulse.get(art, -100.0)) < interval: return
	_last_pulse[art] = now
	art.pivot_offset = art.size * 0.5
	_motions[art] = {"shape": 1.0 - strength, "speed": 0.0}
	pulse_count += 1
	_apply(art, 1.0 - strength)

func _apply(art: Control, shape: float) -> void:
	art.scale = Vector2(1.0 / shape, shape)

func _process(delta: float) -> void:
	for art in _motions.keys():
		if not is_instance_valid(art):
			_motions.erase(art)
			_last_pulse.erase(art)
			continue
		var motion: Dictionary = _motions[art]
		var remaining := minf(delta, 0.1)
		while remaining > 0.0:
			var step := minf(remaining, 1.0 / 240.0)
			motion.speed += ((1.0 - motion.shape) * 260.0 - motion.speed * 14.0) * step
			motion.shape += motion.speed * step
			remaining -= step
		_apply(art, motion.shape)
		if absf(motion.shape - 1.0) < 0.001 and absf(motion.speed) < 0.01:
			art.scale = Vector2.ONE
			_motions.erase(art)

func reset() -> void:
	for art in _motions:
		if is_instance_valid(art): art.scale = Vector2.ONE
	_motions.clear()
	_last_pulse.clear()
