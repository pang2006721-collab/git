extends CanvasLayer
## Contextual retry cue for the two lowest orbs, independent of the modal tutorial.
@export var targets:Array[StringName]=[&"Target01",&"Target02"]
@export var repeat_seconds:float=1.0
@export var head_offset:=Vector2(0,-74)
@export var follow_frequency:float=12.0
@export var maximum_lag:=Vector2(80,26)
var _follow_position:=Vector2.ZERO
var _follow_velocity:=Vector2.ZERO
var _follow_ready:=false
var missed:Dictionary={}
var learned:Dictionary={}
var _jumping:=false
var _jump_target:Node2D
var _age:float=0.0
var _shown:=false
var _alpha:float=0.0
var _pressed_age:float=-1.0
var art:TextureRect
var accents:Array[Line2D]=[]
@onready var level:Node2D=get_parent()
@onready var fork:Node2D=level.get_node("Fork")
@onready var combat:Node=level.get_node("HellCombatShiftReminder")
func _ready():
    layer=80
    var screen=Control.new()
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(screen)
    art=TextureRect.new()
    art.texture=preload("res://assets/art/ui/tutorial_shift.png")
    art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.size=Vector2(240,99)
    art.pivot_offset=art.size*.5
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    screen.add_child(art)
    for side in [-1,1]:
        var accent=Line2D.new()
        accent.width=4
        accent.default_color=Color(1,.87,.45)
        accent.points=PackedVector2Array([Vector2(side*142,-7),Vector2(side*158,-18)])
        screen.add_child(accent)
        accents.append(accent)
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
    _shown=false
    _age=0.0
    _alpha=0.0
    _pressed_age=-1.0
    _follow_ready=false
    _follow_velocity=Vector2.ZERO
    hide()
func _input(event:InputEvent):
    if not _shown or not _eligible() or not event.is_action_pressed(&"possess") or event.is_echo():return
    if event is InputEventKey and event.location==KEY_LOCATION_RIGHT:return
    _pressed_age=0.0
func head_target()->Vector2:
    var sprite:Sprite2D=level.get_node("Demon/Visual/Sprite")
    var head:Vector2=sprite.get_global_transform_with_canvas()*Vector2(sprite.get_rect().get_center().x,sprite.get_rect().position.y)
    var margin:Vector2=art.size*.5+Vector2(24,20)
    return (head+head_offset).clamp(margin,get_viewport().get_visible_rect().size-margin)
func _follow_head(delta:float):
    var target:Vector2=head_target()
    # Same critically damped response as the heaven conversation bubble.
    if not _follow_ready or _follow_position.distance_to(target)>500.0 or delta>.25:
        _follow_position=target
        _follow_velocity=Vector2.ZERO
        _follow_ready=true
    elif delta>0.0:
        var error:Vector2=_follow_position-target
        var impulse:Vector2=_follow_velocity+follow_frequency*error
        var decay:float=exp(-follow_frequency*delta)
        _follow_position=target+(error+impulse*delta)*decay
        _follow_velocity=(_follow_velocity-follow_frequency*impulse*delta)*decay
    _follow_position=target+(_follow_position-target).clamp(-maximum_lag,maximum_lag)
func _process(delta:float):
    var orb_needed:bool=_watched(fork.selected) and missed.has(fork.selected.name)
    var wanted:bool=_eligible() and not get_tree().paused and not fork.flying and not fork.swapping and not fork.launching and (orb_needed or combat.is_reminding())
    if wanted and not _shown:
        _age=0.0
        if _alpha<=0.0:_follow_ready=false
    _shown=wanted
    _age+=delta
    if _pressed_age>=0.0:
        _pressed_age+=delta
        if _pressed_age>=.5:_pressed_age=-1.0
    wanted=wanted or (_pressed_age>=0.0 and _eligible())
    _alpha=move_toward(_alpha,1.0 if wanted else 0.0,delta/.12)
    visible=_alpha>0.0
    if not visible:return
    _follow_head(delta)
    art.position=_follow_position-art.size*.5
    art.rotation=clampf(-_follow_velocity.x*.00007,-.04,.04)
    var beat:float=_pressed_age if _pressed_age>=0.0 else fmod(_age,repeat_seconds)
    var shape_y:float=1.0
    if beat<.1:shape_y=lerpf(1.0,.68,smoothstep(0.0,.1,beat))
    elif beat<.2:shape_y=.68
    elif beat<.5:shape_y=1.0-.32*cos((beat-.2)*24.0)*exp(-(beat-.2)*13.0)
    var enter:float=clampf(_age/.2,0.0,1.0)
    var pop:float=1.0+2.70158*pow(enter-1.0,3)+1.70158*pow(enter-1.0,2)
    art.scale=Vector2(1.0/sqrt(shape_y),shape_y)*maxf(.01,pop)
    art.modulate=Color(1.0,.88 if beat<.2 else 1.0,.68 if beat<.2 else 1.0,_alpha)
    for i in accents.size():
        var side:float=-1.0 if i==0 else 1.0
        accents[i].position=art.position+art.size*.5+Vector2(side*12.0*sin(minf(beat/.35,1.0)*PI),0)
        accents[i].modulate.a=_alpha*(1.0-smoothstep(.12,.36,beat))
