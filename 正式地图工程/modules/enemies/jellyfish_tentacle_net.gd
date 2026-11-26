extends Node2D
## 在上游和下游交错布置固定障碍，保留两侧绕行通道。
signal row_started(height: float)
signal player_hit(direction: Vector2)
signal strike_started
const WARNING = preload("res://modules/visual/tentacle_warning.gd")
const TENDRIL = preload("res://modules/visual/jellyfish_net_tendril.gd")
@export var enabled: bool = false
var spawn_allowed: bool = true
var damage_enabled: bool = true
@export var wave_interval: float = 1.65
@export var minimum_ascent: float = 180.0
@export var spawn_ahead_pixels: float = 800.0
@export var retreat_offset_pixels: float = 140.0
@export var passage_width: float = 280.0
@export var retreat_passage_width: float = 360.0
@export var tentacle_thickness: float = 144.0
@export var charge_seconds: float = 1.15
@export var strike_seconds: float = .18
@export var maximum_rows: int = 6
@export var high_barrier_every: int = 3
@export var high_barrier_ahead: float = 1200.0
var rows: Array[Dictionary] = []
var target: CharacterBody2D
var boss: Node2D
var edge_provider: Node2D
var camera: Camera2D
var _elapsed: float = 0.0
var _last_row_y: float = INF
var _side: int = -1
var _hit: bool = false
var _blink_grace: float = 0.0
var _wave_count: int = 0

func configure(player: CharacterBody2D, jellyfish: Node2D, walls: Node2D) -> void:
    if is_instance_valid(target):
        var old_blink := target.get_node_or_null("Teleport")
        if old_blink!=null and old_blink.teleported.is_connected(_on_teleported):
            old_blink.teleported.disconnect(_on_teleported)
    target = player
    var blink := target.get_node_or_null("Teleport")
    if blink!=null: blink.teleported.connect(_on_teleported)
    camera = jellyfish.camera
    boss = jellyfish
    edge_provider = walls

func _physics_process(delta: float) -> void:
    if not enabled or not is_instance_valid(target): return
    var stun: Node=target.get_node_or_null("Stun")
    if _hit and (stun==null or not stun.is_protected()): _hit=false
    _elapsed += delta
    _blink_grace = maxf(0,_blink_grace-delta)
    var fish_y := to_local(target.global_position).y
    if spawn_allowed and _blink_grace<=0 and boss.state==boss.State.PRESENT and _elapsed>=wave_interval and (_last_row_y==INF or _last_row_y-fish_y>=minimum_ascent): _spawn_row()
    var remove: Array[Dictionary] = []
    for row in rows:
        row.age += delta
        row.dodge_grace = maxf(0,row.dodge_grace-delta)
        var row_top: float = row.node.position.y
        var center: Vector2 = target.get_node("Collision").global_position
        for tendril in row.arms:
            row_top = minf(row_top,row.node.position.y+minf(tendril.start.y,tendril.finish.y))
            if tendril.get_meta(&"awaiting_view",false):
                var preview: Vector2 = tendril.to_global(tendril.start+(tendril.finish-tendril.start).normalized()*150)
                if not _view_rect().grow(-60).has_point(preview):
                    tendril.sample(-1)
                    tendril.get_node("Warning").sample(-1)
                    continue
                # 高处障碍先固定在世界里，进入画面后才开始完整预警计时。
                tendril.set_meta(&"awaiting_view",false)
                tendril.delay = row.age
            var t: float = row.age-tendril.delay
            if not tendril.cancelled and not tendril.warning_confirmed and t>=.28:
                var tip: Vector2 = tendril.to_global(tendril.start+(tendril.finish-tendril.start).normalized()*150)
                # 确认露头和预警被看到后便承诺出手；游出镜头不会取消或转向。
                if _view_rect().grow(-20).has_point(tip):
                    tendril.warning_confirmed = true
                else:
                    tendril.cancel()
            tendril.sample(row.age)
            if tendril.dangerous and not tendril.get_meta(&"strike_reported",false):
                tendril.set_meta(&"strike_reported",true)
                strike_started.emit()
            var warning: Node2D = tendril.get_node("Warning")
            warning.sample(t-.18)
            if tendril.cancelled: warning.hide()
            var local_center: Vector2 = tendril.to_local(center)
            var nearby: bool = local_center.y>=minf(tendril.start.y,tendril.finish.y)-tentacle_thickness and local_center.y<=maxf(tendril.start.y,tendril.finish.y)+tentacle_thickness
            var teleport := target.get_node_or_null("Teleport")
            if damage_enabled and not row.get("hit_reported",false) and row.dodge_grace<=0 and nearby and not _hit and (stun==null or not stun.is_protected()) and (teleport==null or not teleport.is_invulnerable()) and tendril.touches(center,24+(stun.contact_margin if stun!=null else 0)):
                _hit = true
                row.hit_reported=true
                player_hit.emit(Vector2(signf(tendril.finish.x-tendril.start.x),.15))
        if row_top-fish_y>1900: remove.append(row)
    for row in remove:
        row.node.queue_free()
        rows.erase(row)

