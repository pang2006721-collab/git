extends CanvasLayer
@export var stage_key:String="hell"
@export var recording_path:String="res://assets/video/hell_shift"
@export var frame_origin:=Vector2(248,497)
@export var frame_size:=Vector2(830,545)
@export var hole_origin:=Vector2(50,42)
@export var hole_size:=Vector2(735,463)
signal completed
signal dismissed
@export var save_path:String="user://tutorials.cfg"
@export_range(0.0,1.0) var backdrop_opacity:float=.84
var _force_replay:=false
var active:=false
var panel:Control
var key_art:TextureRect
var close_art:TextureButton
var frame:ColorRect
var movie:VideoStreamPlayer
var shade:ColorRect
var elapsed:=0.0
var pulses:Array[float]=[]
var pulse_index:=0
var saved_modes:Dictionary={}
var was_paused:=false
var _closing:=false
var _pulse:Tween
func _ready():
    var recording=JSON.parse_string(FileAccess.get_file_as_string(recording_path+".json"))
    pulses.assign(recording.shift_beats)
    layer=95
    process_mode=Node.PROCESS_MODE_ALWAYS
func _offer():
    var cfg=ConfigFile.new()
    cfg.load(save_path)
    if _force_replay or not cfg.get_value("watched",stage_key,false):start.call_deferred()
func start():
    if active:return
    active=true
    was_paused=get_tree().paused
    _freeze(get_parent())
    get_tree().paused=true
    var screen=Control.new()
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    add_child(screen)
    shade=ColorRect.new()
    shade.color=Color(0,0,0,0)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.add_child(shade)
    panel=Control.new()
    panel.size=Vector2(1080,1080*frame_size.y/frame_size.x+111)
    panel.position=(get_viewport().get_visible_rect().size-panel.size)*.5
    panel.pivot_offset=panel.size*.5
    panel.scale=Vector2(.7,.7)
    screen.add_child(panel)
    movie=VideoStreamPlayer.new()
    movie.expand=true
    movie.size=Vector2(1080,1080*frame_size.y/frame_size.x)
    movie.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var mat=ShaderMaterial.new()
    mat.shader=load("res://shaders/tutorial_movie_frame.gdshader")
    mat.set_shader_parameter("frame_art",load("res://assets/art/ui/tutorial_frames.jpg"))
    mat.set_shader_parameter("frame_origin",frame_origin)
    mat.set_shader_parameter("frame_size",frame_size)
    mat.set_shader_parameter("hole_origin",hole_origin)
    mat.set_shader_parameter("hole_size",hole_size)
    movie.self_modulate.a=0.0
    movie.stream=load(recording_path+".ogv")
    panel.add_child(movie)
    movie.finished.connect(func():finish(true))
    frame=ColorRect.new()
    var padding:=8.0*1080/frame_size.x
    frame.position=-Vector2.ONE*padding
    frame.size=movie.size+Vector2.ONE*padding*2
    frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
    frame.material=mat
    panel.add_child(frame)
    key_art=TextureRect.new()
    key_art.texture=load("res://assets/art/ui/tutorial_shift.png")
    key_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    key_art.size=Vector2(240,99)
    key_art.position=Vector2(420,movie.size.y+12)
    key_art.pivot_offset=key_art.size*.5
    key_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    panel.add_child(key_art)
    close_art=TextureButton.new()
    close_art.texture_normal=load("res://assets/art/ui/tutorial_close.png")
    close_art.ignore_texture_size=true
    close_art.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    close_art.size=Vector2(82,82)
    close_art.position=Vector2(1008,-24)
    close_art.pivot_offset=close_art.size*.5
    panel.add_child(close_art)
    close_art.pressed.connect(func():
        if _closing:return
        close_art.disabled=true
        var bounce=create_tween()
        bounce.tween_property(close_art,"scale",Vector2(.78,1.13),.07)
        bounce.tween_property(close_art,"scale",Vector2.ONE,.1)
        bounce.tween_callback(func():finish(false)))
    Sfx.play(&"bounce")
    var enter=create_tween().set_parallel()
    enter.tween_property(shade,"color:a",backdrop_opacity,.25)
    enter.tween_property(panel,"scale",Vector2.ONE,.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    await enter.finished
    if not _closing:movie.play()
func _freeze(node:Node):
    if node==self:return
    saved_modes[node]=node.process_mode
    node.process_mode=Node.PROCESS_MODE_PAUSABLE
    for child in node.get_children():_freeze(child)
func _process(_delta:float):
    if not active or _closing or not is_instance_valid(movie) or not movie.is_playing():return
    frame.material.set_shader_parameter("movie_texture",movie.get_video_texture())
    frame.material.set_shader_parameter("movie_ready",true)
    elapsed=movie.stream_position
    if pulse_index<pulses.size() and elapsed>=pulses[pulse_index]:
        pulse_index+=1
        _key_feedback()
func _key_feedback():
    Sfx.play(&"bounce")
    if _pulse and _pulse.is_running():_pulse.kill()
    key_art.scale=Vector2.ONE
    _pulse=create_tween()
    _pulse.tween_property(key_art,"scale",Vector2(1.16,.78),.07)
    _pulse.tween_property(key_art,"scale",Vector2(.93,1.12),.13)
    _pulse.tween_property(key_art,"scale",Vector2.ONE,.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    for side in [-1,1]:
        var accent=Line2D.new()
        accent.width=5
        accent.default_color=Color(1,.87,.45)
        accent.add_point(Vector2(side*139,-8))
        accent.add_point(Vector2(side*159,-19))
        accent.position=key_art.position+key_art.size*.5
        panel.add_child(accent)
        var tween=create_tween().set_parallel()
        tween.tween_property(accent,"position:x",accent.position.x+side*22,.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(accent,"modulate:a",0.0,.3)
        tween.chain().tween_callback(accent.queue_free)
func finish(watched:bool):
    if not active or _closing:return
    _closing=true
    Sfx.play(&"bounce")
    movie.paused=true
    var tween=create_tween()
    tween.tween_property(panel,"scale",Vector2(1.05,.95),.09)
    tween.tween_property(panel,"scale",Vector2(.1,.1),.23).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.parallel().tween_property(panel,"modulate:a",0.0,.23)
    tween.parallel().tween_property(shade,"color:a",0.0,.23)
    await tween.finished
    if watched:
        var cfg=ConfigFile.new()
        cfg.load(save_path)
        cfg.set_value("watched",stage_key,true)
        cfg.save(save_path)
    _restore()
    if watched:completed.emit()
    else:dismissed.emit()
    queue_free()
func _restore():
    for node in saved_modes:
        if is_instance_valid(node):node.process_mode=saved_modes[node]
    saved_modes.clear()
    if active:get_tree().paused=was_paused
    active=false
func _exit_tree():_restore()
