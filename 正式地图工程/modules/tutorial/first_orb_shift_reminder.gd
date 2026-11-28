extends "res://modules/ui/following_shift_prompt.gd"
## First missed orb jumps and first enemy attacks share the same head-follow prompt.
@export var targets:Array[StringName]=[&"Target01",&"Target02"]
var missed:Dictionary={}
var learned:Dictionary={}
var _jumping:=false
var _jump_target:Node2D
@onready var level:Node2D=get_parent()
@onready var fork:Node2D=level.get_node("Fork")
@onready var combat:Node=level.get_node("HellCombatShiftReminder")
func _ready():
    super._ready()
    level.get_node("Demon/Movement").jumped.connect(_on_jump)
    level.get_node("Demon/Movement").landed.connect(_on_landed)
    level.died.connect(_on_death)
    fork.selection_changed.connect(_on_selection)
    fork.thrown.connect(_on_throw)
    fork.interaction_reset.connect(_reset_interaction)
    hide()
func _eligible()->bool:
    return level.visible and not level.dead and not level.exit_in_progress and level.get_node("WallEntry").completed and level.player==level.demon and level.demon.get_node("Host").claimed and level.get_node("OceanLink").stage==0
func _watched(ball:Node2D)->bool:
    return is_instance_valid(ball) and ball.name in targets and not learned.has(ball.name)
func _on_jump():
    if not _eligible():return
    _jumping=true
    _jump_target=fork.selected if _watched(fork.selected) else null
func _on_selection(ball:Node2D):
    if _jumping and _eligible() and _watched(ball):_jump_target=ball
func _record_miss():
    if _jumping and _watched(_jump_target):missed[_jump_target.name]=true
    _jumping=false
    _jump_target=null
func _on_landed(_impact:float):_record_miss()
func _on_death():
    _record_miss()
    _reset_interaction()
func _on_throw():
    if is_instance_valid(fork.lodged) and fork.lodged.name in targets:
        learned[fork.lodged.name]=true
        _jumping=false
        _jump_target=null
        if _pressed_age<0.0:_reset_interaction()
func _reset_interaction():
    _jumping=false
    _jump_target=null
    _reset_visual()
func _head_sprite()->Sprite2D:return level.get_node("Demon/Visual/Sprite")
func _wants_prompt()->bool:
    var orb_needed:bool=_watched(fork.selected) and missed.has(fork.selected.name)
    return not fork.flying and not fork.swapping and not fork.launching and (orb_needed or combat.is_reminding())
