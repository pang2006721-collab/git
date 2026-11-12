extends Node2D
@export var flap_texture:Texture2D
@export var flap_pose_duration:float=0.20
@export var flap_sprite_offset:=Vector2(-0.7,2.1)
var _pulse := 0.0
var _wing := 0.0
var _pose_time:=0.0
var _normal_texture:Texture2D
var _normal_position:=Vector2.ZERO
func _ready() -> void:
	_normal_texture=$Sprite.texture
	_normal_position=$Sprite.position
	get_node("../Movement").flapped.connect(_on_flap)
func _on_flap() -> void:
	_wing=1.0
	_pose_time=flap_pose_duration
	_apply_pose()
func _apply_pose() -> void:
	var rising:=_pose_time>0 and flap_texture!=null
	$Sprite.texture=flap_texture if rising else _normal_texture
	$Sprite.position=_normal_position
	if rising:
		$Sprite.position+=Vector2(-flap_sprite_offset.x if $Sprite.flip_h else flap_sprite_offset.x,flap_sprite_offset.y)
func _process(delta: float) -> void:
	var reader:PlatformerInput=get_node("../Input")
	if absf(reader.move_axis)>0.05:
		$Sprite.flip_h=reader.move_axis>0
		# 选中图带作者绘制的 SHIFT，不随朝向镜像文字。
		if has_node("SelectedSprite"):
			$SelectedSprite.flip_h=false
	_pose_time=maxf(0,_pose_time-delta)
	_apply_pose()
	_wing=move_toward(_wing,0,delta*5)
	_pulse=move_toward(_pulse,0,delta*4)
	scale=Vector2(1+_pulse*0.18-_wing*0.06,1-_pulse*0.12+_wing*0.12)
	rotation=lerp_angle(rotation,clampf(get_parent().velocity.y/2400.0,-0.18,0.22),1-exp(-10*delta))
func play_selection_pulse() -> void:
	_pulse=1
func play_possession_pulse() -> void:
	_wing=1
func reset() -> void:
	_pose_time=0
	_apply_pose()
	_pulse=0
	_wing=0
	scale=Vector2.ONE
	rotation=0
