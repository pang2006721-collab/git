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
    game.get_node("CameraAttention").enabled=false
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    var sky=layout.get_node("SkyEagle")
    sky.set_process(false)
    sky.wide_zoom=.5 # Even a requested wider zoom must stop at the authored edges.
    check(not sky.eagle.visible and sky.state==sky.State.WAITING,"The eagle does not appear before possessing the bird")
    var sprite=bird.get_node("Visual/Sprite")
    var rest_scale: Vector2=sprite.scale
    bird.get_node("Host").take_control()
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Patrol").set_physics_process(false)
    layout.get_node("CanopyBirdStage")._finished(bird.get_node("Host"))
    var start_y: float=bird.position.y
    game.camera.zoom=Vector2.ONE*1.35
    game.camera.set_follow_target(bird,true)
    game.camera.set_process(false)
    bird.position.y=start_y-100
    sky._process(0)
    check(sky.state==sky.State.WAITING,"Possession alone does not interrupt play with an eagle reveal")
    var shot=layout.get_node("CanopyPossessionCamera")
    shot.active=true
    bird.position.y=start_y-400
    sky._process(0)
    check(sky.state==sky.State.WAITING,"The reveal waits for possession camera recovery to finish")
    shot.active=false
    sky._process(0)
    check(sky.state==sky.State.REVEALING and sky.eagle.visible,"Climbing triggers the distant eagle and bounded wide view")
    var previous: float=game.camera.zoom.x
    for i in 130:
        sky._process(.015)
        check(game.camera.zoom.x<=previous+.0001,"The reveal continuously pulls back without reversing zoom")
        previous=game.camera.zoom.x
    game.camera._process(.016)
    check(sky.state==sky.State.ACTIVE and abs(game.camera.zoom.x-1.0)<.001,"The wide view remains after the entrance")
    var half: float=game.camera.get_viewport_rect().size.x*.5/game.camera.zoom.x
    check(game.camera.global_position.x-half>=-.1 and game.camera.global_position.x+half<=1920.1,"The eagle view stops at both authored map edges")
    check(sprite.scale==rest_scale and sky.eagle.z_index<bird.z_index,"Bird keeps its world scale and naturally shrinks with the camera pullback")
    check(game.player==bird and bird.get_node("Input").enabled and bird.get_node("Movement").enabled and Engine.time_scale==1,"The eagle entrance keeps bird controls and normal game speed")
    var min_pos: Vector2=sky.eagle.global_position
    var max_pos: Vector2=min_pos
    for i in 800:
        sky._process(.01)
        min_pos=min_pos.min(sky.eagle.global_position)
        max_pos=max_pos.max(sky.eagle.global_position)
    check(max_pos.x-min_pos.x>450 and max_pos.y-min_pos.y>140,"Eagle flies across and vertically even with a stationary camera")
    check(sky.eagle.look_target==bird,"Roaming eagle keeps watching the player")
    var before: Vector2=sky.eagle.global_position
    game.camera.global_position.y-=600
    sky._process(.016)
    check(sky.eagle.global_position.distance_to(before)<45,"Camera movement guides the flight without snapping the eagle")
    sky.reset()
    check(not sky.eagle.visible and game.camera.zoom.is_equal_approx(Vector2.ONE*1.35) and sprite.scale==rest_scale,"Reset restores camera, character size and hidden eagle")
    print("EAGLE_SKY_REVEAL_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
