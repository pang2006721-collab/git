extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.get_node("Fork").set_physics_process(false)
    var route=game.get_node("RouteReveal")
    route.set_process(false)
    game.get_node("LavaRiseReveal").set_process(false)
    route._process(.1)
    check(not route.active,"Unpossessed opening does not trigger route camera")
    game.demon.get_node("Host").take_control()
    game.demon.get_node("Movement").enabled=false
    game.player=game.demon
    game.demon.position=Vector2(1500,47980)
    game.demon.velocity=Vector2.ZERO
    game.camera.set_follow_target(game.demon,true)
    game.camera.zoom=Vector2.ONE*1.35
    var zoom:Vector2=game.camera.zoom
    route._process(.5)
    check(route.active and route.target.name==&"Target03","Approach to right-hand ball reveals its next route")
    check(game.camera.zoom.x<zoom.x and game.camera.zoom.x>=1,"View widens within the authored map boundary")
    game.camera._process(1)
    var size:Vector2=game.camera.get_viewport_rect().size/game.camera.zoom
    var view:Rect2=Rect2(game.camera.global_position-size*.5,size)
    check(view.grow(-50).has_point(game.demon.global_position) and view.grow(-50).has_point(route.target.global_position) and view.grow(-50).has_point(route._landing),"Player, ball and next landing fit the widened view together")
    check(game.demon.get_node("Input").enabled,"Guidance does not disable player controls")
    route._process(3)
    check(not route.active and game.camera.zoom==zoom and game.get_node("CameraAttention").enabled,"Normal framing and attention return after preview")
    route._process(.1)
    check(not route.active,"Staying in the same area does not repeat the preview")
    route.reset(true)
    game.demon.position=Vector2(1250,44830)
    route._process(.5)
    check(route.active and route.target.name==&"Target04","Left checkpoint approach also reveals the upper-left ball")
    game.get_node("LavaRiseReveal")._start()
    check(not route.active and game.get_node("LavaRiseReveal").active,"Lava introduction safely takes priority over route preview")
    game.get_node("LavaRiseReveal").reset()
    check(game.get_node("CameraAttention").enabled and game.camera.zoom==zoom,"Overlapping camera requests preserve the original state")
    route.reset(true)
    game.demon.position=Vector2(1500,47980)
    route._process(.5)
    game.restart()
    check(not route.active and route._seen.is_empty(),"Retry cancels route preview and rearms guidance")
    print("HELL_ROUTE_REVEAL_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
