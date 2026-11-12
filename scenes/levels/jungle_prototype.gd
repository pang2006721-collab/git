extends Node2D
## 丛林保持独立场景；嵌入海底时，由岸边坐标对齐并从鱼交接附身。
signal squirrel_possessed(body: CharacterBody2D)
@export var shore_possession_radius: float = 180.0
@onready var squirrel: CharacterBody2D=$Squirrel
@onready var host: PossessableHost=$Squirrel/Host
@onready var climber: VineClimber=$Squirrel/VineClimber
@onready var possession: PossessionController=$Possession
@onready var camera: FollowCamera=$FollowCamera
var _spawn: Vector2
var _fish_status: FishShoreExit
var _standalone: bool=false
var sky_exit: Node2D
func _ready() -> void:
	sky_exit=$CanopySkyExit
	_spawn=squirrel.position
	possession.selection_radius=shore_possession_radius
	possession.possession_started.connect(_on_transfer_started)
	possession.possession_finished.connect(_on_transfer_finished)
	_standalone=not get_parent().has_method("_start_launch")
	if _standalone:
		var full_art:AtlasTexture=$Background.texture.duplicate()
		full_art.region.size.y=3240
		$Background.texture=full_art
		host.take_control()
		camera.set_follow_target(squirrel,true)
	else:
		camera.enabled=false
	sky_exit.camera=camera
	_extend_sky_bounds(camera)
func configure(fish: CharacterBody2D, status: FishShoreExit, bank: CollisionShape2D, shore_art: Sprite2D, shared_camera: FollowCamera) -> void:
	_fish_status=status
	# 以两张图里的沙地边界对齐；保留作者在编辑器中调整的岸边和碰撞。
	global_position=shore_art.to_global(Vector2(0,1906-2850))
	var bank_top:=bank.to_global(Vector2(0,-bank.shape.size.y*0.5))
	squirrel.position=Vector2(1080,to_local(bank_top).y)
	_spawn=squirrel.position
	$Ground/Collision.disabled=true
	set_camera(shared_camera)
	_extend_sky_bounds(shared_camera)
	possession.set_source_body(fish)
	status.landed_on_shore.connect(func(): possession.enabled=true)
	status.died_on_shore.connect(func():
		if possession.state==PossessionController.State.ROAMING:
			possession.enabled=false
			possession.clear_selection())
func set_camera(shared_camera: FollowCamera) -> void:
	sky_exit.camera=shared_camera
	possession.camera=shared_camera
	possession.shot._camera=shared_camera
func _on_transfer_started(_host: PossessableHost) -> void:
	_fish_status.release_soul()
func _on_transfer_finished(chosen: PossessableHost) -> void:
	squirrel_possessed.emit(chosen.body)
func _unhandled_input(event: InputEvent) -> void:
	if _standalone and event.is_action_pressed(&"restart") and not event.is_echo():
		reset()
		host.take_control()
		camera.set_follow_target(squirrel,true)
func reset() -> void:
	sky_exit.reset()
	climber.reset()
	possession.reset()
	possession.enabled=false
	squirrel.position=_spawn
	host.reset()
	for vine in $Vines.get_children():
		vine.reset()

func _extend_sky_bounds(shared_camera: FollowCamera) -> void:
	var bottom:=shared_camera.world_bounds.end.y
	shared_camera.world_bounds.position.y=minf(shared_camera.world_bounds.position.y,to_global(Vector2(0,-12720)).y)
	shared_camera.world_bounds.size.y=bottom-shared_camera.world_bounds.position.y
