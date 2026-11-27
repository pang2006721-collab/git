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
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.set_physics_process(false)
    var motor=body.get_node("Movement")
    motor.set_physics_process(false)
    body.get_node("VineClimber").set_physics_process(false)
    body.get_node("VineClimber").reset()
    for vine in layout.vines: vine.set_physics_process(false)
    game.camera.set_process(false)
    var transition=layout.get_node("CanopyTransition")
    transition.set_physics_process(false)
    transition.travel.set_process(false)
    await process_frame
    await process_frame
    body.global_position=layout.to_global(Vector2(930,21100))
    check(not transition._can_enter(),"Flight below the canopy does not start a cinematic")
    body.global_position=layout.to_global(Vector2(930,20580))
    check(transition._can_enter(),"The controlled squirrel entering the actual dark leaf underside triggers the exit")
    transition._physics_process(.01)
    check(transition.state==transition.State.BURROWING and game.exit_in_progress,"Canopy entry starts once and protects the transition")
    check(not body.get_node("VineClimber").is_physics_processing() and body.transferring and not motor.enabled and not body.get_node("Input").enabled,"The cinematic owns movement and input")
    check(not layout.get_node("BeeEncounter").enabled and body.z_index<14,"The squirrel burrows behind leaves with bee attacks stopped")
    transition._physics_process(.46)
    check(not body.visible and transition.travel.active,"Squirrel remains hidden during the upward camera trip")
    transition.travel._process(2)
    var bounce=transition.play.bouncer
    bounce.set_physics_process(false)
    check(body.visible and transition.state==transition.State.COMPLETE and bounce.enabled,"Camera arrival hands directly to the old canopy bouncing behavior")
    check(body.z_index>14 and not motor.enabled and not body.get_node("Input").enabled,"Canopy bouncing owns movement and keeps the squirrel above the leaf layer")
    check(not body.transferring and not game.exit_in_progress,"Canopy arrival ends cinematic protection")
    check(transition.play.fold.visible,"Jumping out also pops the fold from its center")
    var locked_fold:=Vector2.INF
    var apex: float=body.position.y
    for i in 200:
        bounce._physics_process(.01)
        transition.play._process(.01)
        transition.play.fold._process(.01)
        apex=minf(apex,body.position.y)
        if bounce.buried: break
    check(apex<transition.canopy_y(body.position.x)+transition.bounce_inset-200,"First jump genuinely rises above the crown")
    check(bounce.buried and not body.visible,"After falling, squirrel burrows back into the crown instead of standing on a platform")
    check(transition.play.fold.visible,"The supplied fold appears on descent and remains through landing")
    check(body.get_node("Visual/Sprite").scale.x<.85,"The squirrel gently shrinks while sinking into the leaves")
    Input.action_press(&"flap")
    bounce._physics_process(.01)
    Input.action_release(&"flap")
    check(not bounce.buried and body.visible and bounce._velocity.y<0,"A second jump can launch from the buried state")
    check(transition.play.fold.visible and body.get_node("Visual/Sprite").scale.x<.85,"Next jump starts small and pulses the fold again")
    for i in 100: transition.play.fold._process(.01)
    check(not transition.play.fold.visible,"The fold spring finishes and disappears without scale drift")
    Input.action_press(&"move_right")
    for i in 30:
        bounce._physics_process(.01)
        transition.play._process(.01)
    Input.action_release(&"move_right")
    check(body.position.x>1040 and body.get_node("Visual/Sprite").flip_h,"Air steering and facing remain available during canopy jumps")
    check(body.get_node("Visual/Sprite").scale.x>.99,"Emergence smoothly restores normal size above the opening")
    var fixed_landing:=Vector2.INF
    for i in 200:
        bounce._physics_process(.01)
        transition.play._process(.01)
        transition.play.fold._process(.01)
        if transition.play._landing_open:
            if fixed_landing==Vector2.INF:
                fixed_landing=transition.play.fold.position
                Input.action_press(&"move_left")
            check(transition.play.fold.position==fixed_landing,"Late opposite steering cannot drag the locked landing fold")
        if bounce.buried: break
    Input.action_release(&"move_left")
    check(bounce.buried and is_finite(bounce.landing_target_x) and abs(body.position.x-bounce.landing_target_x)<4,"The squirrel settles into the fixed opening after a sideways jump")
    transition.reset()
    check(transition.state==transition.State.WAITING and body.z_index==10 and layout.get_node("BeeEncounter").enabled,"Replay restores normal layers and encounters")
    print("SQUIRREL_CANOPY_TRANSITION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
