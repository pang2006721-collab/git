extends Node2D
## 独立效果预览：先审核动画，再接正式通关条件；99颗及以下只展示头顶漂浮。
@export var oranges_total:int=100
@export var auto_play:bool=true
@export var duration:float=8.4
@export var preview_sound:bool=true
var elapsed:float=0.0
var room:Sprite2D
var god_halo:Sprite2D
var soul_halo:Sprite2D
var soul:Node2D
var face:Node2D
var gaze:ShaderMaterial
var halo_texture:Texture2D
var accents:Node2D
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
    accents=Node2D.new()
    accents.set_script(preload("res://modules/visual/halo_preview_accents.gd"))
    accents.z_index=5
    add_child(accents)
    sample(0.0)
func make_halo() -> Sprite2D:
    var halo=Sprite2D.new()
    halo.texture=halo_texture
    add_child(halo)
    return halo
# 所有位置由同一条连续轨迹驱动，避免分段重设速度和叠加 Tween 抢属性。
const GOD_PATH=[Vector3(0,960,262),Vector3(.65,960,262),Vector3(.98,960,280),Vector3(1.14,960,285),Vector3(1.48,960,128),Vector3(1.72,960,146),Vector3(1.98,960,145),Vector3(2.16,960,153),Vector3(2.30,1120,124),Vector3(2.46,1150,145),Vector3(2.72,1130,145),Vector3(3.0,1130,145),Vector3(3.20,1150,118),Vector3(3.34,1130,126),Vector3(3.68,980,240),Vector3(3.8,960,282),Vector3(3.92,957,244),Vector3(4.1,963,266),Vector3(4.4,960,262),Vector3(4.6,960,262),Vector3(10,960,262)]
const SOUL_PATH=[Vector3(2.16,960,153),Vector3(2.24,830,110),Vector3(2.46,700,155),Vector3(2.72,730,165),Vector3(3,730,165),Vector3(4.4,730,165),Vector3(4.62,772,142),Vector3(4.82,700,200),Vector3(5.12,534,370),Vector3(5.35,510,565)]
const GOD_DEFORM=[Vector2(0,1),Vector2(.65,1),Vector2(.98,1.12),Vector2(1.14,1.25),Vector2(1.40,.82),Vector2(1.72,1.05),Vector2(1.98,1),Vector2(2.16,1.34),Vector2(2.30,.90),Vector2(2.46,1.06),Vector2(2.72,1),Vector2(3,1),Vector2(3.2,.85),Vector2(3.4,1),Vector2(3.8,1.30),Vector2(3.92,.87),Vector2(4.1,1.07),Vector2(4.4,1),Vector2(4.6,1),Vector2(10,1)]
const SOUL_SIZE=[Vector2(2.16,.03),Vector2(2.25,1.32),Vector2(2.43,.93),Vector2(2.72,1),Vector2(3,1),Vector2(4.4,1),Vector2(4.62,.95),Vector2(4.9,.87),Vector2(5.35,.68),Vector2(10,.68)]
const SOUL_DEFORM=[Vector2(2.16,1.4),Vector2(2.25,.86),Vector2(2.43,1.1),Vector2(2.72,1),Vector2(3,1),Vector2(4.4,1),Vector2(4.62,1.2),Vector2(4.85,.83),Vector2(5.18,.9),Vector2(5.35,1.28),Vector2(5.48,.86),Vector2(5.66,1.06),Vector2(5.92,1),Vector2(6.15,1),Vector2(10,1)]
const BODY_SQUASH=[Vector2(0,1),Vector2(5.1,1),Vector2(5.3,.9),Vector2(5.36,.82),Vector2(5.49,1.15),Vector2(5.68,.95),Vector2(5.98,1),Vector2(6.2,1),Vector2(10,1)]
const BODY_HOP=[Vector2(0,0),Vector2(5.30,0),Vector2(5.35,0),Vector2(5.49,-26),Vector2(5.65,-10),Vector2(5.95,0),Vector2(6.2,0),Vector2(10,0)]
const RING_RECOIL=[Vector2(5.35,16),Vector2(5.48,-11),Vector2(5.64,4),Vector2(5.92,0),Vector2(6.15,0),Vector2(10,0)]
func eased(a:float,b:float,t:float) -> float:
    return smoothstep(0.0,1.0,clampf((t-a)/(b-a),0,1))
func hermite(a:float,b:float,va:float,vb:float,dt:float,u:float) -> float:
    return (2*u*u*u-3*u*u+1)*a+(u*u*u-2*u*u+u)*dt*va+(-2*u*u*u+3*u*u)*b+(u*u*u-u*u)*dt*vb
