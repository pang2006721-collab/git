extends Node2D
## 世界坐标游动，参考动画的头部注册与喷墨后反冲。
signal ink_sprayed
signal ink_released
signal appeared
enum State { WAITING, ENTERING, SWIMMING, SQUASHING, INKING, EXITING, DASHING }
@export var spawn_interval: float = 3.0
@export var automatic_spawning: bool = true
@export var proximity_radius: float = 460.0
@export var windup_seconds: float = .5
@export var windup_retreat: float = 72.0
@export var dash_speed: float = 1000.0
@export var dash_max_distance: float = 1300.0
@export var dash_max_seconds: float = .65
@export var spray_standoff: float = 110.0
@export var prediction_max_seconds: float = 1.1
@export var prediction_max_distance: float = 900.0
@export var spray_delay: float = .36
@export var cloud_contact_delay: float = .08
@export var visible_seconds: float = 5.0
@export var swim_speed: float = 85.0
@export var artwork_scale: float = .42
@export var ink_radius: float = 130.0
@export var enabled: bool = false:
    set(value):
        if enabled == value: return
        enabled = value
        if is_node_ready(): reset()
var target: CharacterBody2D
var camera: Camera2D
var state: State = State.WAITING
var cycle_elapsed: float = 0.0
var state_elapsed: float = 0.0
var _side: int = 1
var _visit_elapsed: float = 0.0
var _previous_player_y: float = 0.0
var _sprayed: bool = false
var _finishing_visit: bool = false
var _anchors: Dictionary
var _velocity := Vector2.ZERO
var _jet_direction := Vector2.DOWN
var _aim_rotation: float = 0.0
var _swim_clock: float = 0.0
var _cloud: Sprite2D
var _cloud_elapsed: float = 0.0
var _cloud_hit: bool = false
var _cloud_scale: float = 1.0
var _windup_origin := Vector2.ZERO
var _windup_direction := Vector2.DOWN
var _dash_origin := Vector2.ZERO
var _dash_distance: float = 0.0
var _dash_seconds: float = .2
var _predicted_point := Vector2.ZERO
var _last_target_velocity := Vector2.ZERO
var _target_acceleration := Vector2.ZERO
var _prediction_drag := Vector2(1.15,.75)
var _prediction_min_velocity := Vector2(-470,-420)
var _prediction_max_velocity := Vector2(470,680)
const CLOUD = preload("res://assets/art/ocean/octopus/ink-splatter.png")
const INK_TIMES = [.30, .48, .72, .80, .94, 1.08, 1.20, 1.36]
const SWIM_ORDER = [6, 0, 1, 2, 3, 4, 5]
const SWIM_TIMES = [.22, .38, .45, .51, .61, .72, 1.0]
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Art

func _ready() -> void:
    _anchors = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/octopus/anchors.json"))
    reset()

func configure(player: CharacterBody2D, view: Camera2D) -> void:
    target = player
    camera = view
    _previous_player_y = player.global_position.y
    _last_target_velocity = player.velocity
    _target_acceleration = Vector2.ZERO
    var motor := player.get_node_or_null("Movement")
    if motor is SwimMotor:
        _prediction_drag = Vector2(motor.horizontal_drag,motor.vertical_drag)
        _prediction_min_velocity = Vector2(-motor.max_horizontal_speed,-motor.max_rise_speed)
        _prediction_max_velocity = Vector2(motor.max_horizontal_speed,motor.max_sink_speed)

