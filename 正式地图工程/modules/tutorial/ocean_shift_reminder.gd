extends "res://modules/ui/following_shift_prompt.gd"
var needed:Dictionary={"tentacle":false,"shark":false}
var learned:Dictionary={"tentacle":false,"shark":false}
var successes:Dictionary={"tentacle":0,"shark":0}
var _attempt:int=0
@onready var level:Node2D=get_parent()
@onready var stage:Node2D=level.get_node("OceanLink/FishStage")
@onready var fish:CharacterBody2D=stage.get_node("Fish")
@onready var blink:Node=fish.get_node("Teleport")
@onready var stun:Node=fish.get_node("Stun")
func _ready():
    super._ready()
    head_offset=Vector2(0,-68)
    stun.stunned.connect(_on_stunned)
    level.died.connect(_on_death)
    blink.teleported.connect(_on_blink)
func _head_sprite()->Sprite2D:return fish.get_node("Visual/Sprite")
func _eligible()->bool:
    return level.visible and not level.dead and not level.exit_in_progress and stage.active and stage.host.claimed and level.player==fish and stage.get_node("ShoreExit").state==stage.get_node("ShoreExit").State.SWIMMING and blink.enabled and stun.stun_remaining<=0.0 and stun.dizzy_remaining<=0.0
func _on_stunned():
    _attempt+=1
    needed.tentacle=true
    _reset_visual()
func _on_death():
    if level.player==fish and level.death_reason==&"shark":needed.shark=true
    _attempt+=1
    _reset_visual()
func _shark_threat()->bool:
    var sharks:Array=[stage.get_node("Shark")]
    sharks.append_array(stage.get_node("FinalSharks").get_children())
    for shark in sharks:
        if shark.is_visible_in_tree() and shark.state in [shark.State.LOCKING,shark.State.DASHING]:return true
    return false
func _tentacle_threat()->bool:
    var side=stage.get_node("SideTentacle")
    if side.attacking and side._clock<side.emerge_seconds+side.raise_seconds+side.strike_seconds:return true
    var net=stage.get_node("BossTentacleNet")
    for row in net.rows:
        for arm in row.arms:
            if arm.cancelled or arm.get_meta(&"awaiting_view",false) or row.age<arm.delay:continue
            var a:Vector2=arm.to_global(arm.start)
            var b:Vector2=arm.to_global(arm.finish)
            if Geometry2D.get_closest_point_to_segment(fish.global_position,a,b).distance_to(fish.global_position)<600.0:return true
    return false
func _wants_prompt()->bool:
    if blink.cooldown_remaining>0.0 or blink._busy:return false
    return (needed.tentacle and not learned.tentacle and _tentacle_threat()) or (needed.shark and not learned.shark and _shark_threat())
func _on_blink(_from:Vector2,_to:Vector2):
    if not _eligible():return
    var tentacle:bool=_tentacle_threat()
    var shark:bool=_shark_threat()
    var attempt:int=_attempt
    await get_tree().create_timer(.3).timeout
    # Do not label a mistimed blink learned if it still ends in damage/death.
    if attempt!=_attempt or not _eligible() or stun.stun_remaining>0.0:return
    if tentacle:_record_success("tentacle")
    if shark:_record_success("shark")
func _record_success(kind:String):
    successes[kind]=mini(2,successes[kind]+1)
    learned[kind]=successes[kind]>=2
