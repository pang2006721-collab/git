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
