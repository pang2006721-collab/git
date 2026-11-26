extends SceneTree
## 使用实际初始场景运行：--script <本文件> res://scenes/ui/main_menu.tscn -- Settings（或 Start）。
var heard: int = 0
func _initialize(): run.call_deferred()
func run():
    await create_timer(.2).timeout
    var menu = current_scene
    var sfx = root.get_node("Sfx")
    sfx.played.connect(func(cue):
        if cue==&"ui": heard += 1)
    var args := OS.get_cmdline_user_args()
    var button = menu.get_node(args[0] if not args.is_empty() else "Settings")
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.position = button.get_global_rect().get_center()
    click.pressed = true
    root.push_input(click,true)
    await process_frame
    click = click.duplicate()
    click.pressed = false
    root.push_input(click,true)
    await process_frame
    print("STARTUP_UI_SOUND_FAILURES=",0 if heard==1 else 1)
    quit(0 if heard==1 else 1)