func _physics_process(delta: float) -> void:
    if not enabled or not is_instance_valid(target) or not is_instance_valid(camera): return
    _target_acceleration = ((target.velocity-_last_target_velocity)/maxf(delta,.001)).limit_length(1400)
    _last_target_velocity = target.velocity
    _tick_cloud(delta)
    var rising := target.global_position.y < _previous_player_y-.01
    _previous_player_y = target.global_position.y
    if state == State.WAITING:
        cycle_elapsed = cycle_elapsed+delta if rising else 0.0
        if automatic_spawning and not _finishing_visit and cycle_elapsed >= spawn_interval and is_available(): _appear()
        return
    state_elapsed += delta
    _visit_elapsed += delta
    _swim_clock += delta
    match state:
        State.ENTERING, State.SWIMMING:
            var phase := fposmod(_swim_clock,1.12)/1.12
            var pulse := .35
            if phase >= .38 and phase <= .63: pulse += 1.8*pow(sin((phase-.38)/.25*PI),2)
            _velocity = Vector2(float(_side)*12,-swim_speed)*pulse
            global_position += _velocity*delta
            _show_swim()
            if state == State.ENTERING and _view_rect().grow(-35).has_point(global_position): _change_state(State.SWIMMING)
            if not _finishing_visit and global_position.distance_to(target.global_position) <= proximity_radius:
                _jet_direction = global_position.direction_to(target.global_position)
                _update_aim()
                _windup_origin = global_position
                _windup_direction = _jet_direction
                _change_state(State.SQUASHING)
        State.SQUASHING:
            var u := clampf(state_elapsed/windup_seconds,0,1)
            # 先后缩，再轻轻向前回弹；冲刺前一直能读清蓄力方向。
            var retreat := windup_retreat*(1-pow(1-minf(u/.7,1),3))
            if u>.7: retreat -= windup_retreat*.18*smoothstep(.7,1,u)
            global_position = _windup_origin-_windup_direction*retreat
            _plan_intercept(maxf(0,windup_seconds-state_elapsed))
            _update_aim()
            visual.rotation = lerp_angle(visual.rotation,_aim_rotation,1-exp(-delta*12))
            var squeeze := sin(u*PI)*.1
            visual.scale = Vector2(-float(_side)*(1+squeeze),1-squeeze)
            _pose(&"ink",mini(2,int(u*3)))
            if state_elapsed >= windup_seconds:
                visual.scale = Vector2(-float(_side),1)
                visual.rotation = _aim_rotation
                _dash_origin = global_position
                _change_state(State.DASHING)
        State.DASHING:
            # 出手时固定世界方向，玩家移动/瞬移可躲开，不追着镜头拐弯。
            var u := clampf(state_elapsed/_dash_seconds,0,1)
            global_position = _dash_origin+_jet_direction*_dash_distance*(1-pow(1-u,3))
            _pose(&"ink",2 if u<.8 else 3)
            var stretch := sin(u*PI)*.08
            visual.scale = Vector2(-float(_side)*(1-stretch),1+stretch)
            if u>=1:
                visual.scale = Vector2(-float(_side),1)
                _change_state(State.INKING)
                # 前三帧蓄力已在后缩与冲刺中播放，接着喷口出墨。
                state_elapsed = 1.08-spray_delay
        State.INKING:
            var frame_index := 7
            for i in INK_TIMES.size():
                if state_elapsed < INK_TIMES[i]:
                    frame_index = i
                    break
            _pose(&"ink",frame_index)
            if not _sprayed and state_elapsed >= 1.08:
                _sprayed = true
                _release_cloud()
            if _sprayed:
                var recoil := clampf((state_elapsed-1.08)/.28,0,1)
                global_position -= _jet_direction*180*recoil*delta
            if state_elapsed >= 1.36:
                _swim_clock = 0
                _change_state(State.EXITING)
        State.EXITING:
            _show_swim()
            var phase := fposmod(_swim_clock,1.12)/1.12
            var pulse := .35+1.6*pow(sin(clampf((phase-.38)/.25,0,1)*PI),2)
            global_position -= _jet_direction*180*pulse*delta
            visual.rotation = lerp_angle(visual.rotation,_aim_rotation+float(_side)*.35,1-exp(-delta*4))
    # 只在整个身体出画后回收，不在屏幕中间按时隐藏。
    if _visit_elapsed > .7 and not _view_rect().grow(180).has_point(global_position): _finish_body()
    elif _visit_elapsed > visible_seconds+3 and state in [State.ENTERING,State.SWIMMING]:
        _jet_direction = Vector2(-float(_side)*.55,.84)
        _aim_rotation = visual.rotation
        _change_state(State.EXITING)

func _show_swim() -> void:
    var phase := fposmod(_swim_clock,1.12)/1.12
    for i in SWIM_TIMES.size():
        if phase < SWIM_TIMES[i]:
            _pose(&"swim",SWIM_ORDER[i])
            return

func _update_aim() -> void:
    var painted_jet := Vector2(.76,.65)*Vector2(-float(_side),1)
    _aim_rotation = wrapf(_jet_direction.angle()-painted_jet.angle(),-PI,PI)

func _plan_intercept(remaining_windup: float) -> void:
    # 预判的是墨团展开能接触小鱼的时刻，不能只瞄冲刺结束时的旧位置。
    var seconds := .2
    for iteration in 8:
        var horizon := minf(prediction_max_seconds,remaining_windup+seconds+spray_delay+cloud_contact_delay)
        var lead := _predict_swim_displacement(horizon).limit_length(prediction_max_distance)
        _predicted_point = target.global_position+lead
        _dash_distance = clampf(global_position.distance_to(_predicted_point)-spray_standoff,0,dash_max_distance)
        seconds = clampf(_dash_distance/dash_speed,.14,dash_max_seconds)
    _dash_seconds = seconds
    _jet_direction = global_position.direction_to(_predicted_point)

