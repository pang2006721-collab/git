extends Node2D
## 主藤蔓上的静止绑钻；碰触崩开绑藤，复活落在短暂承重的小树枝上。
signal activated
@export var map_position: Vector2 = Vector2(1100,22846)
@export var trigger_radius: float = 105.0
@export var float_lift: float = 90.0
@export var branch_offset: Vector2 = Vector2(240,150)
@export var respawn_grace_seconds: float = 1.5
var active: bool = false
var grace_remaining: float = 0.0
var _opening: bool = false
var _elapsed: float = 0.0
var _motion: Tween
@onready var level: Node2D = get_parent()
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")
@onready var layout: Node2D = stage.get_node("JungleLayout")
@onready var body: CharacterBody2D = layout.get_node("Squirrel")

func _ready() -> void:
    global_position=level.to_global(map_position)
    $Branch.position=branch_offset

func _physics_process(_delta: float) -> void:
    if active or level.dead or level.exit_in_progress or level.player!=body or not body.get_node("Host").claimed: return
    var center: Vector2=body.get_node("Visual/Sprite").global_position
    if center.distance_to($Contact.global_position)<=trigger_radius: activate()

func activate() -> void:
    if active: return
    active=true
    _opening=true
    $Binding.hide()
    _burst_binding()
    _motion=create_tween()
    _motion.tween_property($Float,"position",Vector2(0,-float_lift),.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _motion.tween_callback(func(): _opening=false)
    activated.emit()

func _burst_binding() -> void:
    var texture: AtlasTexture=$Binding.texture
    for i in 4:
        var crop:=AtlasTexture.new()
        crop.atlas=texture.atlas
        crop.region=Rect2(texture.region.position+Vector2(i*21.5,0),Vector2(21.5,texture.region.size.y))
        crop.filter_clip=true
        var piece:=Sprite2D.new()
        piece.texture=crop
        piece.z_index=11
        piece.position=Vector2((i-1.5)*21.5,0)
        add_child(piece)
        var motion:=create_tween().set_parallel(true)
        motion.tween_property(piece,"position",piece.position+Vector2((i-1.5)*85,35 if i%2==0 else -55),.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        motion.tween_property(piece,"rotation",(i-1.5)*.7,.4)
        motion.tween_property(piece,"modulate:a",0.0,.3).set_delay(.1)
        motion.chain().tween_callback(piece.queue_free)

func _process(delta: float) -> void:
    grace_remaining=maxf(0,grace_remaining-delta)
    if not active or _opening: return
    _elapsed+=delta
    $Float.position=Vector2(0,-float_lift+sin(_elapsed*TAU/2.0)*7)

func restore_player() -> void:
    # 共用海底分段的清理和相机初始化，再把控制交给丛林松鼠。
    level.get_node("OceanCheckpoint").restore_player()
    stage.host.reset()
    stage.fish.get_node("Patrol").stop()
    stage.fish.get_node("Input").enabled=false
    stage.fish.get_node("Movement").enabled=false
    stage.fish.get_node("Teleport").enabled=false
    stage.fish.hide()
    stage.get_node("ShoreExit").state=stage.get_node("ShoreExit").State.DEAD
    stage.get_node("JunglePossession").state=PossessionController.State.POSSESSED
    stage.get_node("JunglePossession").enabled=false
    body.get_node("Host").take_control()
    body.get_node("VineClimber").reset()
    body.get_node("VineClimber").set_physics_process(true)
    body.get_node("AirSpin").reset()
    body.get_node("Defeat").reset()
    body.get_node("Visual").reset()
    body.set_active(true)
    body.get_node("Input").enabled=true
    body.get_node("Input").external_control=false
    body.get_node("Input").clear()
    body.get_node("Movement").enabled=true
    body.get_node("Movement").reset()
    body.global_position=$Branch.global_position+Vector2(0,-8)
    body.reset_physics_interpolation()
    body.show()
    level.player=body
    $Branch.prepare(body)
    level.camera.set_follow_target(body,true)
    layout._update_nearby()

func finish_return() -> void:
    grace_remaining=respawn_grace_seconds
    $Branch.arm()
