extends Node2D
## 海面前随机单次追尾缠绕：固定出手方向，瞬移避开或挣脱，不产生额外死亡。
const RETREAT = preload("res://modules/visual/surface_tentacle_retreat.gd")
const SHOT = preload("res://modules/camera/surface_grab_camera.gd")
const PROMPT = preload("res://modules/visual/struggle_shift_prompt.gd")
const TENDRIL = preload("res://modules/visual/jellyfish_net_tendril.gd")
const WARNING = preload("res://modules/visual/tentacle_warning.gd")
const CAUGHT_ART = preload("res://assets/art/characters/fish/abilities/entangled.png")
enum State { WAITING, WARNING, REACHING, CAUGHT, COOLDOWN, FINISHED }
@export var enabled: bool = true
@export var trigger_depth: float = 1100.0
@export var warning_seconds: float = 1.4
@export var warning_rise_speed: float = 360.0
@export var total_rounds: int = 1
@export var struggle_presses_required: int = 6
@export var round_rest_seconds: float = .7
@export var anticipation_seconds: float = 0.0
@export var reach_seconds: float = .38
var state: State = State.WAITING
var elapsed: float = 0
var rounds_completed: int = 0
var attacks_started: int = 0
var _evaded: bool = false
var _evade_point := Vector2.ZERO
var struggle_presses: int = 0
var _struggle_kick: float = 0
var _capture_origin := Vector2.ZERO
var _pull_speed: float = 0
var shot: Node
var prompt: CanvasLayer
var _warning_arms: Array[Node2D] = []
var retreats: Array[Node2D] = []
var _arm: Node2D
var _caught_art: Sprite2D
var _restore_motor: bool = false
var _restore_visual: bool = true
var _previous_tip := Vector2.ZERO
@onready var stage: Node2D = get_parent()
@onready var fish: CharacterBody2D = get_node("../Fish")
@onready var blink: Node = fish.get_node("Teleport")
@onready var motor: Node = fish.get_node("Movement")
@onready var visual: Node2D = fish.get_node("Visual")
@onready var shore: Node = stage.get_node("ShoreExit")
func _ready() -> void:
    z_index = 14
    blink.teleported.connect(_on_blink)
    shot = SHOT.new()
    add_child(shot)
    prompt = PROMPT.new()
    add_child(prompt)
func _physics_process(delta: float) -> void:
    if not enabled or not stage.active or stage.level.dead or stage.level.player!=fish: return
    _hold_surface_route()
    if shore.state!=shore.State.SWIMMING:
        if state in [State.WARNING,State.REACHING]: _end_round(true)
        elif state==State.CAUGHT: _finish()
        return
    if state==State.WAITING:
        var depth: float = fish.position.y-shore.surface_y
        if depth>trigger_depth or depth<80 or fish.velocity.y>-40: return
        _begin_warning()
        return
    elapsed += delta
    if state==State.WARNING:
        _sample_warning(delta)
        if elapsed>=warning_seconds: _begin_reach()
    elif state==State.REACHING:
        _arm.sample(elapsed)
        _arm.body.collision_layer = 0
        _arm.dangerous = false
        var tip: Vector2 = _arm.to_global(_arm.centerline[-1])
        var center: Vector2 = fish.get_node("Collision").global_position
        if not _evaded and elapsed>=anticipation_seconds and not blink.is_invulnerable():
            var closest := Geometry2D.get_closest_point_to_segment(center,_previous_tip,tip)
            if closest.distance_to(center)<_arm.thickness*.5+24:
                _catch()
        _previous_tip = tip
        if state==State.REACHING and elapsed>anticipation_seconds+reach_seconds+.18: _end_round(true)
    elif state==State.COOLDOWN:
        if elapsed>=round_rest_seconds: _begin_warning()
    elif state==State.CAUGHT:
        _struggle_kick = move_toward(_struggle_kick,0,delta*5)
        var remaining: float = maxf(0,380-(fish.global_position.y-_capture_origin.y))
        var tug_speed: float = (65+30*sin(elapsed*TAU/1.15))*clampf(remaining/100,0,1)
        _pull_speed = move_toward(_pull_speed,tug_speed,delta*420)
        var capture_pull: float = 28*(smoothstep(0,.18,elapsed)-smoothstep(0,.18,maxf(0,elapsed-delta)))
        var motion: float = minf(_pull_speed*delta+capture_pull,remaining)
        fish.move_and_collide(Vector2(0,motion))
        fish.velocity = Vector2(0,_pull_speed)
        var spring := sin(elapsed*25)*exp(-elapsed*9)
        var wriggle := sin(elapsed*35)*_struggle_kick
        _caught_art.scale = Vector2(1+spring*.30+wriggle*.12,1-spring*.24-wriggle*.10)
        _caught_art.rotation = spring*.13+wriggle*.14
        # 触手末端贴住包裹小鱼的原图，形成拉住并收紧的连接。
        _arm.finish = _arm.to_local(fish.get_node("Collision").global_position+Vector2(0,38))
        _arm.geometry_locked = false
        _arm.sample(_arm.charge_seconds+_arm.strike_seconds+1)
        _arm.body.collision_layer = 0
        _arm.dangerous = false
