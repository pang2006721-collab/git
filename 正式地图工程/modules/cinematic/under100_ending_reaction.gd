extends Node2D
## One sampled timeline owns the original reaction art; gameplay still owns soul movement.
var opening: Node2D
var question: Sprite2D
var plead: Sprite2D
var accept: Sprite2D
var expression: Sprite2D
var original: Sprite2D
var cry: Texture2D
var relieved: Texture2D
func configure(owner_opening: Node2D) -> void:
    opening=owner_opening
    question=_art("question",self)
    plead=_art("plead",self)
    accept=_art("accept",self)
    expression=_art("cry",opening.soul)
    expression.position=Vector2(0,-45)
    cry=expression.texture
    relieved=load("res://assets/art/heaven/ending/under100/relieved.png")
    original=opening.soul.get_child(0)
func _art(name_key: String,parent: Node) -> Sprite2D:
    var sprite:=Sprite2D.new()
    sprite.texture=load("res://assets/art/heaven/ending/under100/"+name_key+".png")
    sprite.z_index=6
    parent.add_child(sprite)
    return sprite
func _pop(sprite: Sprite2D,t: float,start: float,end: float,size: float) -> void:
    sprite.visible=t>=start and t<end
    if not sprite.visible:return
    var age:=t-start
    var growth:=clampf(age/.16,0,1)
    var spring:=1.0+.25*sin(age*23.0)*exp(-age*7.0)
    sprite.scale=Vector2.ONE*size*growth*spring
    sprite.modulate.a=1.0-clampf((t-(end-.18))/.18,0,1)
func sample(t: float) -> void:
    var offset: Vector2=opening.external_offset if opening.external_soul else Vector2.ZERO
    question.position=Vector2(1300,440)+offset
    accept.position=question.position
    plead.position=(opening.soul.position+Vector2(145,-175)).clamp(Vector2(110,110),Vector2(1810,930))
    _pop(question,t,.6,2.6,.85)
    _pop(plead,t,2.6,4.65,.8)
    _pop(accept,t,4.7,6.8,.85)
    var reacting: bool=t>=1.7
    original.visible=not reacting
    opening.face.visible=not reacting
    expression.visible=reacting
    if reacting:
        expression.texture=cry if t<5.1 else relieved
        var age:=t-(1.7 if t<5.1 else 5.1)
        var pulse:=1.0+.2*sin(age*24.0)*exp(-age*8.0)
        expression.scale=Vector2(pulse,1.0/pulse)*(90.0/155.0)
    var shake:=sin((t-3.7)*17.0)*12.0*sin(clampf((t-3.7)/.8,0,1)*PI) if t>=3.7 and t<=4.5 else 0.0
    opening.gaze.set_shader_parameter("head_shake",shake)
func restore() -> void:
    expression.hide()
    original.show()
    opening.face.show()
    opening.face.happiness=1.0
