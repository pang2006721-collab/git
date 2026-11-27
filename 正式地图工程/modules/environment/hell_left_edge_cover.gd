extends Node2D
## Cover only the outer eight pixels with the matching map artwork.
## Wall cutout registration and the playable inner contour stay untouched.
@export var cover_width: int = 8
func _ready() -> void:
    z_index=18
    z_as_relative=false
    var map_tiles: Node=get_node("../../Map/ImageTiles")
    for index in range(20,26):
        var source: Sprite2D=map_tiles.get_node("Tile%d"%index)
        var texture: Texture2D=load(source.get_meta("runtime_texture",source.get_meta("full_texture")))
        var region: Rect2i=Rect2i(source.region_rect)
        var strip:=texture.get_image().get_region(Rect2i(0,region.position.y,cover_width,region.size.y))
        var art:=Sprite2D.new()
        art.name="Edge%d"%index
        art.texture=ImageTexture.create_from_image(strip)
        art.centered=false
        art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(art)
        art.global_position=source.global_position
