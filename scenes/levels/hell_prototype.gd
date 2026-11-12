extends Node2D
## Level wiring only: ghost -> possession -> climbing -> vortex -> fresh round.

signal prototype_finished
signal exit_completed
signal round_restarted

@export var restart_after_exit: bool = true

@export var spawn_position: Vector2 = Vector2(780, 3110)
@export var demon_spawn_position: Vector2 = Vector2(1100, 2812)
@export var respawn_below_y: float = 3400.0

@onready var player: CharacterBody2D = $Soul
@onready var soul: CharacterBody2D = $Soul
@onready var demon: CharacterBody2D = $Demon
@onready var motor: PlatformerMotor = $Demon/Movement
@onready var reader: PlatformerInput = $Demon/Input
@onready var visual: SquashStretch = $Demon/Visual
@onready var camera: FollowCamera = $FollowCamera
@onready var possession: PossessionController = $Possession
@onready var host: PossessableHost = $Demon/Host
@onready var vortex: VortexExit = $Exit

var finished: bool = false
var rounds_completed: int = 0


func _ready() -> void:
	motor.landed.connect(camera.add_landing_impulse)
	possession.possession_finished.connect(_on_possession_finished)
	vortex.capture_started.connect(_on_capture_started)
	vortex.capture_finished.connect(_on_capture_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart") and not event.is_echo():
		restart()


func _physics_process(_delta: float) -> void:
	if player.position.y > respawn_below_y:
		restart()


func restart() -> void:
	finished = false
	vortex.reset()
	soul.position = spawn_position
	demon.position = demon_spawn_position
	host.reset()
	possession.reset()
	player = soul
	camera.snap_to_target()
	$Background.reset_reference()
	$Foreground.reset_reference()
	round_restarted.emit()


func _on_possession_finished(chosen_host: PossessableHost) -> void:
	player = chosen_host.body
	vortex.eligible_body = player


func _on_capture_started(_body: CharacterBody2D) -> void:
	finished = true
	reader.enabled = false
	reader.external_control = true
	reader.clear()
	motor.enabled = false
	demon.velocity = Vector2.ZERO
	prototype_finished.emit()


func _on_capture_finished(_body: CharacterBody2D) -> void:
	rounds_completed += 1
	if restart_after_exit:
		restart.call_deferred()
	else:
		exit_completed.emit()
