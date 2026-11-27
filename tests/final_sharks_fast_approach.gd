extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    var quick=root.get_node("SegmentQuickStart")
    quick.start_segment(3)
    await quick.segment_started
    var game=current_scene
    var stage=game.get_node("OceanLink/FishStage")
    var fish=stage.fish
    var trio=stage.get_node("FinalSharks")
    var shore=stage.get_node("ShoreExit")
    var pacing=stage.get_node("Pacing")
    fish.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
    game.process_mode=Node.PROCESS_MODE_DISABLED
    pacing.reset()
    stage.get_node("InkOverlay").reset()
    stage.get_node("JellyfishReveal").reset()
    fish.get_node("Movement").enabled=false
    fish.get_node("Input").up_held=true
    for speed in [100,420,1000]:
        trio.reset()
        shore.reset()
        fish.position=Vector2(960,shore.surface_y+1500)
        fish.velocity=Vector2(0,-speed)
        trio._physics_process(0)
        check(trio.triggered,"Wave triggers early enough at speed="+str(speed))
        check(trio.sharks.all(func(s):return s.state==s.State.LOCKING),"All three show warning together")
        fish.position.y=shore.surface_y+300
        var motion: Vector2=fish.get_node("Teleport")._limit_surface_motion(Vector2(0,-640))
        check(fish.position.y+motion.y>=shore.surface_y+trio.shore_clearance,"Blink cannot bypass warning")
        fish.position.y=shore.surface_y-10
        shore._physics_process(.01)
        check(shore.state==shore.State.SWIMMING and fish.position.y>=shore.surface_y+trio.shore_clearance,"Fast approach stays underwater during warning")
        for s in trio.sharks:
            s._physics_process(trio.lock_seconds)
        trio._physics_process(trio.lock_seconds)
        check(trio.sharks.all(func(s):return s.state==s.State.DASHING),"Warning reaches actual simultaneous dash")
        check(not trio.can_leave_water(),"Short dash window is preserved")
        trio._physics_process(trio.dash_experience_seconds+.01)
        check(trio.can_leave_water(),"Surface releases after dash window")
        fish.position.y=shore.surface_y-1
        fish.velocity.y=-200
        shore._physics_process(.001)
        check(shore.state==shore.State.AIRBORNE,"Player can then leap onto shore")
    trio.reset()
    check(not trio.triggered and trio.attack_elapsed==0,"Retry rearms the encounter")
    print("FINAL_SHARKS_FAST_APPROACH failures=",failures)
    quit(1 if failures else 0)
