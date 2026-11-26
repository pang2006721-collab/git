extends Node2D
const SETTINGS_POPUP = preload("res://modules/ui/settings_popup.gd")
var _settings_popup: CanvasLayer
var _localized_buttons: Node
var _starting := false
func _ready() -> void:
	_localized_buttons = preload("res://modules/ui/localized_menu_buttons.gd").new()
	add_child(_localized_buttons)
	_localized_buttons.configure($Start, $Settings)
	_settings_popup = SETTINGS_POPUP.new()
	add_child(_settings_popup)
	_settings_popup.closed.connect(_settings_closed)
	Bgm.play_track(Bgm.Track.MENU)
	$ArrivalMotion.arrived.connect(func(): Bgm.play_track(Bgm.Track.HELL))
	$Start.pressed.connect(_start_game)
	$Settings.pressed.connect(_settings_pressed)
	$Start.mouse_entered.connect($Start/Pulse.pulse)
	$Settings.mouse_entered.connect($Settings/Pulse.pulse)
	$DescentTransition.descent_started.connect($ExitMotion.play)
	$DescentTransition.descent_started.connect($LoadingOverlay.begin_loading)
	$ArrivalMotion.arrived.connect($LoadingOverlay.finish_loading)
	$LoadingOverlay.finished.connect($OpeningChase.start)
	$LoadingOverlay.finished.connect($GameHandoff.prepare)
	$OpeningChase.finished.connect($GameHandoff.play)
	$OpeningChase.ghost_returned.connect($DescentWorld/ArrivalMap/NearMissArrows.start)
	$OpeningChase.ghost_returned.connect($DescentWorld/ArrivalMap/PillarArrows.start)
	$OpeningChase.finished.connect($DescentWorld/ArrivalMap/NearMissArrows.stop)
	$OpeningChase.finished.connect($DescentWorld/ArrivalMap/ExitArrows.start)
func _settings_pressed() -> void:
	$Settings/Pulse.pulse()
	if $Bird/MouseDrag.dragging:
		$Bird/MouseDrag.end_drag()
	$Bird/MouseDrag.set_process_input(false)
	_settings_popup.open()

func _settings_closed() -> void:
	if not _starting:
		$Bird/MouseDrag.set_process_input(true)
func _start_game() -> void:
	if _starting or _settings_popup.is_open():
		return
	_starting = true
	$GameHandoff.warmup()
	$Start/Pulse.pulse()
	$Start.disabled = true
	$Settings.disabled = true
	if $Bird/MouseDrag.dragging:
		$Bird/MouseDrag.end_drag()
	$Bird/MouseDrag.set_process_input(false)
	$DescentTransition.start()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or (_starting and event.physical_keycode == KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			get_tree().reload_current_scene()
