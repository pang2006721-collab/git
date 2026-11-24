extends Node2D
## 沿海底上升路线依次遭遇，世界高度固定，不按镜头时间补刷。
signal ink_sprayed
signal appeared(octopus: Node2D)
@export var spawn_interval: float = 1.5
@export var encounter_spacing: float = 2500.0
@export var first_encounter_distance: float = 900.0
@export var enabled: bool = false:
    set(value):
        if enabled == value: return
        enabled = value
        if is_node_ready(): reset()
var spawn_allowed: bool = true
var target: CharacterBody2D
var camera: Camera2D
var cycle_elapsed: float = 0.0
var _previous_player_y: float = 0.0
var _side: int = 1
var _finishing_visit: bool = false
var _next_encounter_y: float = INF
@onready var visitors: Array[Node] = get_children()

func _ready() -> void:
    for visitor in visitors:
        visitor.ink_sprayed.connect(func(): ink_sprayed.emit())
    reset()

func configure(player: CharacterBody2D, view: Camera2D) -> void:
    target = player
    camera = view
    _previous_player_y = player.global_position.y
    for visitor in visitors: visitor.configure(player,view)

func _physics_process(delta: float) -> void:
    if not enabled or not spawn_allowed or _finishing_visit or not is_instance_valid(target): return
    if is_inf(_next_encounter_y):
        _next_encounter_y = target.global_position.y-first_encounter_distance
    cycle_elapsed = minf(cycle_elapsed+delta,spawn_interval)
    var rising := target.global_position.y<_previous_player_y-.01
    _previous_player_y = target.global_position.y
    if not rising: return
    var view: Rect2 = visitors[0]._view_rect()
    # 快捷切段或大幅瞬移越过的遭遇点直接跳过，绝不在玩家身后补刷。
    while _next_encounter_y > view.position.y+80:
        _next_encounter_y -= encounter_spacing
    if view.position.y > _next_encounter_y+150 or cycle_elapsed < spawn_interval: return
    for visitor in visitors:
        if not visitor.is_available(): continue
        visitor.enabled = true
        visitor._side = _side
        var x := clampf(target.global_position.x+float(_side)*180,view.position.x+140,view.end.x-140)
        visitor._appear(Vector2(x,_next_encounter_y))
        _side = -_side
        _next_encounter_y -= encounter_spacing
        cycle_elapsed = 0
        appeared.emit(visitor)
        return

func finish_current_visit() -> void:
    _finishing_visit = true
    process_mode = Node.PROCESS_MODE_ALWAYS
    for visitor in visitors: visitor.finish_current_visit()

func reset() -> void:
    spawn_allowed = true
    cycle_elapsed = spawn_interval
    _side = 1
    _next_encounter_y = INF
    _finishing_visit = false
    process_mode = Node.PROCESS_MODE_INHERIT
    if is_instance_valid(target): _previous_player_y = target.global_position.y
    for visitor in visitors:
        visitor.enabled = false
        visitor.reset()