func track1(keys:Array,t:float) -> float:
    if t<=keys[0].x:return keys[0].y
    if t>=keys[-1].x:return keys[-1].y
    for i in range(keys.size()-1):
        if t>keys[i+1].x:continue
        var a:Vector2=keys[i]
        var b:Vector2=keys[i+1]
        var va:float=0.0 if i==0 else (b.y-keys[i-1].y)/(b.x-keys[i-1].x)
        var vb:float=0.0 if i+2>=keys.size() else (keys[i+2].y-a.y)/(keys[i+2].x-a.x)
        return hermite(a.y,b.y,va,vb,b.x-a.x,(t-a.x)/(b.x-a.x))
    return keys[-1].y
func track2(keys:Array,t:float) -> Vector2:
    var xs:Array=[]
    var ys:Array=[]
    for key:Vector3 in keys:
        xs.append(Vector2(key.x,key.y))
        ys.append(Vector2(key.x,key.z))
    return Vector2(track1(xs,t),track1(ys,t))
func blink_at(t:float,center:float,width:float=.11) -> float:
    var u:float=clampf(1.0-absf(t-center)/width,0,1)
    return u*u*(3-2*u)
func _process(delta:float) -> void:
    if not auto_play:return
    var previous:float=elapsed
    elapsed=minf(duration,elapsed+delta) if oranges_total>=100 else elapsed+delta
    if oranges_total>=100 and preview_sound:
        for impact in [2.16,3.8,5.35]:
            if previous<impact and elapsed>=impact:Sfx.play(&"bounce")
    sample(elapsed)
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
    face.gaze=Vector2.ZERO
    face.blink=0.0
    var looking_at:Vector2=SOUL_FEET+Vector2(0,-100)
    var blink:float=0.0
    accents.marks=[]
    if oranges_total>=100:
        god_halo.position=track2(GOD_PATH,t)
        var gx:float=maxf(.5,track1(GOD_DEFORM,t))
        god_halo.scale=Vector2(gx,1.0/gx)
        god_halo.rotation=track1([Vector2(0,0),Vector2(.98,-.035),Vector2(1.48,.07),Vector2(1.98,0),Vector2(2.16,-.08),Vector2(2.3,.1),Vector2(2.72,0),Vector2(3.2,-.13),Vector2(3.8,.04),Vector2(4.4,0),Vector2(10,0)],t)
        if t>=4.6:god_halo.position.y+=sin((t-4.6)*2.2)*3
        if t>=2.16:
            soul_halo.visible=true
            soul_halo.position=track2(SOUL_PATH,t)
            var size:float=clampf(track1(SOUL_SIZE,t),.01,1.4)
            var sx:float=maxf(.5,track1(SOUL_DEFORM,t))
            soul_halo.scale=Vector2(size*sx,size/sx)
            soul_halo.rotation=track1([Vector2(2.16,.12),Vector2(2.25,-.11),Vector2(2.46,.06),Vector2(2.72,0),Vector2(4.4,0),Vector2(4.62,.15),Vector2(4.92,-.15),Vector2(5.35,.08),Vector2(5.7,-.04),Vector2(5.98,0),Vector2(10,0)],t)
        var sy:float=clampf(track1(BODY_SQUASH,t),.75,1.25)
        soul.position=SOUL_FEET+Vector2(0,track1(BODY_HOP,t))
        soul.scale=Vector2(1.0/sy,sy)*1.8
        if t>=5.35:
            # 光环晚于身体回弹；从真实头顶位置计算，形变时也不会穿头。
            soul_halo.position=SOUL_HOME+Vector2(0,soul.position.y-SOUL_FEET.y-162*(sy-1.0)+track1(RING_RECOIL,t))
            if t>=6.2:soul_halo.position.y+=sin((t-6.2)*2.2)*3
        face.happiness=eased(5.55,5.95,t)
        face.blink=blink_at(t,5.36,.09)*(1-face.happiness)
        if t<5.55:
            face.gaze=Vector2(.6,-2.8)*eased(.6,1.1,t)
        if t>=.65 and t<4.35:looking_at=god_halo.position
        elif t>=4.35 and t<5.75:looking_at=soul_halo.position
        elif t>=5.75:looking_at=SOUL_FEET+Vector2(0,-130)
        blink=maxf(blink_at(t,.66),blink_at(t,3.82,.08))
        accents.marks=[{"position":Vector2(960,145),"age":t-2.16,"strength":1.0},{"position":GOD_HOME,"age":t-3.8,"strength":.55},{"position":soul_halo.position,"age":t-5.35,"strength":.7}]
    var direction:Vector2=((looking_at-Vector2(960,480))/Vector2(420,300)).limit_length(1.0)
    gaze.set_shader_parameter("gaze_pixels",direction*Vector2(12,8))
    gaze.set_shader_parameter("blink",blink)
    face.queue_redraw()
    accents.queue_redraw()
