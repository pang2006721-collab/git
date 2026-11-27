extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    var fish=stage.fish
    fish.get_node("Movement").set_physics_process(false)
    fish.position=Vector2(960,35000)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","BossTentacleNet","JellyfishBoss"]:
        stage.get_node(name).set_physics_process(false)
    var view=stage.get_node("JellyfishReveal")
    view.set_process(false)
    view.wide_zoom=.5 # Even a requested wider zoom must stop at the authored edges.
    var boss=stage.get_node("JellyfishBoss")
    game.camera.zoom=Vector2.ONE*1.35
    game.camera.set_follow_target(fish,true)
    game.camera.set_process(false)
    var rest_scale: Vector2=fish.get_node("Visual/Sprite").scale
    check(view.state==view.State.WAITING,"Ordinary swimming retains normal framing before the jellyfish arrives")
    boss._begin_entrance()
    view._process(0)
    check(view.state==view.State.REVEALING,"The real jellyfish appeared signal starts the wide reveal")
    var previous: float=game.camera.zoom.x
    for i in 130:
        view._process(.015)
        check(game.camera.zoom.x<=previous+.0001,"Jellyfish entrance pulls back smoothly without zoom reversal")
        previous=game.camera.zoom.x
    game.camera._process(.016)
    check(view.state==view.State.WIDE and abs(game.camera.zoom.x-1.0)<.001,"The encounter retains the same wide view as the eagle")
    var half: float=game.camera.get_viewport_rect().size.x*.5/game.camera.zoom.x
    check(game.camera.global_position.x-half>=-.1 and game.camera.global_position.x+half<=1920.1,"The jellyfish view stays inside the original map edges")
    check(fish.get_node("Visual/Sprite").scale==rest_scale and game.player==fish and fish.get_node("Input").enabled,"Fish naturally scales with the camera while remaining controllable")
    fish.position.y=stage.get_node("ShoreExit").surface_y+2200
    view._process(.3)
    check(view.state==view.State.WIDE,"The near-surface quick start still gets time to see the jellyfish in the wide view")
    for i in 140: view._process(.015)
    for i in 80: view._process(.015)
    check(view.state==view.State.FINISHED and game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Approaching the surface smoothly restores normal framing before the final grab")
    check(fish.get_node("Visual/Sprite").scale==rest_scale,"Surface return restores original fish size")
    view.reset()
    fish.position.y=35000
    boss._begin_entrance()
    view._process(0)
    for i in 130: view._process(.015)
    view.finish_for_surface()
    view.reset()
    boss._begin_entrance()
    view._process(0)
    view._process(.6)
    view.reset()
    check(view.state==view.State.WAITING and game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Restart cancels a partially completed pullback")
    print("JELLYFISH_REVEAL_CAMERA_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
