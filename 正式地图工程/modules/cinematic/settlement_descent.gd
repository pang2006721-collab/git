extends Node2D
## 正式结尾与独立预览共用。保留原文，数字覆盖原横线，注入本局收集与回放。
const HALO = preload("res://scenes/previews/halo_reward_preview.tscn")
const STAGES = [&"hell", &"ocean", &"jungle", &"sky"]
const FRAME_INSET = (976.0-453.0*16.0/9.0)*.5
# 原内窗有少量压到白线，留出2像素间隙；录像始终保持16:9。
const REPLAY_WIDTH = 453.0*16.0/9.0-8.0
const REPLAY_HEIGHT = REPLAY_WIDTH*9.0/16.0
const WINDOWS = [Rect2(504+FRAME_INSET, 6938.25, REPLAY_WIDTH, REPLAY_HEIGHT), Rect2(508+FRAME_INSET, 7933.25, REPLAY_WIDTH, REPLAY_HEIGHT), Rect2(511+FRAME_INSET, 8945.25, REPLAY_WIDTH, REPLAY_HEIGHT), Rect2(519+FRAME_INSET, 9984.25, REPLAY_WIDTH, REPLAY_HEIGHT)]
const FRAME_BOUNDS = [Vector4(450,6800,1540,7440),Vector4(454,7795,1544,8440),Vector4(457,8807,1547,9450),Vector4(465,9846,1555,10490)]
const NUMBER_CENTERS = [Vector2(1427, 7538), Vector2(1433, 8543), Vector2(1424, 9554), Vector2(1412, 10594)]
const DIGIT_RECTS = [Rect2(1241,4579,47,78), Rect2(389,4771,28,59), Rect2(535,4862,78,86), Rect2(554,4624,47,93), Rect2(877,4877,69,87), Rect2(1451,4889,52,80), Rect2(1134,4879,60,94), Rect2(740,4625,64,78), Rect2(994,4613,47,89), Rect2(1431,4616,64,98)]
# y 是镜头滚动距离：云层快速掠过，文字与每个回放附近放慢；连续轨迹不改缩放。
const SCROLL = [Vector2(0,0), Vector2(8.4,0), Vector2(9.2,150), Vector2(11.8,4850), Vector2(14.5,5100), Vector2(17.2,5480), Vector2(20.2,5740), Vector2(22.0,6700), Vector2(27.0,6750), Vector2(29.0,7695), Vector2(34.0,7745), Vector2(36.0,8707), Vector2(41.0,8757), Vector2(43.0,9746), Vector2(48.0,9796), Vector2(50.0,9990)]
@export var auto_play: bool = true
@export var interactive: bool = true
@export var oranges_total: int = 100
@export var opening_offset := Vector2.ZERO
@export var arrival_position := Vector2(510,923)
@export var arrival_velocity := Vector2(0,-620)
@export var arrival_scale := Vector2(1.4,1.4)
@export var initial_god_halo_offset := Vector2.ZERO
@export var review_end_seconds: float = 50.0
@export var duration: float = 60.0
var elapsed: float = 0.0
var data := {"deaths": {&"hell":0, &"ocean":0, &"jungle":0, &"sky":0}, "clips": {}, "fps":8}
var world: Node2D
var opening: Node2D
var ghost_layer: CanvasLayer
var numbers: Array[Node2D] = []
var screens: Array[Sprite2D] = []
var _decoded: Array[ImageTexture] = []
var _frame_indices := [-1,-1,-1,-1]
var _digit_textures: Array[Texture2D] = []
var flight: Node
var cloud_layer: CanvasLayer
var cloud_front: Node2D
var _return_started: bool = false
var gate: Node
var _review_started: bool = false
var _review_time: float = 0.0

