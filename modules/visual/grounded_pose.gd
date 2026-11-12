class_name GroundedPose
extends Node
## 地面姿态以脚底为锚点；转身同步翻转水平偏移，弹性和倾斜不再抬起脚底。
@export_node_path("CharacterBody2D") var body_path: NodePath = ^".."
@export_node_path("Sprite2D") var sprite_path: NodePath = ^"../Visual/Sprite"
@export var grounded_texture: Texture2D
@export var airborne_texture: Texture2D
@export var grounded_offset := Vector2(34,-81.5)
@export var airborne_offset := Vector2(0,-81)
@export_node_path("Node") var climber_path: NodePath
var _body: CharacterBody2D
var _sprite: Sprite2D
var _motor: PlatformerMotor
var _climber: VineClimber
func _ready() -> void:
	process_priority=1
	_body=get_node(body_path)
	_sprite=get_node(sprite_path)
	_motor=_body.get_node("Movement")
	if not climber_path.is_empty():
		_climber=get_node(climber_path)
func _process(_delta: float) -> void:
	if _climber!=null and _climber.vine!=null:
		# 面朝抓取的藤蔓，避免身体随着摆速翻成背对藤蔓。
		_sprite.flip_h=_climber.grip_side<0
	var grounded:=_body.is_on_floor() and _motor.enabled
	_sprite.texture=grounded_texture if grounded else airborne_texture
	var anchor:=grounded_offset if grounded else airborne_offset
	_sprite.position=Vector2(-anchor.x if _sprite.flip_h else anchor.x,anchor.y)
