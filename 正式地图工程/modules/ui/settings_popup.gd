extends CanvasLayer
## PSD原图分层摆放，透明交互层不替换手绘美术。
signal closed
const FOLDER = "res://assets/art/ui/settings/"
const ART = {
	"panel": preload("res://assets/art/ui/settings/panel.png"),
	"decoration": preload("res://assets/art/ui/settings/decoration.png"),
	"sfx_track": preload("res://assets/art/ui/settings/sfx_track.png"),
	"music_track": preload("res://assets/art/ui/settings/music_track.png"),
	"music_icon": preload("res://assets/art/ui/settings/music_icon.png"),
	"speaker_low": preload("res://assets/art/ui/settings/speaker_low.png"),
	"speaker_medium": preload("res://assets/art/ui/settings/speaker_medium.png"),
	"speaker_high": preload("res://assets/art/ui/settings/speaker_high.png"),
	"english": preload("res://assets/art/ui/settings/english.png"),
	"chinese": preload("res://assets/art/ui/settings/chinese.png"),
	"korean": preload("res://assets/art/ui/settings/korean.png"),
	"spanish": preload("res://assets/art/ui/settings/spanish.png"),
	"arrows": preload("res://assets/art/ui/settings/arrows.png"),
	"sfx_knob": preload("res://assets/art/ui/settings/sfx_knob.png"),
	"music_knob": preload("res://assets/art/ui/settings/music_knob.png"),
}
const LANG_ART = ["english", "chinese", "korean", "spanish"]
var _root: Control
var _content: Control
var _speaker: TextureRect
var _language: TextureRect
var _arrows: TextureRect
var _music_icon: TextureRect
var _feedback: Node
var _knobs: Dictionary = {}
var _sfx: HSlider
var _music: HSlider
var _close_button: TextureButton
var _motion: Tween
var _opened := false
var _closing := false
var _bounds: Dictionary

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_bounds = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "layers.json"))
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var outside := ColorRect.new()
	outside.color = Color(0.03, 0.04, 0.10, 0.32)
	outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(outside)
	outside.gui_input.connect(_outside_input)
	_content = Control.new()
	_content.size = Vector2(1920, 1080)
	_content.pivot_offset = Vector2(960, 540)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)
	# 面板本身拦住点击，装饰部分不拦住滑杆与语言交互。
	var panel := _art("panel")
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var outline := ShaderMaterial.new()
	outline.shader = preload("res://shaders/settings_panel_outline.gdshader")
	panel.material = outline
	_art("decoration")
	_art("sfx_track")
	_art("music_track")
	_music_icon = _art("music_icon")
	_speaker = _art("speaker_high")
	_language = _art(LANG_ART[GameSettings.language_index])
	_arrows = _art("arrows")
	_feedback = preload("res://modules/ui/settings_interaction_bounce.gd").new()
	add_child(_feedback)
	_sfx = _slider(Vector2(815, 334), "sfx_knob", GameSettings.sfx_volume)
	_music = _slider(Vector2(814, 491), "music_knob", GameSettings.music_volume)
	_sfx.value_changed.connect(GameSettings.set_sfx)
	_music.value_changed.connect(GameSettings.set_music)
	_sfx.value_changed.connect(_slider_feedback.bind(_sfx, _speaker))
	_music.value_changed.connect(_slider_feedback.bind(_music, _music_icon))
	_sfx.drag_started.connect(_slider_pressed.bind(_sfx, _speaker))
	_music.drag_started.connect(_slider_pressed.bind(_music, _music_icon))
	_sfx.drag_ended.connect(_slider_released.bind(_sfx, _speaker))
	_music.drag_ended.connect(_slider_released.bind(_music, _music_icon))
	# 整栏默认向下翻；两个箭头单独覆盖对应点击区域。
	_hit(Rect2(680, 635, 505, 90), 1)
	_hit(Rect2(1050, 642, 67, 38), -1)
	_hit(Rect2(1050, 681, 67, 38), 1)
	_close_button = TextureButton.new()
	_close_button.name = "Close"
	_close_button.texture_normal = preload("res://assets/art/ui/settings/close.svg")
	_close_button.position = Vector2(1254, 215)
	_close_button.size = Vector2(60, 60)
	_close_button.ignore_texture_size = true
	_close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.pressed.connect(close)
	_content.add_child(_close_button)
	GameSettings.changed.connect(_refresh)
	_root.resized.connect(_layout)
	_layout()
	_refresh()
	_root.hide()

