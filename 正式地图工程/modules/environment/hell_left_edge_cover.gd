extends Node2D
## Extend the original foreground wall color over its transparent outer padding.
@export_range(8,24) var cover_width:int=12
@export_range(2,16) var outer_bleed:int=8
func _ready() -> void:
    z_index=18
    z_as_relative=false
    var walls:Node=get_node("../Walls/Left")
    for index in range(20,26):
        var source:Sprite2D=walls.get_node("Tile%d"%index)
        var art:=Sprite2D.new()
        art.name="Edge%d"%index
        art.texture=source.texture
        art.centered=false
        art.region_enabled=true
        art.region_filter_clip_enabled=true
        art.region_rect=Rect2(0,source.region_rect.position.y,cover_width+outer_bleed,source.region_rect.size.y)
        art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        var material:=ShaderMaterial.new()
        material.shader=preload("res://shaders/hell_left_edge_fill.gdshader")
        art.material=material
        add_child(art)
        art.global_position=Vector2(get_parent().global_position.x-outer_bleed,source.global_position.y)
