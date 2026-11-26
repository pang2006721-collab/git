extends Node
const SURFACE = preload("res://modules/environment/hell_surface.gd")
## 动画通道与正式地图贴边组成同一个世界；唯一显示相机直接平移进入关卡。
signal pan_started
signal finished
@export_file("*.tscn") var gameplay_scene_path: String = "res://scenes/levels/formal_hell_entry.tscn"
@export var map_path: NodePath = ^"../DescentWorld/ArrivalMap"
@export var old_camera_path: NodePath = ^"../DescentCamera"
@export var chase_camera_path: NodePath = ^"../ChaseCamera"
@export var hold_time: float = 0.65
@export var pan_duration: float = 1.35
var join_x: float = 0.0
@export var connected_floor_y: float = 1100.0
@export var gameplay_entry_path: NodePath = ^"LandingPoint"
var _scene_requested := false
var gameplay: Node2D
var playing: bool = false
var elapsed: float = 0.0
var switched: bool = false
var revealed: bool = false
var panning: bool = false
var _pan_from: Vector2
var _pan_to: Vector2
var _pan_elapsed: float = 0.0
@onready var camera: Camera2D = get_node(old_camera_path)
@onready var chase_motion: Node = get_node(chase_camera_path)

func _ready() -> void:
	process_priority = 110

func warmup() -> void:
	# 玩家按开始后才预载，利用原有下降/加载动画期间准备，不在首页常驻整关。
	if _scene_requested or is_instance_valid(gameplay): return
	_scene_requested = ResourceLoader.load_threaded_request(gameplay_scene_path, "PackedScene") == OK

func prepare() -> void:
	if is_instance_valid(gameplay):
		return
	var map: Node2D = get_node(map_path)
	var gameplay_scene: PackedScene = ResourceLoader.load_threaded_get(gameplay_scene_path) if _scene_requested else load(gameplay_scene_path)
	gameplay = gameplay_scene.instantiate()
	gameplay.name = "Gameplay"
	gameplay.z_index = -60
	var wall: Sprite2D = map.get_node("FinalSideWall")
	# 作者柱子右沿与正式地图左沿颜色一致，直接贴边，不重叠、不再额外叠墙。
	join_x = wall.to_global(Vector2(wall.texture.get_width(),0)).x
	var entry: Marker2D = gameplay.get_node(gameplay_entry_path)
	var surface: Vector2 = SURFACE.local_top_at(gameplay.get_node("Ground/Collision"),gameplay,entry.position.x)
	if is_finite(surface.y):
		gameplay.get_node("WallSpawn").position.y += surface.y - entry.position.y
		entry.position.y = surface.y
	gameplay.position = Vector2(join_x, map.global_position.y + connected_floor_y - entry.position.y)
	gameplay.visible = false
	var game_camera: Camera2D = gameplay.get_node("Camera")
	game_camera.world_bounds.position += gameplay.position
	game_camera.zoom = Vector2.ONE * 1.35
	get_parent().add_child(gameplay)
	# 隐藏时仍让流式加载器预载附近高清切片，但禁止隐藏相机移动。
	game_camera.set_process(false)
	gameplay.get_node("CameraOutput").output_camera = camera
	# 地图预载、横移和实际游玩全程使用同一视差参考，交接不再跳一下。
	for layer in gameplay.get_node("Map/Backgrounds").get_children():
		layer.set_camera(camera)
	gameplay.get_node("WallEntry").control_ready.connect(_enable_follow)

func play() -> void:
	if playing or switched:
		return
	prepare()
	playing = true
	chase_motion.lock_frame()

func _process(delta: float) -> void:
	# 后台加载好就成为右侧世界的一部分；相机尚未走到那里，前面自然看不到。
	if is_instance_valid(gameplay) and not gameplay.visible and gameplay.get_node("TextureStreamer").is_view_ready():
		gameplay.visible = true
	if not playing:
		return
	elapsed += delta
	if not panning:
		# 停在动画一侧；正式地图在画面右边界以外，等待高清，不切显示开关。
		if elapsed < hold_time or not gameplay.get_node("TextureStreamer").is_view_ready():
			return
		panning = true
		chase_motion.active = false
		_pan_from = camera.global_position
		var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
		_pan_to = Vector2(gameplay.position.x + half_width, _pan_from.y)
		pan_started.emit()
	_pan_elapsed = minf(_pan_elapsed + delta, pan_duration)
	var u: float = _pan_elapsed / pan_duration
	var eased: float = u * u * (3.0 - 2.0 * u)
	camera.global_position = _pan_from.lerp(_pan_to,eased)
	if u >= 1.0:
		playing = false
		switched = true
		revealed = true
		var game_camera: Camera2D = gameplay.get_node("Camera")
		game_camera.adopt_view(camera.global_position,camera.zoom)
		# 不换显示相机；游戏跟随模块接收当前视野，再继续驱动这一台相机。
		gameplay.get_node("CameraOutput").enabled = true
		gameplay.get_node("WallEntry").play()
		gameplay.get_node("MusicRegions").enabled = true
		finished.emit()

func _enable_follow() -> void:
	if switched:
		gameplay.get_node("Camera").set_process(true)
