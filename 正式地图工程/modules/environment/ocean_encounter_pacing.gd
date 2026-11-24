extends Node
## 前期粉红鲨、中段章鱼、后段追击鲨；只安排时机，不改敌人的动作与地图。
@export var pink_zone_top: float=36200.0
@export var middle_zone_top: float=34000.0
@export var pink_heights:=PackedFloat32Array([37900,36700])
@export var recovery_rest_seconds: float=1.25
@export var checkpoint_rest_seconds: float=2.5
@export var checkpoint_safe_radius: float=360.0
@export var showcase_seconds: float=2.0
var rest_remaining: float=0.0
var showcase_remaining: float=0.0
var side_tentacle_allowed: bool=false
@onready var stage: Node2D=get_parent()
@onready var level: Node2D=get_node("../../..")
@onready var fish: CharacterBody2D=get_node("../Fish")
@onready var shark: Node2D=get_node("../Shark")
@onready var pink: Node2D=get_node("../PinkSharks")
@onready var octopus: Node2D=get_node("../Octopus")
@onready var ink: CanvasLayer=get_node("../InkOverlay")
@onready var net: Node2D=get_node("../BossTentacleNet")
@onready var boss: Node2D=get_node("../JellyfishBoss")
@onready var final: Node2D=get_node("../FinalSharks")
@onready var checkpoint: Node2D=level.get_node("OceanCheckpoint")

func _ready() -> void:
    var lanes:=pink.get_children()
    for i in mini(lanes.size(),pink_heights.size()):
        lanes[i].global_position.y=level.to_global(Vector2(0,pink_heights[i])).y
    fish.get_node("Stun").stunned.connect(func(): request_rest(fish.get_node("Stun").stun_seconds+recovery_rest_seconds))
    fish.get_node("Stun").recovered.connect(func(): request_rest(recovery_rest_seconds))
    boss.appeared.connect(func(): showcase_remaining=showcase_seconds)
    checkpoint.activated.connect(func(): request_rest(checkpoint_rest_seconds))

func request_rest(seconds: float) -> void:
    rest_remaining=maxf(rest_remaining,seconds)

func _protected() -> bool:
    var stun:=fish.get_node("Stun")
    var safe_checkpoint: bool=checkpoint.active and fish.global_position.distance_to(checkpoint.global_position)<checkpoint_safe_radius
    return rest_remaining>0 or showcase_remaining>0 or stun.stun_remaining>0 or stun.dizzy_remaining>0 or checkpoint.grace_remaining>0 or safe_checkpoint

func damage_allowed() -> bool:
    if stage.get_node("ShoreExit").state!=stage.get_node("ShoreExit").State.SWIMMING: return false
    return stage.active and stage.host.claimed and level.player==fish and not level.dead and not level.exit_in_progress and not _protected() and not ink.visible

func can_start_final() -> bool:
    return damage_allowed()

func prepare_final() -> void:
    shark.cancel_pending_attack()
    for lane in pink.get_children(): lane.reset()
    octopus.enabled=false
    ink.reset()
    net.enabled=false
    net.reset()
    stage.get_node("SideTentacle").reset()
    side_tentacle_allowed=false

func update(delta: float,can_attack: bool,y: float) -> void:
    if level.dead: return
    rest_remaining=maxf(0,rest_remaining-delta)
    showcase_remaining=maxf(0,showcase_remaining-delta)
    var final_phase: bool=final.triggered
    var blocked: bool=_protected()
    var screen_clear: bool=not ink.visible
    var early: bool=y>=pink_zone_top
    var middle: bool=y<pink_zone_top and y>=middle_zone_top
    var late: bool=y<middle_zone_top and fish.position.y>stage.get_node("ShoreExit").surface_y+stage.shark_surface_safe_depth
    boss.enabled=can_attack
    # 两段早期横游；离开该段就清理队列，已入场的鲨鱼在短暂停顿时继续游但不伤人。
    var lanes:=pink.get_children()
    for i in lanes.size():
        var use_lane: bool=i<pink_heights.size() and early and can_attack and not final_phase
        if not use_lane:
            if lanes[i].running or lanes[i].started: lanes[i].reset()
        else:
            lanes[i].running=true
            lanes[i].damage_enabled=not blocked and screen_clear
    # 喷墨和访客仍在场时不追加新的访客或追击。
    octopus.enabled=can_attack and middle and not final_phase
    octopus.spawn_allowed=not blocked and screen_clear and not octopus.visitors.any(func(visitor): return visitor.state!=visitor.State.WAITING)
    var octopus_busy: bool=octopus.visitors.any(func(visitor): return visitor.state!=visitor.State.WAITING)
    shark.enabled=can_attack and late and not final_phase and not blocked and screen_clear and not octopus_busy
    if (not late or final_phase or blocked or not screen_clear) and shark.state!=shark.State.WAITING:
        shark.cancel_pending_attack()
    # 水母是全程压力，不随粉红鲨/章鱼/追击鲨的分段或访客入场而停攻。
    # 墨汁期间仍有预警和障碍，但命中回调沿用保护，避免盲视连续受罚。
    net.enabled=can_attack and not blocked and not final_phase
    if not net.enabled and not net.rows.is_empty(): net.reset()
    side_tentacle_allowed=can_attack and not blocked and screen_clear and not final_phase and shark.state==shark.State.WAITING and not octopus_busy
    if not can_attack: ink.reset()

func reset() -> void:
    rest_remaining=0
    showcase_remaining=0
    side_tentacle_allowed=false