func _spawn_row() -> void:
    _elapsed = 0
    var point := to_local(target.global_position)
    _last_row_y = point.y
    var root := Node2D.new()
    add_child(root)
    var view := _view_rect()
    root.position.y = clampf(point.y-spawn_ahead_pixels,to_local(view.position).y+60,to_local(view.end).y-150)
    _wave_count += 1
    var extra_high: bool = high_barrier_every>0 and _wave_count%high_barrier_every==0
    var arms: Array[Node2D] = []
    for i in (3 if extra_high else 2):
        var side := _side if i%2==0 else -_side
        var tendril := TENDRIL.new()
        tendril.thickness = tentacle_thickness
        tendril.curve_height = -40.0 if i==1 else -45.0
        tendril.charge_seconds = charge_seconds
        tendril.strike_seconds = strike_seconds
        tendril.delay = float(i)*.18
        var lane_y: float = root.position.y if i==0 else clampf(point.y+retreat_offset_pixels,to_local(view.position).y+100,to_local(view.end).y-100)
        if i==2: lane_y = point.y-high_barrier_ahead
        var bounds: Vector2 = edge_provider._bounds_at(lane_y)
        var local_y: float = lane_y-root.position.y
        tendril.start = Vector2(bounds.x-80 if side<0 else bounds.y+80,local_y)
        # 两条横向障碍一前一后、左右交错；末端留出可游过的缺口。
        var gap: float = retreat_passage_width if i==1 else passage_width
        if i==2: gap += 40
        tendril.finish = Vector2(bounds.y-gap if side<0 else bounds.x+gap,local_y)
        root.add_child(tendril)
        var exposed: Vector2 = tendril.start+(tendril.finish-tendril.start).normalized()*150
        var warning := WARNING.new()
        warning.name = "Warning"
        warning.position = exposed+Vector2(0,-100 if i==1 else 100)
        tendril.add_child(warning)
        if i==2:
            tendril.set_meta(&"awaiting_view",true)
            tendril.sample(-1)
        else:
            if not view.grow(-20).has_point(tendril.to_global(exposed)):
                tendril.cancel()
            tendril.sample(0)
        arms.append(tendril)
    rows.append({"node":root,"arms":arms,"age":0.0,"aim_frozen":true,"dodge_grace":0.0})
    _side = -_side
    if rows.size()>maximum_rows:
        var old: Dictionary = rows.pop_front()
        old.node.queue_free()
    row_started.emit(root.position.y)

func _view_rect() -> Rect2:
    if not is_instance_valid(camera): return Rect2()
    var size := camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)

func _on_teleported(_from: Vector2, _destination: Vector2) -> void:
    # 瞬移骗过正在蓄力的整组触手，延迟的第二根也不能重新锁定落点。
    for row in rows:
        row.aim_frozen = true
        row.dodge_grace = .65
    _blink_grace = .65

func finish_existing() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    enabled=true
    spawn_allowed=false
    damage_enabled=false

func reset() -> void:
    process_mode=Node.PROCESS_MODE_INHERIT
    spawn_allowed=true
    damage_enabled=true
    enabled = false
    for row in rows: row.node.queue_free()
    rows.clear()
    _elapsed = 0
    _last_row_y = INF
    _side = -1
    _hit = false
    _blink_grace = 0
    _wave_count = 0
