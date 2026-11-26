extends Node2D
## 独立效果预览：先审核动画，再接正式通关条件；99颗及以下只展示头顶漂浮。
@export var oranges_total:int=100
@export var auto_play:bool=true
@export var duration:float=6.2
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
var external_soul:bool=false
var external_offset:=Vector2.ZERO
var initial_god_halo_offset:=Vector2.ZERO
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
const GOD_PULSE=[Vector2(0,1),Vector2(1.8,1),Vector2(2.05,1.04),Vector2(2.16,1.10),Vector2(2.30,.97),Vector2(2.55,1.01),Vector2(2.85,1),Vector2(10,1)]
const SOUL_PATH=[Vector3(2.16,960,262),Vector3(2.25,960,170),Vector3(2.48,960,188),Vector3(2.72,960,183),Vector3(2.86,985,166),Vector3(3.12,835,240),Vector3(3.52,565,410),Vector3(3.8,510,565)]
const SOUL_SIZE=[Vector2(2.16,.03),Vector2(2.25,.78),Vector2(2.48,.64),Vector2(2.72,.68),Vector2(2.86,.65),Vector2(3.25,.64),Vector2(3.8,.68),Vector2(10,.68)]
const SOUL_DEFORM=[Vector2(2.16,1.35),Vector2(2.25,1.08),Vector2(2.48,.96),Vector2(2.72,1),Vector2(2.86,1.14),Vector2(3.25,.86),Vector2(3.8,1.28),Vector2(3.93,.86),Vector2(4.11,1.06),Vector2(4.37,1),Vector2(4.6,1),Vector2(10,1)]
const BODY_SQUASH=[Vector2(0,1),Vector2(3.55,1),Vector2(3.75,.9),Vector2(3.81,.82),Vector2(3.94,1.15),Vector2(4.13,.95),Vector2(4.43,1),Vector2(4.65,1),Vector2(10,1)]
const BODY_HOP=[Vector2(0,0),Vector2(3.75,0),Vector2(3.8,0),Vector2(3.94,-26),Vector2(4.1,-10),Vector2(4.4,0),Vector2(4.65,0),Vector2(10,0)]
const RING_RECOIL=[Vector2(3.8,16),Vector2(3.93,-11),Vector2(4.09,4),Vector2(4.37,0),Vector2(4.6,0),Vector2(10,0)]
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
        for impact in [2.16,3.8]:
            if previous<impact and elapsed>=impact:Sfx.play(&"bounce")
    sample(elapsed)
func sample(t:float) -> void:
    var live_position:Vector2=soul.position
    var live_scale:Vector2=soul.scale
    var live_rotation:float=soul.rotation
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
        # 原光环一直戴在上帝头上，只在分出小光环时轻轻鼓一下。
        var gx:float=maxf(.5,track1(GOD_PULSE,t))
        god_halo.scale=Vector2(gx,1.0/gx)
        if t>=2.16:
            soul_halo.visible=true
            soul_halo.position=track2(SOUL_PATH,t)
            var size:float=clampf(track1(SOUL_SIZE,t),.01,1.4)
            var sx:float=maxf(.5,track1(SOUL_DEFORM,t))
            soul_halo.scale=Vector2(size*sx,size/sx)
            soul_halo.rotation=track1([Vector2(2.16,.04),Vector2(2.25,-.06),Vector2(2.48,.03),Vector2(2.72,0),Vector2(2.86,.12),Vector2(3.25,-.12),Vector2(3.8,.08),Vector2(4.15,-.04),Vector2(4.43,0),Vector2(10,0)],t)
        var sy:float=clampf(track1(BODY_SQUASH,t),.75,1.25)
        soul.position=SOUL_FEET+Vector2(0,track1(BODY_HOP,t))
        soul.scale=Vector2(1.0/sy,sy)*1.8
        if t>=3.8:
            # 光环晚于身体回弹；从真实头顶位置计算，形变时也不会穿头。
            soul_halo.position=SOUL_HOME+Vector2(0,soul.position.y-SOUL_FEET.y-162*(sy-1.0)+track1(RING_RECOIL,t))
            if t>=4.65:soul_halo.position.y+=sin((t-4.65)*2.2)*3
        face.happiness=eased(4.0,4.4,t)
        face.blink=blink_at(t,3.81,.09)*(1-face.happiness)
        if t<4.0:
            face.gaze=Vector2(.6,-2.8)*eased(.6,1.1,t)
        if t>=.65 and t<2.30:looking_at=god_halo.position
        elif t>=2.30 and t<4.2:looking_at=soul_halo.position
        elif t>=4.2:looking_at=SOUL_FEET+Vector2(0,-130)
        blink=blink_at(t,.66)
        accents.marks=[{"position":GOD_HOME,"age":t-2.16,"strength":.65},{"position":soul_halo.position,"age":t-3.8,"strength":.7}]
    if external_soul:
        var base_size:float=sqrt(absf(live_scale.x*live_scale.y))
        var reaction:float=track1(BODY_SQUASH,t) if oranges_total>=100 else 1.0
        var shape_y:float=clampf(live_scale.y/base_size*reaction,.75,1.25)
        soul.position=live_position+Vector2(0,track1(BODY_HOP,t)*base_size/1.8) if oranges_total>=100 else live_position
        soul.scale=Vector2(1.0/shape_y,shape_y)*base_size
        soul.rotation=live_rotation
        god_halo.position+=initial_god_halo_offset*(1.0-eased(0,.65,t))
        var head:Vector2=soul.position+Vector2(0,-90*soul.scale.y-28)
        if t>=2.16:
            if t<3.8:
                soul_halo.position+=external_offset+(head-SOUL_HOME-external_offset)*eased(2.86,3.8,t)
                soul_halo.scale*=base_size/1.8
            else:
                soul_halo.position=head+Vector2(0,track1(RING_RECOIL,t)*base_size/1.8)
                soul_halo.scale*=base_size/1.8
        if t<.65 or t>=4.2: looking_at=live_position+Vector2(0,-90*live_scale.y*.7)-external_offset
        elif t>=2.30: looking_at=soul_halo.position-external_offset
        if accents.marks.size()>=2: accents.marks[1].position=soul_halo.position-external_offset
    var direction:Vector2=((looking_at-Vector2(960,480))/Vector2(420,300)).limit_length(1.0)
    gaze.set_shader_parameter("gaze_pixels",direction*Vector2(12,8))
    gaze.set_shader_parameter("blink",blink)
    face.queue_redraw()
    accents.queue_redraw()
