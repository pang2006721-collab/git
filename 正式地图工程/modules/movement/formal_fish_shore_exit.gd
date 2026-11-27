extends FishShoreExit
## 旧出水运动加正式岸上原画；挣扎、缺氧变红及叉眼死亡依次交接。
const STRUGGLE = preload("res://modules/visual/stranded_fish_visual.gd")
var struggle = STRUGGLE.new()
@onready var stage: Node2D = get_parent()
func _ready() -> void:
    super._ready()
    struggle.configure(_visual,_sprite)
    landed_on_shore.connect(func(): _sprite.position = Vector2(8,-11.5))
func _physics_process(delta: float) -> void:
    if not stage.active or stage.level.dead or stage.level.player!=_fish: return
    var final_sharks: Node=stage.get_node("FinalSharks")
    if state==State.SWIMMING and _fish.position.x>=0 and _fish.position.x<=1920 and _fish.position.y<=surface_y+final_sharks.shore_clearance:
        final_sharks._physics_process(0)
        if not final_sharks.can_leave_water():
            _fish.position.y=surface_y+final_sharks.shore_clearance
            _fish.velocity.y=maxf(_fish.velocity.y,0.0)
            return
    super._physics_process(delta)
    if state==State.STRANDED: struggle.sample(elapsed,stranding_duration)
    _fish.get_node("Teleport").enabled = state==State.SWIMMING
func release_soul() -> void:
    if state==State.DEAD: return
    state = State.DEAD
    _sprite.texture = dead_texture
    struggle.settle_dead()
    _fish.velocity = Vector2.ZERO
    _motor.enabled = false
    _reader.enabled = false
    _reader.clear()
    # 附身离开与正常死亡都保留短暂叉眼，再淡出；冻结关卡时也继续。
    _death_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_IDLE)
    _death_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
    _death_tween.tween_interval(death_hold_duration)
    _death_tween.tween_property(_visual,"modulate:a",0.0,death_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _death_tween.tween_callback(_fish.hide)
    died_on_shore.emit()
func play_death() -> void:
    # 等尸体完成淡出，再交给死亡界面。
    if _death_tween!=null and _death_tween.is_running():
        await _death_tween.finished
func reset() -> void:
    super.reset()
    if struggle.visual!=null: struggle.reset()

func start_on_shore(world_x: float) -> void:
    # 快捷入口直接进入正常落岸后的状态，坐标取编辑器中的原岸线碰撞。
    reset()
    var bank: CollisionShape2D = stage.get_node("OriginalShoreBank/Collision")
    var top: Vector2 = bank.to_global(Vector2(0,-bank.shape.size.y*.5))
    var collision: CollisionShape2D = _fish.get_node("Collision")
    var bounds: Rect2 = collision.shape.get_rect()
    var bottom: float = -INF
    for point in [bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
        bottom = maxf(bottom,(collision.transform*point).y)
    _fish.global_position = Vector2(world_x,top.y-bottom)
    _fish.velocity = Vector2.ZERO
    _fish.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
    _motor.enabled = false
    _reader.clear()
    _visual.set_process(false)
    state = State.STRANDED
    elapsed = 0
    _sprite.texture = stranded_texture
    _sprite.position = Vector2(8,-11.5)
    _visual.rotation = 0
    _fish.get_node("Teleport").enabled = false
    struggle.sample(0,stranding_duration)
    _fish.reset_physics_interpolation()
    landed_on_shore.emit()
