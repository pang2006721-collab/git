extends CanvasLayer
signal open_requested
signal closed
const CHAPTERS=["hell","ocean","jungle","sky"]
const BEANS=["demon","fish","squirrel","bird"]
@export var save_path:String="user://tutorials.cfg"
var entry:TextureButton
var entry_art:TextureRect
var page_index:int=-1
var chapter:CanvasLayer
var previous_chapter:CanvasLayer
var left:TextureButton
var right:TextureButton
var dots:Array[TextureButton]=[]
var dot_art:Array[Control]=[]
var _screen:Control
var _shade:ColorRect
var _nav:CanvasLayer
var _feedback:Node
var _active:=false
var _switching:=false
var _closing:=false
var _saved_modes:Dictionary={}
var _was_paused:=false
var _selection:Tween
var _arrow_motions:Dictionary={}
func _ready():
    layer=94
    process_mode=Node.PROCESS_MODE_ALWAYS
    _feedback=preload("res://modules/ui/settings_interaction_bounce.gd").new()
    add_child(_feedback)
    var layout=Control.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
    layout.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    add_child(layout)
    entry=TextureButton.new()
    entry.position=Vector2(1760,38)
    entry.size=Vector2(116,110)
    entry.focus_mode=Control.FOCUS_NONE
    entry_art=_add_art(entry,load("res://assets/art/ui/tutorial_book.png"),Vector2(12,12),Vector2(92,87))
    layout.add_child(entry)
    entry.pressed.connect(func():
        if _active:return
        entry.disabled=true
        _feedback.pulse(entry_art,.18)
        await get_tree().create_timer(.13).timeout
        open_requested.emit()
        if not _active:entry.disabled=false)
func _add_art(button:Control,texture:Texture2D,position:Vector2,size:Vector2)->TextureRect:
    var art=TextureRect.new()
    art.texture=texture
    art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.position=position
    art.size=size
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    button.add_child(art)
    return art
func is_open()->bool:return _active
func hide_entry():entry.hide()
func open():
    if _active:return
    _active=true
    _closing=false
    _was_paused=get_tree().paused
    _freeze_menu(get_parent())
    get_tree().paused=true
    entry.hide()
    _screen=Control.new()
    _screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_screen)
    _shade=ColorRect.new()
    _shade.color=Color(0,0,0,0)
    _shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _screen.add_child(_shade)
    _nav=CanvasLayer.new()
    _nav.layer=96
    add_child(_nav)
    var nav_layout=Control.new()
    nav_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    nav_layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
    nav_layout.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _nav.add_child(nav_layout)
    left=_arrow(nav_layout,Vector2(288,365),false,-1)
    right=_arrow(nav_layout,Vector2(1504,365),true,1)
    dots.clear()
    dot_art.clear()
    for i in 4:
        var dot=TextureButton.new()
        dot.position=Vector2(776+i*96,970)
        dot.size=Vector2(80,80)
        dot.focus_mode=Control.FOCUS_NONE
        var selection=Control.new()
        selection.position=Vector2(13,13)
        selection.size=Vector2(54,54)
        selection.pivot_offset=selection.size*.5
        selection.mouse_filter=Control.MOUSE_FILTER_IGNORE
        dot.add_child(selection)
        var art=TextureRect.new()
        art.texture=load("res://assets/art/menu/loading_characters/"+BEANS[i]+".png")
        art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.size=selection.size
        art.mouse_filter=Control.MOUSE_FILTER_IGNORE
        selection.add_child(art)
        dots.append(dot)
        dot_art.append(selection)
        nav_layout.add_child(dot)
        dot.pressed.connect(func():
            _feedback.pulse(art,.18)
            show_page(i))
    page_index=-1
    var fade=create_tween()
    fade.tween_property(_shade,"color:a",.62,.25)
    show_page(0)
func _arrow(layout:Control,position:Vector2,mirror:bool,direction:int)->TextureButton:
    var button=TextureButton.new()
    button.position=position
    button.size=Vector2(128,240)
    button.focus_mode=Control.FOCUS_NONE
    var presence=Control.new()
    presence.size=button.size
    presence.pivot_offset=presence.size*.5
    presence.mouse_filter=Control.MOUSE_FILTER_IGNORE
    button.add_child(presence)
    button.set_meta("presence",presence)
    var art=_add_art(presence,load("res://assets/art/ui/tutorial_page_arrow.png"),Vector2(26,22),Vector2(76,196))
    art.flip_h=mirror
    layout.add_child(button)
    button.pressed.connect(func():
        _feedback.pulse(art,.19)
        await get_tree().create_timer(.08).timeout
        if _active and not _closing:show_page(page_index+direction))
    return button
