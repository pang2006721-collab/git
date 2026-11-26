extends Node2D
## 独立效果预览：先审核动画，再接正式通关条件；99颗及以下只展示头顶漂浮。
@export var oranges_total:int=100
@export var auto_play:bool=true
@export var duration:float=10.0
var elapsed:float=0.0
var room:Sprite2D
var god_halo:Sprite2D
var soul_halo:Sprite2D
var soul:Node2D
var face:Node2D
var gaze:ShaderMaterial
var halo_texture:Texture2D
const GOD_HOME=Vector2(960,262)
const SOUL_FEET=Vector2(510,720)
const SOUL_HOME=Vector2(510,520)
func _ready() -> void:
    room=Sprite2D.new()
    room.texture=preload("res://assets/art/heaven/ending/god_room.png")
    room.centered=false
    room.region_enabled=true
    room.region_rect=Rect2(0,0,1920,1080)
    room.region_filter_clip_enabled=true
    gaze=ShaderMaterial.new()
    gaze.shader=preload("res://shaders/halo_preview_gaze.gdshader")
    room.material=gaze
    add_child(room)
    halo_texture=preload("res://assets/art/heaven/ending/halo.png")
    god_halo=make_halo()
    soul_halo=make_halo()
    soul=Node2D.new()
    soul.position=SOUL_FEET
    soul.scale=Vector2.ONE*1.8
    add_child(soul)
    var art=Sprite2D.new()
    var atlas=AtlasTexture.new()
    atlas.atlas=preload("res://assets/art/characters/soul/soul_v001.png")
    atlas.region=Rect2(1092,1589,71,90)
    atlas.filter_clip=true
    art.texture=atlas
    art.position=Vector2(0,-45)
    var white=ShaderMaterial.new()
    white.shader=preload("res://shaders/soul_white.gdshader")
    art.material=white
    soul.add_child(art)
    face=Node2D.new()
    face.set_script(preload("res://modules/visual/halo_preview_soul_face.gd"))
    face.position=Vector2(-35.5,-90)
    soul.add_child(face)
    god_halo.z_index=4
    soul_halo.z_index=4
    sample(0.0)
func make_halo() -> Sprite2D:
    var halo=Sprite2D.new()
    halo.texture=halo_texture
    add_child(halo)
    return halo
func eased(a:float,b:float,t:float) -> float:
    return smoothstep(0.0,1.0,clampf((t-a)/(b-a),0,1))
func arc(a:Vector2,b:Vector2,height:float,u:float) -> Vector2:
    return a.lerp(b,u)+Vector2(0,-height*sin(PI*u))
func _process(delta:float) -> void:
    if auto_play and oranges_total>=100:elapsed=minf(duration,elapsed+delta)
    else:elapsed+=delta
    sample(elapsed if oranges_total>=100 else fmod(elapsed,1.0))
func sample(t:float) -> void:
    god_halo.visible=true
    god_halo.position=GOD_HOME+Vector2(0,sin(t*2.2)*4)
    god_halo.scale=Vector2.ONE
    god_halo.rotation=sin(t*1.6)*.025
    soul_halo.visible=false
    soul_halo.modulate.a=1.0
    soul_halo.position=SOUL_HOME
    soul_halo.scale=Vector2.ONE*.68
    soul_halo.rotation=0.0
    soul.position=SOUL_FEET
    soul.scale=Vector2.ONE*1.8
    face.happiness=0.0
    var looking_at:Vector2=SOUL_FEET+Vector2(0,-100)
    if oranges_total>=100:
        var up:float=eased(1.0,1.65,t)
        looking_at=looking_at.lerp(god_halo.position,up)
        if t>=1.7 and t<2.8:
            var u:float=eased(1.7,2.8,t)
            god_halo.position=GOD_HOME.lerp(Vector2(960,145),u)
            god_halo.rotation=sin(u*PI)*.07
        elif t>=2.8 and t<3.8:
            var u:float=eased(2.8,3.8,t)
            god_halo.position=Vector2(960,145).lerp(Vector2(1130,145),u)
            soul_halo.visible=true
            soul_halo.position=Vector2(960,145).lerp(Vector2(730,165),u)
            soul_halo.scale=Vector2.ONE*lerpf(.12,1.0,u)
            soul_halo.modulate.a=smoothstep(0,.35,u)
        elif t>=3.8:
            soul_halo.visible=true
            soul_halo.position=Vector2(730,165)
            soul_halo.scale=Vector2.ONE
            if t<4.65:
                var u:float=eased(3.8,4.65,t)
                god_halo.position=arc(Vector2(1130,145),GOD_HOME,25,u)
            elif t<5.05:
                var u:float=clampf((t-4.65)/.4,0,1)
                var spring:float=sin(u*TAU*1.3)*exp(-4*u)
                god_halo.position=GOD_HOME+Vector2(0,7*spring)
                god_halo.scale=Vector2(1+.22*spring,1-.28*spring)
            if t>=5.05 and t<6.5:
                var u:float=eased(5.05,6.5,t)
                soul_halo.position=arc(Vector2(730,165),SOUL_HOME,55,u)
                soul_halo.scale=Vector2.ONE*lerpf(1.0,.68,u)
                soul_halo.rotation=sin(u*PI)*-.12
            elif t>=6.5:
                var u:float=clampf((t-6.5)/.65,0,1)
                var spring:float=0.0 if u>=1.0 else sin(u*TAU*1.25)*exp(-4*u)
                var hop:float=-18*sin(PI*u)
                soul.position=SOUL_FEET+Vector2(0,hop)
                soul.scale=Vector2(1+.1*spring,1-.1*spring)*1.8
                soul_halo.position=SOUL_HOME+Vector2(0,hop+5*spring)
                soul_halo.scale=Vector2(1+.18*spring,1-.24*spring)*.68
                if t>7.15:soul_halo.position.y+=sin((t-7.15)*2.2)*3
                face.happiness=eased(6.55,7.1,t)
        if t>=1.65 and t<4.85:looking_at=god_halo.position
        elif t>=4.85 and t<6.6:looking_at=soul_halo.position
        elif t>=6.6:looking_at=SOUL_FEET+Vector2(0,-130)
    var direction:Vector2=((looking_at-Vector2(960,480))/Vector2(420,300)).limit_length(1.0)
    gaze.set_shader_parameter("gaze_pixels",direction*Vector2(10,8))
    face.queue_redraw()
