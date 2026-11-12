extends Node
## 每次按键只产生一次上升冲量，持续按住不会自动扇翅。
@export var gravity: float = 1150.0
@export var flap_speed: float = 540.0
@export var move_speed: float = 430.0
@export var acceleration: float = 1500.0
@export var top_limit: float = -520.0
var enabled := true
var body: CharacterBody2D
var reader: PlatformerInput
signal flapped
func _ready() -> void:
	process_physics_priority=-10
	body=get_parent()
	reader=body.get_node("Input")
func _physics_process(delta: float) -> void:
	if not enabled:
		return
	body.velocity.x=move_toward(body.velocity.x,reader.move_axis*move_speed,acceleration*delta)
	body.velocity.y=minf(body.velocity.y+gravity*delta,850)
	if reader.jump_pressed:
		body.velocity.y=-flap_speed
		flapped.emit()
		reader.jump_pressed=false
	body.move_and_slide()
	body.position.y=maxf(body.position.y,top_limit)
func reset() -> void:
	if body!=null:
		body.velocity=Vector2.ZERO
