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
