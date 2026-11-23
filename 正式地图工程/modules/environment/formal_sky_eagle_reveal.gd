extends Node2D
## 附身后爬升触发远景老鹰，保持原图云层、共享相机与玩家操作。
signal revealed
signal reveal_finished
@export var reveal_ascent: float=320.0
@export var reveal_seconds: float=1.8
@export var wide_zoom: float=1.0
@export var eagle_final_scale: float=.84
enum State { WAITING, REVEALING, ACTIVE }
var state: State=State.WAITING
var elapsed: float=0
var _armed:=false
var _start_y:=0.0
var _rest_zoom:=Vector2.ONE
var _bounded_wide_zoom:=Vector2.ONE
var _band: int=-1
@onready var layout: Node2D=get_parent()
@onready var stage: Node=get_node("../..")
@onready var bird: CharacterBody2D=get_node("../Bird")
@onready var camera: FollowCamera=get_node_or_null("../../../../Camera")
@onready var eagle: Node2D=$Eagle
@onready var flight: Node=$Flight
func _ready() -> void:
    process_priority=5
    eagle.look_target=bird
    eagle.hide()
    eagle.reset()
func arm() -> void:
    if state!=State.WAITING: return
    _armed=true
    _start_y=bird.position.y
func _process(delta: float) -> void:
    if not is_instance_valid(camera) or not stage.has_node("ShoreExit"): return
    if stage.level.dead: return
    if state==State.WAITING:
        if _armed and stage.active and stage.level.player==bird and bird.get_node("Host").claimed and not stage.level.exit_in_progress:
            if bird.position.y<=_start_y-reveal_ascent and not layout.get_node("CanopyPossessionCamera").active:
                _begin()
        return
    if state==State.REVEALING:
        elapsed=minf(elapsed+delta,reveal_seconds)
        var u:=smoothstep(0,reveal_seconds,elapsed)
        camera.zoom=_rest_zoom.lerp(_bounded_wide_zoom,u)
        eagle.scale=Vector2.ONE*lerpf(eagle_final_scale*.55,eagle_final_scale,u)
        eagle.material.set_shader_parameter("reveal_alpha",smoothstep(.05,.7,elapsed/reveal_seconds))
        if elapsed>=reveal_seconds:
            state=State.ACTIVE
            reveal_finished.emit()
    # Fly a broad figure eight behind the original cloud banks.
    var anchor:=Vector2(layout.to_global(Vector2(960,0)).x,camera.global_position.y-140)
    eagle.global_position=flight.advance(delta,anchor)
    _update_map_band()
func _begin() -> void:
    _rest_zoom=camera.zoom
    var viewport_size:=camera.get_viewport_rect().size
    var minimum_zoom:=maxf(viewport_size.x/camera.world_bounds.size.x,viewport_size.y/camera.world_bounds.size.y)
    _bounded_wide_zoom=Vector2.ONE*maxf(wide_zoom,minimum_zoom)
    elapsed=0
    state=State.REVEALING
    eagle.reset()
    eagle.show()
    eagle.scale=Vector2.ONE*eagle_final_scale*.55
    eagle.global_position=Vector2(layout.to_global(Vector2(960,0)).x,camera.global_position.y-140)
    flight.reset(eagle.global_position)
    _update_map_band()
    revealed.emit()
func _update_map_band() -> void:
    var band:=clampi(int(floor(layout.to_local(eagle.global_position).y/2048)),0,8)
    if band==_band: return
    _band=band
    var material: ShaderMaterial=eagle.material
    material.set_shader_parameter("map_origin",layout.global_position)
    material.set_shader_parameter("map_scale",layout.global_scale)
    material.set_shader_parameter("map_band",float(band))
    material.set_shader_parameter("map_above",load("res://assets/art/reference_map/%02d.png"%maxi(0,band-1)))
    material.set_shader_parameter("map_current",load("res://assets/art/reference_map/%02d.png"%band))
    material.set_shader_parameter("map_below",load("res://assets/art/reference_map/%02d.png"%mini(8,band+1)))
func reset() -> void:
    if state!=State.WAITING and is_instance_valid(camera): camera.zoom=_rest_zoom
    state=State.WAITING
    elapsed=0
    _armed=false
    _band=-1
    flight.reset(Vector2.ZERO)
    eagle.hide()
    eagle.reset()
    eagle.material.set_shader_parameter("reveal_alpha",0.0)
