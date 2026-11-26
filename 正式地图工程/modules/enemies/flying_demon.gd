extends CharacterBody2D
signal shot(aim: Vector2, origin: Vector2)
enum Mode { ENTERING, FLYING, WINDUP, RECOVERING, DYING }
const IDLE=preload("res://assets/art/enemies/flying_demon/idle.png")
const DEAD=preload("res://assets/art/enemies/flying_demon/dead.png")
const FLAP=preload("res://assets/art/enemies/flying_demon/flap.png")
@export var attack_interval: float = 2.7
@export var windup_seconds: float = .48
@export var sight_radius: float = 850.0
@export var death_spin_seconds: float = .65
@export var death_jump_speed: float = 320.0
@export var death_gravity: float = 1200.0
@export var death_screen_margin_pixels: float = 48.0
var _death_origin: Vector2
var _death_rotation: float
var _death_drift: float
var encounter: Node
var mode: Mode = Mode.FLYING
var entry_point: Vector2
var entry_side: float = -1.0
var _time: float = 0.0
var _cooldown: float = 1.4
var _sense: float = 0.0
var _can_see: bool = false
var _aim: Vector2
var _state_time: float = 0.0
var _pop: Tween
@onready var art: Sprite2D = $Visual/Art
@onready var lock: Sprite2D = $Lock
@onready var flight: Node = $Flight
@onready var _windup: Texture2D = $Visual/Art.texture

func _ready() -> void:
    if mode!=Mode.ENTERING:add_to_group("fork_targets")
    else:
        collision_mask=0
        $Detection.monitorable=false
    add_to_group("hell_flying_enemies")
    flight.setup(int(get_instance_id()),entry_side)
    var material:=ShaderMaterial.new()
    material.shader=preload("res://shaders/demon_held_fork.gdshader")
    material.set_shader_parameter("enemy_art",true)
    art.material=material
    _cooldown=1.0+fmod(float(get_instance_id()),.9)
    _pose()

func is_defeated() -> bool:
    return mode==Mode.DYING

func set_state(value: int) -> void:
    if is_defeated() or value!=1:
        lock.conceal()
    else:
        lock.reveal()

func _physics_process(delta: float) -> void:
    _time+=delta
    _state_time+=delta
    if mode==Mode.DYING:
        global_position=_death_origin+Vector2(_death_drift*_state_time,-death_jump_speed*_state_time+.5*death_gravity*_state_time*_state_time)
        $Visual.rotation=_death_rotation+TAU*minf(_state_time/death_spin_seconds,1.0)
        # 转完一圈后继续下落，整张死亡图离开实际显示视口才清理。
        if _state_time >= death_spin_seconds and death_gravity*_state_time > death_jump_speed and _death_art_is_outside_view():
            queue_free()
        return
    if not is_instance_valid(encounter) or not encounter.is_active():return
    if mode==Mode.ENTERING:
        if flight.enter_tick(self,entry_point,delta):
            var query:=PhysicsShapeQueryParameters2D.new()
            query.shape=$Collision.shape
            query.transform=global_transform
            query.collision_mask=9
            if get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():
                mode=Mode.FLYING
                collision_mask=9
                add_to_group("fork_targets")
                $Detection.set_deferred("monitorable",true)
                _cooldown=.9
            else:entry_point.y-=75.0
        _pose(delta)
        return
    var target:Vector2=encounter.level.player.global_position+Vector2(0,-55)
    _sense-=delta
    if _sense<=0:
        _sense=.15
        _can_see=encounter.is_on_screen(global_position) and target.distance_squared_to(global_position)<sight_radius*sight_radius and get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position,target,9,[get_rid()])).is_empty()
    flight.tick(self,target,encounter.flight_bounds(),delta,encounter.enemies())
    _cooldown-=delta
    if mode==Mode.WINDUP and not encounter.is_on_screen(global_position):
        mode=Mode.FLYING
        _state_time=0
        _cooldown=.35
    if mode==Mode.FLYING and _cooldown<=0 and _can_see and encounter.is_on_screen(global_position):
        mode=Mode.WINDUP
        _state_time=0
        _aim=target
    elif mode==Mode.WINDUP and _state_time>=windup_seconds:
        if encounter.is_on_screen(global_position): shot.emit(_aim,global_position)
        mode=Mode.RECOVERING
        _state_time=0
        _cooldown=attack_interval
    elif mode==Mode.RECOVERING and _state_time>.65:
        mode=Mode.FLYING
        _state_time=0
    _pose(delta)

func _pose(delta: float = 1.0/60.0) -> void:
    if mode==Mode.WINDUP:
        art.texture=_windup
        art.offset=Vector2(-1,-19.5)
    else:
        art.texture=FLAP if int(_time/.12)%2==1 else IDLE
        art.offset=art.texture.get_size()*.5-Vector2(90,78)
    art.material.set_shader_parameter("has_fork",mode!=Mode.RECOVERING)
    if is_instance_valid(encounter):art.flip_h=encounter.level.player.global_position.x>global_position.x
    $Visual.rotation=lerp_angle($Visual.rotation,clampf(velocity.x/flight.max_speed,-1,1)*.10,1.0-exp(-7.0*delta))

func _death_art_is_outside_view() -> bool:
    var rect := art.get_rect()
    var canvas := art.get_global_transform_with_canvas()
    var bounds := Rect2(canvas*rect.position,Vector2.ZERO)
    for corner in [Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
        bounds = bounds.expand(canvas*corner)
    return not bounds.intersects(get_viewport_rect().grow(death_screen_margin_pixels))

func take_hit() -> void:
    if is_defeated():return
    mode=Mode.DYING
    _state_time=0
    lock.conceal()
    remove_from_group("fork_targets")
    collision_layer=0
    $Detection.set_deferred("monitorable",false)
    _death_origin=global_position
    _death_rotation=$Visual.rotation
    _death_drift=clampf(velocity.x*.3,-60.0,60.0)
    velocity=Vector2.ZERO
    art.texture=DEAD
    art.offset=DEAD.get_size()*.5-Vector2(90,78)
    art.material.set_shader_parameter("has_fork",true)
    if _pop!=null:_pop.kill()
    $Visual.scale=Vector2(1.28,.72)
    _pop=create_tween()
    _pop.tween_property($Visual,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
