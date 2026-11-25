extends SceneTree
var failures:Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    var trail=game.get_node("HellOranges")
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.demon.get_node("Host").take_control()
    game.player=game.demon
    game.demon.get_node("Movement").set_physics_process(false)
    trail.set_physics_process(false)
    await physics_frame
    check(trail.get_child_count()==40,"Forty oranges guide static routes and the jumps toward upper teleport targets")
    for orange in trail.get_children():
        check(orange.global_position.is_finite(),"Orange has a valid static world position: "+str(orange.name))
        var shape=CircleShape2D.new()
        shape.radius=35
        var query=PhysicsShapeQueryParameters2D.new()
        query.shape=shape
        query.transform=Transform2D(0,orange.global_position)
        query.collision_mask=9
        check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(),"Orange lies outside solid platform and wall: "+str(orange.name))
    for a in trail.get_children():
        for b in trail.get_children():
            if a==b:continue
            check(a.global_position.distance_to(b.global_position)>=125,"Orange groups keep a clear minimum spacing")
    var left=trail.get_node("FirstLedge01")
    var right=trail.get_node("FirstLedge02")
    check(absf(left.position.y-right.position.y)<.01 and is_equal_approx(right.position.x-left.position.x,128),"Orange pairs share a baseline with consistent spacing")
    var orange=trail.get_child(0)
    var initial:Vector2=orange.global_position
    orange._process(.3)
    check(orange.global_position!=initial and orange.global_position.distance_to(initial)<18,"Orange floats and gently sways")
    var collision=game.demon.get_node_or_null("Collision")
    var offset:Vector2=collision.global_position-game.demon.global_position if collision!=null else Vector2(0,-60)
    game.demon.global_position=orange.global_position-offset
    trail._physics_process(0)
    check(orange.collected and trail.collected_count==1,"Player collects an actual orange")
    trail._physics_process(0)
    check(trail.collected_count==1,"Same orange cannot count twice")
    orange._process(.04)
    check(orange.visible and orange.art.scale.x>.85 and orange.art.modulate.a==1,"Pickup first pops visibly without fading out")
    game.demon.global_position+=Vector2(90,-30)
    orange._process(.18)
    var target:Vector2=game.demon.get_node("Collision").global_position
    check(orange.visible and orange.art.scale.x<.85 and orange.global_position.distance_to(target)<initial.distance_to(target),"Orange shrinks and flies toward the moving player")
    orange._process(.2)
    check(not orange.visible and orange.global_position.is_equal_approx(target),"Orange finishes inside player body")
    game.restart()
    check(orange.collected and trail.collected_count==1,"Death retry preserves collected oranges and total")
    var other=trail.get_child(1)
    game.dead=true
    game.player=game.demon
    game.demon.get_node("Host").take_control()
    game.demon.global_position=other.global_position-offset
    trail._physics_process(0)
    check(not other.collected,"Dead player cannot collect oranges")
    print("HELL_ORANGE_GUIDANCE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
