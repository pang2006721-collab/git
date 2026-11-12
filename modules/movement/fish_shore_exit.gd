class_name FishShoreExit
extends Node
## 水下推进、出水抛物线与上岸状态分别交接，始终由玩家控制出水时机。
signal landed_on_shore
signal died_on_shore
enum State { SWIMMING, AIRBORNE, STRANDED, DEAD }
@export_node_path("CharacterBody2D") var fish_path: NodePath = ^"../Fish"
@export var surface_y: float = -86.0
@export var leap_speed: float = 1350.0
@export var air_gravity: float = 1500.0
@export var air_control: float = 260.0
@export var stranding_duration: float = 6.0
@export var death_hold_duration: float = 0.8
@export var death_fade_duration: float = 0.7
@export var stranded_texture: Texture2D
@export var dead_texture: Texture2D
var state: State = State.SWIMMING
var elapsed: float = 0.0
var _fish: CharacterBody2D
var _motor: SwimMotor
var _reader: SwimInput
var _visual: SwimVisual
var _sprite: Sprite2D
var _host: PossessableHost
var _normal_texture: Texture2D
var _normal_sprite_position: Vector2
var _up_was_held: bool = false
var _death_tween: Tween

func _ready() -> void:
	process_physics_priority = -12
	_fish = get_node(fish_path)
	_motor = _fish.get_node("Movement")
	_reader = _fish.get_node("Input")
	_visual = _fish.get_node("Visual")
	_sprite = _visual.get_node("Sprite")
	_host = _fish.get_node("Host")
	_normal_texture = _sprite.texture
	_normal_sprite_position = _sprite.position

func _physics_process(delta: float) -> void:
	if not _host.claimed or state == State.DEAD:
		return
	if state == State.SWIMMING:
		if _fish.position.y <= surface_y and _reader.up_held and _fish.velocity.y < -80:
			state = State.AIRBORNE
			_motor.enabled = false
			_visual.set_process(false)
			_fish.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
			_fish.velocity.y = -leap_speed
		else:
			return
	var just_up := _reader.up_held and not _up_was_held
	_up_was_held = _reader.up_held
	if state == State.AIRBORNE:
		_fish.velocity.x += _reader.move_axis * air_control * delta
		_fish.velocity.x = clampf(_fish.velocity.x, -_motor.max_horizontal_speed, _motor.max_horizontal_speed)
		_fish.velocity.y += air_gravity * delta
		_fish.move_and_slide()
		_visual.rotation = lerpf(_visual.rotation, clampf(_fish.velocity.y / 2500.0, -0.25, 0.25), 1.0 - exp(-10.0 * delta))
		if _fish.is_on_floor():
			state = State.STRANDED
			elapsed = 0.0
			_sprite.texture = stranded_texture
			_sprite.position = Vector2(0, -11.5)
			_visual.rotation = 0.0
			landed_on_shore.emit()
		elif _fish.position.y > surface_y + 30 and _fish.velocity.y > 0:
			state = State.SWIMMING
			_fish.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
			_motor.enabled = true
			_visual.reset()
			_visual.set_process(true)
	elif state == State.STRANDED:
		elapsed += delta
		_fish.velocity.x = move_toward(_fish.velocity.x, _reader.move_axis * 55, 500 * delta)
		_fish.velocity.y += air_gravity * delta
		if just_up and _fish.is_on_floor():
			_fish.velocity.y = -180.0
		_fish.move_and_slide()
		var beat := maxf(0.0, sin(elapsed * 9.0)) * exp(-fmod(elapsed, 0.7) * 5.0)
		_visual.scale = Vector2(1.0 + beat * 0.10, 1.0 - beat * 0.12)
		_visual.rotation = sin(elapsed * 9.0) * 0.035
		if elapsed >= stranding_duration:
			release_soul()
	if absf(_reader.move_axis) > 0.05:
		_sprite.flip_h = _reader.move_axis > 0.0

func reset() -> void:
	if _death_tween != null:
		_death_tween.kill()
		_death_tween = null
	_fish.show()
	_visual.modulate.a = 1.0
	state = State.SWIMMING
	elapsed = 0.0
	_up_was_held = false
	_fish.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite.texture = _normal_texture
	_sprite.position = _normal_sprite_position
	_visual.reset()
	_visual.set_process(true)

func release_soul() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	_sprite.texture = dead_texture
	_visual.scale = Vector2.ONE
	_visual.rotation = 0.0
	_fish.velocity = Vector2.ZERO
	_reader.enabled = false
	_reader.clear()
	died_on_shore.emit()
	_death_tween = create_tween()
	_death_tween.tween_interval(death_hold_duration)
	_death_tween.tween_property(_visual, "modulate:a", 0.0, death_fade_duration)
	_death_tween.tween_callback(_fish.hide)
