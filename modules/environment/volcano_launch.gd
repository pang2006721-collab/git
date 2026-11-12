class_name VolcanoLaunch
extends Node
## Scripted emergence behind terrain, followed by normal water physics.
signal finished
signal erupted

@export_node_path("CharacterBody2D") var body_path: NodePath = ^"../UnderwaterDemon"
@export_node_path("Sprite2D") var volcano_art_path: NodePath = ^"../Seabed/Art"
@export var preparation_duration: float = 1.05
@export var preparation_amplitude: float = 28.0
@export var duration: float = 1.05
@export var mouth_y: float = 2980.0
@export var launch_velocity: Vector2 = Vector2(170, -1150)
@export var gravity: float = 1500.0
var active: bool = false
var elapsed: float = 0.0
var preparing: bool = false
var _origin: Vector2
var _body: CharacterBody2D
var _front_z: int
var _material: ShaderMaterial

func _ready() -> void:
	_body = get_node(body_path)
	_front_z = _body.z_index
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/volcano_pulse.gdshader")
	get_node(volcano_art_path).material = _material

func start(origin: Vector2) -> void:
	_origin = origin
	elapsed = 0.0
	active = true
	preparing = true
	_pulse(0.0, 1.0)
	_body.position = origin
	_body.velocity = Vector2.ZERO
	_body.z_index = -1
	_body.get_node("Input").enabled = false
	_body.get_node("Input").clear()
	_body.get_node("Movement").enabled = false
	_body.get_node("Drowning").set_process(false)

func _physics_process(delta: float) -> void:
	if not active:
		return
	elapsed = minf(elapsed + delta, preparation_duration + duration)
	if elapsed < preparation_duration:
		# Three tightening contractions, then a brief held compression before release.
		var progress := elapsed / maxf(preparation_duration, 0.001)
		var ends := [0.36, 0.64, 0.86]
		var start := 0.0
		for i in range(3):
			if progress < ends[i]:
				var phase: float = (progress - start) / (ends[i] - start)
				var amplitude := preparation_amplitude * (0.45 + float(i) * 0.275)
				var pull := sin(phase * TAU) * pow(sin(phase * PI), 2.0)
				_pulse(pull * amplitude, 1.0 - pull * 0.045)
				return
			start = ends[i]
		var hold := smoothstep(0.86, 0.95, progress)
		_pulse(9.0 * hold, 1.0 - 0.045 * hold)
		return
	if preparing:
		preparing = false
		erupted.emit()
	var flight := elapsed - preparation_duration
	# A sharp release and a short decaying recoil sell the burst without new artwork.
	var recoil := exp(-flight * 15.0)
	_pulse(-24.0 * recoil * cos(flight * 28.0), 1.0 + 0.1 * recoil)
	_body.position = _origin + launch_velocity * flight + Vector2(0, gravity * flight * flight * 0.5)
	_body.velocity = launch_velocity + Vector2(0, gravity * flight)
	if _body.position.y <= mouth_y:
		_body.z_index = _front_z
	if elapsed >= preparation_duration + duration:
		active = false
		_pulse(0.0, 1.0)
		_body.z_index = _front_z
		_body.get_node("Movement").enabled = true
		_body.get_node("Input").enabled = true
		_body.get_node("Drowning").set_process(true)
		finished.emit()

func _pulse(offset: float, stretch: float) -> void:
	_material.set_shader_parameter("pulse_y", offset)
	_material.set_shader_parameter("stretch_y", stretch)
