extends "res://modules/ui/following_shift_prompt.gd"
@export var notice_distance:float=380.0
@export var learn_hold_seconds:float=1.1
var learned:bool=false
var _held_seconds:float=0.0
var _hold_done:bool=false
@onready var level:Node2D=get_parent()
@onready var layout:Node2D=level.get_node("OceanLink/FishStage/JungleLayout")
@onready var body:CharacterBody2D=layout.get_node("Squirrel")
@onready var climber:Node=body.get_node("VineClimber")
func _ready():
    super._ready()
    hold_demo=true
    repeat_seconds=1.9
    level.died.connect(func():_held_seconds=0.0;_hold_done=false;_reset_visual())
func _eligible()->bool:
    return level.visible and not level.dead and not level.exit_in_progress and level.player==body and body.get_node("Host").claimed and body.visible and not body.transferring and layout.get_node("CanopyPossession").state!=PossessionController.State.TRANSFERRING
func _head_sprite()->Sprite2D:return body.get_node("Visual/Sprite")
func _is_holding()->bool:return Input.is_action_pressed(climber.grab_action)
func _near_vine()->bool:
    if is_instance_valid(climber.vine):return true
    var hands:Vector2=body.global_position+climber.hands_offset*body.global_scale
    for vine in get_tree().get_nodes_in_group("swing_vines"):
        if hands.distance_to(vine.closest_grip(hands))<notice_distance:return true
    return false
func _wants_prompt()->bool:return not learned and _near_vine()
func _process(delta:float):
    if _eligible() and not get_tree().paused:
        if is_instance_valid(climber.vine) and _is_holding():
            _held_seconds+=delta
            if _held_seconds>=learn_hold_seconds:_hold_done=true
        elif not _is_holding():
            if _hold_done:learned=true
            _held_seconds=0.0
    super._process(delta)
