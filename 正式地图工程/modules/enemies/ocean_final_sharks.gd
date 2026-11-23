extends Node2D
## 海面前的一次三鲨齐袭；复用细长鲨鱼原画、蓄力和固定方向冲刺。
signal player_hit(direction: Vector2)
signal attack_started
@export var trigger_depth: float = 1100.0
@export var lock_seconds: float = 1.0
var triggered: bool = false
var finished: bool = false
@onready var stage: Node2D = get_parent()
@onready var fish: CharacterBody2D = stage.get_node("Fish")
@onready var sharks: Array[Node] = get_children()

func _ready() -> void:
    var level := get_node("../../..")
    for shark in sharks:
        shark.configure(fish,level.get_node("Camera"))
        shark.player_hit.connect(func(direction: Vector2): player_hit.emit(direction))
    level.died.connect(_on_death)

func _physics_process(_delta: float) -> void:
    if not stage.active or stage.level.dead or stage.level.exit_in_progress or stage.level.player!=fish or not stage.host.claimed: return
    var shore := stage.get_node("ShoreExit")
    if shore.state!=shore.State.SWIMMING:
        if triggered and not finished:
            _cancel()
            finished=true
        return
    if triggered:
        if not finished and sharks.all(func(shark): return shark.state==shark.State.WAITING): finished=true
        return
    var depth: float = fish.position.y-shore.surface_y
    if depth>trigger_depth or depth<80.0 or fish.velocity.y>-40.0: return
    triggered = true
    for shark in sharks:
        shark.lock_seconds = lock_seconds
        shark.enabled = true
        shark._begin_lock()
    attack_started.emit()

func _cancel() -> void:
    for shark in sharks: shark.cancel_pending_attack()

func _on_death() -> void:
    _cancel()

func reset() -> void:
    _cancel()
    triggered=false
    finished=false
