extends Node
## 两块原画底板保持不变，文字按设置的四种语言即时切换。
const FOLDER = "res://assets/art/menu/localized/"
const ART = {
	"start_base": preload(FOLDER+"start_base.png"),
	"settings_base": preload(FOLDER+"settings_base.png"),
	"start_en": preload(FOLDER+"start_en.png"),
	"start_zh": preload(FOLDER+"start_zh.png"),
	"start_ko": preload(FOLDER+"start_ko.png"),
	"start_es": preload(FOLDER+"start_es.png"),
	"settings_en": preload(FOLDER+"settings_en.png"),
	"settings_zh": preload(FOLDER+"settings_zh.png"),
	"settings_ko": preload(FOLDER+"settings_ko.png"),
	"settings_es": preload(FOLDER+"settings_es.png"),
}
var _bounds: Dictionary
var _buttons: Dictionary = {}
var labels: Dictionary = {}

func configure(start: TextureButton, settings: TextureButton) -> void:
	_bounds = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"layers.json"))
	_buttons = {"start": start, "settings": settings}
	for key in _buttons:
		var button: TextureButton = _buttons[key]
		var box: Array = _bounds[key+"_base"]
		button.texture_normal = ART[key+"_base"]
		button.position = Vector2(box[0],box[1])
		button.size = Vector2(box[2]-box[0],box[3]-box[1])
		# 开始按钮绕下方蓝底中心回弹，上方角色一起跟随。
		button.pivot_offset = Vector2(button.size.x*0.5,240.0 if key == "start" else button.size.y*0.5)
		var label := TextureRect.new()
		label.name = "LocalizedLabel"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
		labels[key] = label
	GameSettings.changed.connect(refresh)
	refresh()

func refresh() -> void:
	var language: String = GameSettings.LANGUAGES[GameSettings.language_index]
	for key in _buttons:
		var name_key: String = key+"_"+language
		var label: TextureRect = labels[key]
		var box: Array = _bounds[name_key]
		var base: Array = _bounds[key+"_base"]
		label.texture = ART[name_key]
		label.position = Vector2(box[0]-base[0],box[1]-base[1])
		label.size = Vector2(box[2]-box[0],box[3]-box[1])