func _begin_warning() -> void:
    state = State.WARNING
    elapsed = 0
    _evaded = false
    var camera: Camera2D = stage.level.camera
    var size := camera.get_viewport_rect().size/camera.zoom
    var view := Rect2(camera.global_position+camera.offset-size*.5,size)
    for i in 4:
        var arm := TENDRIL.new()
        arm.set_meta(&"formation_index",i)
        arm.visual_only = true
        arm.thickness = 118
        arm.wave_amplitude = 85
        arm.wave_phase = float(i)*1.2
        arm.charge_seconds = 0
        arm.strike_seconds = .4
        var x: float = view.position.x+view.size.x*(.20+float(i)*.20)
        arm.position = to_local(Vector2(x,view.end.y+240))
        arm.start = Vector2.ZERO
        arm.finish = Vector2(-35 if i%2==0 else 35,-430)
        arm.curve_height = 25 if i%2==0 else -25
        add_child(arm)
        var warning := WARNING.new()
        warning.name = "Warning"
        warning.position = arm.finish+Vector2(0,-85)
        arm.add_child(warning)
        arm.sample(0)
        arm.body.collision_layer = 0
        arm.dangerous = false
        _warning_arms.append(arm)
func _sample_warning(delta: float) -> void:
    for i in _warning_arms.size():
        var arm := _warning_arms[i]
        # 按自身速度向上游动，不复制相机位置；微微摆动并带蓄力回弹。
        arm.position.y -= warning_rise_speed*delta
        arm.rotation = sin(elapsed*4.8+i*1.4)*.07
        arm.wave_phase = elapsed*3.8+i*1.2
        arm.geometry_locked = false
        arm.sample(maxf(0,elapsed-float(i)*.07))
        arm.body.collision_layer = 0
        arm.dangerous = false
        arm.get_node("Warning").sample(elapsed-.20-float(i)*.07)
func _begin_reach() -> void:
    var center: Vector2 = fish.get_node("Collision").global_position
    var predicted: Vector2 = _evade_point if _evaded else center+(fish.velocity*reach_seconds).limit_length(240)
    var camera: Camera2D = stage.level.camera
    var size := camera.get_viewport_rect().size/camera.zoom
    var view := Rect2(camera.global_position+camera.offset-size*.5,size).grow(-60)
    var candidates: Array[Node2D] = []
    _arm = null
    for candidate in _warning_arms:
        var tip: Vector2 = candidate.to_global(candidate.centerline[-1])
        if view.has_point(tip): candidates.append(candidate)
    if not candidates.is_empty(): _arm = candidates.pick_random()
    if _arm==null:
        # 玩家已游走或闪避使原触手离屏，本轮算落空，不能重新生成一轮。
        _end_round(true)
        return
    state = State.REACHING
    attacks_started += 1
    elapsed = 0
    var others: Array[Node2D] = []
    for candidate in _warning_arms:
        candidate.get_node("Warning").hide()
        if candidate!=_arm: others.append(candidate)
    _retire_arms(others)
    _previous_tip = _arm.to_global(_arm.centerline[-1])
    _arm.initial_reach = _arm.start.distance_to(_arm.finish)
    _arm.finish = _arm.to_local(predicted)
    _arm.charge_seconds = anticipation_seconds
    _arm.strike_seconds = reach_seconds
    _arm.geometry_locked = false
