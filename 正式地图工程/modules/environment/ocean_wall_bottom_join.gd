extends Node2D
## 补原侧墙素材底端的裁切缺口：只复用地图原像素，沿原黑边遮挡小鱼。
func _ready() -> void:
    z_index=17
    z_as_relative=false
    var source: Sprite2D=get_node("../../Map/ImageTiles/Tile19")
    var art: Texture2D=load(source.get_meta("runtime_texture"))
    var image:=art.get_image()
    global_position=source.global_position
    for left in [true,false]:
        var points:=PackedVector2Array()
        var edge_x:=250 if left else 1690
        points.append(Vector2(0 if left else 1920,0))
        for y in range(0,513,4):
            var edge:=edge_x
            for x in range(0,480) if left else range(1440,1920):
                var color:=image.get_pixel(x,y+1)
                if maxf(color.r,maxf(color.g,color.b))<.08:
                    edge=maxi(edge,x+1) if left else mini(edge,x)
            points.append(Vector2(edge,y))
        points.append(Vector2(0 if left else 1920,512))
        var cover:=Polygon2D.new()
        cover.name="Left" if left else "Right"
        cover.texture=art
        cover.polygon=points
        var uv:=PackedVector2Array()
        for point in points: uv.append(point+Vector2(0,1))
        cover.uv=uv
        add_child(cover)
