extends Node
## 平时自动积攒火焰，身体逐渐变红；Shift 释放并消耗积累。
@export var normal_speed_multiplier: float = .82
@export var normal_flap_multiplier: float = .87
@export var normal_acceleration_multiplier: float = .85
@export var burn_seconds: float = 1.2
@export var charge_seconds: float = 3.0
@export_range(0.01,1.0) var minimum_charge: float = .12
var amount: float = 0.0
var heat: float = 0.0
var burning: bool = false
var _was_held: bool = false
var _clock: float = 0.0
var _base: Dictionary = {}
var _material: ShaderMaterial
var _fire: Sprite2D
@onready var body: CharacterBody2D = get_parent()
@onready var motor: Node = get_node("../Movement")
@onready var reader: PlatformerInput = get_node("../Input")
@onready var host: Node = get_node("../Host")
@onready var sprite: Sprite2D = get_node("../Visual/Sprite")
func _ready() -> void:
    process_physics_priority=-15
    process_priority=1
    if not InputMap.has_action(&"bird_boost"):
        InputMap.add_action(&"bird_boost")
        var key:=InputEventKey.new()
        key.physical_keycode=KEY_SHIFT
        InputMap.action_add_event(&"bird_boost",key)
    _base={"move_speed":motor.move_speed,"acceleration":motor.acceleration,"flap_speed":motor.flap_speed,"held_flap_interval":motor.held_flap_interval}
    _material=ShaderMaterial.new()
    _material.shader=preload("res://shaders/bird_heat.gdshader")
    sprite.material=_material
    _fire=Sprite2D.new()
    _fire.texture=preload("res://assets/art/sky/formal/bird_burning.png")
    _fire.material=_material
    _fire.scale=Vector2.ONE*1.6
    sprite.get_parent().add_child(_fire)
    _fire.hide()
func _can_boost() -> bool:
    return host.claimed and reader.enabled and not reader.external_control and motor.enabled and body.visible
func _physics_process(delta: float) -> void:
    if not _can_boost():
        reset()
        return
    tick(delta,Input.is_action_pressed(&"bird_boost"))
    motor.move_speed=_base.move_speed*normal_speed_multiplier
    motor.acceleration=_base.acceleration*normal_acceleration_multiplier
    motor.flap_speed=_base.flap_speed*normal_flap_multiplier
    motor.held_flap_interval=_base.held_flap_interval
func tick(delta: float,held: bool) -> void:
    if not held: burning=false
    elif not _was_held and heat>=minimum_charge: burning=true
    if burning:
        heat=maxf(0.0,heat-delta/maxf(burn_seconds,.01))
        if heat<=0.0: burning=false
    else:
        var previous: float=heat
        heat=minf(1.0,heat+delta/maxf(charge_seconds,.01))
        if previous<1.0 and heat>=1.0:
            body.get_node("Visual").play_selection_pulse()
    _was_held=held
    amount=1.0 if burning else 0.0
func is_burning() -> bool:
    return burning and _can_boost()
func _process(delta: float) -> void:
    _clock+=delta
    _material.set_shader_parameter("heat",heat)
    _fire.visible=burning
    sprite.self_modulate.a=0.0 if burning else 1.0
    _fire.flip_h=sprite.flip_h
    _fire.position=sprite.position
    _fire.scale=Vector2.ONE*1.6*(1.0+.025*sin(_clock*(30.0 if heat>.75 else 16.0)))
func reset() -> void:
    amount=0.0
    heat=0.0
    burning=false
    _was_held=false
    sprite.self_modulate.a=1.0
    if is_instance_valid(_fire): _fire.hide()
    if not _base.is_empty():
        for property in _base: motor.set(property,_base[property])
    if _material!=null: _material.set_shader_parameter("heat",0.0)
