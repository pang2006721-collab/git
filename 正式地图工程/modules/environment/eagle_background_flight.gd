extends Node
## 平滑的远景盘旋轨迹，与拍翅的轻弹独立。
@export var horizontal_radius: float = 260.0
@export var vertical_radius: float = 85.0
@export_range(2.0, 15.0) var cycle_seconds: float = 6.4
@export var shot_follow_rate: float = 2.4
var _center := Vector2.ZERO
var _clock: float = 0.0
func reset(anchor: Vector2) -> void:
    _center = anchor
    _clock = 0.0
func advance(delta: float, anchor: Vector2) -> Vector2:
    _clock += delta
    # Camera changes guide the flight area gradually, never pin the eagle to a pixel.
    _center = _center.lerp(anchor, 1.0 - exp(-shot_follow_rate * delta))
    var phase := _clock * TAU / maxf(cycle_seconds, 2.0)
    var entrance := smoothstep(0.0, 1.5, _clock)
    return _center + Vector2(sin(phase) * horizontal_radius, sin(phase * 2.0) * vertical_radius) * entrance
