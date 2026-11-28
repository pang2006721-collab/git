extends "res://modules/ui/following_shift_prompt.gd"
## Predict a near collision and whether either horizontal escape is still reachable.
@export var notice_seconds:float=1.0
@export var minimum_notice_seconds:float=.12
@export var reaction_seconds:float=.22
var _remaining:float=0.0
@onready var level:Node2D=get_parent()
@onready var layout:Node2D=level.get_node("OceanLink/FishStage/JungleLayout")
@onready var bird:CharacterBody2D=layout.get_node("Bird")
@onready var fire:Node=bird.get_node("Boost")
@onready var hail:Node=layout.get_node("SkyEagle/Hail")
func _ready():
    super._ready()
    hold_demo=true
    repeat_seconds=3.0
    anchor_below=true
    head_offset=Vector2(0,82)
    level.died.connect(func():_remaining=0.0;_reset_visual())
func _head_sprite()->Sprite2D:return bird.get_node("Visual/Sprite")
func _is_holding()->bool:return Input.is_action_pressed(&"bird_boost")
func _eligible()->bool:
    return level.visible and not level.dead and not level.exit_in_progress and level.player==bird and bird.get_node("Host").claimed and bird.visible and fire._can_boost()
func _danger_near()->bool:
    var motor:Node=bird.get_node("Movement")
    for stone in hail.stones:
        if not is_instance_valid(stone.art) or stone.get("hit_reported",false) or stone.get("melting",false):continue
        var radius:float=float(stone.radius)+hail.BIRD_RADIUS+16.0
        var gap:Vector2=bird.global_position-stone.art.global_position
        if gap.y<0.0:continue
        var closing:float=float(stone.speed)-bird.velocity.y
        var distance:float=maxf(0.0,gap.y-radius)
        var gravity:float=maxf(hail.fall_gravity,.01)
        var time:float=(-closing+sqrt(closing*closing+2.0*gravity*distance))/gravity
        if time<minimum_notice_seconds or time>notice_seconds:continue
        var projected_x:float=bird.global_position.x+bird.velocity.x*time
        if absf(projected_x-stone.art.global_position.x)>radius:continue
        var available:float=maxf(0.0,time-reaction_seconds)
        var acceleration:float=motor.acceleration
        var speed:float=motor.move_speed
        var escape:float=maxf(0.0,radius-absf(gap.x))
        # An optimistic acceleration-limited escape; prompt only when even that is tight.
        var reachable:float=minf(speed*available,absf(bird.velocity.x)*available+.5*acceleration*available*available)
        if reachable<escape+20.0:return true
    return false
func _wants_prompt()->bool:
    if fire.is_burning():
        if _is_holding():_remaining=maxf(_remaining,.15)
        return _remaining>0.0
    return fire.heat>=fire.minimum_charge and (_remaining>0.0 or _danger_near())
func _process(delta:float):
    _remaining=maxf(0.0,_remaining-delta)
    if _eligible() and not get_tree().paused and fire.heat>=fire.minimum_charge and _danger_near():_remaining=.9
    super._process(delta)
