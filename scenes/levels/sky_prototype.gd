extends Node2D
const BACKDROP=preload("res://assets/art/sky/sky_canopy_v001.png")
const OPEN_CANOPY=preload("res://assets/art/sky/sky_canopy_open_v001.png")
const RIPPLE=preload("res://assets/art/sky/canopy_ripple_v001.png")
@onready var bird:CharacterBody2D=$Bird
@onready var possession:PossessionController=$Possession
@onready var bouncer=$Bouncer
@onready var heaven_exit=$HeavenExit
var camera:FollowCamera
var active:=false
var _ripple:Sprite2D
var _squirrel:CharacterBody2D
var _standalone:=false
var _bird_spawn:=Vector2.ZERO
var _squirrel_original_z:int=0
var _canopy_pixels:Image
func _ready() -> void:
	_bird_spawn=bird.position
	process_mode=Node.PROCESS_MODE_PAUSABLE
	if not InputMap.has_action(&"flap"):
		InputMap.add_action(&"flap")
		var key:=InputEventKey.new()
		key.physical_keycode=KEY_W
		InputMap.action_add_event(&"flap",key)
	_ripple=$CanopyRipple
	_canopy_pixels=BACKDROP.get_image()
	_ripple.visibility_changed.connect(func(): $RippleCover.visible=_ripple.visible)
	$FollowCamera.enabled=false
	heaven_exit.arrived.connect(func(ghost):
		if is_instance_valid(_squirrel) and _squirrel.get_parent().has_signal("squirrel_possessed"):
			_squirrel.get_parent().squirrel_possessed.emit(ghost))
	possession.possession_started.connect(func(_chosen): bouncer.release_host())
	possession.possession_finished.connect(func(_chosen):
		if _squirrel.get_parent().has_signal("squirrel_possessed"):
			_squirrel.get_parent().squirrel_possessed.emit(bird))
	_standalone=get_parent()==get_tree().root
	if _standalone:
		var squirrel=preload("res://scenes/actors/squirrel.tscn").instantiate()
		add_child(squirrel)
		squirrel.get_node("Host").take_control()
		set_camera($FollowCamera)
		$FollowCamera.enabled=true
		begin(squirrel,960)
		camera.snap_to_target()
func canopy_y(x:float) -> float:
	# 从编辑器中的真实碰撞轮廓读取高度，手动改点或移动节点都会生效。
	var shape:CollisionPolygon2D=$CanopySurface/CollisionPolygon2D
	var points:=shape.polygon
	for i in range(points.size()-1):
		var a:Vector2=to_local(shape.to_global(points[i]))
		var b:Vector2=to_local(shape.to_global(points[i+1]))
		if b.x>a.x and x>=a.x and x<=b.x:
			return lerpf(a.y,b.y,(x-a.x)/(b.x-a.x))
	return 5500.0
func set_camera(shared_camera:FollowCamera) -> void:
	camera=shared_camera
	heaven_exit.set_camera(shared_camera)
	possession.camera=camera
	possession.shot._camera=camera
func begin(squirrel:CharacterBody2D, x:float) -> void:
	active=true
	_squirrel=squirrel
	_squirrel_original_z=squirrel.z_index
	squirrel.z_index=7
	set_camera(camera)
	possession.set_source_body(squirrel,Vector2(0,-75)*squirrel.global_scale)
	possession.enabled=true
	bouncer.begin(squirrel,x)
	camera.resume_follow_from_current_position(squirrel)
	camera.set_process(true)
func ripple_at(x:float) -> void:
	_ripple.position=Vector2(x,canopy_y(x)+110)
	var cover:ColorRect=$RippleCover
	cover.position=_ripple.position-Vector2(cover.size.x*0.5,0)
	# 方块只取出入口下方原图的树冠颜色，不改变原有身体和地图效果。
	var source_x:=clampi(int(x*1080.0/1920.0),0,_canopy_pixels.get_width()-1)
	var source_y:=clampi(int((_ripple.position.y+40)*1080.0/1920.0),0,_canopy_pixels.get_height()-1)
	cover.color=_canopy_pixels.get_pixel(source_x,source_y)
	_ripple.pulse()
func _physics_process(_delta:float) -> void:
	if not active or heaven_exit.active or heaven_exit.completed:
		return
	possession.enabled=not bouncer.buried and bouncer.enabled and possession.state==PossessionController.State.ROAMING
	if possession.state==PossessionController.State.TRANSFERRING:
		possession.enabled=true
	if bird.get_node("Host").claimed:
		var floor_y:float=canopy_y(bird.position.x)-bird.get_node("Collision").shape.radius
		if bird.position.y>floor_y:
			bird.position.y=floor_y
			bird.velocity.y=minf(bird.velocity.y,0)
func reset() -> void:
	heaven_exit.reset()
	_ripple.reset()
	if is_instance_valid(_squirrel):
		_squirrel.z_index=_squirrel_original_z
	active=false
	bouncer.reset()
	possession.reset()
	possession.enabled=false
	bird.position=_bird_spawn
	bird.get_node("Host").reset()

func _unhandled_input(event:InputEvent) -> void:
	if _standalone and event.is_action_pressed(&"restart") and not event.is_echo():
		reset()
		_squirrel.get_node("Host").take_control()
		begin(_squirrel,960)
		camera.snap_to_target()
