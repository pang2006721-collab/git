extends Node2D
## Hell, connecting earth strata and ocean share one world and one gameplay camera.
enum Stage { HELL, TRANSITION, OCEAN }
const HELL = preload("res://scenes/levels/hell_prototype.tscn")
const OCEAN = preload("res://scenes/levels/ocean_prototype.tscn")
const CAMERA = preload("res://modules/camera/follow_camera.gd")
@export var ocean_origin: Vector2 = Vector2(0, -5794.59375)
@export var ocean_scale: float = 1.03125
var stage: Stage = Stage.HELL
var hell: Node2D
var ocean: Node2D
var camera: FollowCamera
@onready var transition: VerticalSceneTransition = $VerticalTransition
@onready var impact: CameraImpact = $CameraImpact

func _ready() -> void:
	transition.finished.connect(_finish_transition)
	start_hell()

func _input(event: InputEvent) -> void:
	if stage == Stage.TRANSITION and event.is_action_pressed(&"restart") and not event.is_echo():
		start_hell()
		get_viewport().set_input_as_handled()

func start_hell() -> void:
	transition.cancel()
	impact.reset()
	for old_level in [hell, ocean]:
		if is_instance_valid(old_level):
			remove_child(old_level)
			old_level.queue_free()
	hell = HELL.instantiate()
	hell.restart_after_exit = false
	add_child(hell)
	hell.exit_completed.connect(_begin_transition)
	hell.vortex.capture_started.connect(_prepare_transition)
	hell.round_restarted.connect(transition.cancel)
	hell.round_restarted.connect(impact.reset)
	hell.camera.enabled = false
	ocean = OCEAN.instantiate()
	ocean.position = ocean_origin
	ocean.scale = Vector2.ONE * ocean_scale
	var sea_camera: FollowCamera = ocean.get_node("FollowCamera")
	sea_camera.world_bounds = Rect2(ocean_origin + sea_camera.world_bounds.position * ocean_scale, sea_camera.world_bounds.size * ocean_scale)
	ocean.process_mode = Node.PROCESS_MODE_DISABLED
	# 鱼的巡游先独立运行，让镜头进入海底时就能看到活动中的生物。
	# 海底其他逻辑继续等待镜头到达，避免提前喷出或消耗恶魔的憋气时间。
	ocean.get_node("Fish").process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ocean)
	ocean.launch.erupted.connect(impact.kick_up)
	ocean.round_restarted.connect(impact.reset)
	ocean.camera.enabled = false
	if not is_instance_valid(camera):
		camera = CAMERA.new()
		camera.name = "WorldCamera"
		camera.target_path = hell.soul.get_path()
		add_child(camera)
	_use_map_camera_settings(hell, Vector2.ZERO)
	_wire_camera(hell)
	_wire_camera(ocean)
	impact.camera = camera
	camera.set_follow_target(hell.soul, true)
	camera.enabled = true
	camera.make_current()
	_reset_parallax(hell)
	_reset_parallax(ocean)
	stage = Stage.HELL

func _wire_camera(level: Node2D) -> void:
	level.camera = camera
	level.possession.camera = camera
	level.possession.shot._camera = camera
	level.get_node("Background")._camera = camera
	level.get_node("Foreground")._camera = camera
	level.get_node("Background").align_vertical_edges = true
	level.get_node("Foreground").align_vertical_edges = true
	level.get_node("Foreground/Art").scale = Vector2.ONE
	if level==ocean:
		level.jungle.set_camera(camera)

func _use_map_camera_settings(level: Node2D, origin: Vector2) -> void:
	var settings: FollowCamera = level.get_node("FollowCamera")
	for property in [&"framing_offset", &"dead_zone", &"follow_speed", &"horizontal_look_ahead", &"upward_look_ahead", &"max_impulse_pixels", &"impulse_decay"]:
		camera.set(property, settings.get(property))
	camera.world_bounds = settings.world_bounds if level == ocean else Rect2(origin, settings.world_bounds.size)

func _reset_parallax(level: Node2D) -> void:
	level.get_node("Background").reset_reference()
	level.get_node("Foreground").reset_reference()

func _prepare_transition(_body: CharacterBody2D) -> void:
	var entry_zoom := camera.zoom
	hell.possession.shot.cancel()
	var normal_zoom := camera.zoom
	camera.zoom = entry_zoom
	camera.set_follow_target(hell.demon)
	transition.prepare(camera, normal_zoom)

func _begin_transition() -> void:
	if stage != Stage.HELL:
		return
	stage = Stage.TRANSITION
	hell.process_mode = Node.PROCESS_MODE_DISABLED
	# Keep resolving parallax across the seam instead of resetting the artwork.
	for layer_name in ["Background", "Foreground"]:
		hell.get_node(layer_name).process_mode = Node.PROCESS_MODE_ALWAYS
	var half_view := get_viewport_rect().size * 0.5 / transition.rest_zoom
	var destination := ocean_origin + Vector2(960 * ocean_scale, 3240 * ocean_scale - half_view.y)
	transition.travel(camera, destination)

func _finish_transition() -> void:
	stage = Stage.OCEAN
	_use_map_camera_settings(ocean, ocean_origin)
	camera.resume_follow_from_current_position(ocean.demon)
	camera.set_process(true)
	_reset_parallax(ocean)
	ocean.get_node("Background").set_process(true)
	ocean.get_node("Foreground").set_process(true)
	ocean.process_mode = Node.PROCESS_MODE_INHERIT
	ocean.fish.process_mode = Node.PROCESS_MODE_INHERIT
	remove_child(hell)
	hell.queue_free()
	hell = null
