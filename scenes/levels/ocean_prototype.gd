extends Node2D
signal round_restarted
## Drowning demon -> the shared soul transfer -> fish. No camera or drowning logic here.

@export var spawn_position: Vector2 = Vector2(1290, 2838)
@export var demon_spawn_position: Vector2 = Vector2(700, 3050)
@onready var fish: CharacterBody2D = $Fish
@onready var motor: SwimMotor = $Fish/Movement
@onready var reader: SwimInput = $Fish/Input
@onready var visual: SwimVisual = $Fish/Visual
@onready var camera: FollowCamera = $FollowCamera
@onready var demon: CharacterBody2D = $UnderwaterDemon
@onready var soul: CharacterBody2D = $Soul
@onready var drowning: DrowningSource = $UnderwaterDemon/Drowning
@onready var host: PossessableHost = $Fish/Host
@onready var possession: PossessionController = $Possession
@onready var launch: VolcanoLaunch = $VolcanoLaunch
@onready var shore: FishShoreExit = $ShoreExit
@onready var jungle: Node2D = $Jungle

var player: CharacterBody2D
var failed: bool = false


func _ready() -> void:
	# Respect positions edited in the scene when restarting.
	spawn_position = fish.position
	demon_spawn_position = demon.position
	player = demon
	possession.possession_started.connect(_on_possession_started)
	possession.possession_finished.connect(_on_possession_finished)
	drowning.drowned.connect(_on_drowned)
	drowning.vanished.connect(_on_demon_vanished)
	launch.finished.connect(_on_launch_finished)
	_start_launch()
	jungle.configure(fish,shore,$Shore/Bank/Collision,$Shore/Art,camera)
	jungle.squirrel.process_mode=Node.PROCESS_MODE_PAUSABLE
	$Shore/Bank.process_mode=Node.PROCESS_MODE_PAUSABLE
	jungle.squirrel_possessed.connect(func(body): player=body)
	var end := camera.world_bounds.end
	camera.world_bounds.position.y = minf(camera.world_bounds.position.y,jungle.global_position.y)
	camera.world_bounds.size.y = end.y-camera.world_bounds.position.y


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart") and not event.is_echo():
		restart()


func restart() -> void:
	jungle.reset()
	possession.reset()
	fish.position = spawn_position
	demon.position = demon_spawn_position
	shore.reset()
	host.reset()
	drowning.reset()
	player = demon
	failed = false
	_start_launch()
	camera.set_follow_target(demon)
	camera.snap_to_target()
	$Background.reset_reference()
	$Foreground.reset_reference()
	round_restarted.emit()


func _start_launch() -> void:
	possession.enabled = false
	possession.clear_selection()
	launch.start(demon_spawn_position)


func _on_launch_finished() -> void:
	possession.enabled = true


func _on_possession_started(_chosen_host: PossessableHost) -> void:
	drowning.release_soul()


func _on_possession_finished(chosen_host: PossessableHost) -> void:
	player = chosen_host.body


func _on_drowned() -> void:
	failed = true
	possession.enabled = false
	possession.clear_selection()


func _on_demon_vanished(from_timeout: bool) -> void:
	if from_timeout and failed:
		restart.call_deferred()
