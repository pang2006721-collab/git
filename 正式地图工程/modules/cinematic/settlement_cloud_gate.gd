extends Node
## 出云与钻回云层共用原褶皱。封赏期间保留行走/跳跃，落入褶皱后才交给回顾飞行。
enum Phase { AWARD, DIVING, COMPLETE }
var phase: Phase = Phase.AWARD
var position := Vector2.ZERO
var velocity := Vector2.ZERO
var floor_y: float = 923.0
var dive_age: float = 0.0
var ripple_age: float = 0.0
var body: Node2D
var halo: Sprite2D
var clip: Control
var ripple: Sprite2D
var _jump_held: bool = false
var _ripple_scales: Array[Vector2] = []

func configure(soul: Node2D, ring: Sprite2D, layer: CanvasLayer, front: CanvasLayer, start: Vector2, speed: Vector2, size: Vector2, surface: float) -> void:
    body = soul
    halo = ring
    position = start
    velocity = speed
    floor_y = surface
    clip = Control.new()
    clip.name = "CloudSurfaceClip"
    clip.clip_contents = true
    clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip.size = Vector2(get_viewport().get_visible_rect().size.x,floor_y)
    layer.add_child(clip)
    body.reparent(clip,false)
    halo.reparent(clip,false)
    body.position = start
    body.scale = size
    var atlas := AtlasTexture.new()
    atlas.atlas = preload("res://assets/art/heaven/cloud_ripple_v001.png")
    atlas.region = Rect2(465,510,149,32)
    atlas.filter_clip = true
    ripple = Sprite2D.new()
    ripple.name = "CloudFold"
    ripple.texture = atlas
    ripple.scale = Vector2.ONE*1.1
    ripple.set_script(preload("res://modules/visual/canopy_ripple_spring.gd"))
    front.add_child(ripple)
    # 采样原出云弹簧，使用同一条形变轨迹；这里的编排只决定何时打开褶皱。
    ripple.set_process(false)
    ripple.pulse()
    for i in 174:
        _ripple_scales.append(ripple.scale)
        ripple._process(1.0/240.0)
    ripple.reset()
    ripple.position = Vector2(start.x,floor_y-3)
    _sample_ripple(0.0)

func _sample_ripple(age: float) -> void:
    ripple.visible = age >= 0 and age < .72
    if ripple.visible: ripple.scale = _ripple_scales[clampi(int(age*240),0,_ripple_scales.size()-1)]

func advance(delta: float, direction: Vector2, award_finished: bool) -> void:
    if phase == Phase.COMPLETE: return
    ripple_age += delta
    if phase == Phase.AWARD:
        velocity.x = lerpf(velocity.x,direction.x*420.0,1.0-exp(-10.0*delta))
        var jump: bool = direction.y < -.1
        if not award_finished and jump and not _jump_held and position.y >= floor_y-.5: velocity.y = -620
        _jump_held = jump
        velocity.y += 1800*delta
        position += velocity*delta
        position.x = clampf(position.x,90,1830)
        if position.y >= floor_y:
            position.y = floor_y
            velocity.y = 0
            if award_finished:
                phase = Phase.DIVING
                dive_age = 0
                ripple_age = 0
                velocity = Vector2.ZERO
                ripple.position = Vector2(position.x,floor_y-3)
    else:
        dive_age += delta
        velocity.y += 1800*delta
        position.y += velocity.y*delta
        # 褶皱先打开，身体与光环从同一条云面被逐渐遮住，不用透明度淡走。
        if dive_age >= .76: phase = Phase.COMPLETE
    body.position = position
    body.rotation = lerpf(body.rotation,velocity.x*.00008,1.0-exp(-10*delta))
    _sample_ripple(ripple_age)

func release_to_flight(layer: CanvasLayer) -> void:
    body.reparent(layer,false)
    halo.reparent(layer,false)
    body.position = Vector2(position.x,980)
    body.scale = Vector2.ONE*1.35
    body.rotation = 0
    halo.position = body.position+Vector2(0,-150)
    halo.scale = Vector2.ONE*.51
    clip.hide()
    ripple.hide()
