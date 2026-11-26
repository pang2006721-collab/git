extends Node
## 正常登顶与7键共用的唯一结算入口；快捷键只覆盖试玩橘子数与旧局记录。
const ENDING_SCENE = "res://scenes/previews/settlement_descent.tscn"
var enabled := true
var preview_oranges_override: int = -1
var history_override: Dictionary = {}
var _prepared: PackedScene
var _cloud: Node2D
var _level: Node2D
var _layout: Node2D
var _transferring := false

func configure(cloud: Node2D, level: Node2D, layout: Node2D) -> void:
	_cloud = cloud
	_level = level
	_layout = layout
	cloud.entered_cloud.connect(_prepare)
	cloud.arrived.connect(_after_cloud)

func _prepare() -> void:
	if not enabled: return
	# 主线程在钻云开始时准备，避免透明光环首次后台上传后无像素。
	_prepared = load(ENDING_SCENE)

func _after_cloud() -> void:
	if enabled and not _transferring:
		_transferring = true
		_finish.call_deferred()

func _finish() -> void:
	if not enabled or _prepared == null or not is_instance_valid(_level): return
	var tree := get_tree()
	if tree.current_scene == null or (tree.current_scene != _level and not tree.current_scene.is_ancestor_of(_level)): return
	var body: CharacterBody2D = _level.get_node("Soul")
	var viewport := get_viewport()
	var view := viewport.canvas_transform
	var ending := _prepared.instantiate()
	ending.opening_offset = (view * _layout.global_transform) * Vector2(0,487)
	ending.arrival_position = view * body.global_position
	ending.arrival_velocity = view.basis_xform(body.velocity)
	ending.arrival_scale = body.scale * view.get_scale()
	ending.initial_god_halo_offset = Vector2(0,40)
	var oranges := _level.get_node("HellOranges")
	ending.oranges_total = preview_oranges_override if preview_oranges_override >= 0 else oranges.collected_count
	var history: Node = _level.get_node("RunRetrospective")
	history.frozen = true
	ending.set_history(history_override if not history_override.is_empty() else history.snapshot())
	_level.camera.enabled = false
	_level.camera.set_process(false)
	# 同帧卸载旧大图后再构造结算，不绘制空场景；从此以后仅使用局部缓存，旧节点已释放。
	tree.unload_current_scene()
	viewport.canvas_transform = Transform2D.IDENTITY
	tree.root.add_child(ending)
	tree.current_scene = ending
	tree.scene_changed.emit()
	Bgm.play_track(Bgm.Track.HEAVEN)

func cancel() -> void:
	_prepared = null
	_transferring = false
	preview_oranges_override = -1
	history_override = {}
