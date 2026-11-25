extends Node2D
## 附身后爬升触发远景老鹰，保持原图云层、共享相机与玩家操作。
signal revealed
signal reveal_finished
signal screeched
signal departed
signal cycle_reset
@export var reveal_ascent: float=320.0
@export var reveal_seconds: float=1.8
@export var wide_zoom: float=1.0
@export var eagle_final_scale: float=.84
@export var entrance_clearance: float=80.0
@export var circling_seconds: float=1.5
@export var screech_seconds: float=.55
@export var screech_sink: float=45.0
@export var departure_seconds: float=.75
@export var hidden_seconds: float=3.5
enum State { WAITING, REVEALING, ACTIVE, SCREECHING, DEPARTING, HIDDEN }
var state: State=State.WAITING
var elapsed: float=0
var _armed:=false
var _start_y:=0.0
var _rest_zoom:=Vector2.ONE
var _bounded_wide_zoom:=Vector2.ONE
var _band: int=-1
var _entrance_lift: float=0.0
var _phase_elapsed: float=0.0
var _departure_start:=Vector2.ZERO
var _screech_start:=Vector2.ZERO
var _repeat_entry:=false
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
    if state==State.HIDDEN:
        # The quiet interval begins after the final hailstone has fallen out of view.
        if $Hail.is_wave_active():
            _phase_elapsed=0.0
            return
        _phase_elapsed+=delta
        if _phase_elapsed>=hidden_seconds: _begin(true)
        return
    if state==State.SCREECHING:
        _phase_elapsed+=delta
        var sink:=smoothstep(0.0,maxf(screech_seconds,.1),_phase_elapsed)
        eagle.global_position=_screech_start+Vector2(0.0,screech_sink*sink)
        _update_map_band()
        if _phase_elapsed>=screech_seconds:
            _phase_elapsed=0.0
            _departure_start=eagle.global_position
            eagle.begin_departure()
            state=State.DEPARTING
        return
    if state==State.DEPARTING:
        _phase_elapsed+=delta
        var u:=pow(clampf(_phase_elapsed/maxf(departure_seconds,.1),0.0,1.0),1.8)
        var half_view:=camera.get_viewport_rect().size.y*.5/camera.zoom.y
        var half_art: float=eagle.sprite.get_rect().size.y*.5*absf(eagle.sprite.scale.y*eagle.scale.y)
        var offscreen:=Vector2(_departure_start.x+120.0,camera.global_position.y-half_view-half_art-entrance_clearance)
        eagle.global_position=_departure_start.lerp(offscreen,u)
        _update_map_band()
        if _phase_elapsed>=departure_seconds:
            eagle.hide()
            _phase_elapsed=0.0
            state=State.HIDDEN
            departed.emit()
        return
    if state==State.ACTIVE:
        _phase_elapsed+=delta
        if _phase_elapsed>=circling_seconds:
            _phase_elapsed=0.0
            _screech_start=eagle.global_position
            eagle.set_screaming(true)
            state=State.SCREECHING
            screeched.emit()
            return
    if state==State.REVEALING:
        elapsed=minf(elapsed+delta,reveal_seconds)
        var u:=smoothstep(0,reveal_seconds,elapsed)
        if not _repeat_entry: camera.zoom=_rest_zoom.lerp(_bounded_wide_zoom,u)
        eagle.scale=Vector2.ONE*lerpf(eagle_final_scale*.55,eagle_final_scale,u)
        eagle.material.set_shader_parameter("reveal_alpha",smoothstep(.05,.7,elapsed/reveal_seconds))
        if elapsed>=reveal_seconds:
            state=State.ACTIVE
            _phase_elapsed=0.0
            reveal_finished.emit()
    # Fly a broad figure eight behind the original cloud banks.
    var anchor:=Vector2(layout.to_global(Vector2(960,0)).x,camera.global_position.y-140)
    var rising:=1.0-smoothstep(0.0,reveal_seconds,elapsed)
    eagle.global_position=flight.advance(delta,anchor)+Vector2(0.0,_entrance_lift*rising)
    _update_map_band()
func _begin(repeat_entry: bool=false) -> void:
    _repeat_entry=repeat_entry
    if not repeat_entry: _rest_zoom=camera.zoom
    var viewport_size:=camera.get_viewport_rect().size
    var minimum_zoom:=maxf(viewport_size.x/camera.world_bounds.size.x,viewport_size.y/camera.world_bounds.size.y)
    _bounded_wide_zoom=Vector2.ONE*maxf(wide_zoom,minimum_zoom)
    elapsed=0
    _phase_elapsed=0.0
    state=State.REVEALING
    eagle.reset()
    eagle.show()
    eagle.scale=Vector2.ONE*eagle_final_scale*.55
    var anchor:=Vector2(layout.to_global(Vector2(960,0)).x,camera.global_position.y-140)
    # Start the complete silhouette below the widest entrance view, including raised wings.
    var half_view:=viewport_size.y*.5/minf(_rest_zoom.y,_bounded_wide_zoom.y)
    var half_art: float=eagle.sprite.get_rect().size.y*.5*absf(eagle.sprite.scale.y*eagle.scale.y)
    _entrance_lift=half_view+half_art+entrance_clearance+140.0
    flight.reset(anchor)
    eagle.global_position=anchor+Vector2(0.0,_entrance_lift)
    eagle.material.set_shader_parameter("reveal_alpha",0.0)
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
    cycle_reset.emit()
    if state!=State.WAITING and is_instance_valid(camera): camera.zoom=_rest_zoom
    state=State.WAITING
    elapsed=0
    _armed=false
    _band=-1
    _entrance_lift=0.0
    _phase_elapsed=0.0
    _repeat_entry=false
    _departure_start=Vector2.ZERO
    _screech_start=Vector2.ZERO
    flight.reset(Vector2.ZERO)
    eagle.hide()
    eagle.reset()
    eagle.material.set_shader_parameter("reveal_alpha",0.0)