func _art(key: String) -> TextureRect:
	var art := TextureRect.new()
	art.texture = ART[key]
	var box: Array = _bounds[key]
	art.position = Vector2(box[0], box[1])
	art.size = Vector2(box[2] - box[0], box[3] - box[1])
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(art)
	return art

func _slider(at: Vector2, knob: String, value: float) -> HSlider:
	var slider := HSlider.new()
	slider.position = at
	slider.size = Vector2(336, 68)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for key in ["slider", "grabber_area", "grabber_area_highlight"]:
		slider.add_theme_stylebox_override(key, empty)
	var texture := ART[knob] as Texture2D
	# 保留原34像素抓取尺寸，透明原生小球，单独美术小球做回弹。
	var invisible := preload("res://assets/art/ui/settings/slider_hitbox.svg")
	for key in ["grabber", "grabber_highlight", "grabber_disabled"]:
		slider.add_theme_icon_override(key, invisible)
	_content.add_child(slider)
	var art := TextureRect.new()
	art.texture = texture
	art.size = Vector2(34, 34)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(art)
	_knobs[slider] = art
	_position_knob(slider)
	return slider

func _hit(rect: Rect2, direction: int) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	button.pressed.connect(_cycle_language.bind(direction))
	_content.add_child(button)

func _position_knob(slider: HSlider) -> void:
	var knob: TextureRect = _knobs[slider]
	knob.position = slider.position + Vector2(slider.value * (slider.size.x - 34.0), (slider.size.y - 34.0) * 0.5)

func _slider_pressed(slider: HSlider, icon: TextureRect) -> void:
	_feedback.pulse(_knobs[slider], 0.18)
	_feedback.pulse(icon, 0.12)

func _slider_feedback(_value: float, slider: HSlider, icon: TextureRect) -> void:
	_position_knob(slider)
	if not _opened or _closing: return
	_feedback.pulse(_knobs[slider], 0.16, 0.14)
	_feedback.pulse(icon, 0.10, 0.14)

func _slider_released(_changed: bool, slider: HSlider, icon: TextureRect) -> void:
	_feedback.pulse(_knobs[slider], 0.18)
	_feedback.pulse(icon, 0.12)
	Sfx.play(&"ui")

func _cycle_language(direction: int) -> void:
	GameSettings.cycle_language(direction)
	_feedback.pulse(_language, 0.20)
	_feedback.pulse(_arrows, 0.12)

func _refresh() -> void:
	_sfx.set_value_no_signal(GameSettings.sfx_volume)
	_music.set_value_no_signal(GameSettings.music_volume)
	_position_knob(_sfx)
	_position_knob(_music)
	var speaker_key := "speaker_low" if GameSettings.sfx_volume < 0.34 else ("speaker_medium" if GameSettings.sfx_volume < 0.67 else "speaker_high")
	_set_art(_speaker, speaker_key)
	_set_art(_language, LANG_ART[GameSettings.language_index])

func _set_art(art: TextureRect, key: String) -> void:
	art.texture = ART[key]
	var box: Array = _bounds[key]
	art.position = Vector2(box[0], box[1])
	art.size = Vector2(box[2] - box[0], box[3] - box[1])
	art.pivot_offset = art.size * 0.5

func _layout() -> void:
	var view := _root.size
	var ratio := minf(view.x / 1920.0, view.y / 1080.0)
	_content.scale = Vector2.ONE * ratio
	_content.position = (view - Vector2(1920, 1080)) * 0.5

func open() -> void:
	if _opened: return
	_opened = true
	_closing = false
	_feedback.reset()
	_root.show()
	_root.modulate.a = 1.0
	_sfx.set_value_no_signal(GameSettings.sfx_volume)
	_music.set_value_no_signal(GameSettings.music_volume)
	_refresh()
	_layout()
	var target := _content.scale
	_content.scale = target * 0.86
	if _motion: _motion.kill()
	_motion = create_tween()
	_motion.tween_property(_content, "scale", target, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	if not _opened or _closing: return
	_closing = true
	if _motion: _motion.kill()
	_motion = create_tween().set_parallel()
	_motion.tween_property(_content, "scale", _content.scale * 0.94, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion.tween_property(_root, "modulate:a", 0.0, 0.14)
	_motion.chain().tween_callback(_finish_close)

func _finish_close() -> void:
	_feedback.reset()
	_root.hide()
	_opened = false
	_closing = false
	closed.emit()

func is_open() -> bool:
	return _opened

func _outside_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close()
		_root.accept_event()

func _input(event: InputEvent) -> void:
	if _opened and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
