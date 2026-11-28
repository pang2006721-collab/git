extends Node2D
## 只连接原地图两个火山口，不加载旧海洋场景、平台或覆盖美术。
signal ocean_entered
signal eruption_finished
enum Stage { HELL, CAPTURING, TRAVELLING, ERUPTING, OCEAN }
@export var eruption_seconds: float = 0.7
@export var ocean_follow_blend_seconds: float = 0.65
var stage: Stage = Stage.HELL
var _eruption: Tween
var _motor_settings: Dictionary = {}
var _enemies_enabled: bool = true
@onready var level: Node2D = get_parent()
@onready var camera: FollowCamera = get_node("../Camera")
@onready var vortex: VortexExit = $Exit
@onready var transition: VerticalSceneTransition = $VerticalTransition
@onready var ocean_mouth: Marker2D = $OceanMouth

func _ready() -> void:
    _align_volcano_anchors_to_map()
    vortex.capture_started.connect(_capture)
    vortex.capture_finished.connect(_travel)
    transition.finished.connect(_arrive)

func _align_volcano_anchors_to_map() -> void:
    # 这三处坐标来自原地图；OceanLink 的编辑器位移只影响其余分段布局。
    for path in ["Exit","OceanMouth","OriginalSeabed","FishBottomBoundary"]:
        var node: Node2D=get_node(path)
        var authored: Transform2D=node.transform
        node.top_level=true
        node.global_transform=level.global_transform*authored

func _physics_process(_delta: float) -> void:
    if stage != Stage.HELL: return
    vortex.eligible_body = level.demon if level.player == level.demon and not level.dead and not level.exit_in_progress and level.demon.get_node("Host").claimed else null
    # 在口边重新起跳也能钻入，不依赖首次进入 Area 的事件。
    for body in vortex.get_overlapping_bodies():
        if vortex.try_capture(body): break

func _capture(body: CharacterBody2D) -> void:
    stage = Stage.CAPTURING
    level.exit_in_progress = true
    var zoom_before := camera.zoom
    level.possession.shot.cancel()
    camera.zoom = zoom_before
    var rig = level.get_node("Fork")
    rig.reset()
    rig.set_physics_process(false)
    rig.set_process_unhandled_input(false)
    level.possession.enabled = false
    level.get_node("CameraAttention").enabled = false
    var enemies = level.get_node("FlyingEnemies")
    _enemies_enabled = enemies.enabled
    enemies.begin_departure()
    var motor = body.get_node("Movement")
    for property in [&"move_speed", &"acceleration", &"braking", &"jump_speed", &"gravity", &"max_fall_speed", &"fast_fall_multiplier"]:
        _motor_settings[property] = motor.get(property)
    motor.enabled = false
    body.get_node("Input").enabled = false
    body.get_node("Input").clear()
    body.get_node("Visual").reset()
    body.get_node("Visual").position = Vector2.ZERO
    body.velocity = Vector2.ZERO
    camera.clear_impulse()
    transition.prepare(camera, camera.zoom)

func _travel(body: CharacterBody2D) -> void:
    stage = Stage.TRAVELLING
    body.get_node("Visual").hide()
    transition.travel(camera,ocean_mouth.global_position+Vector2(0,-300))

func _arrive() -> void:
    stage = Stage.ERUPTING
    ocean_entered.emit()
    Bgm.play_track(Bgm.Track.OCEAN)
    var visual = level.demon.get_node("Visual")
    visual.rotation = 0.0
    visual.modulate = Color.WHITE
    $Breath.start()
    visual.show()
    _sample_eruption(0.0)
    _eruption = create_tween()
    _eruption.tween_method(_sample_eruption,0.0,1.0,eruption_seconds)
    _eruption.tween_callback(_finish_eruption)

func _sample_eruption(u: float) -> void:
    var body = level.demon
    var visual = body.get_node("Visual")
    body.global_position = ocean_mouth.global_position+Vector2(0,80.0-440.0*u+120.0*u*u)
    var amount := lerpf(0.06,1.0,ease(minf(u/.45,1.0),0.4))
    visual.scale = Vector2.ONE*amount
    visual.position = visual.get_node("Sprite").position*(1.0-amount)
    visual.modulate.a = smoothstep(0.0,.18,u)

func _finish_eruption() -> void:
    stage = Stage.OCEAN
    level.exit_in_progress = false
    var body = level.demon
    body.reset_physics_interpolation()
    var visual = body.get_node("Visual")
    visual.reset()
    visual.position = Vector2.ZERO
    visual.set_process(true)
    var motor = body.get_node("Movement")
    motor.move_speed = 110.0
    motor.acceleration = 360.0
    motor.braking = 600.0
    motor.jump_speed = 160.0
    motor.gravity = 180.0
    motor.max_fall_speed = 120.0
    motor.fast_fall_multiplier = 1.2
    body.velocity = Vector2(0,-100)
    motor.enabled = true
    body.get_node("Input").enabled = true
    camera.resume_follow_from_current_position(body)
    camera.set_process(true)
    $FishStage.activate()
    # 喷出时镜头静止，交还控制后从零位移渐进跟随，避免第一帧突然追赶。
    camera.blend_to_target(body,ocean_follow_blend_seconds)
    eruption_finished.emit()

func reset() -> void:
    $FishStage.reset()
    $Breath.reset()
    if stage == Stage.HELL: return
    if _eruption != null: _eruption.kill()
    transition.cancel()
    vortex.reset()
    var motor = level.demon.get_node("Movement")
    for property in _motor_settings: motor.set(property,_motor_settings[property])
    _motor_settings.clear()
    level.exit_in_progress = false
    level.get_node("FlyingEnemies").enabled = _enemies_enabled
    level.get_node("CameraAttention").enabled = true
    level.get_node("Fork").set_physics_process(true)
    level.get_node("Fork").set_process_unhandled_input(true)
    stage = Stage.HELL