func _ready() -> void:
    world = Node2D.new()
    add_child(world)
    for i in 6:
        var tile := Sprite2D.new()
        tile.texture = load("res://assets/art/heaven/settlement/descent_%02d.png" % i)
        tile.centered = false
        tile.position.y = i * 2048
        if i == 0:
            var material := ShaderMaterial.new()
            material.shader = preload("res://shaders/settlement_opening_background.gdshader")
            material.set_shader_parameter("opening_room",preload("res://assets/art/heaven/ending/god_room.png"))
            tile.material = material
        elif i >= 3:
            var material := ShaderMaterial.new()
            material.shader = preload("res://shaders/settlement_replay_frame.gdshader")
            material.set_shader_parameter("poster",tile.texture)
            material.set_shader_parameter("clean_poster",load("res://assets/art/reference_map/%02d.png" % i))
            material.set_shader_parameter("band_top",i*2048.0)
            material.set_shader_parameter("inset_pixels",FRAME_INSET)
            material.set_shader_parameter("frame_bounds",PackedVector4Array(FRAME_BOUNDS))
            tile.material = material
        world.add_child(tile)
    # 两张文字分开按原图取出，不把散落的白色笔触算进结算标题。
    var text: Texture2D = load("res://assets/art/heaven/settlement/恭喜文字.png")
    _sprite(text, Rect2(330,150,1340,620), Vector2(330,5380), world)
    _sprite(text, Rect2(330,1100,1360,310), Vector2(330,6100), world)
    for i in 10:
        var atlas := AtlasTexture.new()
        atlas.atlas = load("res://assets/art/heaven/settlement/%d.png" % i)
        atlas.region = DIGIT_RECTS[i]
        atlas.filter_clip = true
        _digit_textures.append(atlas)
    for i in 4:
        var screen := Sprite2D.new()
        screen.centered = false
        screen.position = WINDOWS[i].position
        screen.visible = false
        world.add_child(screen)
        screens.append(screen)
        _decoded.append(ImageTexture.new())
        var number := Node2D.new()
        number.position = NUMBER_CENTERS[i]
        world.add_child(number)
        numbers.append(number)
    opening = HALO.instantiate()
    opening.auto_play = false
    opening.oranges_total = oranges_total
    world.add_child(opening)
    ghost_layer = CanvasLayer.new()
    ghost_layer.layer = 1
    add_child(ghost_layer)
    _build_cloud_front()
    flight = preload("res://modules/movement/settlement_ghost_flight.gd").new()
    add_child(flight)
    flight.exited.connect(_on_ghost_exited)
    gate = preload("res://modules/cinematic/settlement_cloud_gate.gd").new()
    add_child(gate)
    gate.configure(opening.soul,opening.soul_halo,ghost_layer,cloud_layer,arrival_position,arrival_velocity,arrival_scale,923.0+opening_offset.y)
    opening.external_soul = true
    opening.external_offset = opening_offset
    opening.initial_god_halo_offset = initial_god_halo_offset
    set_history(data)
    opening.sample(0)
    _render_scene(0)

func _sprite(texture: Texture2D, region: Rect2, at: Vector2, parent: Node) -> Sprite2D:
    var sprite := Sprite2D.new()
    var atlas := AtlasTexture.new()
    atlas.atlas = texture
    atlas.region = region
    atlas.filter_clip = true
    sprite.texture = atlas
    sprite.centered = false
    sprite.position = at
    parent.add_child(sprite)
    return sprite

func set_history(history: Dictionary) -> void:
    data = history
    if numbers.is_empty(): return
    for i in 4:
        var group := numbers[i]
        for child in group.get_children():
            group.remove_child(child)
            child.queue_free()
        var value := str(maxi(0, int(data.get("deaths", {}).get(STAGES[i], 0))))
        var width: float = 0.0
        for digit in value:
            var sprite := Sprite2D.new()
            sprite.texture = _digit_textures[int(digit)]
            sprite.centered = false
            var s: float = minf(92.0 / sprite.texture.get_height(), 150.0 / maxf(1.0, value.length() * 65.0))
            sprite.scale = Vector2.ONE * s
            sprite.position = Vector2(width, -sprite.texture.get_height() * s * .5)
            width += sprite.texture.get_width() * s + 9.0
            group.add_child(sprite)
        for child in group.get_children(): child.position.x -= (width - 9.0) * .5
        _frame_indices[i] = -1

func scroll_at(t: float) -> float:
    # 单调三次 Hermite：每个停留段仍向下缓行，接缝位置和速度连续。
    if t <= SCROLL[0].x: return SCROLL[0].y
    for i in range(SCROLL.size()-1):
        var a: Vector2 = SCROLL[i]
        var b: Vector2 = SCROLL[i+1]
        if t > b.x: continue
        var slope: float = (b.y-a.y)/(b.x-a.x)
        var before: float = 0.0 if i == 0 else (a.y-SCROLL[i-1].y)/(a.x-SCROLL[i-1].x)
        var after: float = 0.0 if i+2 >= SCROLL.size() else (SCROLL[i+2].y-b.y)/(SCROLL[i+2].x-b.x)
        var va: float = 0.0 if before*slope <= 0 else 2.0*before*slope/(before+slope)
        var vb: float = 0.0 if after*slope <= 0 else 2.0*after*slope/(after+slope)
        return opening.hermite(a.y,b.y,va,vb,b.x-a.x,(t-a.x)/(b.x-a.x))
    return SCROLL[-1].y

