extends "res://modules/environment/hell_platform.gd"
signal fractured
## 使用作者手绘碎片；分离后独立累计速度和旋转，不再回写平台位置。
@export var debris_gravity: float = 1100.0
@export var separation_speed: float = 120.0
@export var spin_speed: float = 1.4
@export var debris_seconds: float = 1.4
@export var respawn_seconds: float = 5.0
var pieces: Array[Sprite2D] = []
var _piece_transforms: Array[Transform2D] = []
var _velocities: Array[Vector2] = []
var _art_transform: Transform2D
var _debris_elapsed: float = 0.0
var _respawn_tween: Tween

func _ready() -> void:
	super._ready()
	pieces.assign([$Piece1, $Piece2])
	_art_transform = sprite.transform
	for piece in pieces:
		_piece_transforms.append(piece.transform)
		_velocities.append(Vector2.ZERO)
		piece.hide()
	# 材质状态独立，踩踏一块平台不会使其他平台同时开裂。
	sprite.material = sprite.material.duplicate()

func _physics_process(delta: float) -> void:
	if broken:
		_update_debris(delta)
		return
	if _respawn_tween != null and _respawn_tween.is_running():
		return
	if not loaded:
		for body in get_tree().get_nodes_in_group("hell_players"):
			if not body.is_on_floor():
				continue
			for index in range(body.get_slide_collision_count()):
				if body.get_slide_collision(index).get_collider() == self:
					loaded = true
	if not loaded:
		return
	progress = minf(progress + delta, break_seconds)
	var amount := progress / break_seconds
	(sprite.material as ShaderMaterial).set_shader_parameter("fracture_amount", smoothstep(0.3, 1.0, amount))
	# 只让图案轻微松动，承重碰撞保持在编辑器保存的位置。
	sprite.position = _art_transform.origin + Vector2(sin(progress * 71.0), cos(progress * 43.0) * 0.5) * amount
	sprite.rotation = sin(progress * 57.0) * amount * 0.006
	if progress >= break_seconds:
		_release_pieces()

func _release_pieces() -> void:
	broken = true
	fractured.emit()
	collision.set_deferred("disabled", true)
	sprite.hide()
	sprite.transform = _art_transform
	_debris_elapsed = 0.0
	for index in range(pieces.size()):
		pieces[index].transform = _piece_transforms[index]
		pieces[index].show()
		pieces[index].modulate.a = 1.0
		var side := -1.0 if index == 0 else 1.0
		_velocities[index] = Vector2(side * separation_speed, -35.0 if index == 0 else -10.0)

func _update_debris(delta: float) -> void:
	_debris_elapsed += delta
	for index in range(pieces.size()):
		var piece := pieces[index]
		_velocities[index].y += debris_gravity * delta
		piece.position += _velocities[index] * delta
		piece.rotation += (-1.0 if index == 0 else 1.0) * spin_speed * delta
		piece.modulate.a = 1.0 - smoothstep(maxf(0.0, debris_seconds - 0.35), debris_seconds, _debris_elapsed)
		if _debris_elapsed >= debris_seconds:
			piece.hide()
	if _debris_elapsed >= respawn_seconds:
		reset()
		_sample_respawn(0.0)
		_respawn_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		_respawn_tween.tween_method(_sample_respawn, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _sample_respawn(amount: float) -> void:
	var stretch := Vector2(1.04, 0.65).lerp(Vector2.ONE, amount)
	sprite.scale = _art_transform.get_scale() * stretch
	# 弹性复原固定贴图上沿，避免落脚面随着图案缩放上下漂移。
	sprite.position = _art_transform.origin + Vector2(0, sprite.texture.get_height() * 0.5 * (stretch.y - 1.0))

func reset() -> void:
	if _respawn_tween != null:
		_respawn_tween.kill()
		_respawn_tween = null
	super.reset()
	_debris_elapsed = 0.0
	sprite.transform = _art_transform
	sprite.visible = collision != null
	(sprite.material as ShaderMaterial).set_shader_parameter("fracture_amount", 0.0)
	for index in range(pieces.size()):
		pieces[index].transform = _piece_transforms[index]
		pieces[index].modulate = Color.WHITE
		pieces[index].hide()
		_velocities[index] = Vector2.ZERO
	set_physics_process(collision != null)