func show_page(index:int):
    if not _active or _closing or _switching or index<0 or index>=4 or index==page_index:return
    _switching=true
    page_index=index
    _update_selection()
    previous_chapter=chapter
    chapter=load("res://modules/tutorial/"+CHAPTERS[index]+"_tutorial.gd").new()
    chapter.book_mode=true
    chapter.save_path=save_path
    add_child(chapter)
    chapter.presented.connect(func():
        if is_instance_valid(previous_chapter):
            previous_chapter.hide()
            previous_chapter.queue_free()
        previous_chapter=null
        _switching=false
        _update_selection(),CONNECT_ONE_SHOT)
    chapter.dismissed.connect(close)
    chapter.start()
func _update_selection():
    if _selection and _selection.is_running():_selection.kill()
    _selection=create_tween().set_parallel()
    for i in 4:
        _selection.tween_property(dot_art[i],"scale",Vector2.ONE*(1.24 if i==page_index else .78),.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        _selection.tween_property(dot_art[i],"modulate",Color.WHITE if i==page_index else Color(.42,.42,.42,.65),.2)
        dots[i].disabled=_switching
    left.disabled=_switching or page_index==0
    right.disabled=_switching or page_index==3
    _arrow_presence(left,page_index>0)
    _arrow_presence(right,page_index<3)
func _arrow_presence(button:TextureButton,shown:bool):
    var presence:Control=button.get_meta("presence")
    if not button.has_meta("shown"):
        button.set_meta("shown",shown)
        button.visible=shown
        presence.scale=Vector2.ONE if shown else Vector2(.02,.02)
        presence.modulate.a=1.0 if shown else 0.0
        return
    if button.get_meta("shown")==shown:return
    button.set_meta("shown",shown)
    if _arrow_motions.has(button) and _arrow_motions[button].is_running():_arrow_motions[button].kill()
    button.show()
    var tween=create_tween()
    _arrow_motions[button]=tween
    if shown:
        tween.tween_property(presence,"scale",Vector2.ONE,.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.parallel().tween_property(presence,"modulate:a",1.0,.2)
    else:
        tween.tween_property(presence,"scale",Vector2(1.16,.84),.07)
        tween.tween_property(presence,"scale",Vector2(.02,.02),.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        tween.parallel().tween_property(presence,"modulate:a",0.0,.2)
        tween.tween_callback(func():
            if is_instance_valid(button) and not button.get_meta("shown"):button.hide())
func close():
    if not _active or _closing:return
    _closing=true
    if _selection and _selection.is_running():_selection.kill()
    for motion in _arrow_motions.values():
        if motion.is_running():motion.kill()
    _arrow_motions.clear()
    if is_instance_valid(chapter):chapter.queue_free()
    if is_instance_valid(previous_chapter):previous_chapter.queue_free()
    chapter=null
    previous_chapter=null
    var fade=create_tween().set_parallel()
    fade.tween_property(_shade,"color:a",0.0,.2)
    for control in _nav.get_children():fade.tween_property(control,"modulate:a",0.0,.2)
    await fade.finished
    _screen.queue_free()
    _nav.queue_free()
    _restore()
    _feedback.reset()
    entry.show()
    entry.disabled=false
    closed.emit()
func _freeze_menu(node:Node):
    if node==self:return
    _saved_modes[node]=node.process_mode
    node.process_mode=Node.PROCESS_MODE_PAUSABLE
    for child in node.get_children():_freeze_menu(child)
func _restore():
    for node in _saved_modes:
        if is_instance_valid(node):node.process_mode=_saved_modes[node]
    _saved_modes.clear()
    if _active:get_tree().paused=_was_paused
    _active=false
    _switching=false
func _unhandled_input(event:InputEvent):
    if not _active or _closing or not event is InputEventKey or not event.pressed or event.echo:return
    var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
    if key in [KEY_LEFT,KEY_RIGHT]:
        var direction:int=-1 if key==KEY_LEFT else 1
        var button=left if direction<0 else right
        if not button.disabled:button.pressed.emit()
        get_viewport().set_input_as_handled()
    elif key==KEY_ESCAPE:
        if is_instance_valid(chapter) and not chapter.close_art.disabled:chapter.close_art.pressed.emit()
        get_viewport().set_input_as_handled()
func _exit_tree():_restore()
