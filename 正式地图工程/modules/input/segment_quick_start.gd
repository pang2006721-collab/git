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
var _prepared_ending: PackedScene

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
    _prepared_ending = null
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
        # 在穿云开始前由主线程准备小型封赏素材，避免后台首次上传透明光环纹理后丢失。
        _prepared_ending = load(ENDING_SCENE)
        cloud.arrived.connect(_after_preview_cloud.bind(_ending_generation),CONNECT_ONE_SHOT)
    entry.start_segment(index)
    segment_started.emit(index)

func _after_preview_cloud(generation: int) -> void:
    _finish_cloud_handoff.call_deferred(generation)

func _finish_cloud_handoff(generation: int) -> void:
    # 资源已在穿云开始前准备好；弹出后保留原画面与控制，没有淡黑或定格。
    if generation != _ending_generation: return
    if _prepared_ending == null:
        push_error("结尾试玩场景加载失败")
        return
    var level := get_tree().current_scene
    var body: CharacterBody2D = level.get_node("Soul")
    var layout: Node2D = level.get_node("OceanLink/FishStage/JungleLayout")
    var view: Transform2D = get_viewport().canvas_transform
    var packed := _prepared_ending
    _prepared_ending = null
    var ending := packed.instantiate()
    # 两张原画精确相差487像素。保持屏幕构图、同一只幽灵的位置和弹出速度。
    ending.opening_offset = (view*layout.global_transform)*Vector2(0,487)
    ending.arrival_position = view*body.global_position
    ending.arrival_velocity = view.basis_xform(body.velocity)
    ending.arrival_scale = body.scale*view.get_scale()
    ending.initial_god_halo_offset = Vector2(0,40)
    ending.oranges_total = ENDING_ORANGES
    if not _ending_history.is_empty(): ending.set_history(_ending_history)
    _ending_history = {}
    level.camera.enabled = false
    level.camera.set_process(false)
    # 同一帧内卸载、组装、交还控制，不绘制空场景或遮幕；释放旧地图后才分配结算大图。
    get_tree().unload_current_scene()
    get_viewport().canvas_transform = Transform2D.IDENTITY
    get_tree().root.add_child(ending)
    get_tree().current_scene = ending
    get_tree().scene_changed.emit()
    Bgm.play_track(Bgm.Track.HEAVEN)
