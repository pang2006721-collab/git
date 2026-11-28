extends "res://modules/tutorial/recorded_tutorial.gd"
func _ready():
    stage_key="jungle"
    backdrop_opacity=.62
    clean_outer_matte=true
    recording_path="res://assets/video/jungle_shift"
    frame_origin=Vector2(238, 1967)
    frame_size=Vector2(820, 532)
    hole_origin=Vector2(50, 50)
    hole_size=Vector2(720, 440)
    super._ready()
    var game=get_parent()
    if game.has_meta("skip_tutorial") or "--script" in OS.get_cmdline_args():return
    game.get_node("OceanLink/FishStage/JunglePossession").possession_finished.connect(_on_possessed)
func _on_possessed(_host):_offer.call_deferred()
func replay_now():
    _force_replay=true
    _offer()
