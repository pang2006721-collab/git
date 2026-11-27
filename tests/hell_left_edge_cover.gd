extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.process_mode=Node.PROCESS_MODE_DISABLED
    var cover=game.get_node("WorldLayers/HellLeftEdgeCover")
    check(cover.get_child_count()==6,"All six foreground wall tiles receive edge fill")
    var covered_until:=40960.0
    for index in range(20,26):
        var art=cover.get_node("Edge%d"%index)
        var wall=game.get_node("WorldLayers/Walls/Left/Tile%d"%index)
        check(art.texture==wall.texture,"Fill uses original wall colors rather than background")
        check(art.global_position.x<0 and art.global_position.x+art.get_rect().size.x>=12,"Fill spans viewport boundary with outer bleed")
        check(art.global_position.y==wall.global_position.y,"Fill follows actual foreground wall registration")
        check(art.global_position.y<=covered_until,"No vertical gap between fill tiles")
        covered_until=maxf(covered_until,art.global_position.y+art.get_rect().size.y)
        check(art.material.shader.resource_path=="res://shaders/hell_left_edge_fill.gdshader","Transparent source padding receives opaque matching color")
    check(covered_until>=52000,"Fill reaches bottom of hell")
    check(game.get_node("WorldLayers/Walls/Left").position==Vector2(-3,0),"Playable wall contour stays unchanged")
    print("HELL_LEFT_EDGE_COVER failures=",failures)
    game.queue_free()
    await process_frame
    quit(1 if failures else 0)
