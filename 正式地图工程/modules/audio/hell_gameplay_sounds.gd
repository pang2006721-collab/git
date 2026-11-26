extends Node
## 关卡只装配音效信号，脚步依据实际主角、落地和移动状态播放。
@onready var level: Node2D = get_parent()
var _awaiting_landing: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    level.died.connect(_on_death)
    level.get_node("Possession").possession_started.connect(_on_possession)
    level.get_node("Demon/Movement").jumped.connect(_on_jump)
    level.get_node("Demon/Movement").landed.connect(_on_landed)
    level.get_node("Fork").thrown.connect(func():Sfx.play(&"fork"))
    level.get_node("Fork").bounced.connect(_on_bounced)
    level.get_node("Fork").interaction_reset.connect(_on_interaction_reset)
    level.get_node("FlyingEnemies").fork_thrown.connect(func():Sfx.play(&"fork"))
    for platform in level.get_node("Platforms").get_children():
        if platform.has_signal("fractured"):
            platform.fractured.connect(_on_fracture.bind(platform))

func _hell_active() -> bool:
    return level.visible and not level.dead and not level.exit_in_progress and level.get_node("OceanLink").stage==0 and level.get_node("WallEntry").completed

func _physics_process(_delta: float) -> void:
    if Sfx.cinematic_running: return
    var cue: StringName = &""
    if _hell_active():
        var body: CharacterBody2D = level.player
        var motor: Node = body.get_node("Movement")
        if motor.enabled and body.is_visible_in_tree() and body.is_on_floor() and absf(body.velocity.x)>25:
            if body==level.demon and body.get_node("Host").claimed: cue = &"demon_run"
            elif body==level.soul: cue = &"ghost_run"
    Sfx.set_movement(cue)

func _on_possession(host: PossessableHost) -> void:
    if host.body==level.demon and _hell_active():
        Sfx.set_movement(&"")
        Sfx.play(&"possess")

func _on_jump() -> void:
    if _hell_active() and level.player==level.demon:
        _awaiting_landing = true
        Sfx.set_movement(&"")
        Sfx.play(&"jump")

func _on_landed(_impact_speed: float) -> void:
    if not _awaiting_landing: return
    _awaiting_landing = false
    if _hell_active() and level.player==level.demon: Sfx.play(&"jump")

func _on_bounced() -> void:
    _awaiting_landing = true
    Sfx.set_movement(&"")
    Sfx.play(&"bounce")

func _on_interaction_reset() -> void:
    _awaiting_landing = false

func _on_fracture(platform: Node2D) -> void:
    if not _hell_active(): return
    var half: Vector2 = level.camera.get_viewport_rect().size*.5/level.camera.zoom
    if Rect2(level.camera.global_position-half,half*2).grow(100).has_point(platform.global_position): Sfx.play(&"fracture")

func _on_death() -> void:
    _awaiting_landing = false
    Sfx.set_movement(&"")
    Sfx.play(&"death")

func _exit_tree() -> void:
    if not Sfx.cinematic_running: Sfx.set_movement(&"")
