extends Node
## 本局记录；只听有效死亡信号，不在重试时清零。截图是实际游玩画面，非重演敌人 AI。
@export var recording_enabled: bool = true
@export_range(2, 12) var capture_fps: int = 8
@export var clip_seconds: float = 6.0
@export var capture_size := Vector2i(640, 360)
var deaths := {&"hell": 0, &"ocean": 0, &"jungle": 0, &"sky": 0}
var recent := {&"hell": [], &"ocean": [], &"jungle": [], &"sky": []}
var failures := {&"hell": [], &"ocean": [], &"jungle": [], &"sky": []}
var current_stage: StringName = &"hell"
var frozen: bool = false
var _clock: float = 0.0
var _capturing: bool = false
var _capture_view: SubViewport
var _capture_art: TextureRect
@onready var level: Node = get_parent()

func _ready() -> void:
    level.died.connect(_on_death)

func stage_for_player(body: Node) -> StringName:
    if body == null: return current_stage
    match str(body.name):
        "Demon": return &"hell"
        "Fish": return &"ocean"
        "Squirrel": return &"jungle"
        "Bird": return &"sky"
    # 附身途中使用同一个 Soul，仍归到离开的关卡。
    return current_stage

func _process(delta: float) -> void:
    if frozen or not level.is_visible_in_tree() or level.dead or level.exit_in_progress: return
    current_stage = stage_for_player(level.player)
    if not recording_enabled or DisplayServer.get_name() == "headless": return
    _clock += delta
    if _clock < 1.0 / capture_fps or _capturing: return
    _clock = fmod(_clock, 1.0 / capture_fps)
    _capture(current_stage)

func _capture(stage: StringName) -> void:
    _capturing = true
    if not is_instance_valid(_capture_view):
        _capture_view = SubViewport.new()
        _capture_view.name = "ReplayDownsample"
        _capture_view.size = capture_size
        _capture_view.disable_3d = true
        _capture_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
        add_child(_capture_view)
        _capture_art = TextureRect.new()
        _capture_art.texture = get_viewport().get_texture()
        _capture_art.size = Vector2(capture_size)
        _capture_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _capture_art.stretch_mode = TextureRect.STRETCH_SCALE
        _capture_view.add_child(_capture_art)
    _capture_view.render_target_update_mode = SubViewport.UPDATE_ONCE
    await RenderingServer.frame_post_draw
    if not frozen and level.is_visible_in_tree() and not level.dead and not level.exit_in_progress and stage == current_stage:
        var image: Image = _capture_view.get_texture().get_image()
        if not image.is_empty():
            append_frame(stage, image.save_jpg_to_buffer(.76))
    _capturing = false

func append_frame(stage: StringName, jpeg: PackedByteArray) -> void:
    if not recent.has(stage) or jpeg.is_empty(): return
    recent[stage].append(jpeg)
    var capacity: int = maxi(1, ceili(capture_fps * clip_seconds))
    while recent[stage].size() > capacity: recent[stage].pop_front()

func _on_death() -> void:
    current_stage = stage_for_player(level.player)
    deaths[current_stage] += 1
    # 保留第一次失败前的片段，再配合该关最后一段，回顾有失败也有进步。
    if failures[current_stage].is_empty(): failures[current_stage] = recent[current_stage].duplicate()

func snapshot() -> Dictionary:
    var clips := {}
    for stage in deaths:
        var clip: Array = failures[stage].duplicate()
        clip.append_array(recent[stage])
        clips[stage] = clip
    return {"deaths": deaths.duplicate(), "clips": clips, "fps": capture_fps}
