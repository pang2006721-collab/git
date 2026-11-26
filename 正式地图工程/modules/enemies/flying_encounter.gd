extends Node2D
signal enemy_spawned(enemy: Node2D)
signal fork_thrown
const ENEMY=preload("res://scenes/enemies/flying_demon.tscn")
const PROJECTILE=preload("res://scenes/enemies/enemy_fork.tscn")
@export var enabled: bool = true
@export var spawn_interval: float = 5.0
@export var max_alive: int = 6
var _next_side: float = -1.0
var elapsed: float = 0.0
var total_spawned: int = 0
var total_shots: int = 0
var _rng:=RandomNumberGenerator.new()
@onready var level: Node2D = get_parent()

func _ready() -> void:
    _rng.randomize()
    level.died.connect(func(): process_mode=Node.PROCESS_MODE_ALWAYS)
    enemy_spawned.connect(level.get_node("CameraAttention").notify_incoming)

func is_active() -> bool:
    return enabled and level.visible and not level.dead and not level.exit_in_progress and level.player==level.demon and level.demon.get_node("Host").claimed

func is_on_screen(point: Vector2, inset: Vector2 = Vector2(100,90)) -> bool:
    var camera:Camera2D=level.camera
    var half:=camera.get_viewport_rect().size*.5/camera.zoom
    return Rect2(camera.global_position-half+inset,(half-inset)*2.0).has_point(point)

func enemies() -> Array:
    return $Enemies.get_children()

func flight_bounds() -> Rect2:
    var bounds:Rect2=level.camera.world_bounds
    return Rect2(bounds.position+Vector2(170,0),bounds.size-Vector2(340,0))

func _physics_process(delta: float) -> void:
    if level.exit_in_progress:
        if $Enemies.get_child_count()>0 or $Projectiles.get_child_count()>0:reset()
        return
    if not is_active():return
    for enemy in enemies():
        if not enemy.is_defeated() and enemy.mode!=enemy.Mode.ENTERING and enemy.global_position.distance_to(level.player.global_position)>1900:enemy.queue_free()
    elapsed+=delta
    if elapsed>=spawn_interval:
        elapsed-=spawn_interval
        if enemies().filter(func(e):return not e.is_defeated()).size()<max_alive:
            if spawn_one()==null:elapsed=maxf(0.0,spawn_interval-.5)

func spawn_one() -> Node2D:
    var bounds:=flight_bounds()
    var camera:Camera2D=level.camera
    var half:=camera.get_viewport_rect().size*.5/camera.zoom
    var point:Vector2
    var available:=false
    var side:=_next_side
    for attempt in 18:
        var inset:=160.0+float(attempt)*40.0
        point=camera.global_position+Vector2(side*(half.x-inset),_rng.randf_range(-half.y+95,-90))
        point=point.clamp(bounds.position+Vector2(65,80),bounds.end-Vector2(65,80))
        if point.distance_to(level.player.global_position)<240:continue
        var query:=PhysicsShapeQueryParameters2D.new()
        var shape:=CircleShape2D.new()
        shape.radius=62
        query.shape=shape
        query.transform=Transform2D(0,point)
        query.collision_mask=9
        if get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():available=true;break
    if not available:return null
    var enemy=ENEMY.instantiate()
    enemy.encounter=self
    enemy.mode=enemy.Mode.ENTERING
    enemy.entry_point=point
    enemy.entry_side=side
    var edge:float=camera.world_bounds.position.x-180.0 if side<0 else camera.world_bounds.end.x+180.0
    enemy.position=to_local(Vector2(edge,point.y))
    $Enemies.add_child(enemy)
    enemy.shot.connect(_shoot)
    _next_side*=-1.0
    total_spawned+=1
    enemy_spawned.emit(enemy)
    return enemy

func _shoot(aim: Vector2, origin: Vector2) -> void:
    if not is_active() or not is_on_screen(origin):return
    var fork=PROJECTILE.instantiate()
    fork.encounter=self
    fork.position=to_local(origin)
    $Projectiles.add_child(fork)
    fork.launch(aim)
    fork_thrown.emit()
    total_shots+=1

func reset() -> void:
    process_mode=Node.PROCESS_MODE_INHERIT
    _next_side=-1.0
    elapsed=0
    for child in $Enemies.get_children()+$Projectiles.get_children():
        child.hide()
        child.queue_free()
