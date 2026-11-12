class_name DrowningSource
extends Node
## Breath urgency and a cancellable death/disappearance. No UI or camera logic here.

signal drowned
signal vanished(from_timeout: bool)
enum State { BREATHING, RELEASED, DEAD, GONE }

@export_node_path("CharacterBody2D") var body_path: NodePath = ^".."
@export var dead_texture: Texture2D
@export var breath_duration: float = 16.0
@export var initial_redness: float = 0.15
@export var critical_color: Color = Color(1.0, 0.28, 0.28)
@export var release_death_delay: float = 0.12
@export var corpse_hold_time: float = 0.65
@export var disappearance_duration: float = 0.75

var state: State = State.BREATHING
var elapsed: float = 0.0
var _body: CharacterBody2D
var _sprite: Sprite2D
var _visual: SquashStretch
var _motor: PlatformerMotor
var _reader: PlatformerInput
var _live_texture: Texture2D
var _release_tween: Tween
var _death_tween: Tween


func _ready() -> void:
	_body = get_node(body_path) as CharacterBody2D
	_visual = _body.get_node("Visual") as SquashStretch
	_sprite = _visual.get_node("Sprite") as Sprite2D
	_motor = _body.get_node("Movement") as PlatformerMotor
	_reader = _body.get_node("Input") as PlatformerInput
	_live_texture = _sprite.texture
	_visual.modulate = Color.WHITE.lerp(critical_color, initial_redness)


func _process(delta: float) -> void:
	if state != State.BREATHING:
		return
	elapsed += delta
	var progress := clampf(elapsed / maxf(breath_duration, 0.01), 0.0, 1.0)
	_visual.modulate = Color.WHITE.lerp(critical_color, lerpf(initial_redness, 1.0, progress))
	if progress >= 1.0:
		drowned.emit()
		_begin_death(true)


func release_soul() -> void:
	if state != State.BREATHING:
		return
	state = State.RELEASED
	_freeze_body()
	_release_tween = create_tween().set_ignore_time_scale(true)
	_release_tween.tween_interval(release_death_delay)
	_release_tween.tween_callback(_begin_death.bind(false))


func _begin_death(from_timeout: bool) -> void:
	state = State.DEAD
	_freeze_body()
	_visual.set_process(false)
	_sprite.texture = dead_texture
	_death_tween = create_tween().set_ignore_time_scale(true)
	_death_tween.tween_interval(corpse_hold_time)
	_death_tween.tween_property(_visual, "modulate:a", 0.0, disappearance_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_death_tween.tween_callback(_finish_death.bind(from_timeout))


func _finish_death(from_timeout: bool) -> void:
	state = State.GONE
	_body.hide()
	vanished.emit(from_timeout)


func _freeze_body() -> void:
	_reader.enabled = false
	_reader.clear()
	_motor.enabled = false
	_body.velocity = Vector2.ZERO


func reset() -> void:
	if is_instance_valid(_release_tween):
		_release_tween.kill()
	if is_instance_valid(_death_tween):
		_death_tween.kill()
	state = State.BREATHING
	elapsed = 0.0
	_body.show()
	_sprite.texture = _live_texture
	_visual.reset()
	_visual.set_process(true)
	_visual.modulate = Color.WHITE.lerp(critical_color, initial_redness)
	_motor.enabled = true
	_motor.reset()
	_reader.enabled = true
	_reader.external_control = false
	_reader.clear()
