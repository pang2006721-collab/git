extends Node2D
## 右墙嵌入的海底重生点；接近弹出钻石、撑开原画气泡。
signal activated
@export var world_height: float = 32300.0
@export var embedded_depth: float = 10.0
@export var trigger_distance: float = 190.0
@export var pop_distance: float = 155.0
@export var bob_height: float = 7.0
@export var respawn_grace_seconds: float = 1.5
var active: bool = false
var grace_remaining: float = 0.0
var _opening: bool = false
var _elapsed: float = 0.0
var _motion: Tween
@onready var level: Node2D = get_parent()
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")
@onready var rig: Node2D = $Float

func _ready() -> void:
    # 读取原墙面真实透明边缘，不移动地图边界，也不补画墙体。
    var walls: Sprite2D = level.get_node("WorldLayers/OceanWalls")
    var source := walls.texture.get_image()
    var point := walls.to_local(level.to_global(Vector2(960,world_height)))
    var row := clampi(roundi(point.y),0,source.get_height()-1)
    for x in range(source.get_width()/2,source.get_width()):
        if source.get_pixel(x,row).a > 0.5:
            global_position = walls.to_global(Vector2(x,row))+Vector2(embedded_depth,0)
            break
    $Float/Bubble.hide()

func _physics_process(_delta: float) -> void:
    if active or not stage.active or not stage.host.claimed or level.player!=stage.fish or level.dead or level.exit_in_progress: return
    if stage.fish.global_position.distance_to(global_position) <= trigger_distance: activate()

func activate() -> void:
    if active: return
    active = true
    _opening = true
    $Float/Bubble.show()
    $Float/Bubble.scale = Vector2.ONE*0.01
    _motion = create_tween().set_parallel(true)
    _motion.tween_property(rig,"position",Vector2(-pop_distance,0),0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _motion.tween_property($Float/Diamond,"rotation",0.0,0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _motion.tween_property($Float/Bubble,"scale",Vector2.ONE,0.55).set_delay(0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    _motion.chain().tween_callback(func(): _opening=false)
    activated.emit()

func _process(delta: float) -> void:
    grace_remaining = maxf(0.0,grace_remaining-delta)
    if not active or _opening: return
    _elapsed += delta
    rig.position = Vector2(-pop_distance,sin(_elapsed*TAU/2.4)*bob_height)

func restore_player() -> void:
    # 死亡流程已重置全关；只恢复海底游泳宿主，不重放洞口、喷发和附身过场。
    level.get_node("WallEntry").completed = true
    level.soul.hide()
    level.demon.hide()
    level.sleeping.hide()
    level.zzz.hide()
    level.awake = true
    level.possession.enabled = false
    level.get_node("CameraAttention").enabled = false
    level.get_node("FlyingEnemies").enabled = false
    level.get_node("Fork").set_physics_process(false)
    level.get_node("Fork").set_process_unhandled_input(false)
    var link := level.get_node("OceanLink")
    link.stage = link.Stage.OCEAN
    stage.activate()
    stage.fish.global_position = global_position+Vector2(-pop_distance,0)
    stage.fish.reset_physics_interpolation()
    stage.host.take_control()
    stage.possession.state = PossessionController.State.POSSESSED
    stage.possession.enabled = false
    stage._on_transfer_finished(stage.host)
    stage.get_node("SideTentacle")._cooldown = respawn_grace_seconds
    level.camera.zoom = Vector2.ONE*1.35
    level.camera.framing_bias = Vector2.ZERO
    level.camera.set_follow_target(stage.fish,true)
    Bgm.play_track(Bgm.Track.OCEAN)

func finish_return() -> void:
    grace_remaining = respawn_grace_seconds
    stage.fish.get_node("Stun").protection_remaining = respawn_grace_seconds
