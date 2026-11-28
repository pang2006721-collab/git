extends "res://modules/tutorial/recorded_tutorial.gd"
func _ready():
    stage_key="sky"
    backdrop_opacity=.62
    clean_outer_matte=true
    recording_path="res://assets/video/sky_shift"
    frame_origin=Vector2(254, 2708)
    frame_size=Vector2(824, 532)
    hole_origin=Vector2(30, 30)
    hole_size=Vector2(764, 472)
    hole_mask_path="res://assets/art/ui/tutorial_sky_hole.png"
    super._ready()
