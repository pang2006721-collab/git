extends SceneTree
func _initialize():run.call_deferred()
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var shot=game.get_node("PossessionCamera")
    var route=game.get_node("RouteReveal")
    route.set_process(false)
    shot.set_process(false)
    game.camera.zoom=Vector2.ONE*1.35
    var normal:Vector2=game.camera.zoom
    shot.begin(game.soul,game.demon.get_node("Host"))
    for i in 60:
        shot._process(1.0/60)
        assert(game.camera.zoom.is_equal_approx(normal),"Hell possession keeps the normal zoom")
    game.demon.get_node("Host").take_control()
    game.demon.get_node("Movement").enabled=false
    game.player=game.demon
    game.demon.position=Vector2(1500,47980)
    shot.finish(game.demon)
    route._process(.1)
    assert(not route.active,"Route cannot acquire camera during possession recovery")
    shot._process(1.0/60)
    assert(not shot.active)
    for target_name in ["Target01","Target02","Target04"]:
        game.demon.global_position=game.get_node("Fork/Targets/"+target_name).global_position+Vector2(100,400)
        route._process(.5)
        assert(not route.active and game.camera.zoom.is_equal_approx(normal),"Other balls keep normal zoom")
    game.demon.position=Vector2(1500,47980)
    route._process(.5)
    assert(route.active)
    route._process(3)
    assert(game.camera.zoom.is_equal_approx(normal),"Route restores the true normal zoom")
    print("HELL_ENTRY_ZOOM_PASS")
    quit()
