extends Node2D
## 独立海底突袭：视野内锁定，固定出手方向，连续位移及扫掠接触。
signal lock_started
signal dash_started
signal player_hit(direction: Vector2)

enum State { WAITING, LOCKING, DASHING }
@export var automatic_attacks: bool = true
@export_enum("交替:0","左侧:-1","右侧:1") var entry_side: int = 0
@export var lock_vertical_offset: float = -100.0
@export var spawn_interval: float = 6.0
@export var first_spawn_delay: float = 2.0
@export var lock_seconds: float = 1.0
@export var dash_speed: float = 2200.0
@export var prediction_max_seconds: float = .4
@export var prediction_max_pixels: float = 180.0
@export var bob_pixels: float = 12.0
@export var entrance_rebound_pixels: float = 28.0
@export var windup_pullback_pixels: float = 42.0
@export var artwork_scale: float = 0.8
@export var hit_radius: float = 30.0
@export var body_half_length: float = 75.0
@export var enabled: bool = false:
    set(value):
        if enabled == value: return
        if value and _finishing and state!=State.WAITING: return
        enabled = value
        if is_node_ready() and not _finishing and state != State.DASHING: reset()
var target: CharacterBody2D
var camera: Camera2D
var state: State = State.WAITING
var cycle_elapsed: float = 0.0
var state_elapsed: float = 0.0
var dash_direction := Vector2.RIGHT
var locked_point := Vector2.ZERO
var _side: int = 1
var _screen_anchor := Vector2.ZERO
var _anchors: Dictionary
var _hit_reported: bool = false
var _first_attack: bool = true
var _finishing: bool = false
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Art

func _ready() -> void:
    process_priority = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    _anchors = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/shark/anchors.json"))
    sprite.frame_changed.connect(_register_frame)
    sprite.animation_changed.connect(_register_frame)
    reset()

func configure(player: CharacterBody2D, view: Camera2D) -> void:
    target = player
    camera = view

func _physics_process(delta: float) -> void:
    if _target_dead() and not _finishing:
        finish_current_attack()
    if state == State.DASHING and is_instance_valid(camera):
        state_elapsed += delta
        if enabled: cycle_elapsed += delta
        _advance_dash(delta)
        return
    if (not enabled and not _finishing) or not is_instance_valid(target) or not is_instance_valid(camera): return
    cycle_elapsed += delta
    state_elapsed += delta
    match state:
        State.WAITING:
            if enabled and automatic_attacks and cycle_elapsed >= (first_spawn_delay if _first_attack else spawn_interval): _begin_lock()
        State.LOCKING:
            _follow_lock_view()
            locked_point = _predicted_target(global_position)
            var aim := locked_point-global_position
            if not aim.is_zero_approx():
                _face(Vector2.RIGHT.rotated(lerp_angle(global_rotation,aim.angle(),1.0-exp(-12.0*delta))))
            if state_elapsed >= lock_seconds:
                _begin_dash()
            elif state_elapsed >= maxf(0.0,lock_seconds-3.0/11.0) and sprite.animation != &"windup":
                sprite.play(&"windup")

func _process(_delta: float) -> void:
    if _target_dead() and not _finishing:
        finish_current_attack()
    if (enabled or _finishing) and state == State.LOCKING: _follow_lock_view()

func _target_dead() -> bool:
    if not is_instance_valid(target): return false
    var stage := target.get_parent()
    return stage.get("level")!=null and stage.level.dead

func finish_current_attack() -> void:
    # 命中/死亡只停后续出手，现有蓄力和冲刺完整播放到出画。
    _finishing=true
    enabled=false
    _hit_reported=true

func cancel_pending_attack() -> void:
    enabled = false
    reset()

func _view_rect() -> Rect2:
    var size := camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)

func _begin_lock() -> void:
    _first_attack = false
    state = State.LOCKING
    state_elapsed = 0.0
    cycle_elapsed = 0.0
    _side = -_side if entry_side==0 else entry_side
    var view := _view_rect()
    var inset := minf(210.0,view.size.x*.22)
    var relative_y := clampf(_target_center().y-view.position.y+lock_vertical_offset,150.0,view.size.y-150.0)
    _screen_anchor = Vector2(inset if _side<0 else view.size.x-inset,relative_y)
    sprite.play(&"idle")
    show()
    _follow_lock_view()
    _face((_predicted_target(global_position)-global_position).normalized())
    lock_started.emit()

func _follow_lock_view() -> void:
    var view := _view_rect()
    var entrance_seconds := minf(.2,lock_seconds*.3)
    var entrance := smoothstep(0.0,entrance_seconds,state_elapsed)
    var settle := smoothstep(entrance_seconds,entrance_seconds+minf(.16,lock_seconds*.2),state_elapsed)
    var start_x := -180.0 if _side<0 else view.size.x+180.0
    # 先略微游过停靠点，再顺着水流回弹；上下起伏在蓄力时逐渐收住。
    var rebound := float(-_side)*entrance_rebound_pixels*entrance*(1.0-settle)
    var windup := smoothstep(maxf(0.0,lock_seconds-3.0/11.0),lock_seconds,state_elapsed)
    var bob := sin(state_elapsed*TAU/1.25)*bob_pixels*entrance*(1.0-windup)
    var anchor := view.position+Vector2(lerpf(start_x,_screen_anchor.x,entrance)+rebound,_screen_anchor.y+bob)
    var aim := (_predicted_target(anchor)-anchor).normalized()
    global_position = anchor-aim*windup_pullback_pixels*windup
    visual.modulate.a = smoothstep(0.0,minf(.12,lock_seconds*.2),state_elapsed)

