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
    var hud=game.get_node("OrangeCounter")
    hud.set_process(false)
    var trail=game.get_node("HellOranges")
    trail.set_physics_process(false)
    check(hud.displayed_count==0 and hud.numbers.get_child_count()==1,"Counter starts at zero using the supplied digit")
    var fixed_logo:Vector2=hud._logo_origin
    for i in 11:trail._collect_orange(trail.get_child(i))
    check(hud._target_count==11 and hud.displayed_count==0,"Burst pickups queue every increment")
    hud._process(.02)
    check(hud.displayed_count==0 and hud.numbers.scale.y<1,"Number anticipates before adding one")
    hud._process(.04)
    check(hud.displayed_count==1,"First pop increments by exactly one")
    for frame in 200:hud._process(1.0/60)
    check(hud.displayed_count==11 and hud.numbers.get_child_count()==2,"Queued pickups finish and carry from nine to ten")
    check(hud._logo_origin==fixed_logo,"Changing numeral widths and carrying never shifts the logo")
    check(hud.numbers.scale==Vector2.ONE,"Number settles at exactly its rest scale")
    var logo:Vector2=hud.logo.position
    hud._process(.5)
    check(hud.logo.position.distance_to(logo)>0 and hud.logo.position.distance_to(hud._logo_origin)<4,"Logo gently moves within a few pixels")
    var saved:Vector2=hud.anchor.position
    game.camera.zoom=Vector2.ONE*1.0
    hud._process(0)
    check(hud.anchor.position==saved,"World camera zoom cannot move or scale the screen counter")
    game.restart()
    hud._process(0)
    check(hud.displayed_count==11 and trail.collected_count==11,"Retry preserves both the collected total and its display")
    trail._collect_orange(trail.get_child(11))
    game.process_mode=Node.PROCESS_MODE_DISABLED
    for frame in 20:hud._process(1.0/60)
    check(hud.displayed_count==12 and hud.process_mode==Node.PROCESS_MODE_ALWAYS,"A queued increment can finish while death freezes gameplay")
    game.process_mode=Node.PROCESS_MODE_INHERIT
    hud.motion_amount=0
    hud._process(.1)
    check(hud.logo.position==hud._logo_origin and hud.multiply.position==hud._multiply_origin,"Motion strength can be reduced to zero")
    game.hide()
    hud._process(0)
    check(not hud.visible,"Hidden preloaded level cannot leak the HUD into the opening")
    print("ORANGE_COUNTER_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
