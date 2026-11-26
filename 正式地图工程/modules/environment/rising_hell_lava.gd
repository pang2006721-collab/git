extends Node2D
## 固定世界高度缓慢上涨；复用原岩浆边缘，不追赶相机或玩家。
signal rise_started
signal first_exchange_started
const ART = preload("res://assets/art/hell/layers/lava.png")
const STRIP = Rect2i(840,80,750,167)
@export var rise_speed: float = 60.0
@export var startup_grace_seconds: float = 0.0
@export var initial_surface_y: float = 51900.0
@export var ceiling_y: float = 41900.0
@export var world_width: float = 1920.0
@export var world_bottom_y: float = 52180.0
@export var checkpoint_gap: float = 650.0
var armed: bool = false
var grace_remaining: float = 0.0
var surface_y: float = 51900.0
var _original_top := PackedFloat32Array()
@onready var level: Node2D = get_parent()
@onready var fork: Node2D = get_node("../Fork")
@onready var surface: Sprite2D = $Surface
@onready var fill: Polygon2D = $Fill

func _ready() -> void:
    # 缓存原图每列真实可见的橙色边缘，伤害与原画保持一致。
    var image := ART.get_image()
    _original_top.resize(image.get_width())
    for x in image.get_width():
        _original_top[x] = INF
        for y in image.get_height():
            if image.get_pixel(x,y).a > .5:
                _original_top[x] = float(y)
                break
    fork.exchanged.connect(_on_exchanged)
    reset()

func _on_exchanged(body: Node2D) -> void:
    if not armed and body == level.demon and _can_run():
        arm(initial_surface_y)
        first_exchange_started.emit()

func arm(start_y: float) -> void:
    surface_y = clampf(start_y,ceiling_y,initial_surface_y)
    armed = true
    grace_remaining = startup_grace_seconds
    _place_art()
    show()
    if grace_remaining <= 0: rise_started.emit()

func start_at_checkpoint(body: Node2D) -> void:
    arm(level.to_local(body.global_position).y+checkpoint_gap)

func _can_run() -> bool:
    return level.visible and not level.dead and not level.exit_in_progress and level.get_node("WallEntry").completed and level.player == level.demon and level.demon.get_node("Host").claimed and level.get_node("OceanLink").stage == 0

func _physics_process(delta: float) -> void:
    if not _can_run(): return
    var feet := level.to_local(level.demon.global_position)
    if armed:
        var rising_delta := delta
        if grace_remaining > 0:
            var used := minf(grace_remaining,delta)
            grace_remaining -= used
            rising_delta -= used
            if grace_remaining <= 0: rise_started.emit()
        surface_y = maxf(ceiling_y,surface_y-rise_speed*rising_delta)
        _place_art()
    if feet.y >= surface_at(feet.x): level.die(&"lava")

func surface_at(x: float) -> float:
    var original_x := clampi(roundi(x-3),0,_original_top.size()-1)
    var original_y := 51754.0+_original_top[original_x]
    if not armed: return original_y
    var strip_x := STRIP.position.x+clampi(int(x/world_width*STRIP.size.x),0,STRIP.size.x-1)
    var rising_y := surface_y+_original_top[strip_x]-STRIP.position.y
    return minf(original_y,rising_y)

func _place_art() -> void:
    position = Vector2(0,surface_y)
    surface.scale.x = world_width/STRIP.size.x
    var seam := float(STRIP.size.y)-1.0
    var bottom := maxf(seam+1,world_bottom_y-surface_y)
    fill.polygon = PackedVector2Array([Vector2(0,seam),Vector2(world_width,seam),Vector2(world_width,bottom),Vector2(0,bottom)])

func reset() -> void:
    armed = false
    grace_remaining = 0
    surface_y = initial_surface_y
    _place_art()
    hide()
