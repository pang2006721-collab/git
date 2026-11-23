extends Node
## 死亡、结束界面和回程镜头的编排；不改平台及投叉算法。
signal retry_finished
enum State { PLAYING, DEAD, RETURNING, ENTERING, HOME }
const OVERLAY = preload("res://scenes/ui/hell_death_overlay.tscn")
@export var return_min_seconds: float = 0.45
@export var return_max_seconds: float = 1.35
@export var return_pixels_per_second: float = 18000.0
var state: State = State.PLAYING
var impact_shake: Node
var death_animation: Node2D
var overlay: CanvasLayer
var _saved_mode: int
var _saved_output_mode: int
var _saved_streamer_mode: int
var _return_tween: Tween
@onready var level: Node2D = get_parent()
@onready var camera: Camera2D = get_node("../Camera")
@onready var output: Node = get_node("../CameraOutput")
@onready var streamer: Node = get_node("../TextureStreamer")
@onready var entry: Node = get_node("../WallEntry")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 20
	impact_shake = preload("res://modules/camera/death_impact_shake.gd").new()
	impact_shake.name = "ImpactShake"
	add_child(impact_shake)
	death_animation = preload("res://modules/environment/hell_demon_death.gd").new()
	death_animation.name = "DemonDeath"
	add_child(death_animation)
	overlay = OVERLAY.instantiate()
	add_child(overlay)
	level.died.connect(_on_death)
	overlay.retry_requested.connect(_retry)
	overlay.home_requested.connect(_home)
	entry.control_ready.connect(_entry_finished)

func _on_death() -> void:
	if state != State.PLAYING:
		return
	state = State.DEAD
	_freeze.call_deferred()

func _freeze() -> void:
	_saved_mode = level.process_mode
	_saved_output_mode = output.process_mode
	_saved_streamer_mode = streamer.process_mode
	level.process_mode = Node.PROCESS_MODE_DISABLED
	# 相机输出与切片预载在回程中继续工作，其余关卡逻辑冻结。
	output.process_mode = Node.PROCESS_MODE_ALWAYS
	streamer.process_mode = Node.PROCESS_MODE_ALWAYS
	impact_shake.play(camera, level.death_reason == &"fall")
	if level.death_reason == &"stranded":
		await level.get_node("OceanLink/FishStage/ShoreExit").play_death()
	elif level.death_reason == &"drown":
		await level.get_node("OceanLink/Breath").play_death()
	elif level.death_reason == &"tentacle":
		await level.get_node("OceanLink/FishStage/SideTentacle").play_death()
	elif level.death_reason in [&"shark",&"pink_shark",&"jellyfish_net"]:
		var knockback = level.get_node("OceanLink/FishStage/SharkKnockback")
		await knockback.play(level.player, camera, knockback.impact_direction)
	elif level.death_reason == &"bee":
		var squirrel_defeat=level.player.get_node("Defeat")
		if squirrel_defeat.falling: await squirrel_defeat.finished
	elif level.player == level.demon:
		await death_animation.play(level.demon, camera, level.get_node("Fork").held)
	overlay.show_death()

func _retry() -> void:
	if state != State.DEAD:
		return
	state = State.RETURNING
	await overlay.dismiss()
	var from: Vector2 = camera.global_position
	var from_zoom: Vector2 = camera.zoom
	impact_shake.stop()
	death_animation.reset()
	var checkpoint: Node2D = level.get_active_checkpoint()
	var use_checkpoint: bool = checkpoint != null
	level.restart()
	level.dead = true
	entry.reset_for_replay()
	if use_checkpoint:
		checkpoint.restore_player()
		level.player.hide()
	level.soul.hide()
	level.demon.hide()
	camera.set_process(false)
	var to: Vector2 = camera.global_position
	var to_zoom: Vector2 = camera.zoom
	camera.adopt_view(from, from_zoom)
	var seconds := clampf(from.distance_to(to) / return_pixels_per_second, return_min_seconds, return_max_seconds)
	_return_tween = create_tween().set_ignore_time_scale(true)
	_return_tween.tween_method(func(u: float): camera.adopt_view(from.lerp(to, u), from_zoom.lerp(to_zoom, u)), 0.0, 1.0, seconds).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await _return_tween.finished
	# 保留轻量预览作后备；最多等高清两秒，载入异常也不会卡死重来。
	var waited := 0.0
	while not streamer.is_view_ready() and waited < 2.0:
		await get_tree().create_timer(0.05, true, false, true).timeout
		waited += 0.05
	if use_checkpoint: level.player.show()
	else: level.demon.show()
	state = State.ENTERING
	level.process_mode = _saved_mode
	output.process_mode = _saved_output_mode
	streamer.process_mode = _saved_streamer_mode
	if use_checkpoint:
		checkpoint.finish_return()
		level.dead = false
		state = State.PLAYING
		camera.resume_follow_from_current_position(level.player)
		camera.set_process(true)
		retry_finished.emit()
	else:
		entry.play()

func _entry_finished() -> void:
	if state != State.ENTERING:
		return
	level.dead = false
	state = State.PLAYING
	camera.resume_follow_from_current_position(level.soul)
	camera.set_process(true)
	retry_finished.emit()

func _home() -> void:
	if state != State.DEAD:
		return
	impact_shake.stop()
	state = State.HOME
	await overlay.dismiss()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6] or event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]):
		# 分段试玩入口由全局处理，死亡和回程阶段也允许直接切换。
		return
	if state != State.PLAYING and event is InputEventKey:
		# 界面关闭后的回程也不允许首页 R/ESC 重载整段开场。
		if state in [State.RETURNING, State.ENTERING, State.HOME] or (state == State.DEAD and not overlay.visible):
			get_viewport().set_input_as_handled()
