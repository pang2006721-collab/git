extends PlatformerInput
## 天空阶段只用 W 扇翅，保持按下边沿触发。
func _ready() -> void:
	_bind_default(&"flap",[KEY_W])
	super._ready()
