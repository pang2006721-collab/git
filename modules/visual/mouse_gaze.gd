extends Node2D
## 鼠标转换到脸部局部坐标，限定眼睛位移，保持五官在脸内。
@export var eye_travel := Vector2(7, 4)
@export var gaze_distance: float = 250.0
@onready var _eye_origin: Vector2 = $Eyes.position
@onready var _brow_origin: Vector2 = $Brows.position
func _process(delta: float) -> void:
	var gaze := ((get_local_mouse_position() - _eye_origin) / gaze_distance).limit_length(1.0) * eye_travel
	$Eyes.position = $Eyes.position.lerp(_eye_origin + gaze, 1.0 - exp(-15.0 * delta))
	$Brows.position = $Brows.position.lerp(_brow_origin + Vector2(0, gaze.y * 0.18), 1.0 - exp(-12.0 * delta))