func _process(delta: float) -> void:
    if not auto_play:
        if _review_started: move_ghost(delta)
        return
    var previous: float = elapsed
    elapsed += delta
    if not _review_started:
        gate.advance(delta,_read_direction(),elapsed >= opening.duration)
        opening.external_offset = opening_offset
        opening.sample(minf(elapsed,opening.duration))
        if elapsed < opening.duration:
            var impacts: Array=[2.16,3.8] if oranges_total>=100 else [.6,1.7,2.6,4.7,5.1]
            for impact in impacts:
                if previous < impact and elapsed >= impact: Sfx.play(&"bounce")
        _render_scene(minf(elapsed,8.4))
        if gate.phase == gate.Phase.COMPLETE: _begin_review()
    else:
        _review_time += delta
        var timeline: float = 8.4+_review_time
        if timeline >= review_end_seconds and not flight.leaving: flight.leave_upward()
        move_ghost(delta)
        _render_scene(timeline)

func _begin_review() -> void:
    if _review_started: return
    _review_started = true
    if opening.under100!=null:opening.under100.restore()
    gate.release_to_flight(ghost_layer)
    flight.configure(opening.soul,opening.soul_halo,opening.face)
    ghost_layer.hide()

# 离线采样保留既有结算时间轴，实际播放先完成封赏和钻云，再启动这条回顾时间轴。
func sample(t: float) -> void:
    if t < 8.4:
        opening.sample(t)
    else:
        _begin_review()
    _render_scene(t)

func _render_scene(t: float) -> void:
    var scroll: float = scroll_at(t)
    world.position = opening_offset-Vector2(0,scroll)
    cloud_front.position = world.position
    cloud_layer.visible = true
    cloud_front.visible = _review_started
    ghost_layer.visible = not _review_started or scroll >= 1000
    for i in 4:
        var cue: float = [22.0,29.0,36.0,43.0][i]
        var age: float = t-cue
        var pop: float = 1.0
        if age >= 0 and age < .6: pop += sin(age*22.0)*.25*exp(-age*7.0)
        numbers[i].scale = Vector2(pop,1.0/pop)
        var clip: Array = data.get("clips", {}).get(STAGES[i], [])
        if clip.is_empty() or absf(WINDOWS[i].get_center().y-scroll-540) > 1150: continue
        var index: int = int(maxf(0,age) * float(data.get("fps",8))) % clip.size()
        if index == _frame_indices[i]: continue
        var image := Image.new()
        if image.load_jpg_from_buffer(clip[index]) != OK: continue
        _decoded[i].set_image(image)
        screens[i].texture = _decoded[i]
        var fit: float = minf(WINDOWS[i].size.x/image.get_width(), WINDOWS[i].size.y/image.get_height())
        screens[i].scale = Vector2.ONE*fit
        screens[i].position = WINDOWS[i].get_center()-Vector2(image.get_size())*fit*.5
        screens[i].visible = true
        _frame_indices[i] = index

func _read_direction() -> Vector2:
    var direction := Vector2.ZERO
    if interactive:
        direction.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
        direction.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_SPACE))
    return direction

func move_ghost(delta: float) -> void:
    flight.advance(delta,_read_direction())

func _build_cloud_front() -> void:
    cloud_layer = CanvasLayer.new()
    cloud_layer.layer = 2
    add_child(cloud_layer)
    cloud_front = Node2D.new()
    cloud_layer.add_child(cloud_front)
    var edge: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/heaven/settlement/cloud_edge.json"))
    var profile := Image.create(1920,1,false,Image.FORMAT_RF)
    for x in 1920: profile.set_pixel(x,0,Color(float(edge[x])/6144.0,0,0))
    var profile_texture := ImageTexture.create_from_image(profile)
    for i in 3:
        var cloud := Sprite2D.new()
        cloud.texture = load("res://assets/art/heaven/settlement/descent_%02d.png" % i)
        cloud.centered = false
        cloud.position.y = i*2048
        if i == 0:
            cloud.region_enabled = true
            cloud.region_rect = Rect2(0,1080,1920,968)
            cloud.position.y = 1080
            cloud.region_filter_clip_enabled = true
        var material := ShaderMaterial.new()
        material.shader = preload("res://shaders/settlement_cloud_occlusion.gdshader")
        material.set_shader_parameter("cloud_edge",profile_texture)
        material.set_shader_parameter("source_y",i*2048.0)
        material.set_shader_parameter("align_opening",i == 0)
        cloud.material = material
        cloud_front.add_child(cloud)

func _on_ghost_exited() -> void:
    if _return_started: return
    _return_started = true
    var transition = preload("res://modules/cinematic/settlement_return_home.gd").new()
    # 独立于结算场景存活，确保换主页时黑幕与右下角五角色不会闪断。
    get_tree().root.add_child(transition)
    transition.start.call_deferred()
