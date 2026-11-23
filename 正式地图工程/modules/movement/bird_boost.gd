extends Node
## 仅正式小鸟拥有的长按加速；不改变碰撞体或 NPC 巡飞。
@export var horizontal_multiplier: float = 2.4
@export var acceleration_multiplier: float = 3.2
@export var flap_multiplier: float = 1.6
@export var flap_interval_multiplier: float = .75
@export_range(0.0,.6) var blur_amount: float = .20
@export var blur_pixels: float = 4.0
var amount: float = 0.0
var _base: Dictionary = {}
var _material: ShaderMaterial
var _last_texture: Texture2D
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
        for location in [KEY_LOCATION_LEFT,KEY_LOCATION_RIGHT]:
            var key:=InputEventKey.new()
            key.physical_keycode=KEY_SHIFT
            key.location=location
            InputMap.action_add_event(&"bird_boost",key)
    _base={"move_speed":motor.move_speed,"acceleration":motor.acceleration,"flap_speed":motor.flap_speed,"held_flap_interval":motor.held_flap_interval}
    _material=ShaderMaterial.new()
    _material.shader=preload("res://shaders/bird_boost_blur.gdshader")
    _material.set_shader_parameter("blur_pixels",blur_pixels)
    sprite.material=_material
func _can_boost() -> bool:
    return host.claimed and reader.enabled and not reader.external_control and motor.enabled and body.visible
func _physics_process(delta: float) -> void:
    if not _can_boost():
        reset()
        return
    var held:=Input.is_action_pressed(&"bird_boost")
    amount=move_toward(amount,1.0 if held else 0.0,delta*(8.0 if held else 6.0))
    motor.move_speed=_base.move_speed*lerpf(1.0,horizontal_multiplier,amount)
    motor.acceleration=_base.acceleration*lerpf(1.0,acceleration_multiplier,amount)
    motor.flap_speed=_base.flap_speed*lerpf(1.0,flap_multiplier,amount)
    motor.held_flap_interval=_base.held_flap_interval*lerpf(1.0,flap_interval_multiplier,amount)
func _process(_delta: float) -> void:
    var direction:=body.velocity.normalized().rotated(-sprite.global_rotation)
    if sprite.flip_h: direction.x=-direction.x
    _material.set_shader_parameter("blur_direction",direction)
    _material.set_shader_parameter("blur_strength",amount*blur_amount*smoothstep(60.0,260.0,body.velocity.length()))
    if sprite.texture!=_last_texture:
        _last_texture=sprite.texture
        if sprite.texture is AtlasTexture:
            var frame: AtlasTexture=sprite.texture
            var size: Vector2=frame.atlas.get_size()
            _material.set_shader_parameter("frame_uv",Vector4(frame.region.position.x/size.x,frame.region.position.y/size.y,frame.region.end.x/size.x,frame.region.end.y/size.y))
        else:
            _material.set_shader_parameter("frame_uv",Vector4(0,0,1,1))
func reset() -> void:
    amount=0.0
    if not _base.is_empty():
        for property in _base: motor.set(property,_base[property])
    if _material!=null: _material.set_shader_parameter("blur_strength",0.0)
