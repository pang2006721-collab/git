extends Node
## 只保存设置值，音量通过独立总线作用于全部场景。
signal changed
const SAVE_PATH = "user://settings.cfg"
var save_path: String = SAVE_PATH
const LANGUAGES = ["en", "zh", "ko", "es"]
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var language_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		sfx_volume = clampf(float(config.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
		music_volume = clampf(float(config.get_value("audio", "music", 1.0)), 0.0, 1.0)
		language_index = clampi(int(config.get_value("language", "index", 0)), 0, 3)
	_apply()

func set_sfx(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_store()

func set_music(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_store()

func cycle_language(direction: int) -> void:
	language_index = posmod(language_index + direction, LANGUAGES.size())
	_store()

func _store() -> void:
	_apply()
	var config := ConfigFile.new()
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("language", "index", language_index)
	config.save(save_path)
	changed.emit()

func _apply() -> void:
	for entry in [["SFX", sfx_volume], ["BgmMusic", music_volume]]:
		var index := AudioServer.get_bus_index(entry[0])
		if index >= 0:
			AudioServer.set_bus_volume_linear(index, entry[1])
			AudioServer.set_bus_mute(index, entry[1] <= 0.0)
	TranslationServer.set_locale(LANGUAGES[language_index])
