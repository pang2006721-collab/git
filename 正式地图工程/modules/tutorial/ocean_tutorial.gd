extends "res://modules/tutorial/recorded_tutorial.gd"
func _ready():
    stage_key="ocean"
    clean_left_matte=true
    recording_path="res://assets/video/ocean_dodge"
    frame_origin=Vector2(240,1224)
    frame_size=Vector2(824,535)
    hole_origin=Vector2(55,55)
    hole_size=Vector2(710,430)
    super._ready()
    var game=get_parent()
    if game.has_meta("skip_tutorial") or "--script" in OS.get_cmdline_args():return
    game.get_node("OceanLink/FishStage/Possession").possession_finished.connect(_on_possessed)
func _on_possessed(_host):_offer.call_deferred()
func replay_now():
    _force_replay=true
    _offer()