func _catch() -> void:
    state = State.CAUGHT
    elapsed = 0
    struggle_presses = 0
    _struggle_kick = 0
    _capture_origin = fish.global_position
    _pull_speed = 0
    var reveal:=stage.get_node_or_null("JellyfishReveal")
    if reveal!=null: reveal.finish_for_surface()
    shot.begin(stage.level.camera)
    prompt.show_prompt()
    _arm.start = _arm.to_local(fish.global_position+Vector2(0,720))
    _restore_motor = motor.enabled
    _restore_visual = visual.visible
    motor.enabled = false
    fish.velocity = Vector2.ZERO
    visual.hide()
    _caught_art = Sprite2D.new()
    _caught_art.texture = CAUGHT_ART
    _caught_art.position = Vector2(8,7)
    _caught_art.flip_h = fish.get_node("Visual/Sprite").flip_h
    _caught_art.z_index = 1
    fish.add_child(_caught_art)
func _on_blink(_from: Vector2, _destination: Vector2) -> void:
    if state in [State.WARNING,State.REACHING] and not _evaded:
        _evaded = true
        _evade_point = _from
func _input(event: InputEvent) -> void:
    if state!=State.CAUGHT or stage.level.dead: return
    if not event.is_action_pressed(&"possess") or event.is_echo(): return
    if event is InputEventKey and event.location==KEY_LOCATION_RIGHT: return
    if try_struggle(): get_viewport().set_input_as_handled()
func try_struggle() -> bool:
    if state!=State.CAUGHT or stage.level.dead: return false
    struggle_presses += 1
    _struggle_kick = 1
    _pull_speed = -160
    prompt.pulse()
    shot.pulse()
    if struggle_presses>=struggle_presses_required:
        _end_round()
        fish.velocity = Vector2(0,-180)
    return true
func _finish() -> void:
    if is_instance_valid(shot): shot.release(stage.level.dead)
    if is_instance_valid(prompt): prompt.hide_prompt(stage.level.dead)
    if state==State.CAUGHT:
        motor.enabled = _restore_motor and not stage.level.dead
        visual.visible = _restore_visual
    if is_instance_valid(_caught_art):
        _caught_art.queue_free()
        _caught_art = null
    _clear_arms()
    state = State.FINISHED
func _clear_arms() -> void:
    for arm in _warning_arms:
        if is_instance_valid(arm): arm.queue_free()
    _warning_arms.clear()
    _arm = null
func _retire_arms(arms: Array[Node2D]) -> void:
    if arms.is_empty(): return
    retreats = retreats.filter(func(node): return is_instance_valid(node))
    var retreat := RETREAT.new()
    add_child(retreat)
    retreat.configure(arms,stage.level.camera)
    retreats.append(retreat)
    for arm in arms: _warning_arms.erase(arm)
func _end_round(retreat_on_miss: bool = false) -> void:
    if retreat_on_miss:
        _retire_arms(_warning_arms.duplicate())
        _arm = null
    _finish()
    rounds_completed += 1
    if rounds_completed<total_rounds:
        state = State.COOLDOWN
        elapsed = 0
func blocks_exit() -> bool:
    # 闪避已成功，即使落空动画仍在播放也立即允许出水。
    return enabled and not _evaded and state!=State.WAITING and rounds_completed<total_rounds and state!=State.FINISHED
func _hold_surface_route() -> void:
    if not blocks_exit(): return
    var depth: float = fish.position.y-shore.surface_y
    if depth<500:
        fish.velocity.y = maxf(fish.velocity.y,-80)
    if depth<220:
        fish.position.y = shore.surface_y+220
        fish.velocity.y = maxf(fish.velocity.y,0)
func reset() -> void:
    _finish()
    for retreat in retreats:
        if is_instance_valid(retreat): retreat.queue_free()
    retreats.clear()
    if is_instance_valid(shot): shot.reset()
    if is_instance_valid(prompt): prompt.hide_prompt(true)
    state = State.WAITING
    elapsed = 0
    rounds_completed = 0
    attacks_started = 0
    struggle_presses = 0
    _struggle_kick = 0
    _evaded = false
