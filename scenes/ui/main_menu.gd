extends Node2D
var _starting := false
func _ready() -> void:
	$Start.pressed.connect(_start_game)
	$Settings.pressed.connect(_settings_pressed)
	$Start.mouse_entered.connect($Start/Pulse.pulse)
	$Settings.mouse_entered.connect($Settings/Pulse.pulse)
func _settings_pressed() -> void:
	$Settings/Pulse.pulse()
func _start_game() -> void:
	if _starting:
		return
	_starting = true
	$Start/Pulse.pulse()
	$Start.disabled = true
	await get_tree().create_timer(0.32).timeout
	get_tree().change_scene_to_file("res://scenes/game_flow.tscn")
