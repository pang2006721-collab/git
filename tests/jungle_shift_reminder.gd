extends SceneTree
func _initialize():run.call_deferred()
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    var layout=stage.get_node("JungleLayout")
    layout.get_node("BeeEncounter").enabled=false
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.show()
    body.transferring=false
    body.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    var climber=body.get_node("VineClimber")
    climber.set_physics_process(false)
    var hint=game.get_node("JungleShiftReminder")
    game.camera.set_process(false)
    game.camera.global_position=body.global_position
    assert(not game.has_node("JungleTutorial") and not paused)
    await create_timer(.3).timeout
    assert(hint.visible and hint.hold_demo,"Nearby vine shows the hold lesson")
    hint._age=.4
    hint._process(0)
    var center:Vector2=hint.art.get_global_transform()*(hint.art.size*.5)
    assert(hint.art.scale.y<.7)
    hint._age=.95
    hint._process(0)
    assert(hint.art.scale.y<.7,"Demo stays pressed instead of repeatedly tapping")
    assert((hint.art.get_global_transform()*(hint.art.size*.5)).is_equal_approx(center))
    Input.action_press(climber.grab_action)
    await create_timer(.5).timeout
    assert(hint.art.scale.y<.7 and not hint.learned)
    Input.action_release(climber.grab_action)
    await process_frame
    assert(not hint.learned,"A short hold does not end the lesson")
    Input.action_press(climber.grab_action)
    await create_timer(1.2).timeout
    assert(hint._hold_done and hint.visible and hint.art.scale.y<.7)
    Input.action_release(climber.grab_action)
    await create_timer(.2).timeout
    assert(hint.learned and not hint.visible,"Sustained grip then release completes the lesson")
    game.player=stage.fish
    hint.learned=false
    hint._process(.2)
    assert(not hint.visible,"No jungle cue in another character stage")
    root.get_node("SegmentQuickStart").start_segment(5)
    for i in 240:
        await create_timer(.02).timeout
        if current_scene!=game and current_scene!=null:break
    await create_timer(.5).timeout
    assert(not current_scene.has_node("JungleTutorial") and not paused,"Key 5 also skips the modal")
    print("JUNGLE_HOLD_SHIFT_PASS: nearby vine, long press demo, actual hold, short tap, release, center, no modal")
    quit()
