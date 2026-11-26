extends Node
## 独立音效总线：原始素材不变，按实测响度设置增益，播放不受死亡冻结影响。
signal played(cue: StringName)
const FOLDER = "res://assets/audio/sfx/"
var levels: Dictionary
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _movement: AudioStreamPlayer
var _movement_kind: StringName = &""
var _movement_target: float = 0.0
var _movement_gain: float = 0.0
var cinematic_running: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    levels = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"levels.json"))
    if AudioServer.get_bus_index("SFX")<0:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count-1,"SFX")
    var limiter := AudioEffectLimiter.new()
    limiter.ceiling_db = -1.0
    AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),limiter)
    for cue in levels:
        _streams[cue] = load(FOLDER+levels[cue].file)
    for i in range(16):
        var voice := AudioStreamPlayer.new()
        voice.bus = &"SFX"
        add_child(voice)
        _voices.append(voice)
    _movement = AudioStreamPlayer.new()
    _movement.bus = &"SFX"
    add_child(_movement)
    get_tree().node_added.connect(_watch_button)
    get_tree().scene_changed.connect(_bind_scene_buttons)
    _bind_scene_buttons.call_deferred()

func _bind_scene_buttons() -> void:
    for button in get_tree().root.find_children("*","BaseButton",true,false):
        _bind_button(button)

func _watch_button(node: Node) -> void:
    if node is BaseButton: _bind_button(node)

func _bind_button(button: BaseButton) -> void:
    if not is_instance_valid(button): return
    if not button.pressed.is_connected(_on_ui_pressed):
        button.pressed.connect(_on_ui_pressed)

func _on_ui_pressed() -> void:
    play(&"ui")

func play(cue: StringName) -> void:
    var voice: AudioStreamPlayer
    for candidate in _voices:
        if not candidate.playing:
            voice = candidate
            break
    if voice==null:
        voice = _voices[0]
        voice.stop()
    voice.stream = _streams[cue]
    voice.volume_db = levels[cue].gain_db
    voice.play()
    played.emit(cue)

func set_movement(cue: StringName) -> void:
    _movement_target = 0.0 if cue==&"" else 1.0
    if cue==&"" or cue==_movement_kind: return
    _movement.stop()
    _movement_kind = cue
    var stream := _streams[cue].duplicate() as AudioStreamMP3
    stream.loop = true
    _movement.stream = stream
    _movement.volume_linear = 0.0
    _movement_gain = 0.0
    _movement.play()
    played.emit(cue)

func set_cinematic_running(active: bool) -> void:
    if cinematic_running==active: return
    cinematic_running = active
    set_movement(&"ghost_run" if active else &"")

func _process(delta: float) -> void:
    if not _movement.playing: return
    var seconds := delta/maxf(Engine.time_scale,.01)
    _movement_gain = move_toward(_movement_gain,_movement_target,seconds*14)
    _movement.volume_linear = _movement_gain*db_to_linear(levels[_movement_kind].gain_db)
    if is_zero_approx(_movement_gain) and is_zero_approx(_movement_target):
        _movement.stop()
        _movement_kind = &""
