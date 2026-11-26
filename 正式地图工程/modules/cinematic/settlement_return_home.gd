extends CanvasLayer
## 留在场景树根部跨场景存活；复用原有五角色加载动画，主页准备好后才揭开黑幕。
signal completed
const MENU = "res://scenes/ui/main_menu.tscn"
const LOADING = preload("res://scenes/ui/loading_character_overlay.tscn")
@export var fade_to_black_seconds: float = .7
@export var minimum_black_seconds: float = 2.4
@export var reveal_seconds: float = 1.4
var black: ColorRect
var beans: CanvasLayer
var started: bool = false
var menu_ready: bool = false
var _fade: Tween

func _ready() -> void:
    layer = 80
    process_mode = Node.PROCESS_MODE_ALWAYS
    var layout := Control.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(layout)
    black = ColorRect.new()
    black.color = Color(0,0,0,0)
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_child(black)
    beans = LOADING.instantiate()
    beans.layer = 81
    beans.dim_strength = 0.0
    add_child(beans)

func start() -> void:
    if started: return
    started = true
    _fade = create_tween()
    _fade.tween_property(black,"color:a",1.0,fade_to_black_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await _fade.finished
    beans.begin_loading()
    # 先释放结算的大图/录像，再加载主页引用的完整地图，避免两套纹理同时常驻。
    get_tree().unload_current_scene()
    await get_tree().process_frame
    await get_tree().process_frame
    if ResourceLoader.load_threaded_request(MENU) != OK:
        _recover()
        return
    await get_tree().create_timer(minimum_black_seconds).timeout
    while ResourceLoader.load_threaded_get_status(MENU) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        await get_tree().process_frame
    if ResourceLoader.load_threaded_get_status(MENU) != ResourceLoader.THREAD_LOAD_LOADED:
        _recover()
        return
    var scene := ResourceLoader.load_threaded_get(MENU) as PackedScene
    if get_tree().change_scene_to_packed(scene) != OK:
        _recover()
        return
    await get_tree().scene_changed
    var menu_camera: Camera2D = get_tree().current_scene.get_node("DescentCamera")
    menu_camera.make_current()
    menu_camera.force_update_scroll()
    # 黑幕下先完成实际绘制，避免仅节点就绪、视口尚未交接时开始揭幕。
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
    menu_ready = true
    # 主页已实际进入树，仍保持纯黑，先让五个小豆子完整退场。
    beans.finish_loading()
    await beans.finished
    _fade = create_tween()
    _fade.tween_property(black,"color:a",0.0,reveal_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await _fade.finished
    completed.emit()
    queue_free()

func _recover() -> void:
    push_error("结算返回主页加载失败，已撤销黑幕")
    _fade = create_tween()
    _fade.tween_property(black,"color:a",0.0,.4)
    _fade.tween_callback(queue_free)
