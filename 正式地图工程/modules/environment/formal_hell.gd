extends Node2D
## 正式地狱组装；沿用原角色、附身控制器及附身运镜。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
signal died
var exit_in_progress: bool = false
var dead: bool = false
var death_reason: StringName = &"impact"
var _demon_spawn: Vector2
var _ghost_spawn: Vector2
var _zzz_origin: Vector2
@onready var soul: CharacterBody2D = $Soul
@onready var demon: CharacterBody2D = $Demon
@onready var camera: FollowCamera = $Camera
@onready var possession: PossessionController = $Possession
var awake: bool = false
var sleeping: Sprite2D
var zzz: Sprite2D
var elapsed: float = 0.0
var platforms: Array = []
var player: CharacterBody2D

func _ready() -> void:
	preload("res://modules/ui/authored_cursor.gd").apply()
	player = soul
	_demon_spawn = demon.position
	var surface: Vector2 = SURFACE.top_at($Ground/Collision,demon.global_position.x)
	if is_finite(surface.y):
		_demon_spawn.y = to_local(surface).y
	demon.position = _demon_spawn
	_ghost_spawn = $LandingPoint.position
	var ghost_surface: Vector2 = SURFACE.top_at($Ground/Collision,$LandingPoint.global_position.x)
	if is_finite(ghost_surface.y):
		_ghost_spawn.y = to_local(ghost_surface).y
	soul.z_index = 15
	demon.z_index = 15
	soul.add_to_group("hell_players")
	demon.add_to_group("hell_players")
	demon.get_node("Patrol").process_mode = Node.PROCESS_MODE_DISABLED
	demon.get_node("Movement").enabled = false
	demon.get_node("Input").enabled = false
	possession.enabled = false
	possession.selection_radius = 220.0
	possession.possession_finished.connect(func(_host): player = demon)
	for body in [soul, demon]:
		body.get_node("Movement").landed.connect(camera.add_landing_impulse)
	demon.get_node("Visual/Sprite").texture = load("res://assets/art/hell/new/right.png")
	demon.get_node("Visual/Sprite").position = Vector2(0, -57.5)
	sleeping = $Demon/Sleeping
	zzz = $Demon/SleepLetters
	_zzz_origin = zzz.position
	demon.get_node("Visual").hide()
	platforms = $Platforms.get_children()
	for area in $Hazards.get_children():
		area.body_entered.connect(func(body):
			if body == player:
				die.call_deferred())
	$WallEntry.control_ready.connect(func():
		camera.set_follow_target(soul)
		if get_parent() == get_tree().root:
			camera.set_process(true))
	if get_parent() == get_tree().root:
		camera.enabled = true
		camera.global_position = to_global(Vector2(960, 51540))
		$WallEntry.play()

func _physics_process(delta: float) -> void:
	if dead or exit_in_progress:
		return
	elapsed += delta
	zzz.position = _zzz_origin - Vector2(0,fmod(elapsed*12,22))
	zzz.modulate.a = 1.0 - fmod(elapsed, 2.0) * 0.35
	if not awake and $WallEntry.completed and soul.global_position.distance_to(demon.global_position) < 220.0:
		awake = true
		sleeping.hide()
		zzz.hide()
		demon.get_node("Visual").show()
		possession.enabled = true
	if player.position.y > 52120:
		die(&"fall")

func die(reason: StringName = &"impact") -> void:
	if dead or exit_in_progress or not visible or not $WallEntry.completed:
		return
	if $Checkpoint.grace_remaining > 0.0 or $OceanCheckpoint.grace_remaining > 0.0 or $JungleCheckpoint.grace_remaining > 0.0:
		return
	var teleport := player.get_node_or_null("Teleport")
	if teleport != null and teleport.is_invulnerable():
		return
	dead = true
	death_reason = reason
	died.emit()

func restart() -> void:
	$RouteReveal.reset(true)
	$LavaRiseReveal.reset()
	$RisingLava.reset()
	$OceanLink.reset()
	dead = false
	death_reason = &"impact"
	$Fork.reset()
	$FlyingEnemies.reset()
	possession.reset()
	demon.get_node("Host").reset()
	demon.get_node("Patrol").process_mode = Node.PROCESS_MODE_DISABLED
	demon.get_node("Movement").enabled = false
	demon.get_node("Input").enabled = false
	demon.get_node("Input").clear()
	demon.position = _demon_spawn
	soul.position = _ghost_spawn
	player = soul
	awake = false
	possession.enabled = false
	sleeping.show()
	zzz.show()
	demon.get_node("Visual").hide()
	for platform in platforms:
		platform.reset()
	camera.set_follow_target(soul, true)

func get_active_checkpoint() -> Node2D:
	if $JungleCheckpoint.active: return $JungleCheckpoint
	if $OceanCheckpoint.active: return $OceanCheckpoint
	if $Checkpoint.active: return $Checkpoint
	return null
