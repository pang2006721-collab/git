extends Node2D
## 正式长图内的树冠衔接：叶后钻入、连续上升、从原画树冠顶部弹出。
signal started
signal arrived
const TRAVEL=preload("res://modules/camera/vertical_scene_transition.gd")
const MASK=preload("res://shaders/formal_canopy_foreground.gdshader")
const CROWN=preload("res://assets/art/reference_map/08.png")
@export var entry_min_y: float=20480.0
@export var entry_max_y: float=20800.0
@export var burrow_seconds: float=.45
@export var travel_seconds: float=1.7
@export var landing_x: float=1040.0
@export var bounce_inset: float=180.0
enum State { WAITING, BURROWING, TRAVELLING, EMERGING, COMPLETE }
var state: State=State.WAITING
var elapsed: float=0
var profile:=PackedVector2Array()
var play: Node
var travel: Node
var _start:=Vector2.ZERO
var _landing:=Vector2.ZERO
var _original_z: int=10
var _canopy_image: Image
var _entry_image: Image
var _surface: StaticBody2D
@onready var layout: Node2D=get_parent()
@onready var stage: Node=get_node("../..")
@onready var body: CharacterBody2D=get_node("../Squirrel")
func _ready() -> void:
    _original_z=body.z_index
    _canopy_image=CROWN.get_image()
    _entry_image=load("res://assets/art/reference_map/10.png").get_image()
    _build_canopy()
    travel=TRAVEL.new()
    travel.duration=travel_seconds
    travel.suction_zoom=1.025
    add_child(travel)
    travel.finished.connect(_begin_emerge)
    play=preload("res://modules/environment/formal_canopy_play.gd").new()
    add_child(play)
func _build_canopy() -> void:
    var material:=ShaderMaterial.new()
    material.shader=MASK
    for index in [8,9,10]:
        var art:=Sprite2D.new()
        art.texture=load("res://assets/art/reference_map/%02d.png"%index)
        art.centered=false
        art.region_enabled=true
        art.region_rect=Rect2(0,1,1920,2048)
        art.position=Vector2(0,index*2048)
        art.z_index=14
        if index==10:
            # Only the contiguous underside of the crown occludes the squirrel.
            # Dark trunk decorations farther down must remain behind gameplay.
            var underside:=_entry_image.get_region(Rect2i(0,1,1920,300))
            underside.convert(Image.FORMAT_RGBA8)
            for x in 1920:
                var below_leaf:=false
                for y in 300:
                    if underside.get_pixel(x,y).g>.22: below_leaf=true
                    if below_leaf:
                        # Retain source RGB under zero alpha to avoid dark filtered fringes.
                        var pixel:=underside.get_pixel(x,y)
                        pixel.a=0.0
                        underside.set_pixel(x,y,pixel)
            art.texture=ImageTexture.create_from_image(underside)
            art.region_enabled=false
            art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        else:
            art.material=material
        add_child(art)
    for x in range(0,1921,24):
        var y: int=1900
        for row in range(1150,1950):
            var color: Color=_canopy_image.get_pixel(mini(x,1919),row+1)
            if color.r<.29 and color.g<.29 and color.b<.12:
                y=row
                break
        profile.append(Vector2(x,16384+y))
    _surface=StaticBody2D.new()
    _surface.collision_layer=32
    _surface.collision_mask=0
    add_child(_surface)
    var polygon:=CollisionPolygon2D.new()
    var points:=profile.duplicate()
    points.append(Vector2(1920,18800))
    points.append(Vector2(0,18800))
    polygon.polygon=points
    polygon.one_way_collision=true
    polygon.one_way_collision_margin=8
    _surface.add_child(polygon)
func canopy_y(x: float) -> float:
    for i in profile.size()-1:
        if x>=profile[i].x and x<=profile[i+1].x:
            return lerpf(profile[i].y,profile[i+1].y,(x-profile[i].x)/(profile[i+1].x-profile[i].x))
    return profile[0].y if x<0 else profile[-1].y
