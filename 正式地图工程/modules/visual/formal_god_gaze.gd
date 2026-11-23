extends Sprite2D
## 只移动正式长图中上帝原有的瞳孔，不覆盖或替换身体原画。
@export var maximum_offset: Vector2=Vector2(11,7)
@export var response: float=12.0
var target: Node2D
var enabled: bool=false
var gaze: Vector2=Vector2.ZERO
var _face: ShaderMaterial
func _ready() -> void:
    var region:=AtlasTexture.new()
    region.atlas=load("res://assets/art/reference_map/00.png")
    region.region=Rect2(840,920,240,100)
    texture=region
    centered=false
    position=Vector2(840,920)
    z_index=18
    _face=ShaderMaterial.new()
    _face.shader=preload("res://shaders/formal_god_gaze.gdshader")
    material=_face
func _process(delta: float) -> void:
    var desired:=Vector2.ZERO
    if enabled and is_instance_valid(target):
        var center: Vector2=get_parent().to_global(Vector2(960,970))
        var direction:Vector2=(target.global_position+Vector2(0,-55)-center)/Vector2(450,350)
        desired=direction.limit_length(1.0)*maximum_offset
    gaze=gaze.lerp(desired,1-exp(-response*delta))
    _face.set_shader_parameter("gaze_pixels",gaze)
func reset() -> void:
    enabled=false
    gaze=Vector2.ZERO
    _face.set_shader_parameter("gaze_pixels",gaze)
