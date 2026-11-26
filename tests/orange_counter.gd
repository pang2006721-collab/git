extends SceneTree
var failures: Array[String]=[]
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.demon.get_node("Host").take_control()
    game.player=game.demon
    game.demon.get_node("Movement").enabled=false
    var hud=game.get_node("OrangePickupCounter")
    hud.set_process(false)
    var trail=game.get_node("HellOranges")
    trail.set_physics_process(false)
    game.camera.set_follow_target(game.demon,true)
    check(not game.has_node("OrangeCounter") and not hud.visible,"Fixed corner counter is removed; no idle count remains")
    check(not hud.has_node("Anchor/Background") and not hud.has_node("Anchor/Logo"),"Popup contains just digits without a card or logo")
    for i in 3:trail._collect_orange(trail.get_child(i))
    check(hud._target_count==3 and hud.displayed_count==1 and hud.visible,"Three pickups queue individually and the first number pops immediately")
    var previous:int=hud.displayed_count
    for frame in 40:
        hud._process(1.0/60)
        check(hud.displayed_count-previous<=1,"Each animation adds only one")
        previous=hud.displayed_count
    check(hud.displayed_count==3 and hud.phase==hud.Phase.HOLD,"All three numbers pop before briefly holding the total")
    var fixed_position:Vector2=hud.anchor.position
    var screen:Vector2=hud.get_viewport().get_visible_rect().size
    check(absf(fixed_position.x-screen.x*.5)<1 and fixed_position.y<screen.y*.25,"Number is at the top center of the whole screen")
    game.demon.position+=Vector2(120,-180)
    game.camera.zoom=Vector2.ONE*1.0
    game.camera.set_follow_target(game.demon,true)
    hud._process(0)
    check(hud.anchor.position==fixed_position,"Player movement and camera zoom never move the popup from screen top center")
    hud._process(.5)
    check(hud.phase==hud.Phase.EXIT,"Idle total starts its exit")
    var before:float=hud.numbers.position.y
    hud._process(.2)
    check(hud.numbers.position.y<before and hud.numbers.modulate.a<1,"Exit moves upward while fading")
    hud._process(.4)
    check(not hud.visible and hud.displayed_count==3,"Popup disappears completely without clearing the true total")
    for i in range(3,11):trail._collect_orange(trail.get_child(i))
    hud._process(3)
    check(hud.displayed_count==11 and hud.numbers.get_child_count()==2,"Burst pickups and the nine-to-ten carry keep every increment")
    game.restart()
    check(not hud.visible and hud.displayed_count==11 and trail.collected_count==11,"Retry hides stale feedback and preserves session count")
    game.player=game.demon
    trail._collect_orange(trail.get_child(11))
    game.process_mode=Node.PROCESS_MODE_DISABLED
    hud._process(2)
    check(not hud.visible and hud.displayed_count==12 and hud.process_mode==Node.PROCESS_MODE_ALWAYS,"Pickup feedback finishes during death freeze")
    game.process_mode=Node.PROCESS_MODE_INHERIT
    print("ORANGE_COUNTER_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