func _predict_swim_displacement(seconds: float) -> Vector2:
    # 小鱼仍在加速时，用观察到的加速度和真实水阻力/速度上限外推。
    var velocity := target.velocity.limit_length(850)
    var acceleration := _target_acceleration
    var displacement := Vector2.ZERO
    var step := seconds/12.0
    var decay := Vector2(exp(-_prediction_drag.x*step),exp(-_prediction_drag.y*step))
    var gain := Vector2(step if _prediction_drag.x<.001 else (1-decay.x)/_prediction_drag.x,step if _prediction_drag.y<.001 else (1-decay.y)/_prediction_drag.y)
    for index in 12:
        var next := velocity+acceleration*gain
        next = next.clamp(_prediction_min_velocity,_prediction_max_velocity)
        displacement += (velocity+next)*(.5*step)
        velocity = next
        acceleration *= decay
    return displacement

func _pose(animation: StringName, frame_index: int) -> void:
    sprite.animation = animation
    sprite.frame = frame_index
    sprite.pause()
    _register_frame()

func _view_rect() -> Rect2:
    var size := camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.get_screen_center_position()-size*.5,size)

func is_available() -> bool:
    return state == State.WAITING and not is_instance_valid(_cloud)

func _appear(spawn_point: Vector2 = Vector2.INF) -> void:
    cycle_elapsed = 0
    _visit_elapsed = 0
    _swim_clock = 0
    _sprayed = false
    var view := _view_rect()
    var x := clampf(target.global_position.x+float(_side)*180,view.position.x+140,view.end.x-140)
    global_position = Vector2(x,view.position.y-110) if spawn_point == Vector2.INF else spawn_point
    visual.scale = Vector2(-float(_side),1)
    visual.rotation = 0
    _show_swim()
    _change_state(State.ENTERING)
    show()
    appeared.emit()

func _release_cloud() -> void:
    ink_released.emit()
    _cloud = Sprite2D.new()
    _cloud.texture = CLOUD
    _cloud.material = sprite.material
    _cloud.z_index = z_index
    get_parent().add_child(_cloud)
    _cloud.global_position = global_position+_jet_direction*112
    _cloud_scale = 260.0/CLOUD.get_width()
    _cloud.scale = Vector2.ONE*_cloud_scale*.55
    _cloud_elapsed = 0
    _cloud_hit = false

func _tick_cloud(delta: float) -> void:
    if not is_instance_valid(_cloud): return
    _cloud_elapsed += delta
    var expand := 1-pow(1-clampf(_cloud_elapsed/.2,0,1),3)
    _cloud.scale = Vector2.ONE*_cloud_scale*lerpf(.55,1,expand)
    _cloud.modulate.a = 1-clampf((_cloud_elapsed-3.2)/.65,0,1)
    if not _cloud_hit and not _finishing_visit and target.global_position.distance_to(_cloud.global_position) <= ink_radius*lerpf(.55,1,expand):
        var teleport := target.get_node_or_null("Teleport")
        if teleport == null or not teleport.is_invulnerable():
            _cloud_hit = true
            ink_sprayed.emit()
    if _cloud_elapsed >= 3.85:
        _cloud.queue_free()
        _cloud = null

func _change_state(next: State) -> void:
    state = next
    state_elapsed = 0

func _finish_body() -> void:
    hide()
    _change_state(State.WAITING)
    cycle_elapsed = 0

func finish_current_visit() -> void:
    _finishing_visit = true
    process_mode = Node.PROCESS_MODE_ALWAYS

func _register_frame() -> void:
    # 头部注册不包含喷出的墨汁，切换动作使用同一比例。
    var pivot: Array = _anchors[sprite.animation][sprite.frame]
    var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
    sprite.offset = texture.get_size()*.5-Vector2(pivot[0],pivot[1])
    sprite.scale = Vector2.ONE*artwork_scale

func reset() -> void:
    process_mode = Node.PROCESS_MODE_INHERIT
    _finishing_visit = false
    state = State.WAITING
    cycle_elapsed = 0
    state_elapsed = 0
    _side = 1
    _sprayed = false
    _visit_elapsed = 0
    _swim_clock = 0
    _velocity = Vector2.ZERO
    _windup_origin = Vector2.ZERO
    _windup_direction = Vector2.DOWN
    _dash_origin = Vector2.ZERO
    _dash_distance = 0
    _predicted_point = Vector2.ZERO
    _target_acceleration = Vector2.ZERO
    if is_instance_valid(target): _last_target_velocity = target.velocity
    if is_instance_valid(_cloud): _cloud.queue_free()
    _cloud = null
    if is_instance_valid(target): _previous_player_y = target.global_position.y
    hide()
    visual.scale = Vector2.ONE
    visual.rotation = 0
    _pose(&"swim",0)
