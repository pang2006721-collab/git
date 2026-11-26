extends Node2D
## 沿用旧版钻云、单镜头上移、幽灵弹出的流程；遮挡和地面均取正式长图。
signal entered_cloud
signal arrived
const TRAVEL=preload("res://modules/camera/vertical_scene_transition.gd")
const FOREGROUND=preload("res://shaders/formal_cloud_foreground.gdshader")
@export var entry_seconds: float=.65
@export var travel_seconds: float=3.6
@export var entry_rise: float=360.0
@export var ghost_x: float=960.0
@export var room_framing_offset: Vector2=Vector2(0,-295)
@export var walkway_y: float=1410.0
@export var walkway_bounds: Vector2=Vector2(260,1660)
@export var heaven_zoom: float=1.0
enum State { WAITING, ENTERING, TRAVELLING, COMPLETE }
var state: State=State.WAITING
var elapsed: float=0.0
var travel: VerticalSceneTransition
var _profiles: Dictionary
var _entry: Vector2
var _spawn: Vector2
var _zoom: Vector2
var _rest_framing: Vector2
var _bird_z: int
var _soul_scale: Vector2
var _soul_z: int
var _ripple: Sprite2D
var gaze: Sprite2D
var _wall_collisions: Array[CollisionShape2D]=[]
var _floor: StaticBody2D
var _floor_collision: CollisionPolygon2D
var ending_handoff: Node
@onready var layout: Node2D=get_parent()
@onready var stage: Node2D=get_node("../..")
@onready var level: Node2D=get_node("../../../..")
@onready var bird: CharacterBody2D=get_node("../Bird")
@onready var camera: FollowCamera=level.get_node("Camera")

func _ready() -> void:
    _bird_z=bird.z_index
    _soul_scale=level.get_node("Soul").scale
    _soul_z=level.get_node("Soul").z_index
    _profiles=JSON.parse_string(FileAccess.get_file_as_string("res://assets/layout/formal_cloud_profiles.json"))
    _build_foreground("sky",2,false)
    _build_foreground("heaven",0,true)
    _build_floor()
    _build_ripple()
    _build_gaze()
    travel=TRAVEL.new()
    travel.duration=travel_seconds
    add_child(travel)
    travel.finished.connect(_arrive)
    ending_handoff = preload("res://modules/cinematic/heaven_ending_handoff.gd").new()
    ending_handoff.name = "EndingHandoff"
    add_child(ending_handoff)
    ending_handoff.configure(self,level,layout)

func height_at(kind: String,x: float) -> float:
    var points: Array=_profiles[kind]
    x=clampf(x,float(points[0][0]),float(points[-1][0]))
    for i in range(points.size()-1):
        if x>=points[i][0] and x<=points[i+1][0]:
            return lerpf(points[i][1],points[i+1][1],(x-points[i][0])/float(points[i+1][0]-points[i][0]))
    return points[-1][1]

func _build_foreground(kind: String,band: int,below: bool) -> void:
    var profile:=Image.create(1920,1,false,Image.FORMAT_RF)
    for x in 1920: profile.set_pixel(x,0,Color((height_at(kind,x)-band*2048+1)/2050.0,0,0))
    var material:=ShaderMaterial.new()
    material.shader=FOREGROUND
    material.set_shader_parameter("cloud_profile",ImageTexture.create_from_image(profile))
    material.set_shader_parameter("below_profile",below)
    var art:=Sprite2D.new()
    art.name="HeavenCloudFront" if below else "SkyCloudFront"
    art.texture=load("res://assets/art/reference_map/%02d.png"%band)
    art.region_enabled=true
    art.region_rect=Rect2(0,1,1920,2048)
    art.centered=false
    art.position=Vector2(0,band*2048)
    art.z_index=19
    art.material=material
    add_child(art)

func _build_floor() -> void:
    _floor=StaticBody2D.new()
    _floor.name="OriginalCloudSurface"
    _floor.collision_layer=16
    _floor.collision_mask=4
    add_child(_floor)
    _floor_collision=CollisionPolygon2D.new()
    var polygon:=PackedVector2Array([Vector2(walkway_bounds.x,walkway_y),Vector2(walkway_bounds.y,walkway_y),Vector2(walkway_bounds.y,1750),Vector2(walkway_bounds.x,1750)])
    _floor_collision.polygon=polygon
    _floor_collision.one_way_collision=true
    _floor_collision.disabled=true
    _floor.add_child(_floor_collision)
    for x in [walkway_bounds.x-20,walkway_bounds.y+20]:
        var collision:=CollisionShape2D.new()
        var shape:=RectangleShape2D.new()
        shape.size=Vector2(40,1100)
        collision.shape=shape
        collision.position=Vector2(x,walkway_y-450)
        collision.disabled=true
        _floor.add_child(collision)
        _wall_collisions.append(collision)

