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
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    var sky=layout.get_node("SkyEagle")
    sky.set_process(false)
    check(sky.circling_seconds==2.0 and sky.hidden_seconds==5.0,"Circling starts the call after two seconds; quiet interval lasts five")
    sky.circling_seconds=20.0 # Isolate orbit coverage from the short production call interval.
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
    var initial_y: float=sky.eagle.global_position.y
    var art_half: float=sky.eagle.sprite.get_rect().size.y*.5*absf(sky.eagle.sprite.scale.y*sky.eagle.scale.y)
    check(initial_y-art_half>game.camera.global_position.y+game.camera.get_viewport_rect().size.y*.5/game.camera.zoom.y,"Entire eagle starts below the viewport, including raised wing tips")
    var previous: float=game.camera.zoom.x
    for i in 130:
        sky._process(.015)
        check(game.camera.zoom.x<=previous+.0001,"The reveal continuously pulls back without reversing zoom")
        previous=game.camera.zoom.x
    check(sky.eagle.global_position.y<initial_y-650,"Entrance lifts the eagle into view from below")
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
    var wide_rest: Vector2=game.camera.zoom
    sky.circling_seconds=sky._phase_elapsed+.02
    sky._process(.03)
    check(sky.state==sky.State.SCREECHING and sky.eagle.screaming,"Circling periodically switches to the approved upward-screech pose")
    check(sky.eagle.sprite.texture==sky.eagle.SCREECH,"Screech displays the approved flat-color image")
    var call_start: Vector2=sky.eagle.global_position
    sky._process(sky.screech_seconds*.5)
    check(sky.eagle.global_position.y>call_start.y and sky.eagle.global_position.y<call_start.y+sky.screech_sink,"Calling eagle slowly sinks instead of holding a still pose")
    sky._process(sky.screech_seconds*.5+.01)
    check(sky._departure_start.distance_to(sky.eagle.global_position)<.01,"Departure continues smoothly from the lowered call position")
    check(sky.state==sky.State.DEPARTING and not sky.eagle.screaming,"After the call the eagle resumes flapping and departs")
    check(sky.eagle.frame_index==1 and sky.eagle.sprite.texture!=sky.eagle.SCREECH,"Departure closes the mouth and immediately starts a power downstroke")
    var launch_start: Vector2=sky.eagle.global_position
    sky._process(sky.departure_seconds*.2)
    var early_distance: float=sky.eagle.global_position.distance_to(launch_start)
    var accelerating_start: Vector2=sky.eagle.global_position
    sky._process(sky.departure_seconds*.2)
    check(sky.eagle.global_position.distance_to(accelerating_start)>early_distance,"Departure accelerates instead of lingering through another wing hold")
    sky._process(sky.departure_seconds+.01)
    check(sky.state==sky.State.HIDDEN and not sky.eagle.visible,"Eagle disappears only after flying above the viewport")
    sky.get_node("Hail").reset() # Hail timing is covered by sky_hail_rows.gd.
    sky._process(sky.hidden_seconds-.1)
    check(sky.state==sky.State.HIDDEN,"Eagle stays absent for the configured interval")
    sky._process(.11)
    check(sky.state==sky.State.REVEALING and sky.eagle.visible,"Next cycle starts below the screen")
    check(sky.eagle.global_position.y>game.camera.global_position.y+500,"Repeat entrance begins below the viewport")
    sky._process(sky.reveal_seconds+.01)
    check(sky.state==sky.State.ACTIVE and game.camera.zoom==wide_rest,"Repeat entrance resumes circling without zooming the camera again")
    sky.circling_seconds=.2
    sky._process(.21)
    check(sky.state==sky.State.SCREECHING,"The sequence repeats rather than ending after one call")
    sky.reset()
    check(not sky.eagle.visible and game.camera.zoom.is_equal_approx(Vector2.ONE*1.35) and sprite.scale==rest_scale,"Reset restores camera, character size and hidden eagle")
    check(not sky.eagle.screaming and sky.eagle.playback_speed==1.0 and sky._phase_elapsed==0.0,"Reset cancels the call cycle and restores normal flight art")
    print("EAGLE_SKY_REVEAL_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
