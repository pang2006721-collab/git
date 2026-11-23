extends Node2D
## 接触激活的固定重生点；美术直接使用原画裁切，状态只保留在本局。
signal activated
const SURFACE = preload("res://modules/environment/hell_surface.gd")
@export_node_path("AnimatableBody2D") var platform_path: NodePath = ^"../Platforms/Static04"
@export var lift_height: float = 55.0
@export var lift_seconds: float = 0.45
@export var bob_height: float = 8.0
@export var bob_period: float = 2.0
@export var respawn_grace_seconds: float = 1.2
var active: bool = false
var grace_remaining: float = 0.0
var _elapsed: float = 0.0
var _lift: float = 0.0
var _origin: Vector2
@onready var level: Node2D = get_parent()
@onready var diamond: Sprite2D = $Diamond

func _ready() -> void:
    var platform := get_node(platform_path) as Node2D
    # 使用选中平台的主表面；同一节点的上方另有平台，不能取最高碰撞。
    global_position = SURFACE.top_at(platform.get_node("Collision"),platform.global_position.x)+Vector2(0,3)
    _origin = diamond.position
    $Touch.body_entered.connect(_on_touch)
    $Rays.hide()

func _on_touch(body: Node2D) -> void:
    if active or level.dead or level.exit_in_progress: return
    if body != level.player or body != level.demon or not body.get_node("Host").claimed: return
    active = true
    _elapsed = 0.0
    activated.emit()

func _process(delta: float) -> void:
    grace_remaining = maxf(0.0, grace_remaining-delta)
    if not active: return
    _elapsed += delta
    var u := clampf(_elapsed/lift_seconds,0.0,1.0)
    _lift = 1.0-pow(1.0-u,3.0)
    diamond.position = _origin+Vector2(0,-lift_height*_lift+sin(maxf(0.0,_elapsed-lift_seconds)*TAU/bob_period)*bob_height*_lift)
    $Rays.visible = _elapsed < 0.75
    $Rays.modulate.a = clampf(1.0-_elapsed/0.75,0.0,1.0)

func restore_player() -> void:
    # 调用方先重置整关；在冻结期间准备角色，回程结束后才恢复输入。
    var body: CharacterBody2D = level.demon
    level.get_node("WallEntry").completed = true
    level.soul.hide()
    level.awake = true
    level.sleeping.hide()
    level.zzz.hide()
    body.show()
    body.get_node("Visual").show()
    body.get_node("Host").take_control()
    body.get_node("Patrol").process_mode = Node.PROCESS_MODE_DISABLED
    level.player = body
    level.possession.state = PossessionController.State.POSSESSED
    level.possession.enabled = false
    body.global_position = $Spawn.global_position
    body.velocity = Vector2.ZERO
    body.reset_physics_interpolation()
    level.get_node("RisingLava").start_at_checkpoint(body)
    level.camera.zoom = Vector2.ONE*1.35
    level.camera.framing_bias = Vector2.ZERO
    level.camera.set_follow_target(body,true)
    Bgm.play_track(Bgm.Track.HELL)

func finish_return() -> void:
    grace_remaining = respawn_grace_seconds