func _physics_process(delta: float) -> void:
    if state==State.WAITING:
        if not stage.active or level.dead or level.exit_in_progress or level.player!=bird or not bird.get_node("Host").claimed: return
        if bird.position.y>height_at("sky",bird.position.x)+30: return
        _enter()
    if state==State.ENTERING:
        elapsed+=delta
        bird.position=_entry+Vector2(0,-entry_rise*smoothstep(0,entry_seconds,elapsed))
        if elapsed>=entry_seconds:
            bird.hide()
            state=State.TRAVELLING
            var destination:=Vector2(ghost_x,walkway_y-2)+room_framing_offset
            travel.rest_zoom=Vector2.ONE*heaven_zoom
            travel.travel(camera,layout.to_global(destination))

func _enter() -> void:
    state=State.ENTERING
    elapsed=0
    level.exit_in_progress=true
    _entry=bird.position
    _zoom=camera.zoom
    _rest_framing=camera.framing_offset
    bird.get_node("Boost").reset()
    bird.get_node("Movement").enabled=false
    bird.get_node("Input").enabled=false
    bird.get_node("Input").clear()
    bird.velocity=Vector2.ZERO
    layout.get_node("CanopyPossession").enabled=false
    layout.get_node("SkyEagle").reset()
    layout.get_node("SkyEagle").set_process(false)
    camera.zoom=_zoom
    camera.clear_impulse()
    travel.prepare(camera,_zoom)
    entered_cloud.emit()

func _build_ripple() -> void:
    # 旧版同一张云纹和同一套弹簧参数，只复用出场效果。
    var texture:=AtlasTexture.new()
    texture.atlas=load("res://assets/art/heaven/cloud_ripple_v001.png")
    texture.region=Rect2(465,510,149,32)
    texture.filter_clip=true
    _ripple=Sprite2D.new()
    _ripple.name="CloudRipple"
    _ripple.texture=texture
    _ripple.scale=Vector2.ONE*1.1
    _ripple.z_index=21
    _ripple.visible=false
    _ripple.set_script(preload("res://modules/visual/canopy_ripple_spring.gd"))
    add_child(_ripple)

func _build_gaze() -> void:
    gaze=preload("res://modules/visual/formal_god_gaze.gd").new()
    gaze.name="GodGaze"
    gaze.target=level.get_node("Soul")
    add_child(gaze)

func _arrive() -> void:
    # 与旧版 Heaven.begin 一致：云面上方直接给向上初速、弹性回弹，立即可操作。
    state=State.COMPLETE
    elapsed=0
    level.exit_in_progress=false
    _spawn=Vector2(ghost_x,walkway_y-2)
    _floor_collision.set_deferred("disabled",false)
    for collision in _wall_collisions: collision.set_deferred("disabled",false)
    gaze.enabled=true
    var soul: CharacterBody2D=level.soul
    soul.global_position=layout.to_global(_spawn)
    soul.scale=Vector2.ONE*1.4
    soul.get_node("Visual").reset()
    soul.get_node("Visual").set_process(true)
    soul.get_node("Visual").modulate=Color.WHITE
    soul.get_node("Visual/Sprite").show()
    soul.z_index=20
    soul.show()
    soul.get_node("Collision").set_deferred("disabled",false)
    soul.get_node("Input").external_control=false
    soul.get_node("Input").enabled=true
    soul.get_node("Input").clear()
    soul.get_node("Movement").enabled=true
    soul.get_node("Movement").reset()
    soul.velocity=Vector2(0,-620)
    soul.get_node("Visual").play_possession_pulse()
    soul.reset_physics_interpolation()
    _ripple.position=_spawn+Vector2(0,-3)
    _ripple.pulse()
    level.player=soul
    camera.framing_offset=room_framing_offset
    camera.resume_follow_from_current_position(soul)
    camera.set_process(true)
    Bgm.play_track(Bgm.Track.HEAVEN)
    arrived.emit()

func reset() -> void:
    ending_handoff.cancel()
    if state!=State.WAITING:
        travel.cancel()
        camera.zoom=_zoom
        camera.framing_offset=_rest_framing
        level.exit_in_progress=false
        level.soul.z_index=_soul_z
        level.soul.scale=_soul_scale
        level.soul.get_node("Visual").reset()
    _ripple.reset()
    gaze.reset()
    for collision in _wall_collisions: collision.set_deferred("disabled",true)
    state=State.WAITING
    elapsed=0
    _floor_collision.set_deferred("disabled",true)
    bird.z_index=_bird_z
    bird.show()
    layout.get_node("SkyEagle").set_process(true)
