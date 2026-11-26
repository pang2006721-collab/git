extends CanvasLayer
## 仅负责死亡界面的显示、弹入与按钮反馈，不处理关卡重置。
signal retry_requested
signal home_requested
signal presentation_finished
enum State { HIDDEN, ENTERING, OPEN, LEAVING }
@export_range(0.0, 0.9) var darkness: float = 0.68
@export var pop_seconds: float = 0.42
@export var button_stagger: float = 0.14
const STAGE_CARDS := {
	&"ocean": {"path": "res://assets/art/ui/death/ocean_end.png", "position": Vector2(696, 232)},
	&"jungle": {"path": "res://assets/art/ui/death/jungle_end.png", "position": Vector2(748, 210)},
	&"sky": {"path": "res://assets/art/ui/death/sky_end.png", "position": Vector2(727, 267)},
}
var death_stage: StringName = &"hell"
var _hell_texture: Texture2D
var state: State = State.HIDDEN
var _motion: Tween
var _hover: Dictionary = {}
var _retry_rest_y: float
var _home_rest_y: float
@onready var dim: ColorRect = $Root/Dim
@onready var stage: Node2D = $Root/Stage
@onready var card: TextureRect = $Root/Stage/Card
@onready var retry: TextureButton = $Root/Stage/Retry
@onready var home: TextureButton = $Root/Stage/Home

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	_hell_texture = card.texture
	_retry_rest_y = retry.position.y
	_home_rest_y = home.position.y
	get_viewport().size_changed.connect(_layout)
	_layout()
	for button in [retry, home]:
		button.mouse_entered.connect(func(): _hover_button(button, 1.05))
		button.mouse_exited.connect(func(): _hover_button(button, 1.0))
		var mask := BitMap.new()
		mask.create_from_image_alpha(button.texture_normal.get_image())
		button.texture_click_mask = mask
	retry.pressed.connect(func(): _choose(true))
	home.pressed.connect(func(): _choose(false))

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	stage.scale = Vector2.ONE * fit
	stage.position = (viewport_size - Vector2(1920, 1080) * fit) * 0.5

func _set_stage_card(stage_name: StringName) -> void:
	death_stage = stage_name if STAGE_CARDS.has(stage_name) else &"hell"
	if death_stage == &"hell":
		card.texture = _hell_texture
		card.position = Vector2(627, 184)
	else:
		var art: Dictionary = STAGE_CARDS[death_stage]
		card.texture = load(art.path)
		card.position = art.position
	# 每张原画使用 PSD 中的实际尺寸与位置，不拉伸成恶魔的长宽比。
	card.size = card.texture.get_size()
	card.pivot_offset = card.size * 0.5

func show_death(stage_name: StringName = &"hell") -> void:
	if state != State.HIDDEN:
		return
	_set_stage_card(stage_name)
	state = State.ENTERING
	visible = true
	dim.color.a = 0.0
	card.scale = Vector2.ONE * 0.12
	for button in [retry, home]:
		button.position.y = 1160.0
		button.scale = Vector2.ONE
		button.disabled = true
	_motion = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_motion.tween_property(dim, "color:a", darkness, 0.22)
	_motion.tween_property(card, "scale", Vector2.ONE, pop_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_property(retry, "position:y", _retry_rest_y, 0.38).set_delay(0.23).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_property(home, "position:y", _home_rest_y, 0.38).set_delay(0.23 + button_stagger).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.chain().tween_callback(func():
		state = State.OPEN
		retry.disabled = false
		home.disabled = false
		presentation_finished.emit())

func _choose(restart_level: bool) -> void:
	if state != State.OPEN:
		return
	state = State.LEAVING
	retry.disabled = true
	home.disabled = true
	if restart_level:
		retry_requested.emit()
	else:
		home_requested.emit()

func dismiss() -> void:
	state = State.LEAVING
	if is_instance_valid(_motion):
		_motion.kill()
	for tween in _hover.values():
		if is_instance_valid(tween): tween.kill()
	_motion = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_motion.tween_property(dim, "color:a", 0.0, 0.18)
	_motion.tween_property(card, "modulate:a", 0.0, 0.12)
	_motion.tween_property(retry, "position:y", 1160.0, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion.tween_property(home, "position:y", 1160.0, 0.17).set_delay(0.035).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _motion.finished
	visible = false
	state = State.HIDDEN
	card.modulate.a = 1.0

func _hover_button(button: TextureButton, amount: float) -> void:
	if state != State.OPEN:
		return
	if _hover.has(button) and is_instance_valid(_hover[button]): _hover[button].kill()
	var tween := create_tween().set_ignore_time_scale(true)
	_hover[button] = tween
	tween.tween_property(button, "scale", Vector2.ONE * amount, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	# 不让首页的 R 重播穿透死亡界面。
	if event.physical_keycode in [KEY_R, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		if not event.echo and state == State.OPEN:
			_choose(event.physical_keycode == KEY_R)
