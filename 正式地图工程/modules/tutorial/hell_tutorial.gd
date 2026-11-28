extends "res://modules/tutorial/recorded_tutorial.gd"
func _ready():
    super._ready()
    var game=get_parent()
    if book_mode or game.has_meta("skip_tutorial") or "--script" in OS.get_cmdline_args():return
    game.get_node("WallEntry").control_ready.connect(_offer,CONNECT_ONE_SHOT)
func replay_on_entry():
    _force_replay=true
    var entry=get_parent().get_node("WallEntry")
    if not entry.control_ready.is_connected(_offer):
        entry.control_ready.connect(_offer,CONNECT_ONE_SHOT)
