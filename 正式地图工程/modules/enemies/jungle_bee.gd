extends CharacterBody2D
## 复用地狱小恶魔飞行模块；只用作者蜜蜂原图，蓄力瞄准后短暂有限追踪冲刺蜇击。
signal stung
const FLIGHT = preload("res://modules/enemies/flying_motion.gd")
const ART2 = preload("res://assets/art/jungle/formal/bee2.png")
@export var ranged: bool = false
var art_scale: float = .52
const ART = preload("res://assets/art/jungle/formal/bee.png")
enum Mode { EMERGING, FLYING, WINDUP, DARTING, RECOVERING, DEFLECTED }
@export var attack_interval: float = 3.5
@export var warning_seconds: float = .55
@export var dart_tracking_seconds: float = .82
@export var dart_turn_rate: float = 6.0
@export var dart_speed: float = 1450.0
@export var dart_seconds: float = .9
var _previous_target := Vector2.INF
var encounter: Node
var mode: Mode = Mode.EMERGING
var elapsed: float = 0
var lifetime: float = 0
var cooldown: float = 1.5
var flight: Node
var visual: Sprite2D
var _aim := Vector2.ZERO
var _dart_velocity := Vector2.ZERO
var _hit: bool = false
func _ready() -> void:
    collision_layer=0
    collision_mask=32
    motion_mode=MOTION_MODE_FLOATING
    var shape:=CollisionShape2D.new()
    shape.shape=CircleShape2D.new()
    shape.shape.radius=45
    add_child(shape)
    visual=Sprite2D.new()
    visual.texture=ART2 if ranged else ART
    art_scale=150.0/maxf(visual.texture.get_width(),visual.texture.get_height())
    visual.scale=Vector2.ONE*art_scale
    add_child(visual)
    flight=Node.new()
    flight.set_script(FLIGHT)
    add_child(flight)
    flight.max_speed=440
    flight.acceleration=900
    flight.orbit_radius=Vector2(240,85)
    flight.setup(int(get_instance_id()),-1 if get_instance_id()%2==0 else 1)
    add_to_group("jungle_bees")
    velocity=Vector2(0,-300)
    _pose(0)
func is_defeated() -> bool:
    return mode==Mode.DEFLECTED or is_queued_for_deletion()
