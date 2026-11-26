extends Node
## 分段试玩快捷入口；重载同一个正式场景，避免继承旧过场、死亡或附身状态。
signal segment_started(index: int)
const FORMAL_SCENE = "res://scenes/levels/formal_hell_entry.tscn"
const ENDING_SCENE = "res://scenes/previews/settlement_descent.tscn"
const ENDING_ORANGES = 100
var _pending: int = 0
var _loading: bool = false
var _ending_generation: int = 0
var _ending_history: Dictionary = {}
var _ending_fade: CanvasLayer
var _ending_tween: Tween

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().scene_changed.connect(_on_scene_changed)

func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
        return
    var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    var index: int = {KEY_1:1,KEY_2:2,KEY_3:3,KEY_4:4,KEY_5:5,KEY_6:6,KEY_7:7}.get(key,0)
    if index == 0: return
    get_viewport().set_input_as_handled()
    start_segment(index)

func start_segment(index: int) -> void:
    if index not in [1,2,3,4,5,6,7]: return
    _ending_generation += 1
    _cancel_ending_fade()
    if index == 7:
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
    if index == 7:
        var cloud := get_tree().current_scene.get_node("OceanLink/FishStage/JungleLayout/SkyCloudExit")
        cloud.arrived.connect(_after_preview_cloud.bind(_ending_generation),CONNECT_ONE_SHOT)
    entry.start_segment(index)
    segment_started.emit(index)

func _cancel_ending_fade() -> void:
    if is_instance_valid(_ending_tween): _ending_tween.kill()
    if is_instance_valid(_ending_fade): _ending_fade.queue_free()
    _ending_fade = null

func _after_preview_cloud(generation: int) -> void:
    # 保留原来的幽灵弹出，再用短淡出衔接光环镜头，隐藏两种构图之间的切换。
    await get_tree().create_timer(.85,true,false,true).timeout
    if generation != _ending_generation: return
    _ending_fade = CanvasLayer.new()
    _ending_fade.layer = 120
    add_child(_ending_fade)
    var black := ColorRect.new()
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    black.color = Color(0,0,0,0)
    _ending_fade.add_child(black)
    _ending_tween = create_tween().set_ignore_time_scale(true)
    _ending_tween.tween_property(black,"color:a",1.0,.22)
    await get_tree().create_timer(.24,true,false,true).timeout
    if generation != _ending_generation: return
    get_tree().unload_current_scene()
    await get_tree().process_frame
    await get_tree().process_frame
    if generation != _ending_generation: return
    get_viewport().canvas_transform = Transform2D.IDENTITY
    if ResourceLoader.load_threaded_request(ENDING_SCENE) != OK:
        _cancel_ending_fade()
        push_error("无法载入结尾试玩场景")
        return
    while ResourceLoader.load_threaded_get_status(ENDING_SCENE) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        await get_tree().process_frame
        if generation != _ending_generation: return
    if ResourceLoader.load_threaded_get_status(ENDING_SCENE) != ResourceLoader.THREAD_LOAD_LOADED:
        _cancel_ending_fade()
        push_error("结尾试玩场景加载失败")
        return
    var packed := ResourceLoader.load_threaded_get(ENDING_SCENE) as PackedScene
    if get_tree().change_scene_to_packed(packed) != OK:
        _cancel_ending_fade()
        return
    await get_tree().scene_changed
    if generation != _ending_generation: return
    var ending := get_tree().current_scene
    ending.oranges_total = ENDING_ORANGES
    ending.opening.oranges_total = ENDING_ORANGES
    if not _ending_history.is_empty(): ending.set_history(_ending_history)
    _ending_history = {}
    Bgm.play_track(Bgm.Track.HEAVEN)
    _ending_tween = create_tween().set_ignore_time_scale(true)
    _ending_tween.tween_property(black,"color:a",0.0,.35)
    await get_tree().create_timer(.37,true,false,true).timeout
    if generation == _ending_generation: _cancel_ending_fade()