func _can_enter() -> bool:
    if not stage.has_node("ShoreExit") or not stage.active or stage.level.dead or stage.level.exit_in_progress: return false
    if stage.level.player!=body or not body.get_node("Host").claimed: return false
    var head: Vector2=layout.to_local(body.get_node("Visual/Sprite").global_position)
    if head.x<120 or head.x>1800 or head.y<entry_min_y or head.y>entry_max_y: return false
    var color: Color=_entry_image.get_pixel(clampi(int(head.x),0,1919),clampi(int(head.y)-20480+1,0,2049))
    return color.g<.185
func _physics_process(delta: float) -> void:
    if state==State.WAITING:
        if _can_enter(): _begin()
        return
    if state==State.COMPLETE: return
    elapsed+=delta
    if state==State.BURROWING:
        var u: float=smoothstep(0,burrow_seconds,elapsed)
        body.global_position=layout.to_global(_start+Vector2(0,-200*u))
        if elapsed>=burrow_seconds:
            body.hide()
            state=State.TRAVELLING
            travel.travel(layout.camera,layout.to_global(_landing+Vector2(0,-230)))
func _begin() -> void:
    state=State.BURROWING
    elapsed=0
    _start=layout.to_local(body.global_position)
    _landing=Vector2(landing_x,canopy_y(landing_x)+bounce_inset)
    stage.level.exit_in_progress=true
    body.get_node("VineClimber").reset()
    body.get_node("VineClimber").set_physics_process(false)
    body.get_node("AirSpin").stop()
    body.get_node("Movement").enabled=false
    body.get_node("Input").enabled=false
    body.get_node("Input").clear()
    body.transferring=true
    body.velocity=Vector2.ZERO
    body.get_node("Visual").reset()
    body.z_index=_original_z
    var bees=layout.get_node("BeeEncounter")
    bees.reset()
    bees.enabled=false
    layout.camera.clear_impulse()
    layout.camera.set_process(false)
    travel.prepare(layout.camera,layout.camera.zoom)
    started.emit()
func _begin_emerge() -> void:
    state=State.COMPLETE
    body.transferring=false
    stage.level.exit_in_progress=false
    play.begin(body,landing_x)
    layout.camera.resume_follow_from_current_position(body)
    layout.camera.set_process(true)
    body.reset_physics_interpolation()
    arrived.emit()
func ripple_at(x: float) -> void:
    play.pulse(x)
func reset() -> void:
    if state!=State.WAITING and stage.has_node("ShoreExit"): stage.level.exit_in_progress=false
    play.reset()
    travel.cancel()
    state=State.WAITING
    elapsed=0
    body.z_index=_original_z
    body.get_node("VineClimber").set_physics_process(true)
    body.transferring=false
    body.show()
    layout.get_node("BeeEncounter").enabled=true

func preview_from_top_vine() -> void:
    # 快捷试玩先呈现最上层藤蔓，再自动松手，沿真实抛物线进入树冠。
    var climber=body.get_node("VineClimber")
    var motor=body.get_node("Movement")
    var reader=body.get_node("Input")
    climber.reset()
    climber.set_physics_process(false)
    reader.enabled=false
    reader.clear()
    motor.enabled=false
    body.set_active(true)
    body.get_node("AirSpin").reset()
    var vine=layout.vines[0]
    vine.process_mode=Node.PROCESS_MODE_DISABLED
    for i in vine.rope.points.size():
        var point:=Vector2(0,vine.rope.segment_length*i).rotated(-1.0)
        vine.rope.points[i]=point
        vine.rope.previous[i]=point
    vine.angle=1.0
    vine.rider_offset=Vector2(78,60)
    body.global_position=vine.to_global(vine.rope.sample(400))+vine.rider_offset
    vine.catch(body,Vector2.ZERO,body.global_position)
    vine.grip_length=400
    vine._ribbon.update_points(vine.rope.points)
    climber.adopt_vine(vine)
    layout.get_node("BeeEncounter").reset()
    layout.get_node("BeeEncounter").enabled=false
    layout.camera.set_follow_target(body,true)
    layout.camera.set_process(true)
    body.reset_physics_interpolation()
    await get_tree().create_timer(.35).timeout
    vine.release()
    vine.process_mode=Node.PROCESS_MODE_INHERIT
    climber.vine=null
    motor.enabled=true
    motor.launch_with_momentum(Vector2(500,-sqrt(2*motor.gravity*450)))
    climber.released.emit(body.velocity)
