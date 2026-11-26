extends Node
## 仅控制结算中的视觉幽灵。解析积分使加减速不受帧率影响，无重力或隐形跳台。
signal exited
@export var speed: float = 460.0
@export var acceleration_rate: float = 8.0
@export var braking_rate: float = 6.0
@export var resting_scale: float = 1.35
var position := Vector2(510,720)
var velocity := Vector2.ZERO
var elapsed: float = 0.0
var leaving: bool = false
var finished: bool = false
var body: Node2D
var halo: Sprite2D
var face: Node2D
var _tilt: float = 0.0
var _halo_offset := Vector2(0,-200)
var _starting_scale: float = 1.8

func configure(soul: Node2D, ring: Sprite2D, expression: Node2D) -> void:
    body = soul
    halo = ring
    face = expression
    position = body.position
    _starting_scale = sqrt(absf(body.scale.x*body.scale.y))
    _halo_offset = halo.position-body.position

func flight_bounds() -> Rect2:
    # 包含倾斜后的身体与光环；相机怎么滚动都只相对屏幕活动。
    return Rect2(Vector2(85,200), get_viewport().get_visible_rect().size-Vector2(170,245))

func advance(delta: float, direction: Vector2) -> void:
    if finished or body == null: return
    elapsed += delta
    var target: Vector2 = direction.limit_length(1.0)*speed
    var rate: float = acceleration_rate if direction.length_squared() > .001 else braking_rate
    if leaving:
        target = Vector2(0,-1050)
        rate = 3.2
    var decay: float = exp(-rate*delta)
    position += target*delta+(velocity-target)*(1.0-decay)/rate
    velocity = target+(velocity-target)*decay
    if not leaving:
        var bounds: Rect2 = flight_bounds()
        var clamped := position.clamp(bounds.position,bounds.end)
        if clamped.x != position.x: velocity.x = 0
        if clamped.y != position.y: velocity.y = 0
        position = clamped
    var blend: float = smoothstep(0,.65,elapsed)
    var size: float = lerpf(_starting_scale,resting_scale,blend)
    var stretch: float = 1.0+clampf(-velocity.y/1050.0,-.035,.075)
    _tilt = lerpf(_tilt,clampf(velocity.x/speed,-1,1)*.085,1.0-exp(-9.0*delta))
    body.rotation = _tilt
    body.scale = Vector2(1.0/stretch,stretch)*size
    body.position = position+Vector2(sin(elapsed*2.3)*1.8,sin(elapsed*2.9)*2.5)*blend
    var desired := Vector2(-velocity.x*.018,-90*body.scale.y-28-maxf(0,-velocity.y)*.012)
    _halo_offset = _halo_offset.lerp(desired,1.0-exp(-10.0*delta))
    # 与身体共用平移，只让相对偏移轻微滞后；快速上飞时光环不会穿过头。
    _halo_offset.y = minf(_halo_offset.y,-90*body.scale.y-25)
    halo.position = body.position+_halo_offset
    halo.scale = Vector2.ONE*(size/1.8*.68)
    halo.rotation = _tilt*.45
    face.gaze = velocity/speed*1.2
    face.happiness = 1.0
    face.queue_redraw()
    if leaving and position.y < -140:
        finished = true
        exited.emit()

func leave_upward() -> void:
    leaving = true
