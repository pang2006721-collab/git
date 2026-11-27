extends Node
## 附身后才启用的 Shift 瞬移。沿完整鱼碰撞体扫掠，复用作者技能原图。
signal teleported(from: Vector2, destination: Vector2)
const BURST = preload("res://assets/art/characters/fish/abilities/teleport.png")
@export var distance: float = 320.0
@export var cooldown_seconds: float = 0.6
@export var anticipation_seconds: float = 0.04
@export var minimum_distance: float = 12.0
@export var camera_blend_seconds: float = 0.16
@export var arrival_invulnerability_seconds: float = 0.18
var enabled: bool = false
var cooldown_remaining: float = 0.0
var _busy: bool = false
var _invulnerability_remaining: float = 0.0
var _windup: Tween
var _motor_was_enabled: bool = false
var _visual_was_visible: bool = false
var _effects: Array[Sprite2D] = []
@onready var body: CharacterBody2D = get_parent()
@onready var stage: Node2D = body.get_parent()
@onready var reader: SwimInput = body.get_node("Input")
@onready var motor: SwimMotor = body.get_node("Movement")
@onready var visual: Node2D = body.get_node("Visual")
@onready var sprite: Sprite2D = visual.get_node("Sprite")

func _physics_process(delta: float) -> void:
    cooldown_remaining = maxf(0.0,cooldown_remaining-delta)
    _invulnerability_remaining = maxf(0.0,_invulnerability_remaining-delta)

func is_invulnerable() -> bool:
    return enabled and (_busy or _invulnerability_remaining>0.0)

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed(&"possess") or event.is_echo(): return
    if event is InputEventKey and event.location == KEY_LOCATION_RIGHT: return
    if try_teleport(): get_viewport().set_input_as_handled()

func try_teleport(direction: Vector2 = Vector2.ZERO) -> bool:
    var stun := body.get_node_or_null("Stun")
    if stun!=null and (stun.stun_remaining>0 or stun.dizzy_remaining>0): return false
    if not enabled or _busy or cooldown_remaining>0.0 or not body.get_node("Host").claimed:
        return false
    if not stage.active or stage.level.dead or stage.level.exit_in_progress or stage.level.player!=body:
        return false
    if direction.is_zero_approx(): direction = reader.get_visual_direction()
    if direction.is_zero_approx(): direction = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT
    direction = direction.normalized()
    var hit := _blink_motion(direction*distance,true)
    var travel := hit.get_travel() if hit != null else direction*distance
    if travel.length()<minimum_distance: return false
    _busy = true
    cooldown_remaining = cooldown_seconds
    _motor_was_enabled = motor.enabled
    _visual_was_visible = visual.visible
    motor.enabled = false
    visual.hide()
    _burst(body.global_position,direction)
    _windup = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    _windup.tween_interval(anticipation_seconds)
    _windup.tween_callback(_perform.bind(direction))
    return true

func _perform(direction: Vector2) -> void:
    if not enabled or stage.level.dead:
        reset()
        return
    var start := body.global_position
    # 施放前重新扫掠：短准备期间移动的障碍物也不能被穿过。
    _blink_motion(direction*distance,false)
    body.velocity = Vector2.ZERO
    body.reset_physics_interpolation()
    visual.visible = _visual_was_visible
    motor.enabled = _motor_was_enabled
    _invulnerability_remaining = arrival_invulnerability_seconds
    _busy = false
    _burst(body.global_position,direction)
    stage.level.camera.blend_to_target(body,camera_blend_seconds)
    teleported.emit(start,body.global_position)

func _blink_motion(motion: Vector2, test_only: bool) -> KinematicCollision2D:
    # 地形与触手共用碰撞层，只临时忽略触手本体，不关闭整层地形碰撞。
    var temporary: Array[PhysicsBody2D] = []
    var existing := body.get_collision_exceptions()
    for obstacle in get_tree().get_nodes_in_group(&"blink_passable_tentacles"):
        if obstacle is PhysicsBody2D and not existing.has(obstacle):
            body.add_collision_exception_with(obstacle)
            temporary.append(obstacle)
    var hit := body.move_and_collide(motion,test_only)
    for obstacle in temporary:
        if is_instance_valid(obstacle): body.remove_collision_exception_with(obstacle)
    return hit

func _burst(point: Vector2, direction: Vector2) -> void:
    _effects = _effects.filter(func(effect):return is_instance_valid(effect))
    var effect := Sprite2D.new()
    effect.texture = BURST
    effect.z_index = body.z_index+1
    stage.add_child(effect)
    effect.global_position = point
    effect.rotation = Vector2.LEFT.angle_to(direction)
    _effects.append(effect)
    var fade := effect.create_tween()
    fade.tween_property(effect,"modulate:a",0.0,0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    fade.tween_callback(effect.queue_free)

func reset() -> void:
    if _windup != null: _windup.kill()
    if _busy:
        visual.visible = _visual_was_visible
        motor.enabled = _motor_was_enabled and not stage.level.dead
    _busy = false
    _invulnerability_remaining = 0.0
    cooldown_remaining = 0.0
    for effect in _effects:
        if is_instance_valid(effect): effect.queue_free()
    _effects.clear()
