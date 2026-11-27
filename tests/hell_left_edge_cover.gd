extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.process_mode=Node.PROCESS_MODE_DISABLED
    var cover=game.get_node("WorldLayers/HellLeftEdgeCover")
    check(cover.get_child_count()==6,"All six hell tiles cover the viewport edge")
    for index in range(20,26):
        var art=cover.get_node("Edge%d"%index)
        var source=game.get_node("Map/ImageTiles/Tile%d"%index)
        var image: Image=art.texture.get_image()
        check(art.global_position==source.global_position,"Edge shares original map registration")
        check(image.get_width()==8,"Only outer eight pixels are covered")
        for y in range(0,image.get_height(),8):
            for x in 8:check(image.get_pixel(x,y).a>.99,"Outer edge is opaque throughout")
    check(game.get_node("WorldLayers/Walls/Left").position==Vector2(-3,0),"Inner wall registration stays unchanged")
    print("HELL_LEFT_EDGE_COVER failures=",failures)
    quit(1 if failures else 0)
