extends Node
## AI 使用同一扇翅模块，以普通飞行动作巡游，不直接播放位置动画。
@export var patrol_radius := Vector2(270, 45)
@export var patrol_frequency := Vector2(0.65, 1.0)
var enabled := true
var center := Vector2.ZERO
var _time := 0.0
var _reader: PlatformerInput
var _body: CharacterBody2D
func _ready() -> void:
	process_physics_priority=-15
	_body=get_parent()
	_reader=_body.get_node("Input")
	center=_body.position
	start()
func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_time+=delta
	var target:=center+Vector2(sin(_time*patrol_frequency.x)*patrol_radius.x,sin(_time*patrol_frequency.y)*patrol_radius.y)
	_reader.move_axis=clampf((target.x-_body.position.x)*0.012,-0.55,0.55)
	_reader.jump_pressed=_body.position.y>target.y and _body.velocity.y>30
func stop() -> void:
	enabled=false
	_reader.clear()
func start() -> void:
	enabled=true
	_time=0
	_reader.external_control=true
	_reader.enabled=true
	_reader.clear()
