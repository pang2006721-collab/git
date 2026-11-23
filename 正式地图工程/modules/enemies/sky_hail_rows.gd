extends Node2D
## 鸣叫离场后的成排冰雹。每排七格、六颗，只留一个空位。
signal row_spawned(row_index: int, gap_start: int)
const ART = preload("res://assets/art/sky/formal/hailstone.png")
const LANE_COUNT = 7
const GAP_WIDTH = 1
@export var rows_per_wave: int = 3
@export_range(1,5) var max_rows_per_wave: int = 5
@export var row_interval: float = 1.1
@export var first_row_delay: float = .3
@export var fall_speed: float = 420.0
@export var fall_gravity: float = 100.0
@export var spin_min: float = .8
@export var spin_max: float = 1.6
@export var horizontal_bounds := Vector2(80,1840)
@export var spawn_above_view: float = 110.0
var stones: Array[Dictionary] = []
var _texture: AtlasTexture
var _rng := RandomNumberGenerator.new()
var _emitting: bool = false
var _timer: float = 0.0
var _remaining: int = 0
var _row: int = 0
var _wave_count: int = 0
var _gap: int = 3
var _previous_target := Vector2.INF
@onready var encounter: Node = get_parent()
@onready var bird: CharacterBody2D = get_node("../../Bird")
func _ready() -> void:
    z_index=18
    _rng.randomize()
    _texture=AtlasTexture.new()
    _texture.atlas=ART
    # Crop empty padding around the supplied image, retaining its bold outer contour.
    _texture.region=Rect2(229,180,854,861)
    _texture.filter_clip=true
    encounter.departed.connect(_on_departed)
    encounter.revealed.connect(_stop_emitting)
    encounter.cycle_reset.connect(reset)
    get_node("../../../../..").died.connect(reset)
func _can_play() -> bool:
    var stage: Node=encounter.stage
    return stage.active and stage.level.player==bird and bird.get_node("Host").claimed and bird.visible and not stage.level.dead and not stage.level.exit_in_progress
func _on_departed() -> void:
    if not _can_play(): return
    reset(false)
    _emitting=true
    _remaining=mini(maxi(rows_per_wave,1)+_wave_count,max_rows_per_wave)
    _wave_count+=1
    _timer=first_row_delay
    var left: float=encounter.layout.to_global(Vector2(horizontal_bounds.x,0)).x
    var width: float=(horizontal_bounds.y-horizontal_bounds.x)*absf(encounter.layout.global_scale.x)
    var lane:=int(floor((bird.global_position.x-left)/(width/LANE_COUNT)))
    _gap=clampi(lane,1,LANE_COUNT-GAP_WIDTH-1)
func _stop_emitting() -> void:
    _emitting=false
    _remaining=0
func _physics_process(delta: float) -> void:
    if not _can_play():
        if _emitting or not stones.is_empty(): reset()
        return
    if _emitting:
        _timer-=delta
        if _timer<=0:
            _spawn_row()
            _remaining-=1
            _emitting=_remaining>0
            _timer+=maxf(row_interval,.2)
    var target: Vector2=bird.global_position
    var last_target: Vector2=target if not _previous_target.is_finite() or _previous_target.distance_to(target)>600 else _previous_target
    _previous_target=target
    var bottom: float=_view_rect().end.y+400.0
    var hit:=false
    for i in range(stones.size()-1,-1,-1):
        var stone: Dictionary=stones[i]
        var art: Sprite2D=stone.art
        var previous: Vector2=art.global_position
        art.global_position+=Vector2(0,stone.speed*delta+fall_gravity*delta*delta*.5)
        stone.speed+=fall_gravity*delta
        stone.age+=delta
        art.rotation+=stone.spin*delta
        var relative:=Geometry2D.get_closest_point_to_segment(Vector2.ZERO,previous-last_target,art.global_position-target)
        if relative.length()<float(stone.radius)+26.0: hit=true
        if art.global_position.y>bottom or stone.age>8.0:
            art.hide()
            art.queue_free()
            stones.remove_at(i)
    if hit:
        encounter.stage.level.die(&"hail")
func _spawn_row() -> void:
    if _row>0:
        _gap=clampi(_gap+(-1 if _rng.randf()<.5 else 1),1,LANE_COUNT-GAP_WIDTH-1)
    var left: float=encounter.layout.to_global(Vector2(horizontal_bounds.x,0)).x
    var width: float=(horizontal_bounds.y-horizontal_bounds.x)*absf(encounter.layout.global_scale.x)
    var step:=width/LANE_COUNT
    var diameter:=minf(step*.72,180.0)
    var y:=_view_rect().position.y-spawn_above_view
    for lane in LANE_COUNT:
        if lane>=_gap and lane<_gap+GAP_WIDTH: continue
        var art:=Sprite2D.new()
        art.texture=_texture
        art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        art.scale=Vector2.ONE*(diameter/861.0)
        art.rotation=_rng.randf_range(-.25,.25)
        add_child(art)
        art.global_position=Vector2(left+(lane+.5)*step,y)
        var spin:=_rng.randf_range(spin_min,maxf(spin_max,spin_min))*(-1 if (lane+_row)%2==0 else 1)
        stones.append({"art":art,"lane":lane,"row":_row,"speed":fall_speed,"spin":spin,"radius":diameter*.38,"age":0.0})
    row_spawned.emit(_row,_gap)
    _row+=1
func _view_rect() -> Rect2:
    var camera: Camera2D=encounter.camera
    var size:=camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)
func is_wave_active() -> bool:
    if _emitting: return true
    var bottom: float=_view_rect().end.y
    for stone in stones:
        # Count rows above the screen too, but not cached debris already below it.
        if stone.art.global_position.y-float(stone.radius)*1.9<=bottom: return true
    return false
func reset(reset_difficulty: bool=true) -> void:
    if reset_difficulty: _wave_count=0
    _stop_emitting()
    _timer=0.0
    _row=0
    _previous_target=Vector2.INF
    for stone in stones:
        var art: Sprite2D=stone.art
        art.hide()
        art.queue_free()
    stones.clear()
