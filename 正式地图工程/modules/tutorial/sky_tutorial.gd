extends "res://modules/tutorial/recorded_tutorial.gd"
func _ready():
    stage_key="sky"
    clean_outer_matte=true
    recording_path="res://assets/video/sky_shift"
    frame_origin=Vector2(254, 2708)
    frame_size=Vector2(824, 532)
    hole_origin=Vector2(30, 30)
    hole_size=Vector2(764, 472)
    hole_mask_path="res://assets/art/ui/tutorial_sky_hole.png"
    super._ready()
    var game=get_parent()
    if game.has_meta("skip_tutorial") or "--script" in OS.get_cmdline_args():return
    game.get_node("OceanLink/FishStage/JungleLayout/CanopyPossession").possession_finished.connect(_on_possessed)
func _on_possessed(_host):_offer.call_deferred()
func replay_now():
    _force_replay=true
    _offer()
