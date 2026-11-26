extends SceneTree
var failures:Array[String]=[]
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func _initialize():run.call_deferred()
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    await physics_frame
    for node in game.find_children("*","Node",true,false)+[game]:
        node.set_process(false)
        node.set_physics_process(false)
    var platform=game.get_node("Platforms/Breakable18")
    var body=game.demon
    var motor=body.get_node("Movement")
    var reader=body.get_node("Input")
    motor.enabled=true
    reader.external_control=true
    reader.jump_pressed=false
    reader.jump_held=false
    for direction in [-1.0,1.0]:
        body.global_position=platform.global_position+Vector2(-direction*90,-30)
        motor.reset()
        reader.move_axis=0
        for frame in 40:
            motor._physics_process(1.0/120)
            await physics_frame
        var ys:Array[float]=[]
        var speeds:Array[float]=[]
        var contacts:int=0
        reader.move_axis=direction
        for frame in 50:
            var previous:Vector2=body.global_position
            motor._physics_process(1.0/120)
            await physics_frame
            if absf(body.global_position.x-platform.global_position.x)<80:
                ys.append(body.global_position.y)
                speeds.append(absf(body.global_position.x-previous.x)*120)
                if body.is_on_floor():contacts+=1
        check(ys.size()>30,"Actual demon traverses the central walking surface in both directions")
        check(contacts==ys.size(),"Walking keeps floor contact at every central sample")
        check(ys.max()-ys.min()<.2,"Feet stay level instead of hopping across hand-drawn bumps")
        check(speeds.max()>motor.move_speed-2,"Walking reaches the controller's normal speed")
        print("WALK ",direction," samples=",ys.size()," contacts=",contacts," y_range=",ys.max()-ys.min()," min_speed=",speeds.min()," max_speed=",speeds.max())
    print("FIRST_BREAKABLE_WALK_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
