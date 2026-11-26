extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    var walls=game.get_node("WorldLayers/Walls")
    var tile=walls.get_node("Left/Tile25")
    check(walls.position==Vector2.ZERO and walls.get_node("Left").position==Vector2(-3,0),"Left wall uses the corrected registration without moving the shared wall root")
    check(tile.position==Vector2(3,51155),"Bottom tile retains its original position and collision alignment")
    check(tile.material!=null and tile.material.shader.resource_path=="res://shaders/hell_start_wall_outline.gdshader","Only affected start-wall tile uses local outline repair")
    var original:Texture2D=tile.material.get_shader_parameter("original_art")
    check(original.resource_path=="res://assets/art/reference_map/25.png","Repair samples the unmodified original drawing")
    var source=original.get_image()
    var foreground=tile.texture.get_image()
    for p in [Vector2i(357,200),Vector2i(400,220),Vector2i(450,240)]:
        var c:Color=source.get_pixelv(p)
        check(foreground.get_pixelv(p).a==0 and c.a>.9 and maxf(c.r,maxf(c.g,c.b))<.18,"Original black contour exists behind incorrectly transparent foreground at "+str(p))
    check(walls.get_node("Right/Tile25").material==null,"Opposite wall is not modified")
    print("HELL_START_WALL_OUTLINE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
