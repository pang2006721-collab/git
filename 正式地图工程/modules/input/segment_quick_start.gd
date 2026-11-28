extends Node
## 分段试玩快捷入口；重载同一个正式场景，避免继承旧过场、死亡或附身状态。
signal segment_started(index: int)
const FORMAL_SCENE = "res://scenes/levels/formal_hell_entry.tscn"
const ENDING_SCENE = "res://scenes/previews/settlement_descent.tscn"
const ENDING_ORANGES = 100
var _pending: int = 0
var _loading: bool = false
var _ending_history: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().scene_changed.connect(_on_scene_changed)

func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
        return
    var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    var index: int = {KEY_1:1,KEY_2:2,KEY_3:3,KEY_4:4,KEY_5:5,KEY_6:6,KEY_7:7,KEY_8:8}.get(key,0)
    if index == 0: return
    get_viewport().set_input_as_handled()
    start_segment(index)

func start_segment(index: int) -> void:
    if index not in [1,2,3,4,5,6,7,8]: return
    if index in [7,8]:
        _ending_history = {}
        var scene := get_tree().current_scene
        if scene != null:
            var history := scene.find_child("RunRetrospective",true,false)
            if history != null: _ending_history = history.snapshot()
            elif scene.scene_file_path == ENDING_SCENE: _ending_history = scene.data
    # 任意快捷入口都可以打断结算收尾，避免旧黑幕稍后又把新关卡换回主页。
    for child in get_tree().root.get_children():
        if child.get_script() != null and child.get_script().resource_path.ends_with("settlement_return_home.gd"):
            child.queue_free()
    _pending = index
    if _loading: return
    _loading = true
    _reload.call_deferred()

func _reload() -> void:
    Engine.time_scale = 1.0
    get_tree().paused = false
    var error := get_tree().change_scene_to_file(FORMAL_SCENE)
    if error != OK:
        _pending = 0
        _loading = false
        push_error("无法载入正式分段试玩场景："+error_string(error))

func _on_scene_changed() -> void:
    if _pending == 0: return
    if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != FORMAL_SCENE: return
    _apply.call_deferred()

func _apply() -> void:
    var index := _pending
    _pending = 0
    _loading = false
    Engine.time_scale = 1.0
    var entry := get_tree().current_scene.get_node("SegmentStart")
    if index in [7,8]:
        var cloud := get_tree().current_scene.get_node("OceanLink/FishStage/JungleLayout/SkyCloudExit")
        cloud.ending_handoff.preview_oranges_override = ENDING_ORANGES if index == 7 else 0
        cloud.ending_handoff.history_override = _ending_history
        _ending_history = {}
    entry.start_segment(7 if index == 8 else index)
    if index == 5:
        get_tree().current_scene.get_node("JungleTutorial").replay_now()
    if index == 6:
        get_tree().current_scene.get_node("SkyTutorial").replay_now()
    segment_started.emit(index)
