extends Node2D
## 三个明确拍翅关键姿势；仅下拍触发一次轻弹，目光独立追踪玩家。
signal downstroke
const ART = preload("res://assets/art/sky/formal/eagle_three_pose_clean.png")
const SCREECH = preload("res://assets/art/sky/formal/eagle_screech.png")
const FRAME_COUNT = 3
const CELL_SIZE = 1024
const EYES = [Vector4(0.465911,0.431193,0.514098,0.430873), Vector4(0.466483,0.436116,0.513920,0.436159), Vector4(0.462987,0.431141,0.515283,0.430432)]
@export_range(.4, 3.0) var cycle_seconds: float = 1.1
@export var bounce_pixels: float = 9.0
@export var gaze_distance: float = 500.0
var look_target: Node2D
var sprite: Sprite2D
var frame_index: int = 0
var _clock: float = 0.0
var _frames: Array[AtlasTexture] = []
var gaze := Vector2.ZERO
var screaming: bool = false
func _ready() -> void:
    sprite = Sprite2D.new()
    sprite.use_parent_material = true
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    sprite.scale = Vector2.ONE * (1595.0 / 768.0)
    add_child(sprite)
    for index in FRAME_COUNT:
        var frame := AtlasTexture.new()
        frame.atlas = ART
        frame.region = Rect2(index * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
        frame.filter_clip = true
        _frames.append(frame)
    sample_frame(0)
func _process(delta: float) -> void:
    if not is_visible_in_tree() or screaming: return
    _clock = fposmod(_clock + delta, cycle_seconds)
    var phase := _clock / cycle_seconds
    var index := 0 if phase < .38 else (1 if phase < .57 else 2)
    if index != frame_index:
        sample_frame(index)
        if index == 1: downstroke.emit()
    # One damped impulse after the power stroke, returning exactly to rest.
    var t := (_clock - cycle_seconds * .38)
    var bounce := 0.0
    if t >= 0 and t < .42:
        bounce = -bounce_pixels * sin(t / .42 * TAU) * pow(1.0 - t / .42, 2)
    sprite.position.y = bounce
    var desired := Vector2.ZERO
    if is_instance_valid(look_target):
        var head := to_global(Vector2(-20, -114))
        desired = ((look_target.global_position - head) / gaze_distance).limit_length(1.0)
    gaze = gaze.lerp(desired, 1.0 - exp(-delta * 10.0))
    if material is ShaderMaterial: material.set_shader_parameter("gaze", gaze)
func sample_frame(index: int) -> void:
    frame_index = posmod(index, FRAME_COUNT)
    if is_instance_valid(sprite) and not _frames.is_empty(): sprite.texture = _frames[frame_index]
    if material is ShaderMaterial:
        material.set_shader_parameter("pose_index", float(frame_index))
        material.set_shader_parameter("eye_centers", EYES[frame_index])
func set_screaming(value: bool) -> void:
    screaming = value
    sprite.position = Vector2.ZERO
    if material is ShaderMaterial:
        material.set_shader_parameter("screech_pose", value)
        material.set_shader_parameter("gaze", Vector2.ZERO)
    if value:
        sprite.texture = SCREECH
    else:
        _clock = 0.0
        sample_frame(0)

func reset() -> void:
    set_screaming(false)
    _clock = 0.0
    gaze = Vector2.ZERO
    if is_instance_valid(sprite): sprite.position = Vector2.ZERO
    sample_frame(0)
    if material is ShaderMaterial: material.set_shader_parameter("gaze", Vector2.ZERO)