func _physics_process(delta: float) -> void:
    if not is_instance_valid(encounter) or not encounter.can_simulate():
        queue_free()
        return
    elapsed+=delta
    lifetime+=delta
    var target: Vector2 = encounter.target_position()
    var last_target: Vector2 = target if not _previous_target.is_finite() or _previous_target.distance_to(target)>500 else _previous_target
    _previous_target=target
    if global_position.distance_to(target)>1900:
        queue_free()
        return
    if mode==Mode.DEFLECTED:
        _tick_deflection(delta)
        return
    if not encounter.is_active():
        if mode==Mode.DARTING:
            velocity=_dart_velocity
            move_and_slide()
            if elapsed>=dart_seconds: _set_mode(Mode.RECOVERING)
        else:
            flight.tick(self,target,encounter.flight_bounds(),delta,encounter.enemies())
        _pose(delta)
        return
    var motion_start: Vector2=global_position
    if encounter.player_spinning() and motion_start.distance_to(target)<95:
        deflect(target)
        return
    if mode==Mode.EMERGING:
        velocity=velocity.move_toward(Vector2.ZERO,delta*500)
        move_and_slide()
        if elapsed>=.45: _set_mode(Mode.FLYING)
    elif mode==Mode.FLYING:
        flight.tick(self,target,encounter.flight_bounds(),delta,encounter.enemies())
        cooldown-=delta
        if cooldown<=0 and global_position.distance_to(target)<650 and encounter.is_on_screen(global_position):
            _aim=target
            _set_mode(Mode.WINDUP)
    elif mode==Mode.WINDUP:
        if elapsed<warning_seconds-.12:
            var predicted: Vector2 = encounter.intercept_target(global_position,1200 if ranged else dart_speed,.3)
            _aim=_aim.lerp(predicted,1-exp(-delta*16))
        velocity=velocity.move_toward(Vector2.ZERO,delta*1100)
        move_and_slide()
        if not encounter.is_on_screen(global_position):
            cooldown=.6
            _set_mode(Mode.FLYING)
        elif elapsed>=warning_seconds:
            if ranged:
                encounter.fire_stinger(global_position,encounter.intercept_target(global_position,1200,.3))
                _set_mode(Mode.RECOVERING)
            else:
                _aim=encounter.intercept_target(global_position,dart_speed,.3)
                _dart_velocity=(_aim-global_position).normalized()*dart_speed
                _hit=false
                _set_mode(Mode.DARTING)
    elif mode==Mode.DARTING:
        var before: Vector2 = global_position
        if elapsed<=dart_tracking_seconds and encounter.is_on_screen(global_position):
            var toward: Vector2 = encounter.intercept_target(global_position,dart_speed,.2)-global_position
            if _dart_velocity.dot(toward)>0:
                var turn: float = clampf(wrapf(toward.angle()-_dart_velocity.angle(),-PI,PI),-dart_turn_rate*delta,dart_turn_rate*delta)
                _dart_velocity=_dart_velocity.rotated(turn)
        velocity=_dart_velocity
        move_and_slide()
        var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target,before,global_position)
        var relative: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2.ZERO,before-last_target,global_position-target)
        if not _hit and relative.length()<70 and encounter.is_on_screen(closest):
            if encounter.player_spinning():
                deflect(target)
                return
            _hit=true
            encounter.defeat_player()
            stung.emit()
        elif elapsed>=dart_seconds: _set_mode(Mode.RECOVERING)
    elif mode==Mode.RECOVERING:
        velocity=velocity.move_toward(Vector2.ZERO,delta*1400)
        move_and_slide()
        if elapsed>=.65:
            cooldown=attack_interval
            _set_mode(Mode.FLYING)
    if encounter.player_spinning():
        var swept: Vector2=Geometry2D.get_closest_point_to_segment(Vector2.ZERO,motion_start-last_target,global_position-target)
        if swept.length()<95:
            deflect(target)
            return
    _pose(delta)
func deflect(origin: Vector2) -> void:
    if mode==Mode.DEFLECTED: return
    var away: Vector2=(global_position-origin).normalized()
    if away.length_squared()<.01: away=Vector2.UP
    velocity=away*1100+(encounter.body.velocity*.25).limit_length(350)+Vector2(0,-220)
    _set_mode(Mode.DEFLECTED)
    encounter.bee_deflected()
    _tick_deflection(0)
func _tick_deflection(delta: float) -> void:
    if elapsed<.065:
        visual.scale=Vector2(1.65,.55)*art_scale
        return
    velocity.y+=1100*delta
    move_and_slide()
    visual.rotation+=delta*14*(1 if velocity.x>=0 else -1)
    var impact_time: float=elapsed-.065
    var spring: float=cos(impact_time*26)*exp(-impact_time*8)
    visual.scale=Vector2(1+.65*spring,1-.4*spring)*art_scale
    if elapsed>=1.8: queue_free()
func _set_mode(value: Mode) -> void:
    mode=value
    elapsed=0
func _pose(delta: float) -> void:
    # 原图朝左；以小恶魔同样的倾身表现运动，翅膀以整图短促弹性轻颤表现。
    visual.flip_h=velocity.x>15 if absf(velocity.x)>15 else visual.flip_h
    var pop: float = 1.0
    if lifetime<.45:
        var u: float = clampf(lifetime/.45,0,1)
        pop=1+2.70158*pow(u-1,3)+1.70158*pow(u-1,2)
    var stretch: float = 1+sin(lifetime*42)*.025
    if mode==Mode.WINDUP: stretch=1+sin(elapsed*40)*.07
    elif mode==Mode.DARTING: stretch=.84
    visual.scale=Vector2.ONE*art_scale*maxf(.05,pop)*Vector2(1/stretch,stretch)
    var lean: float = clampf(velocity.x/950,-1,1)*.25
    visual.rotation=lerp_angle(visual.rotation,lean,1-exp(-delta*12))
