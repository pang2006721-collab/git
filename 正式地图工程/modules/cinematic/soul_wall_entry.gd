extends Node
## 幽灵从左侧洞口短暂探出，再交回已有移动与输入模块。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
signal control_ready
@export var body_path: NodePath = ^"../Soul"
@export var spawn_path: NodePath = ^"../WallSpawn"
@export var landing_path: NodePath = ^"../LandingPoint"
@export var duration: float = 0.6
@export var cave_edge_offset: float = 40.0
@export var ground_shape_path: NodePath = ^"../Ground/Collision"
var _start_position: Vector2
var _landing_position: Vector2
var playing: bool = false
var completed: bool = false
var elapsed: float = 0.0
var _original_material: Material
var _exit_material: ShaderMaterial
@onready var soul: CharacterBody2D = get_node(body_path)
@onready var start_point: Marker2D = get_node(spawn_path)
@onready var landing_point: Marker2D = get_node(landing_path)

func _ready() -> void:
	_landing_position = landing_point.position
	var ground := get_node_or_null(ground_shape_path) as CollisionPolygon2D
	if ground != null:
		var point: Vector2 = SURFACE.top_at(ground, landing_point.global_position.x)
		if is_finite(point.y):
			_landing_position.y = soul.get_parent().to_local(point).y
	_start_position = start_point.position
	_start_position.y += _landing_position.y - landing_point.position.y
	soul.position = _start_position
	soul.hide()
	soul.get_node("Input").enabled = false
	soul.get_node("Movement").enabled = false
	soul.get_node("Collision").disabled = true

func play() -> void:
	if playing or completed:
		return
	playing = true
	soul.show()
	var sprite: Sprite2D = soul.get_node("Visual/Sprite")
	_original_material = sprite.material
	_exit_material = ShaderMaterial.new()
	_exit_material.shader = preload("res://shaders/soul_cave_exit.gdshader")
	_exit_material.set_shader_parameter("cave_edge_x", soul.get_parent().to_global(start_point.position + Vector2(cave_edge_offset, 0)).x)
	sprite.material = _exit_material

func _process(delta: float) -> void:
	if not playing:
		return
	elapsed = minf(elapsed + delta, duration)
	var u: float = elapsed / duration
	_landing_position = landing_point.position
	var ground := get_node_or_null(ground_shape_path) as CollisionPolygon2D
	if ground != null:
		var point: Vector2 = SURFACE.top_at(ground, landing_point.global_position.x)
		if is_finite(point.y):
			_landing_position.y = soul.get_parent().to_local(point).y
	_start_position = start_point.position
	_start_position.y += _landing_position.y - landing_point.position.y
	var eased := 1.0 - pow(1.0 - u, 3.0)
	soul.position = _start_position.lerp(_landing_position, eased)
	if u >= 1.0:
		playing = false
		completed = true
		soul.get_node("Visual/Sprite").material = _original_material
		soul.get_node("Movement").reset()
		soul.get_node("Collision").set_deferred("disabled", false)
		soul.get_node("Movement").enabled = true
		soul.get_node("Input").enabled = true
		control_ready.emit()

func reset_for_replay() -> void:
	## 重来只复用洞口入场，不重新播放追逐过场。
	playing = false
	completed = false
	elapsed = 0.0
	var sprite: Sprite2D = soul.get_node("Visual/Sprite")
	if _exit_material != null and sprite.material == _exit_material:
		sprite.material = _original_material
	_exit_material = null
	soul.position = start_point.position
	soul.velocity = Vector2.ZERO
	soul.hide()
	soul.get_node("Input").clear()
	soul.get_node("Input").enabled = false
	soul.get_node("Movement").enabled = false
	soul.get_node("Collision").set_deferred("disabled", true)
