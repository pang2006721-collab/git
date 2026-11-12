extends Node2D
signal arrived(ghost:CharacterBody2D)
@export var entry_y:float=-400.0
@export var entry_duration:float=0.65
var camera:FollowCamera
var active:=false
var completed:=false
var _elapsed:=0.0
var _entry:=Vector2.ZERO
var _sky:Node2D
var _travel:VerticalSceneTransition
@onready var heaven:Node2D=$Heaven
func _ready() -> void:
	_sky=get_parent()
	_travel=VerticalSceneTransition.new()
	add_child(_travel)
	_travel.finished.connect(func():
		active=false
		completed=true
		heaven.begin(camera)
		arrived.emit(heaven.ghost))
func set_camera(shared_camera:FollowCamera) -> void:
	camera=shared_camera
	heaven.god.target=_sky.bird
func _physics_process(delta:float) -> void:
	if camera==null or completed or not _sky.active:
		return
	var bird:CharacterBody2D=_sky.bird
	if not active:
		if not bird.get_node("Host").claimed:
			return
		bird.z_index=15 if bird.position.y<1500 else 7
		if bird.position.y>entry_y:
			return
		active=true
		_entry=bird.position
		bird.get_node("Movement").enabled=false
		bird.get_node("Input").enabled=false
		bird.get_node("Input").clear()
		bird.velocity=Vector2.ZERO
		_travel.prepare(camera,camera.zoom)
	_elapsed+=delta
	if _elapsed<=entry_duration:
		bird.position=_entry.lerp(_entry+Vector2(0,-360),smoothstep(0,entry_duration,_elapsed))
	elif not _travel.active:
		bird.hide()
		var destination:Vector2=heaven.get_node("GhostSpawn").global_position+heaven.room_framing_offset
		_travel.travel(camera,destination)
func reset() -> void:
	_travel.cancel()
	heaven.reset()
	active=false
	completed=false
	_elapsed=0
	_sky.bird.show()
	_sky.bird.z_index=7
