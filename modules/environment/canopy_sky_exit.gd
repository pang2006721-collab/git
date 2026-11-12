extends Node2D
## 同一世界内的树冠入口和上升过场；树冠前景独立遮挡，不改变角色常规层级。
signal arrived
const ART = preload("res://assets/art/transitions/jungle_to_sky_v001.png")
const MASK = preload("res://shaders/canopy_occlusion.gdshader")
@export var entry_y: float = -35.0
@export var entry_region := Vector2(350, 1570)
@export var artwork_top: float = -3200.0
var camera: FollowCamera
var active := false
var completed := false
var _jungle: Node2D
var _entry_time := 0.0
var _start := Vector2.ZERO
var _travel: VerticalSceneTransition
var sky:Node2D
func _ready() -> void:
	_jungle = get_parent()
	sky=$Sky
	_travel = VerticalSceneTransition.new()
	add_child(_travel)
	_travel.finished.connect(func():
		active = false
		completed = true
		$CanopyOccluder.hide()
		sky.set_camera(camera)
		sky.begin(_jungle.squirrel,_start.x)
		arrived.emit())
func _physics_process(delta: float) -> void:
	if camera == null or completed:
		return
	var body: CharacterBody2D = _jungle.squirrel
	if not active:
		if not _jungle.host.claimed or body.position.y > entry_y or body.position.x < entry_region.x or body.position.x > entry_region.y:
			return
		active = true
		_start = body.position
		_jungle.climber.reset()
		body.get_node("Movement").enabled = false
		body.get_node("Input").enabled = false
		body.velocity = Vector2.ZERO
		_travel.prepare(camera, camera.zoom)
	_entry_time += delta
	if _entry_time <= 0.8:
		# 身体先向树丛深处移动，保持在树冠的第 4 层后面。
		body.position = _start.lerp(Vector2(_start.x, -280), smoothstep(0, 0.8, _entry_time))
	elif not _travel.active:
		body.hide()
		sky.set_camera(camera)
		_travel.travel(camera, sky.to_global(Vector2(960,sky.canopy_y(_start.x)-170)))
func reset() -> void:
	_travel.cancel()
	sky.reset()
	$CanopyOccluder.show()
	active = false
	completed = false
	_entry_time = 0
	_jungle.squirrel.show()