func _begin_dash() -> void:
    state = State.DASHING
    state_elapsed = 0.0
    _hit_reported = false
    locked_point = _predicted_target(global_position)
    dash_direction = (locked_point-global_position).normalized()
    if dash_direction.is_zero_approx(): dash_direction = Vector2(float(-_side),0)
    _face(dash_direction)
    visual.modulate.a = 1.0
    sprite.play(&"dash")
    dash_started.emit()

func _advance_dash(delta: float) -> void:
    var speed := dash_speed*lerpf(.35,1.0,smoothstep(0.0,.08,state_elapsed))
    var next := global_position+dash_direction*speed*delta
    var hit := enabled and not _hit_reported and is_instance_valid(target) and _touches_target(global_position,next)
    global_position = next
    if hit:
        _hit_reported = true
        player_hit.emit(dash_direction)
    if _fully_offscreen():
        _finish_attack()

func _fully_offscreen() -> bool:
    var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
    var border: float = sprite.material.get_shader_parameter("outline_pixels")
    var size := texture.get_size()+Vector2.ONE*border*2.0
    var top_left := sprite.offset-size*.5
    var bounds := Rect2(sprite.to_global(top_left),Vector2.ZERO)
    for corner in [top_left+Vector2(size.x,0),top_left+size,top_left+Vector2(0,size.y)]:
        bounds = bounds.expand(sprite.to_global(corner))
    return not _view_rect().intersects(bounds)

func _target_center() -> Vector2:
    var collision := target.get_node_or_null("Collision") as CollisionShape2D
    return collision.global_position if collision != null else target.global_position

func _predicted_target(origin: Vector2) -> Vector2:
    var center := _target_center()
    var velocity := target.velocity.limit_length(850)
    # 短距离提前量：迭代飞行时间，并补上开头 0.08 秒加速损失的 0.026 秒。
    var seconds := origin.distance_to(center)/maxf(dash_speed,1)+.026
    var lead := Vector2.ZERO
    for iteration in 6:
        lead = (velocity*minf(seconds,prediction_max_seconds)).limit_length(prediction_max_pixels)
        seconds = origin.distance_to(center+lead)/maxf(dash_speed,1)+.026
    return center+lead

func _touches_target(from: Vector2, to: Vector2) -> bool:
    var teleport := target.get_node_or_null("Teleport")
    if teleport != null and teleport.is_invulnerable(): return false
    var collision := target.get_node_or_null("Collision") as CollisionShape2D
    var center := _target_center()
    var radius := 25.0
    var half_axis := Vector2.ZERO
    if collision != null and collision.shape is CapsuleShape2D:
        var capsule := collision.shape as CapsuleShape2D
        radius = capsule.radius*absf(collision.global_scale.x)
        half_axis = Vector2(0,maxf(0.0,capsule.height*.5-capsule.radius)*absf(collision.global_scale.y)).rotated(collision.global_rotation)
    var start := from-dash_direction*body_half_length
    var finish := to+dash_direction*body_half_length
    if half_axis.is_zero_approx():
        return Geometry2D.get_closest_point_to_segment(center,start,finish).distance_to(center) <= hit_radius+radius
    var nearest := Geometry2D.get_closest_points_between_segments(start,finish,center-half_axis,center+half_axis)
    return nearest[0].distance_to(nearest[1]) <= hit_radius+radius

func _face(direction: Vector2) -> void:
    global_rotation = direction.angle()
    visual.scale = Vector2(artwork_scale,artwork_scale*(-1.0 if direction.x<0.0 else 1.0))

func _register_frame() -> void:
    var frame_texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
    var source_size := frame_texture.get_size()
    var region := Rect2(Vector2.ZERO,source_size)
    if frame_texture is AtlasTexture:
        source_size = frame_texture.atlas.get_size()
        region = frame_texture.region
    sprite.material.set_shader_parameter("source_texel",Vector2.ONE/source_size)
    sprite.material.set_shader_parameter("frame_bounds",Vector4(region.position.x/source_size.x,region.position.y/source_size.y,region.end.x/source_size.x,region.end.y/source_size.y))
    sprite.material.set_shader_parameter("clean_edges",sprite.animation != &"idle")
    if sprite.animation == &"idle":
        var pivot: Array = _anchors.idle_pivot
        sprite.offset = sprite.sprite_frames.get_frame_texture(&"idle",0).get_size()*.5-Vector2(pivot[0],pivot[1])
        sprite.scale = Vector2.ONE*.74
    else:
        var index := sprite.frame+(3 if sprite.animation==&"dash" else 0)
        var data: Dictionary = _anchors.frames[index]
        var pivot: Array = data.pivot
        var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
        sprite.offset = texture.get_size()*.5-Vector2(pivot[0],pivot[1])
        sprite.scale = Vector2.ONE

func _finish_attack() -> void:
    state = State.WAITING
    state_elapsed = 0.0
    hide()
    sprite.pause()
    if not enabled: cycle_elapsed = 0.0
    if _finishing: _first_attack=true
    _finishing=false

func reset() -> void:
    _finishing=false
    _first_attack = true
    cycle_elapsed = 0.0
    state_elapsed = 0.0
    state = State.WAITING
    dash_direction = Vector2.RIGHT
    locked_point = Vector2.ZERO
    _side = 1
    _hit_reported = false
    hide()
    sprite.play(&"idle")
    sprite.stop()
    _register_frame()
