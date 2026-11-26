extends Node2D
## 冰雹致死的视觉替身：原角色冻结，死亡原画从命中位置向屏幕下方坠落。
signal finished
const ART_PATH = "res://assets/art/sky/expressions/bird_dead.png"
const ART_REGION = Rect2(526,2593,83,65)
@export var hit_seconds: float = 0.075
@export var initial_fall_speed: float = 90.0
@export var fall_gravity: float = 1800.0
var corpse: Sprite2D
var falling := false
var _original: Node2D
var _was_visible := true
var _motion: Tween
var _origin := Vector2.ZERO
var _scale := Vector2.ONE
var _rotation := 0.0
var _drift := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(body: CharacterBody2D, camera: Camera2D) -> void:
	reset()
	_original = body.get_node("Visual")
	_was_visible = _original.visible
	var source: Sprite2D = _original.get_node("Sprite")
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ART_PATH)
	atlas.region = ART_REGION
	atlas.filter_clip = true
	corpse = Sprite2D.new()
	corpse.texture = atlas
	corpse.flip_h = source.flip_h
	corpse.z_index = 40
	add_child(corpse)
	corpse.global_transform = source.global_transform
	_original.hide()
	_origin = corpse.global_position
	_scale = corpse.scale
	_rotation = corpse.rotation
	_drift = clampf(body.velocity.x * 0.18,-70.0,70.0)
	falling = true
	# 保持镜头在命中位置，替身自行坠出画面，不让镜头追着尸体向下。
	var bottom := camera.global_position.y + camera.offset.y + camera.get_viewport_rect().size.y * 0.5 / camera.zoom.y
	var distance := maxf(450.0,bottom + ART_REGION.size.y * absf(corpse.global_scale.y) - _origin.y)
	var seconds := (-initial_fall_speed + sqrt(initial_fall_speed * initial_fall_speed + 2.0 * fall_gravity * distance)) / fall_gravity
	_motion = create_tween().set_ignore_time_scale(true)
	_motion.tween_property(corpse,"scale",_scale * Vector2(1.12,1.0/1.12),hit_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion.tween_method(_sample,0.0,seconds,seconds)
	await _motion.finished
	if is_instance_valid(corpse): corpse.hide()
	falling = false
	finished.emit()

func _sample(t: float) -> void:
	corpse.global_position = _origin + Vector2(_drift*t,initial_fall_speed*t + 0.5*fall_gravity*t*t)
	var squash := lerpf(1.12,1.0,smoothstep(0.0,0.16,t))
	corpse.scale = _scale * Vector2(squash,1.0/squash)
	corpse.rotation = _rotation + deg_to_rad(16.0) * smoothstep(0.0,0.65,t) * (-1.0 if corpse.flip_h else 1.0)

func reset() -> void:
	if _motion != null: _motion.kill()
	if is_instance_valid(corpse): corpse.queue_free()
	corpse = null
	if is_instance_valid(_original): _original.visible = _was_visible
	_original = null
	falling = false
