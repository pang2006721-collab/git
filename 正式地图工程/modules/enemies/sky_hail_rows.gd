extends Node2D
## 六颗与七颗交替错排；普通小缝封住，只保留每排一个错位通道。
signal stone_melted
signal row_spawned(row_index: int, gap_start: int)
const ART = preload("res://assets/art/sky/formal/hailstone.png")
const LANE_COUNT = 7
const GAP_WIDTH = 1
const BIRD_RADIUS = 26.0
@export var rows_per_wave: int = 3
@export_range(1,5) var max_rows_per_wave: int = 5
@export var row_interval: float = 1.35
@export var first_row_delay: float = .3
@export var melt_seconds: float = .8
@export_range(0,1) var melt_heat_cost: float = .3
@export var flame_reach: float = 42.0
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
var _row_pattern: int = 0
var _last_gap_center: float = INF
var _last_gap_half_width: float = 0.0
var last_row_layout: Dictionary = {}
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
    get_node("../../../../..").died.connect(_on_player_died)
func _on_player_died() -> void:
    _stop_emitting()
    process_mode=Node.PROCESS_MODE_ALWAYS

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
    var lanes:=LANE_COUNT+_row_pattern%2
    var lane:=int(floor((bird.global_position.x-left)/(width/lanes)))
    _gap=clampi(lane,1,lanes-GAP_WIDTH-1)
func _stop_emitting() -> void:
    _emitting=false
    _remaining=0
func _physics_process(delta: float) -> void:
    var can_hit: bool=_can_play()
    if not can_hit and not encounter.stage.level.dead:
        if _emitting or not stones.is_empty(): reset()
        return
    if _emitting and can_hit:
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
        var fire: Node=bird.get_node("Boost")
        if stone.get("melting",false):
            var transfer: float=minf(delta,maxf(0.0,melt_seconds-stone.melt_elapsed))
            var cost: float=melt_heat_cost*transfer/maxf(melt_seconds,.01)
            if can_hit and fire.absorb_heat(cost):
                stone.melt_elapsed=minf(melt_seconds,stone.melt_elapsed+transfer)
            else:
                stone.melting=false
                stone.hit_reported=true
                if can_hit: hit=true
        if not stone.get("melting",false) or not can_hit:
            art.global_position+=Vector2(0,stone.speed*delta+fall_gravity*delta*delta*.5)
            stone.speed+=fall_gravity*delta
        stone.age+=delta
        art.rotation+=stone.spin*delta
        if stone.get("melting",false):
            var remaining: float=maxf(0.0,1.0-stone.melt_elapsed/maxf(melt_seconds,.01))
            art.scale=stone.original_scale*remaining
            art.modulate=Color(1,1,1,smoothstep(0.0,.3,remaining))
            stone.radius=stone.original_radius*remaining
            if can_hit:
                var head: Vector2=target+Vector2(0,-42.0-float(stone.radius)*1.05)
                var settle: float=smoothstep(0.0,.12,stone.melt_elapsed)
                art.global_position=stone.melt_origin.lerp(head,settle)
        var relative:=Geometry2D.get_closest_point_to_segment(Vector2.ZERO,previous-last_target,art.global_position-target)
        if can_hit and not stone.get("melting",false) and not stone.get("hit_reported",false) and fire.is_burning() and fire.heat>=melt_heat_cost*minf(delta,melt_seconds)/maxf(melt_seconds,.01) and relative.length()<float(stone.radius)+BIRD_RADIUS+flame_reach:
            stone.melting=true
            if not stone.has("melt_elapsed"):
                stone.melt_elapsed=0.0
                stone.original_scale=art.scale
                stone.original_radius=stone.radius
            stone.melt_origin=art.global_position
            stone.hit_reported=true
        if can_hit and not stone.get("hit_reported",false) and relative.length()<float(stone.radius)+BIRD_RADIUS:
            stone.hit_reported=true
            hit=true
        if art.global_position.y>bottom or stone.age>8.0 or (stone.get("melting",false) and stone.melt_elapsed>=melt_seconds):
            if can_hit and stone.get("melting",false) and stone.melt_elapsed>=melt_seconds:stone_melted.emit()
            art.hide()
            art.queue_free()
            stones.remove_at(i)
    if hit:
        encounter.stage.level.die(&"hail")
func _spawn_row() -> void:
    var lanes:=LANE_COUNT+_row_pattern%2
    var left: float=encounter.layout.to_global(Vector2(horizontal_bounds.x,0)).x
    var width: float=(horizontal_bounds.y-horizontal_bounds.x)*absf(encounter.layout.global_scale.x)
    var step:=width/lanes
    var diameter:=minf(step*.90,240.0)
    var radius:=diameter*.45
    var gap_half_width:=step-radius-BIRD_RADIUS
    if is_finite(_last_gap_center):
        # Choose the nearest reachable opening with no shared straight-up corridor.
        var choices: Array[int]=[]
        var nearest:=INF
        for candidate in range(1,lanes-1):
            var center:=left+(candidate+.5)*step
            var distance:=absf(center-_last_gap_center)
            if distance<=_last_gap_half_width+gap_half_width+12.0: continue
            if distance<nearest-1.0:
                nearest=distance
                choices.clear()
            if absf(distance-nearest)<=1.0: choices.append(candidate)
        if not choices.is_empty(): _gap=choices[_rng.randi_range(0,choices.size()-1)]
    _gap=clampi(_gap,1,lanes-2)
    _last_gap_center=left+(_gap+.5)*step
    _last_gap_half_width=gap_half_width
    var y:=_view_rect().position.y-spawn_above_view
    for lane in lanes:
        if lane==_gap: continue
        var art:=Sprite2D.new()
        art.texture=_texture
        art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        art.scale=Vector2.ONE*(diameter/861.0)
        art.rotation=_rng.randf_range(-.25,.25)
        add_child(art)
        art.global_position=Vector2(left+(lane+.5)*step,y)
        var spin:=_rng.randf_range(spin_min,maxf(spin_max,spin_min))*(-1 if (lane+_row)%2==0 else 1)
        stones.append({"art":art,"lane":lane,"row":_row,"speed":fall_speed,"spin":spin,"radius":radius,"age":0.0})
    last_row_layout={"count":lanes-1,"lanes":lanes,"gap":_gap,"center":_last_gap_center,"safe_left":_last_gap_center-gap_half_width,"safe_right":_last_gap_center+gap_half_width,"pitch":step,"radius":radius}
    row_spawned.emit(_row,_gap)
    _row+=1
    _row_pattern+=1
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
    process_mode=Node.PROCESS_MODE_INHERIT
    if reset_difficulty:
        _wave_count=0
        _row_pattern=0
    _stop_emitting()
    _timer=0.0
    _row=0
    _last_gap_center=INF
    _last_gap_half_width=0.0
    last_row_layout.clear()
    _previous_target=Vector2.INF
    for stone in stones:
        var art: Sprite2D=stone.art
        art.hide()
        art.queue_free()
    stones.clear()
